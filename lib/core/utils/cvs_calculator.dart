import 'package:ecogrid_intelligence/core/enums/plant_type.dart';

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

  // ─── Sensitivity Matrix ──────────────────────────────
  /// [tempSensitivity, waterSensitivity, windSensitivity]
  static const Map<PlantType, List<double>> _sensitivityMatrix = {
    PlantType.nuclear: [0.70, 0.90, 0.30],
    PlantType.hydro: [0.40, 1.00, 0.20],
    PlantType.solar: [0.60, 0.20, 0.80],
    PlantType.wind: [0.20, 0.10, 1.00],
    PlantType.coal: [0.80, 0.70, 0.40],
    PlantType.gas: [0.70, 0.50, 0.50],
    PlantType.oil: [0.75, 0.55, 0.45],
    PlantType.biomass: [0.50, 0.60, 0.35],
    PlantType.geothermal: [0.30, 0.40, 0.25],
    PlantType.waste: [0.55, 0.45, 0.40],
    PlantType.wave: [0.20, 0.30, 0.90],
    PlantType.storage: [0.40, 0.30, 0.50],
    PlantType.cogeneration: [0.65, 0.55, 0.40],
    PlantType.petcoke: [0.80, 0.60, 0.40],
    PlantType.other: [0.50, 0.50, 0.50],
  };

  /// Compute CVS score (0–100) for a given plant type and anomaly intensities.
  ///
  /// [tempAnomaly], [waterAnomaly], [windAnomaly] should be normalized 0.0–1.0.
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

    final totalWeight = weightTemperature + weightWater + weightWind;
    final cvs =
        ((tempContribution + waterContribution + windContribution) /
            totalWeight) *
        100;

    return cvs.clamp(0, 100);
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

    return {
      'temperature': (sensitivities[0] * tempAnomaly.clamp(0.0, 1.0) * 100)
          .clamp(0, 100),
      'water': (sensitivities[1] * waterAnomaly.clamp(0.0, 1.0) * 100)
          .clamp(0, 100),
      'wind': (sensitivities[2] * windAnomaly.clamp(0.0, 1.0) * 100)
          .clamp(0, 100),
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
}
