import 'dart:math';
import '../../domain/model/climate_data.dart';

class AnomalyEngine {
  AnomalyEngine._();
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
    double tempAnomaly = 0.0;
    if (temps.isNotEmpty) {
      final p90Temp = temps[(temps.length * 0.90).floor()];
      final meanTemp = temps.reduce((a, b) => a + b) / temps.length;
      final peakStress = ((p90Temp - 22) / 18).clamp(0.0, 1.0);
      final baselineStress = ((meanTemp - 18) / 20).clamp(0.0, 1.0);
      tempAnomaly = (peakStress * 0.6 + baselineStress * 0.4).clamp(0.0, 1.0);
    }
    double waterAnomaly = 0.0;
    if (precips.isNotEmpty) {
      final mean = precips.reduce((a, b) => a + b) / precips.length;
      final variance =
          precips.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
          precips.length;
      final stdDev = sqrt(variance);
      final volatility = mean > 0.1
          ? (stdDev / (mean + 1)).clamp(0.0, 1.0)
          : 0.3;
      final p90Precip = precips[(precips.length * 0.90).floor()];
      final extremeRain = (p90Precip / 15.0).clamp(0.0, 1.0);
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
    double windAnomaly = 0.0;
    if (winds.isNotEmpty) {
      final p90Wind = winds[(winds.length * 0.90).floor()];
      final peakStress = ((p90Wind - 15) / 35).clamp(0.0, 1.0);
      final gustyDays = winds.where((w) => w > 25).length;
      final gustFrequency = (gustyDays / winds.length * 2).clamp(0.0, 1.0);
      windAnomaly = (peakStress * 0.6 + gustFrequency * 0.4).clamp(0.0, 1.0);
    }
    return {'temp': tempAnomaly, 'water': waterAnomaly, 'wind': windAnomaly};
  }
}
