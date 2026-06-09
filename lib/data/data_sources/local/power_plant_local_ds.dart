import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ecogrid_intelligence/core/enums/plant_type.dart';
import 'package:ecogrid_intelligence/core/exception/exceptions.dart';
import 'package:ecogrid_intelligence/core/resources/ingestion_report.dart';
import 'package:ecogrid_intelligence/core/utils/geo_utils.dart';
import 'package:ecogrid_intelligence/domain/model/power_plant.dart';
import 'package:ecogrid_intelligence/domain/model/region.dart';

/// CSV column indices for the EcoGrid power plant dataset.
///
/// Header: country, country_long, name, [empty], capacity_mw, latitude, longitude, primary_fuel
class _CsvColumns {
  static const int country = 0;
  static const int countryLong = 1;
  static const int name = 2;
  // index 3 is an empty column in the CSV
  static const int capacityMw = 4;
  static const int latitude = 5;
  static const int longitude = 6;
  static const int primaryFuel = 7;
  static const int minColumnsRequired = 8;
}

/// Local data source for power plant data.
///
/// Responsibilities:
/// - Parses the bundled CSV dataset from Flutter assets
/// - Validates rows and logs ingestion diagnostics
/// - Provides efficient in-memory querying (search, filter, geo)
///
/// Design decisions:
/// - In-memory list is the primary query surface (~35k records fits easily)
/// - Parsing CSV via background isolate takes ~1 second, eliminating need for disk caching
/// - All query methods are synchronous over the cached list after initial load
/// - Duplicate detection is conservative (coordinate + name similarity)
class PowerPlantLocalDataSource {
  List<PowerPlant>? _cachedPlants;
  IngestionReport? _lastReport;

  PowerPlantLocalDataSource();

  /// The most recent ingestion report, if available.
  IngestionReport? get lastReport => _lastReport;

  // ═══════════════════════════════════════════════════════
  // PUBLIC API — Data Access
  // ═══════════════════════════════════════════════════════

  /// Load all plants from memory cache or fresh CSV parse.
  Future<List<PowerPlant>> getAllPlants() async {
    if (_cachedPlants != null) return _cachedPlants!;

    // Fresh parse from bundled CSV in background isolate
    final result = await _parseAndIngest();
    _cachedPlants = result.plants;
    _lastReport = result.report;
    debugPrint(result.report.toString());

    return _cachedPlants!;
  }

  /// Get plants within a geographic region's bounding box or specific countries.
  Future<List<PowerPlant>> getPlantsByRegion(Region region) async {
    final all = await getAllPlants();

    // If the region specifies exact countries, use strict string matching
    if (region.countries != null && region.countries!.isNotEmpty) {
      final countrySet = region.countries!.map((c) => c.toLowerCase()).toSet();
      return all.where((p) {
        return countrySet.contains(p.country.toLowerCase()) ||
            (p.countryLong != null &&
                countrySet.contains(p.countryLong!.toLowerCase()));
      }).toList();
    }

    // Fallback: Use Bounding box for multi-country or continental regions
    return all.where((p) {
      return p.latitude >= region.minLat &&
          p.latitude <= region.maxLat &&
          p.longitude >= region.minLon &&
          p.longitude <= region.maxLon;
    }).toList();
  }

  /// Get plants filtered by country ISO code (e.g., "IND", "USA").
  Future<List<PowerPlant>> getPlantsByCountry(String countryCode) async {
    final all = await getAllPlants();
    final code = countryCode.toUpperCase().trim();
    return all.where((p) => p.country.toUpperCase() == code).toList();
  }

  /// Get plants filtered by fuel type.
  Future<List<PowerPlant>> getPlantsByFuelType(PlantType fuel) async {
    final all = await getAllPlants();
    return all.where((p) => p.primaryFuel == fuel).toList();
  }

  /// Find plants within a radius of a given coordinate.
  ///
  /// Uses bounding-box pre-filter + Haversine for accuracy.
  Future<List<PowerPlant>> getNearbyPlants(
    double lat,
    double lon, {
    double radiusKm = 50.0,
    int limit = 20,
  }) async {
    final all = await getAllPlants();

    // Fast bounding box pre-filter to reduce Haversine calculations
    final bbox = GeoUtils.boundingBox(lat, lon, radiusKm);
    final candidates = all.where((p) {
      return GeoUtils.isInBoundingBox(
        p.latitude,
        p.longitude,
        bbox['minLat']!,
        bbox['minLon']!,
        bbox['maxLat']!,
        bbox['maxLon']!,
      );
    }).toList();

    // Precise Haversine filter + sort by distance
    final withDistance =
        candidates
            .map(
              (p) => MapEntry(
                p,
                GeoUtils.haversineDistance(lat, lon, p.latitude, p.longitude),
              ),
            )
            .where((entry) => entry.value <= radiusKm)
            .toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    return withDistance.take(limit).map((e) => e.key).toList();
  }

  /// Search plants by name, country, or fuel type using a custom fuzzy match.
  ///
  /// Returns at most [limit] results to prevent UI lag on broad queries.
  Future<List<PowerPlant>> searchPlants(String query, {int limit = 50}) async {
    final all = await getAllPlants();
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) return [];

    final scoredPlants = <MapEntry<PowerPlant, int>>[];
    for (final plant in all) {
      final score = _fuzzyScore(lowerQuery, plant.searchKey);
      if (score > -10000) {
        scoredPlants.add(MapEntry(plant, score));
      }
    }

    scoredPlants.sort((a, b) => b.value.compareTo(a.value));
    return scoredPlants.take(limit).map((e) => e.key).toList();
  }

  /// Search for regions (countries) matching the query and dynamically compute their bounding boxes.
  Future<List<Region>> searchRegions(String query) async {
    final all = await getAllPlants();
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) return [];

    // First check against quick regions using fuzzy match
    final matchedQuickRegions = Region.quickRegions
        .where(
          (r) =>
              _fuzzyScore(lowerQuery, r.name.toLowerCase()) > -10000 ||
              (r.displayName != null &&
                  _fuzzyScore(lowerQuery, r.displayName!.toLowerCase()) >
                      -10000),
        )
        .toList();

    // Then find distinct countries matching the query via fuzzy match
    final matchingCountries = <String>{};
    for (final plant in all) {
      if (_fuzzyScore(lowerQuery, plant.country.toLowerCase()) > -10000 ||
          (plant.countryLong != null &&
              _fuzzyScore(lowerQuery, plant.countryLong!.toLowerCase()) >
                  -10000)) {
        matchingCountries.add(plant.countryLong ?? plant.country);
      }
      if (matchingCountries.length > 10) {
        break; // Limit to avoid long processing
      }
    }

    // Build dynamic regions for matched countries
    final dynamicRegions = <Region>[];
    for (final countryName in matchingCountries) {
      // Check if it's already covered by a quick region exact match to avoid duplicates
      if (matchedQuickRegions.any(
        (r) => r.countries?.contains(countryName) == true,
      )) {
        continue;
      }

      final countryPlants = all
          .where(
            (p) => p.countryLong == countryName || p.country == countryName,
          )
          .toList();
      if (countryPlants.isEmpty) continue;

      double minLat = 90, maxLat = -90, minLon = 180, maxLon = -180;
      double sumLat = 0, sumLon = 0;

      for (final p in countryPlants) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLon) minLon = p.longitude;
        if (p.longitude > maxLon) maxLon = p.longitude;
        sumLat += p.latitude;
        sumLon += p.longitude;
      }

      dynamicRegions.add(
        Region(
          id: 'country_${countryName.toLowerCase().replaceAll(' ', '_')}',
          name: countryName,
          displayName: countryName,
          centerLat: sumLat / countryPlants.length,
          centerLon: sumLon / countryPlants.length,
          minLat: minLat,
          minLon: minLon,
          maxLat: maxLat,
          maxLon: maxLon,
          countries: [countryName],
          defaultZoom: 5.0,
        ),
      );
    }

    return [...matchedQuickRegions, ...dynamicRegions];
  }

  /// Get a plant by its generated ID.
  Future<PowerPlant?> getPlantById(String id) async {
    final all = await getAllPlants();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Force a full re-ingestion from CSV.
  Future<IngestionReport> forceReIngest() async {
    _cachedPlants = null;
    final result = await _parseAndIngest();
    _cachedPlants = result.plants;
    _lastReport = result.report;
    debugPrint(result.report.toString());
    return result.report;
  }

  // ═══════════════════════════════════════════════════════
  // PRIVATE — CSV Parsing & Validation
  // ═══════════════════════════════════════════════════════

  /// Parse CSV from assets and validate rows.
  Future<_IngestionResult> _parseAndIngest() async {
    try {
      // 1. Load string from assets
      final csvString = await rootBundle.loadString(
        'assets/data/global_powerplant_dataset_1 - Sheet1.csv',
      );

      // 2. Offload heavy CSV conversion and validation to a background isolate
      // This completely frees the main thread, ensuring 0 dropped frames.
      final result = await compute(_parseCsvIsolate, csvString);

      return result;
    } catch (e, stackTrace) {
      debugPrint('[EcoGrid] CSV parsing error: $e');
      debugPrint('[EcoGrid] $stackTrace');
      throw ParseException(message: 'Failed to parse power plant dataset: $e');
    }
  }

  /// The heavy parsing logic that runs in a background isolate.
  /// Must be a static or top-level function.
  static _IngestionResult _parseCsvIsolate(String csvString) {
    final stopwatch = Stopwatch()..start();

    int totalRows = 0;
    int skippedCoords = 0;
    int skippedName = 0;
    int skippedMalformed = 0;
    int duplicatesDetected = 0;
    final warnings = <String>[];
    final plants = <PowerPlant>[];

    // Coordinate-based duplicate tracking:
    final coordIndex = <String, List<int>>{};

    // Parse the CSV string into rows. We use standard split to be extremely fast.
    // The CsvToListConverter is robust but too slow for 35k rows.
    final rawLines = csvString.split('\n');

    if (rawLines.isEmpty || rawLines.length == 1) {
      stopwatch.stop();
      return _IngestionResult(
        plants: [],
        report: IngestionReport(
          totalRows: 0,
          validPlants: 0,
          skippedMissingCoordinates: 0,
          skippedMissingName: 0,
          skippedMalformed: 0,
          duplicatesDetected: 0,
          elapsed: stopwatch.elapsed,
          warnings: ['CSV file is empty'],
        ),
      );
    }

    // Skip header row
    for (int i = 1; i < rawLines.length; i++) {
      final line = rawLines[i].trim();
      if (line.isEmpty) continue;

      totalRows++;

      // Simple split is safe here because our CSV doesn't use complex quotes
      // for the data we actually extract, except maybe names.
      // We will handle basic splitting.
      final row = line.split(',');

      // ── Column count check ──────────────────────
      if (row.length < _CsvColumns.minColumnsRequired) {
        skippedMalformed++;
        continue;
      }

      // ── Extract and clean fields ────────────────
      final name = _cleanString(row[_CsvColumns.name]);
      final country = _cleanString(row[_CsvColumns.country]);
      final countryLong = _cleanString(row[_CsvColumns.countryLong]);
      final fuelStr = _cleanString(row[_CsvColumns.primaryFuel]);
      final latStr = _cleanString(row[_CsvColumns.latitude]);
      final lonStr = _cleanString(row[_CsvColumns.longitude]);
      final capStr = _cleanString(row[_CsvColumns.capacityMw]);

      // ── Validate name ───────────────────────────
      if (name.isEmpty) {
        skippedName++;
        continue;
      }

      // ── Validate coordinates ────────────────────
      final lat = double.tryParse(latStr);
      final lon = double.tryParse(lonStr);
      if (lat == null || lon == null) {
        skippedCoords++;
        continue;
      }

      // Sanity-check coordinate ranges
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
        skippedCoords++;
        continue;
      }

      // ── Parse optional fields ───────────────────
      final capacityMw = double.tryParse(capStr);

      // ── Conservative duplicate detection ────────
      final coordKey = '${(lat * 1000).round()}_${(lon * 1000).round()}';
      bool isDuplicate = false;

      if (coordIndex.containsKey(coordKey)) {
        for (final existingIdx in coordIndex[coordKey]!) {
          final existing = plants[existingIdx];
          final similarity = _nameSimilarity(name, existing.name);
          if (similarity > 0.85) {
            isDuplicate = true;
            duplicatesDetected++;

            // Merge: prefer existing but fill in missing fields
            if (existing.capacityMw == null && capacityMw != null) {
              plants[existingIdx] = PowerPlant(
                id: existing.id,
                name: existing.name,
                country: existing.country,
                countryLong: existing.countryLong ?? countryLong,
                latitude: existing.latitude,
                longitude: existing.longitude,
                primaryFuel: existing.primaryFuel,
                capacityMw: capacityMw,
                searchKey: existing.searchKey,
              );
            }
            break;
          }
        }
      }

      if (isDuplicate) continue;

      // ── Create entity ───────────────────────────
      final id = _generateId(country, name, i);
      final primaryFuel = PlantType.fromCsvFuel(fuelStr);

      // Pre-compute the searchable string to eliminate O(N) allocations during runtime search
      final searchKey =
          '${name.toLowerCase()} ${country.toLowerCase()} ${countryLong.toLowerCase()} ${primaryFuel.displayName.toLowerCase()}';

      final plant = PowerPlant(
        id: id,
        name: name,
        country: country,
        countryLong: countryLong.isNotEmpty ? countryLong : null,
        latitude: lat,
        longitude: lon,
        primaryFuel: primaryFuel,
        capacityMw: capacityMw,
        searchKey: searchKey,
      );

      final plantIndex = plants.length;
      plants.add(plant);
      coordIndex.putIfAbsent(coordKey, () => []).add(plantIndex);
    }

    stopwatch.stop();

    return _IngestionResult(
      plants: plants,
      report: IngestionReport(
        totalRows: totalRows,
        validPlants: plants.length,
        skippedMissingCoordinates: skippedCoords,
        skippedMissingName: skippedName,
        skippedMalformed: skippedMalformed,
        duplicatesDetected: duplicatesDetected,
        elapsed: stopwatch.elapsed,
        warnings: warnings,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // PRIVATE — Parsing Utilities
  // ═══════════════════════════════════════════════════════

  /// Clean a raw CSV cell value.
  static String _cleanString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim().replaceAll('\r', '');
  }

  /// Generate a deterministic, unique ID from country + name + row index.
  ///
  /// Format: `{country_code}_{sanitized_name}_{row_index}`
  /// e.g., `IND_kudankulam_nuclear_power_plant_4521`
  static String _generateId(String country, String name, int rowIndex) {
    final sanitizedName = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final truncated = sanitizedName.length > 40
        ? sanitizedName.substring(0, 40)
        : sanitizedName;
    return '${country.toLowerCase()}_${truncated}_$rowIndex';
  }

  /// Calculate name similarity using a simple normalized longest common subsequence.
  ///
  /// Returns 0.0 (no match) to 1.0 (identical).
  /// This is intentionally simple — we want conservative matching only.
  static double _nameSimilarity(String a, String b) {
    final la = a.toLowerCase().trim();
    final lb = b.toLowerCase().trim();
    if (la == lb) return 1.0;
    if (la.isEmpty || lb.isEmpty) return 0.0;

    // Quick length-based rejection
    final lenRatio = la.length < lb.length
        ? la.length / lb.length
        : lb.length / la.length;
    if (lenRatio < 0.5) return 0.0;

    // Count matching characters (order-sensitive)
    int matches = 0;
    int j = 0;
    for (int i = 0; i < la.length && j < lb.length; i++) {
      if (la[i] == lb[j]) {
        matches++;
        j++;
      }
    }
    return matches / (la.length > lb.length ? la.length : lb.length);
  }

  /// Calculate a fuzzy score for subsequence matching.
  ///
  /// Returns a higher positive score for better matches (especially consecutive).
  /// Returns -10000 if not a match.
  static int _fuzzyScore(String query, String target) {
    if (query.isEmpty) return 100;
    int qIdx = 0;
    int tIdx = 0;
    int score = 0;
    int consecutiveMatches = 0;

    final qLen = query.length;
    final tLen = target.length;

    while (qIdx < qLen && tIdx < tLen) {
      if (query[qIdx] == target[tIdx]) {
        score += 10 + (consecutiveMatches * 5);
        consecutiveMatches++;
        qIdx++;
      } else {
        consecutiveMatches = 0;
      }
      tIdx++;
    }

    if (qIdx == qLen) {
      return score - tLen; // Penalty for longer non-matching tails
    }
    return -10000;
  }
}

/// Internal result type for the parsing pipeline.
/// Bundles the parsed plants with their diagnostic report.
class _IngestionResult {
  final List<PowerPlant> plants;
  final IngestionReport report;
  const _IngestionResult({required this.plants, required this.report});
}
