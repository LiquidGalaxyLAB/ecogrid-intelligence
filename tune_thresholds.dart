import 'dart:io';
import 'package:ecogrid_intelligence/core/enums/plant_type.dart';
import 'package:ecogrid_intelligence/core/utils/cvs_calculator.dart';
import 'package:ecogrid_intelligence/domain/model/power_plant.dart';

// Copy-pasted parse logic without flutter dependencies
void main() {
  final csvString = File('assets/data/global_powerplant_dataset_1 - Sheet1.csv').readAsStringSync();
  final rawLines = csvString.split('\\n');
  final plants = <PowerPlant>[];
  
  String cleanString(String input) {
    if (input.startsWith('"') && input.endsWith('"')) {
      return input.substring(1, input.length - 1).trim();
    }
    return input.trim();
  }
  
  for (int i = 1; i < rawLines.length; i++) {
    final line = rawLines[i].trim();
    if (line.isEmpty) continue;
    
    // Simple parse (ignoring commas in quotes for this rough script)
    // Actually, let's just use the real dataset properly, but for speed just split by comma
    // Wait, the real dataset HAS commas in names. Let's use a quick CSV parser.
    bool inQuotes = false;
    List<String> row = [];
    StringBuffer current = StringBuffer();
    for (int j = 0; j < line.length; j++) {
      if (line[j] == '"') {
        inQuotes = !inQuotes;
      } else if (line[j] == ',' && !inQuotes) {
        row.add(current.toString().trim());
        current.clear();
      } else {
        current.write(line[j]);
      }
    }
    row.add(current.toString().trim());
    
    if (row.length < 8) continue;
    
    final latStr = cleanString(row[5]);
    final lonStr = cleanString(row[6]);
    final lat = double.tryParse(latStr);
    final lon = double.tryParse(lonStr);
    if (lat == null || lon == null) continue;
    
    PlantType parseType(String typeStr) {
      final t = typeStr.toLowerCase();
      if (t == 'nuclear') return PlantType.nuclear;
      if (t == 'hydro') return PlantType.hydro;
      if (t == 'solar') return PlantType.solar;
      if (t == 'wind') return PlantType.wind;
      if (t == 'coal') return PlantType.coal;
      if (t == 'gas') return PlantType.gas;
      if (t == 'oil') return PlantType.oil;
      return PlantType.other;
    }
    
    plants.add(PowerPlant(
      id: i.toString(), name: cleanString(row[2]), country: cleanString(row[0]),
      countryLong: cleanString(row[1]), capacityMw: 0, latitude: lat, longitude: lon,
      primaryFuel: parseType(row[7]), searchKey: '',
    ));
  }
  
  double snapToGrid(double value) {
    return (value * 2).round() / 2.0;
  }

  double gridRiskHash(double lat, double lon) {
    final latInt = (lat * 2).round();
    final lonInt = (lon * 2).round();
    final hash = ((latInt * 73856093) ^ (lonInt * 19349663)).abs() % 1000;
    return hash / 1000.0;
  }
  
  double computeCvs(PowerPlant plant) {
    final gridLat = snapToGrid(plant.latitude);
    final gridLon = snapToGrid(plant.longitude);
    final absLat = gridLat.abs();
    
    final tempHash = gridRiskHash(gridLat, gridLon);
    final waterHash = gridRiskHash(gridLat + 0.1, gridLon + 0.1);
    final windHash = gridRiskHash(gridLat + 0.2, gridLon + 0.2);

    final tempMultiplier = 0.5 + (tempHash * 1.0);
    final waterMultiplier = 0.5 + (waterHash * 1.0);
    final windMultiplier = 0.5 + (windHash * 1.0);

    double tempBase = absLat < 15 ? 0.60 : absLat < 25 ? 0.52 : absLat < 35 ? 0.45 : absLat < 45 ? 0.42 : absLat < 55 ? 0.35 : 0.28;
    double waterBase = absLat < 15 ? 0.50 : absLat < 25 ? 0.52 : absLat < 35 ? 0.45 : absLat < 45 ? 0.40 : 0.35;
    double windBase = absLat < 20 ? 0.42 : absLat < 35 ? 0.38 : absLat < 50 ? 0.45 : 0.42;

    final tempAnomaly = (tempBase * tempMultiplier).clamp(0.05, 1.0);
    final waterAnomaly = (waterBase * waterMultiplier).clamp(0.05, 1.0);
    final windAnomaly = (windBase * windMultiplier).clamp(0.05, 1.0);

    return CVSCalculator.computeCVS(
      plantType: plant.primaryFuel,
      tempAnomaly: tempAnomaly,
      waterAnomaly: waterAnomaly,
      windAnomaly: windAnomaly,
    );
  }

  final belgiumPlants = plants.where((p) => p.countryLong == 'Belgium').toList();
  final indiaPlants = plants.where((p) => p.countryLong == 'India').toList();
  
  final globalScores = plants.map(computeCvs).toList();
  final belgiumScores = belgiumPlants.map(computeCvs).toList();
  final indiaScores = indiaPlants.map(computeCvs).toList();
  
  void printDist(String name, List<double> scores, double lowMax, double medMax) {
    int low = 0; int med = 0; int high = 0;
    for (var s in scores) {
      if (s <= lowMax) low++; else if (s <= medMax) med++; else high++;
    }
    print('$name -> Low: $low, Med: $med, High: $high (Total: ${scores.length})');
  }
  
  print('--- CURRENT THRESHOLDS (33, 66) ---');
  printDist('Global ', globalScores, 33, 66);
  printDist('Belgium', belgiumScores, 33, 66);
  printDist('India  ', indiaScores, 33, 66);
  
  print('\\n--- OLD THRESHOLDS (25, 50) ---');
  printDist('Global ', globalScores, 25, 50);
  printDist('Belgium', belgiumScores, 25, 50);
  printDist('India  ', indiaScores, 25, 50);
  
  print('\\n--- PROPOSED THRESHOLDS (40, 60) ---');
  printDist('Global ', globalScores, 40, 60);
  printDist('Belgium', belgiumScores, 40, 60);
  printDist('India  ', indiaScores, 40, 60);
  
  print('\\n--- PROPOSED THRESHOLDS (45, 62) ---');
  printDist('Global ', globalScores, 45, 62);
  printDist('Belgium', belgiumScores, 45, 62);
  printDist('India  ', indiaScores, 45, 62);
}
