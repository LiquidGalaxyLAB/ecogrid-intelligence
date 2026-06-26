import '../enums/plant_type.dart';
import 'dart:math';

/// Climate Vulnerability Score calculator.
///
/// CVS = Σ(Wi × Si × Ai) / ΣWi × 100
///
/// Where:
///   i ∈ {temperature, water, wind}
///   Wi = global weight for stress type i
///   Si = sensitivity coefficient (plant_type × stress_type)
///   Ai = anomaly intensity (normalized 0.0–1.0)
class CVSCalculator {
  CVSCalculator._();

  // ─── Global Weights ──────────────────────────────────
  static const double weightTemperature = 0.40;
  static const double weightWater = 0.35;
  static const double weightWind = 0.25;

  // ─── Sensitivity Multipliers ─────────────────────────
  /// [tempMultiplier, waterMultiplier, windMultiplier]
  /// A value of 1.0 means average sensitivity. >1.0 means highly sensitive.
  static const Map<PlantType, List<double>> _sensitivityMatrix = {
    PlantType.nuclear: [1.8, 2.0, 0.8], // Highly dependent on cooling water
    PlantType.hydro: [0.8, 2.2, 0.5], // Extremely vulnerable to drought/flood
    PlantType.solar: [
      1.4,
      0.6,
      1.8,
    ], // Heat lowers efficiency; wind damages panels
    PlantType.wind: [0.5, 0.3, 2.2], // Extreme wind damages turbines
    PlantType.coal: [1.6, 1.5, 0.9], // Needs cooling water, affected by heat
    PlantType.gas: [1.4, 1.2, 1.0],
    PlantType.oil: [1.5, 1.3, 0.9],
    PlantType.biomass: [1.2, 1.4, 0.8],
    PlantType.geothermal: [1.0, 1.2, 0.6],
    PlantType.waste: [1.1, 1.0, 0.8],
    PlantType.wave: [0.5, 0.8, 2.0],
    PlantType.storage: [1.2, 0.5, 1.0],
    PlantType.cogeneration: [1.4, 1.3, 0.9],
    PlantType.petcoke: [1.6, 1.4, 0.9],
    PlantType.other: [1.0, 1.0, 1.0], // Neutral baseline
  };

  /// Compute CVS score (0–100) for a given plant type and anomaly intensities.
  static double computeCVS({
    required PlantType plantType,
    required double tempAnomaly,
    required double waterAnomaly,
    required double windAnomaly,
  }) {
    final sensitivities =
        _sensitivityMatrix[plantType] ?? _sensitivityMatrix[PlantType.other]!;

    // Raw weighted contributions
    final tempContribution =
        weightTemperature * sensitivities[0] * tempAnomaly.clamp(0.0, 1.0);
    final waterContribution =
        weightWater * sensitivities[1] * waterAnomaly.clamp(0.0, 1.0);
    final windContribution =
        weightWind * sensitivities[2] * windAnomaly.clamp(0.0, 1.0);

    final rawSum = tempContribution + waterContribution + windContribution;

    // Normalize by the plant type's theoretical maximum (when all anomalies = 1.0).
    final maxPossible =
        weightTemperature * sensitivities[0] +
        weightWater * sensitivities[1] +
        weightWind * sensitivities[2];

    final normalized = (rawSum / maxPossible).clamp(0.0, 1.0);

    // Apply a gentler curve (power of 0.75) to lift mid-latitude scores
    // so that regions like USA and China can still have High Risk plants.
    final curved = pow(normalized, 0.75);
    final cvs = curved * 100;

    return cvs.clamp(0, 100).toDouble();
  }

  /// Compute individual stress components for display.
  static Map<String, double> computeStressBreakdown({
    required PlantType plantType,
    required double tempAnomaly,
    required double waterAnomaly,
    required double windAnomaly,
  }) {
    final sensitivities =
        _sensitivityMatrix[plantType] ?? _sensitivityMatrix[PlantType.other]!;

    // Uses a square root curve to smooth out extremes and avoid binary clustering (0% or 100%).
    // Maps the theoretical max of ~2.5 down to a realistic 0-100 gradient with a 12% baseline.
    double normalize(double anomaly, double sensitivity) {
      final raw = anomaly.clamp(0.0, 1.0) * sensitivity;
      // 2.5 is the absolute maximum multiplier in our matrix
      final smoothed = (raw / 2.5);
      // Apply square root to raise the mid-curve (so average anomalies look like 40-60% rather than 10%)
      final curve = sqrt(smoothed);

      // All infrastructure has a base natural degradation stress (~12%)
      const baseline = 0.12;
      return ((baseline + (curve * (1.0 - baseline))) * 100).clamp(0.0, 100.0);
    }

    return {
      'temperature': normalize(tempAnomaly, sensitivities[0]),
      'water': normalize(waterAnomaly, sensitivities[1]),
      'wind': normalize(windAnomaly, sensitivities[2]),
    };
  }

  /// Simulate a scenario by applying multipliers to base anomalies.
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

  /// Generate exact base anomalies based on coordinates (replicates the backend model).
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
    final waterHash = gridRiskHash(
      gridLat,
      gridLon,
      17,
    ); // Offset to break symmetry
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

  /// Generate human-readable consequences from CVS difference and multipliers.
  static Map<String, String> calculateHumanConsequences({
    required PlantType plantType,
    required double baseCvs,
    required double projectedCvs,
    required double tempMultiplier,
    required double waterMultiplier,
    required double windMultiplier,
  }) {
    final cvsDiff = projectedCvs - baseCvs;

    // Output Reduction (approx 0.45% per 1 point of CVS increase)
    final outputReduction = cvsDiff > 0
        ? (cvsDiff * 0.45).clamp(0.0, 100.0)
        : 0.0;

    // Cooling Water Demand / Operational Stress
    double waterDemand = 0.0;
    if (plantType == PlantType.nuclear ||
        plantType == PlantType.coal ||
        plantType == PlantType.gas) {
      waterDemand =
          ((tempMultiplier - 1.0) * 20.0) + ((waterMultiplier - 1.0) * 15.0);
    }

    // Operational Risk
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

  /// Calculates the absolute worst-case scenario.
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

  /// Find the combined shift needed to reach High Risk (CVS > 67).
  static Map<String, dynamic>? findPathToDanger(
    PlantType plantType,
    Map<String, double> baseAnomalies,
    double currentCvs,
  ) {
    if (currentCvs >= 67) return null; // Already in danger

    // Iteratively increase temp and water together to find the breaking point
    double tMult = 1.0;
    double wMult = 1.0;
    double simulatedCvs = currentCvs;

    // Max 3.0 multiplier to prevent infinite loops
    while (simulatedCvs < 67 && tMult <= 3.0) {
      tMult += 0.1; // Temp increases
      wMult += 0.2; // Rainfall deviation increases faster

      simulatedCvs = simulateScenario(
        plantType: plantType,
        tempAnomaly: baseAnomalies['temp'] ?? 0.15,
        waterAnomaly: baseAnomalies['water'] ?? 0.15,
        windAnomaly: baseAnomalies['wind'] ?? 0.15,
        tempMultiplier: tMult,
        waterMultiplier: wMult,
        windMultiplier: 1.0, // Keeping wind stable for typical path to danger
      );
    }

    if (simulatedCvs >= 67) {
      // Approximate translation to real terms:
      // 0.1 multiplier = roughly +0.5°C and -5% rainfall
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
