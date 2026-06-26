import 'dart:math';
import '../../domain/model/climate_data.dart';

/// Statistically evaluates raw climate data to compute normalized (0.0-1.0) anomaly intensities.
/// These represent long-term historical climate vulnerability for infrastructure.
class AnomalyEngine {
  AnomalyEngine._();

  /// Computes statistical anomalies from historical climate data.
  /// Returns a map with 'temp', 'water', and 'wind' anomaly intensities (0.0–1.0).
  static Map<String, double> computeAnomalies(
    List<ClimateData> historicalData,
  ) {
    if (historicalData.isEmpty) {
      return {'temp': 0.0, 'water': 0.0, 'wind': 0.0};
    }

    final temps =
        historicalData.map((d) => d.temperature).whereType<double>().toList()
          ..sort();
    final precips =
        historicalData.map((d) => d.precipitation).whereType<double>().toList()
          ..sort();
    final winds =
        historicalData.map((d) => d.windSpeed).whereType<double>().toList()
          ..sort();

    // ── 1. Temperature Anomaly ────────────────────────────────
    // Based on 90th percentile heat extremes + mean temperature.
    // Infrastructure stress begins at ~25°C and escalates sharply above 35°C.
    double tempAnomaly = 0.0;
    if (temps.isNotEmpty) {
      final p90Temp = temps[(temps.length * 0.90).floor()];
      final meanTemp = temps.reduce((a, b) => a + b) / temps.length;

      // Two-factor: peak heat stress + sustained heat baseline
      final peakStress = ((p90Temp - 22) / 18).clamp(
        0.0,
        1.0,
      ); // 22°C start, max at 40°C
      final baselineStress = ((meanTemp - 18) / 20).clamp(
        0.0,
        1.0,
      ); // warmer regions = higher base

      tempAnomaly = (peakStress * 0.6 + baselineStress * 0.4).clamp(0.0, 1.0);
    }

    // ── 2. Water Anomaly ──────────────────────────────────────
    // Combined: precipitation volatility (flood/drought cycles) + extreme rain days.
    double waterAnomaly = 0.0;
    if (precips.isNotEmpty) {
      final mean = precips.reduce((a, b) => a + b) / precips.length;
      final variance =
          precips.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
          precips.length;
      final stdDev = sqrt(variance);

      // Volatility factor: high std dev relative to mean = unpredictable water supply
      final volatility = mean > 0.1
          ? (stdDev / (mean + 1)).clamp(0.0, 1.0)
          : 0.3;

      // Extreme rain factor: 90th percentile precipitation
      final p90Precip = precips[(precips.length * 0.90).floor()];
      final extremeRain = (p90Precip / 15.0).clamp(0.0, 1.0);

      // Drought factor: percentage of dry days (< 0.5mm)
      final dryDays = precips.where((p) => p < 0.5).length;
      final droughtRatio = (dryDays / precips.length).clamp(0.0, 1.0);
      final droughtStress = droughtRatio > 0.7
          ? (droughtRatio - 0.3)
          : droughtRatio * 0.5;

      waterAnomaly =
          (volatility * 0.35 + extremeRain * 0.30 + droughtStress * 0.35).clamp(
            0.0,
            1.0,
          );
    }

    // ── 3. Wind Anomaly ───────────────────────────────────────
    // Based on 90th percentile wind + frequency of high-wind days.
    double windAnomaly = 0.0;
    if (winds.isNotEmpty) {
      final p90Wind = winds[(winds.length * 0.90).floor()];

      // Peak wind stress: infrastructure risk begins at 20 km/h, severe above 50 km/h
      final peakStress = ((p90Wind - 15) / 35).clamp(0.0, 1.0);

      // Frequency of gusty days (> 25 km/h)
      final gustyDays = winds.where((w) => w > 25).length;
      final gustFrequency = (gustyDays / winds.length * 2).clamp(0.0, 1.0);

      windAnomaly = (peakStress * 0.6 + gustFrequency * 0.4).clamp(0.0, 1.0);
    }

    return {'temp': tempAnomaly, 'water': waterAnomaly, 'wind': windAnomaly};
  }
}
