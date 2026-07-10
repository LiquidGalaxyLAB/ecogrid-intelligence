import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../core/enums/plant_type.dart';
import '../../../core/exception/invalid_response_exception.dart';
import '../../../core/resources/ingestion_report.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../domain/model/power_plant.dart';
import '../../../domain/model/region.dart';

class _CsvColumns {
  static const int country = 0;
  static const int countryLong = 1;
  static const int name = 2;
  static const int capacityMw = 4;
  static const int latitude = 5;
  static const int longitude = 6;
  static const int primaryFuel = 7;
  static const int minColumnsRequired = 8;
}

class PowerPlantLocalDataSource {
  List<PowerPlant>? _cachedPlants;
  IngestionReport? _lastReport;
  PowerPlantLocalDataSource();
  IngestionReport? get lastReport => _lastReport;
  Future<List<PowerPlant>> getAllPlants() async {
    if (_cachedPlants != null) return _cachedPlants!;
    final result = await _parseAndIngest();
    _cachedPlants = result.plants;
    _lastReport = result.report;
    debugPrint(result.report.toString());
    return _cachedPlants!;
  }

  Future<List<PowerPlant>> getPlantsByRegion(Region region) async {
    final all = await getAllPlants();
    if (region.countries != null && region.countries!.isNotEmpty) {
      final countrySet = region.countries!.map((c) => c.toLowerCase()).toSet();
      return all.where((p) {
        return countrySet.contains(p.country.toLowerCase()) ||
            (p.countryLong != null &&
                countrySet.contains(p.countryLong!.toLowerCase()));
      }).toList();
    }
    return all.where((p) {
      return p.latitude >= region.minLat &&
          p.latitude <= region.maxLat &&
          p.longitude >= region.minLon &&
          p.longitude <= region.maxLon;
    }).toList();
  }

  Future<List<PowerPlant>> getPlantsByCountry(String countryCode) async {
    final all = await getAllPlants();
    final code = countryCode.toUpperCase().trim();
    return all.where((p) => p.country.toUpperCase() == code).toList();
  }

  Future<List<PowerPlant>> getPlantsByFuelType(PlantType fuel) async {
    final all = await getAllPlants();
    return all.where((p) => p.primaryFuel == fuel).toList();
  }

  Future<List<PowerPlant>> getNearbyPlants(
    double lat,
    double lon, {
    double radiusKm = 50.0,
    int limit = 20,
  }) async {
    final all = await getAllPlants();
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

  Future<List<Region>> searchRegions(String query) async {
    final all = await getAllPlants();
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) return [];
    final matchedQuickRegions = Region.quickRegions
        .where(
          (r) =>
              _fuzzyScore(lowerQuery, r.name.toLowerCase()) > -10000 ||
              (r.displayName != null &&
                  _fuzzyScore(lowerQuery, r.displayName!.toLowerCase()) >
                      -10000),
        )
        .toList();
    final matchingCountries = <String>{};
    for (final plant in all) {
      if (_fuzzyScore(lowerQuery, plant.country.toLowerCase()) > -10000 ||
          (plant.countryLong != null &&
              _fuzzyScore(lowerQuery, plant.countryLong!.toLowerCase()) >
                  -10000)) {
        matchingCountries.add(plant.countryLong ?? plant.country);
      }
      if (matchingCountries.length > 10) {
        break;
      }
    }
    final dynamicRegions = <Region>[];
    for (final countryName in matchingCountries) {
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

  Future<PowerPlant?> getPlantById(String id) async {
    final all = await getAllPlants();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<IngestionReport> forceReIngest() async {
    _cachedPlants = null;
    final result = await _parseAndIngest();
    _cachedPlants = result.plants;
    _lastReport = result.report;
    debugPrint(result.report.toString());
    return result.report;
  }

  Future<_IngestionResult> _parseAndIngest() async {
    try {
      final csvString = await rootBundle.loadString(
        'assets/data/global_powerplant_dataset_1 - Sheet1.csv',
      );
      final result = await compute(_parseCsvIsolate, csvString);
      return result;
    } catch (e, stackTrace) {
      debugPrint('[EcoGrid] CSV parsing error: $e');
      debugPrint('[EcoGrid] $stackTrace');
      throw ParseException(message: 'Failed to parse power plant dataset: $e');
    }
  }

  static _IngestionResult _parseCsvIsolate(String csvString) {
    final stopwatch = Stopwatch()..start();
    int totalRows = 0;
    int skippedCoords = 0;
    int skippedName = 0;
    int skippedMalformed = 0;
    int duplicatesDetected = 0;
    final warnings = <String>[];
    final plants = <PowerPlant>[];
    final coordIndex = <String, List<int>>{};
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
    for (int i = 1; i < rawLines.length; i++) {
      final line = rawLines[i].trim();
      if (line.isEmpty) continue;
      totalRows++;
      final row = line.split(',');
      if (row.length < _CsvColumns.minColumnsRequired) {
        skippedMalformed++;
        continue;
      }
      final name = _cleanString(row[_CsvColumns.name]);
      final country = _cleanString(row[_CsvColumns.country]);
      final countryLong = _cleanString(row[_CsvColumns.countryLong]);
      final fuelStr = _cleanString(row[_CsvColumns.primaryFuel]);
      final latStr = _cleanString(row[_CsvColumns.latitude]);
      final lonStr = _cleanString(row[_CsvColumns.longitude]);
      final capStr = _cleanString(row[_CsvColumns.capacityMw]);
      if (name.isEmpty) {
        skippedName++;
        continue;
      }
      final lat = double.tryParse(latStr);
      final lon = double.tryParse(lonStr);
      if (lat == null || lon == null) {
        skippedCoords++;
        continue;
      }
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
        skippedCoords++;
        continue;
      }
      final capacityMw = double.tryParse(capStr);
      final coordKey = '${(lat * 1000).round()}_${(lon * 1000).round()}';
      bool isDuplicate = false;
      if (coordIndex.containsKey(coordKey)) {
        for (final existingIdx in coordIndex[coordKey]!) {
          final existing = plants[existingIdx];
          final similarity = _nameSimilarity(name, existing.name);
          if (similarity > 0.85) {
            isDuplicate = true;
            duplicatesDetected++;
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
      final id = _generateId(country, name, i);
      final primaryFuel = PlantType.fromCsvFuel(fuelStr);
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

  static String _cleanString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim().replaceAll('\r', '');
  }

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

  static double _nameSimilarity(String a, String b) {
    final la = a.toLowerCase().trim();
    final lb = b.toLowerCase().trim();
    if (la == lb) return 1.0;
    if (la.isEmpty || lb.isEmpty) return 0.0;
    final lenRatio = la.length < lb.length
        ? la.length / lb.length
        : lb.length / la.length;
    if (lenRatio < 0.5) return 0.0;
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
      return score - tLen;
    }
    return -10000;
  }
}

class _IngestionResult {
  final List<PowerPlant> plants;
  final IngestionReport report;
  const _IngestionResult({required this.plants, required this.report});
}
