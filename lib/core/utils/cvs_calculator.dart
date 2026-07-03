import '../enums/plant_type.dart';
import 'dart:math';

class CVSCalculator {
  CVSCalculator._();
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
    final sensitivities =
        _sensitivityMatrix[plantType] ?? _sensitivityMatrix[PlantType.other]!;
    final tempContribution =
        weightTemperature * sensitivities[0] * tempAnomaly.clamp(0.0, 1.0);
    final waterContribution =
        weightWater * sensitivities[1] * waterAnomaly.clamp(0.0, 1.0);
    final windContribution =
        weightWind * sensitivities[2] * windAnomaly.clamp(0.0, 1.0);
    final rawSum = tempContribution + waterContribution + windContribution;
    final maxPossible =
        weightTemperature * sensitivities[0] +
        weightWater * sensitivities[1] +
        weightWind * sensitivities[2];
    final normalized = (rawSum / maxPossible).clamp(0.0, 1.0);
    final curved = pow(normalized, 0.75);
    final cvs = curved * 100;
    return cvs.clamp(0, 100).toDouble();
  }

  static Map<String, double> computeStressBreakdown({
    required PlantType plantType,
    required double tempAnomaly,
    required double waterAnomaly,
    required double windAnomaly,
  }) {
    final sensitivities =
        _sensitivityMatrix[plantType] ?? _sensitivityMatrix[PlantType.other]!;
    double normalize(double anomaly, double sensitivity) {
      final raw = anomaly.clamp(0.0, 1.0) * sensitivity;
      final smoothed = (raw / 2.5);
      final curve = sqrt(smoothed);
      const baseline = 0.12;
      return ((baseline + (curve * (1.0 - baseline))) * 100).clamp(0.0, 100.0);
    }

    return {
      'temperature': normalize(tempAnomaly, sensitivities[0]),
      'water': normalize(waterAnomaly, sensitivities[1]),
      'wind': normalize(windAnomaly, sensitivities[2]),
    };
  }

  static double simulateScenario({
    required PlantType plantType,
    required double tempAnomaly,
    required double waterAnomaly,
    required double windAnomaly,
    double tempMultiplier = 1.0,
    double waterMultiplier = 1.0,
    double windMultiplier = 1.0,
  }) {
    return computeCVS(
      plantType: plantType,
      tempAnomaly: (tempAnomaly * tempMultiplier).clamp(0.0, 1.0),
      waterAnomaly: (waterAnomaly * waterMultiplier).clamp(0.0, 1.0),
      windAnomaly: (windAnomaly * windMultiplier).clamp(0.0, 1.0),
    );
  }

  static Map<String, double> generateBaseAnomalies(double lat, double lon) {
    double snapToGrid(double value) => (value * 2).round() / 2.0;
    final gridLat = snapToGrid(lat);
    final gridLon = snapToGrid(lon);
    final absLat = gridLat.abs();
    double gridRiskHash(double l1, double l2, int offset) {
      final latInt = (l1 * 2).round();
      final lonInt = (l2 * 2).round();
      final hash =
          (((latInt + offset) * 73856093) ^ ((lonInt + offset) * 19349663))
              .abs() %
          1000;
      return hash / 1000.0;
    }

    final tempHash = gridRiskHash(gridLat, gridLon, 0);
    final waterHash = gridRiskHash(gridLat, gridLon, 17);
    final windHash = gridRiskHash(gridLat, gridLon, 31);
    final tempMultiplier = 0.5 + (tempHash * 1.0);
    final waterMultiplier = 0.5 + (waterHash * 1.0);
    final windMultiplier = 0.5 + (windHash * 1.0);
    double tempBase = absLat < 15
        ? 0.60
        : absLat < 25
        ? 0.52
        : absLat < 35
        ? 0.45
        : absLat < 45
        ? 0.42
        : absLat < 55
        ? 0.35
        : 0.28;
    double waterBase = absLat < 15
        ? 0.50
        : absLat < 25
        ? 0.52
        : absLat < 35
        ? 0.45
        : absLat < 45
        ? 0.40
        : 0.35;
    double windBase = absLat < 20
        ? 0.42
        : absLat < 35
        ? 0.38
        : absLat < 50
        ? 0.45
        : 0.42;
    return {
      'temp': (tempBase * tempMultiplier).clamp(0.05, 1.0),
      'water': (waterBase * waterMultiplier).clamp(0.05, 1.0),
      'wind': (windBase * windMultiplier).clamp(0.05, 1.0),
    };
  }

  static Map<String, String> calculateHumanConsequences({
    required PlantType plantType,
    required double baseCvs,
    required double projectedCvs,
    required double tempMultiplier,
    required double waterMultiplier,
    required double windMultiplier,
  }) {
    final cvsDiff = projectedCvs - baseCvs;
    final outputReduction = cvsDiff > 0
        ? (cvsDiff * 0.45).clamp(0.0, 100.0)
        : 0.0;
    double waterDemand = 0.0;
    if (plantType == PlantType.nuclear ||
        plantType == PlantType.coal ||
        plantType == PlantType.gas) {
      waterDemand =
          ((tempMultiplier - 1.0) * 20.0) + ((waterMultiplier - 1.0) * 15.0);
    }
    String risk = "Stable operations.";
    if (projectedCvs > 80) {
      risk = plantType == PlantType.wind
          ? "Extreme risk of turbine lock-down to prevent structural damage."
          : "High risk of forced curtailment due to severe environmental stress.";
    } else if (projectedCvs > 66) {
      risk = "Elevated operational stress; partial output reduction likely.";
    }
    return {
      'outputReduction': outputReduction > 0
          ? "Loses approx ${outputReduction.toStringAsFixed(1)}% generation capacity."
          : "No significant capacity loss.",
      'waterDemand': waterDemand > 0
          ? "Cooling demand increases by ~${waterDemand.toStringAsFixed(0)}%."
          : (waterDemand < 0
                ? "Water availability increases."
                : "Water requirements remain stable."),
      'operationalRisk': risk,
    };
  }

  static double calculateWorstCase(
    PlantType plantType,
    Map<String, double> baseAnomalies,
  ) {
    return simulateScenario(
      plantType: plantType,
      tempAnomaly: baseAnomalies['temp'] ?? 0.15,
      waterAnomaly: baseAnomalies['water'] ?? 0.15,
      windAnomaly: baseAnomalies['wind'] ?? 0.15,
      tempMultiplier: 3.0,
      waterMultiplier: 3.0,
      windMultiplier: 3.0,
    );
  }

  static Map<String, dynamic>? findPathToDanger(
    PlantType plantType,
    Map<String, double> baseAnomalies,
    double currentCvs,
  ) {
    if (currentCvs >= 67) return null;
    double tMult = 1.0;
    double wMult = 1.0;
    double simulatedCvs = currentCvs;
    while (simulatedCvs < 67 && tMult <= 3.0) {
      tMult += 0.1;
      wMult += 0.2;
      simulatedCvs = simulateScenario(
        plantType: plantType,
        tempAnomaly: baseAnomalies['temp'] ?? 0.15,
        waterAnomaly: baseAnomalies['water'] ?? 0.15,
        windAnomaly: baseAnomalies['wind'] ?? 0.15,
        tempMultiplier: tMult,
        waterMultiplier: wMult,
        windMultiplier: 1.0,
      );
    }
    if (simulatedCvs >= 67) {
      final tempIncrease = ((tMult - 1.0) * 5.0).toStringAsFixed(1);
      final rainDrop = ((wMult - 1.0) * 25.0).toStringAsFixed(0);
      return {
        'message':
            "A $tempIncrease°C temperature rise combined with a $rainDrop% rainfall deviation would push this plant into High Risk.",
        'requiredCvs': simulatedCvs,
        'tempMultiplier': tMult,
        'waterMultiplier': wMult,
      };
    }
    return {
      'message':
          "This plant is extremely resilient. Even extreme concurrent shifts in temperature and water stress fail to push it into High Risk.",
      'requiredCvs': simulatedCvs,
      'tempMultiplier': 3.0,
      'waterMultiplier': 3.0,
    };
  }
}
