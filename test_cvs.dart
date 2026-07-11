import 'dart:io';
import 'dart:math';

enum PlantType { nuclear, hydro, solar, wind, coal, gas, oil, biomass, geothermal, waste, wave, storage, cogeneration, petcoke, other }

PlantType parseType(String t) {
  t = t.toLowerCase();
  for (var v in PlantType.values) {
    if (t == v.name) return v;
  }
  return PlantType.other;
}

class CVSCalculator {
  static const double weightTemperature = 0.40;
  static const double weightWater = 0.35;
  static const double weightWind = 0.25;
  static const Map<PlantType, List<double>> _sensitivityMatrix = {
    PlantType.nuclear: [1.8, 2.0, 0.8],
    PlantType.hydro: [0.8, 2.2, 0.5],
    PlantType.solar: [1.4, 0.6, 1.8],
    PlantType.wind: [0.5, 0.3, 2.2],
    PlantType.coal: [1.6, 1.5, 0.9],
    PlantType.gas: [1.4, 1.2, 1.0],
    PlantType.oil: [1.5, 1.3, 0.9],
    PlantType.biomass: [1.2, 1.4, 0.8],
    PlantType.geothermal: [1.0, 1.2, 0.6],
    PlantType.waste: [1.1, 1.0, 0.8],
    PlantType.wave: [0.5, 0.8, 2.0],
    PlantType.storage: [1.2, 0.5, 1.0],
    PlantType.cogeneration: [1.4, 1.3, 0.9],
    PlantType.petcoke: [1.6, 1.4, 0.9],
    PlantType.other: [1.0, 1.0, 1.0],
  };
  static double computeCVS({
    required PlantType plantType,
    required double tempAnomaly,
    required double waterAnomaly,
    required double windAnomaly,
  }) {
    final sensitivities = _sensitivityMatrix[plantType]!;
    final tempContribution = weightTemperature * sensitivities[0] * tempAnomaly.clamp(0.0, 1.0);
    final waterContribution = weightWater * sensitivities[1] * waterAnomaly.clamp(0.0, 1.0);
    final windContribution = weightWind * sensitivities[2] * windAnomaly.clamp(0.0, 1.0);
    final rawSum = tempContribution + waterContribution + windContribution;
    final maxPossible = weightTemperature * sensitivities[0] + weightWater * sensitivities[1] + weightWind * sensitivities[2];
    final normalized = (rawSum / maxPossible).clamp(0.0, 1.0);
    final curved = pow(normalized, 0.75);
    final cvs = curved * 100;
    return cvs.clamp(0, 100).toDouble();
  }
}

void main() async {
  final lines = await File('assets/data/global_powerplant_dataset_1 - Sheet1.csv').readAsLines();
  int high = 0, med = 0, low = 0;
  double snapToGrid(double value) => (value * 2).round() / 2.0;
  
  double gridRiskHash(double l1, double l2, int offset) {
    final latInt = (l1 * 2).round();
    final lonInt = (l2 * 2).round();
    final hash = (((latInt + offset) * 73856093) ^ ((lonInt + offset) * 19349663)).abs() % 1000;
    return hash / 1000.0;
  }

  for (int i = 1; i < lines.length; i++) {
    final line = lines[i];
    final parts = line.split(',');
    if (parts.length < 8) continue;
    final country = parts[0];
    final countryLong = parts[1];
    if (country.toLowerCase() == 'ind' || countryLong.toLowerCase() == 'india') {
      double lat = double.tryParse(parts[5]) ?? 0.0;
      double lon = double.tryParse(parts[6]) ?? 0.0;
      PlantType type = parseType(parts[7]);
      
      final gridLat = snapToGrid(lat);
      final gridLon = snapToGrid(lon);
      final absLat = gridLat.abs();
      
      final tempHash = gridRiskHash(gridLat, gridLon, 0);
      final waterHash = gridRiskHash(gridLat + 0.1, gridLon + 0.1, 0); // Correct offset? No, in computeScoresIsolate: waterHash = gridRiskHash(gridLat+0.1, lon+0.1)
      final windHash = gridRiskHash(gridLat + 0.2, gridLon + 0.2, 0);
      
      final tempMultiplier = 0.5 + (tempHash * 1.0);
      final waterMultiplier = 0.5 + (waterHash * 1.0);
      final windMultiplier = 0.5 + (windHash * 1.0);
      
      double tempBase = absLat < 15 ? 0.60 : absLat < 25 ? 0.52 : absLat < 35 ? 0.45 : absLat < 45 ? 0.42 : absLat < 55 ? 0.35 : 0.28;
      double waterBase = absLat < 15 ? 0.50 : absLat < 25 ? 0.52 : absLat < 35 ? 0.45 : absLat < 45 ? 0.40 : 0.35;
      double windBase = absLat < 20 ? 0.42 : absLat < 35 ? 0.38 : absLat < 50 ? 0.45 : 0.42;
      
      double tempAnomaly = (tempBase * tempMultiplier).clamp(0.05, 1.0);
      double waterAnomaly = (waterBase * waterMultiplier).clamp(0.05, 1.0);
      double windAnomaly = (windBase * windMultiplier).clamp(0.05, 1.0);
      
      double cvs = CVSCalculator.computeCVS(plantType: type, tempAnomaly: tempAnomaly, waterAnomaly: waterAnomaly, windAnomaly: windAnomaly);
      if (cvs >= 67) {
        high++;
      } else if (cvs >= 34) med++;
      else low++;
    }
  }
  print('India - High: $high, Med: $med, Low: $low');
}
