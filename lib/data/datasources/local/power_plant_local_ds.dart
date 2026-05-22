import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:hive/hive.dart';
import 'package:ecogrid_intelligence/core/enums/plant_type.dart';
import 'package:ecogrid_intelligence/core/errors/exceptions.dart';
import 'package:ecogrid_intelligence/domain/entities/power_plant.dart';
import 'package:ecogrid_intelligence/domain/entities/region.dart';

/// Local data source for power plant data.
/// Parses the bundled WRI CSV and caches in Hive.
class PowerPlantLocalDataSource {
  final Box box;
  List<PowerPlant>? _cachedPlants;

  PowerPlantLocalDataSource({required this.box});

  /// Load all plants — from Hive cache or fresh CSV parse.
  Future<List<PowerPlant>> getAllPlants() async {
    if (_cachedPlants != null) return _cachedPlants!;

    // Check Hive first
    final cached = box.get('all_plants_loaded');
    if (cached == true && box.length > 1) {
      _cachedPlants = _loadFromHive();
      if (_cachedPlants!.isNotEmpty) return _cachedPlants!;
    }

    // Parse from bundled CSV
    _cachedPlants = await _parseFromCsv();
    await _saveToHive(_cachedPlants!);
    return _cachedPlants!;
  }

  /// Get plants within a region's bounding box.
  Future<List<PowerPlant>> getPlantsByRegion(Region region) async {
    final allPlants = await getAllPlants();
    return allPlants.where((plant) {
      return plant.latitude >= region.minLat &&
          plant.latitude <= region.maxLat &&
          plant.longitude >= region.minLon &&
          plant.longitude <= region.maxLon;
    }).toList();
  }

  /// Search plants by name, country, or fuel type.
  Future<List<PowerPlant>> searchPlants(String query) async {
    final allPlants = await getAllPlants();
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) return [];

    return allPlants.where((plant) {
      return plant.name.toLowerCase().contains(lowerQuery) ||
          plant.country.toLowerCase().contains(lowerQuery) ||
          (plant.countryLong?.toLowerCase().contains(lowerQuery) ?? false) ||
          plant.primaryFuel.displayName.toLowerCase().contains(lowerQuery);
    }).take(50).toList();
  }

  /// Get a plant by ID.
  Future<PowerPlant?> getPlantById(String id) async {
    final allPlants = await getAllPlants();
    try {
      return allPlants.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Parse WRI Global Power Plant Database CSV from assets.
  Future<List<PowerPlant>> _parseFromCsv() async {
    try {
      final csvString =
          await rootBundle.loadString('assets/data/global_power_plants.csv');
      final rows = const CsvToListConverter().convert(csvString, eol: '\n');

      if (rows.isEmpty) return [];

      // Skip header row
      final plants = <PowerPlant>[];
      for (int i = 1; i < rows.length; i++) {
        try {
          final row = rows[i];
          if (row.length < 10) continue;

          plants.add(PowerPlant(
            id: row[1]?.toString() ?? 'plant_$i',
            name: row[2]?.toString() ?? 'Unknown',
            country: row[0]?.toString() ?? '',
            countryLong: row[3]?.toString(),
            latitude: _parseDouble(row[5]),
            longitude: _parseDouble(row[6]),
            primaryFuel: PlantType.fromCsvFuel(row[7]?.toString() ?? ''),
            capacityMw: _parseDoubleNullable(row[4]),
            commissioningYear: _parseIntNullable(row[8]),
            owner: row.length > 9 ? row[9]?.toString() : null,
          ));
        } catch (_) {
          // Skip malformed rows
          continue;
        }
      }

      return plants;
    } catch (e) {
      throw ParseException(message: 'Failed to parse power plant CSV: $e');
    }
  }

  List<PowerPlant> _loadFromHive() {
    final plants = <PowerPlant>[];
    for (var key in box.keys) {
      if (key == 'all_plants_loaded') continue;
      final data = box.get(key);
      if (data is Map) {
        try {
          plants.add(PowerPlant(
            id: data['id'] ?? '',
            name: data['name'] ?? '',
            country: data['country'] ?? '',
            countryLong: data['countryLong'],
            latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
            longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
            primaryFuel:
                PlantType.fromCsvFuel(data['primaryFuel']?.toString() ?? ''),
            capacityMw: (data['capacityMw'] as num?)?.toDouble(),
            commissioningYear: data['commissioningYear'] as int?,
            owner: data['owner'],
          ));
        } catch (_) {}
      }
    }
    return plants;
  }

  Future<void> _saveToHive(List<PowerPlant> plants) async {
    for (final plant in plants) {
      await box.put(plant.id, {
        'id': plant.id,
        'name': plant.name,
        'country': plant.country,
        'countryLong': plant.countryLong,
        'latitude': plant.latitude,
        'longitude': plant.longitude,
        'primaryFuel': plant.primaryFuel.csvLabel,
        'capacityMw': plant.capacityMw,
        'commissioningYear': plant.commissioningYear,
        'owner': plant.owner,
      });
    }
    await box.put('all_plants_loaded', true);
  }

  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  double? _parseDoubleNullable(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int? _parseIntNullable(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    if (value is int) return value;
    return int.tryParse(value.toString().split('.').first);
  }
}
