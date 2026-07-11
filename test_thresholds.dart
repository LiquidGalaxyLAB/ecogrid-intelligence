import 'dart:io';

double computeCVS({
  required double tempAnomaly,
  required double waterAnomaly,
  required double windAnomaly,
}) {
  final weightTemperature = 0.40;
  final weightWater = 0.35;
  final weightWind = 0.25;
  final sensitivities = [0.5, 0.5, 0.5]; // PlantType.other

  final tempContribution = weightTemperature * sensitivities[0] * tempAnomaly;
  final waterContribution = weightWater * sensitivities[1] * waterAnomaly;
  final windContribution = weightWind * sensitivities[2] * windAnomaly;

  final rawSum = tempContribution + waterContribution + windContribution;
  final maxPossible = weightTemperature * sensitivities[0] +
      weightWater * sensitivities[1] +
      weightWind * sensitivities[2];
  final normalized = (rawSum / maxPossible).clamp(0.0, 1.0);
  final curved = mathPow(normalized, 0.75);
  return curved * 100;
}

double mathPow(double x, double exponent) {
  // Simple approximation or just use dart:math
  return 0.0;
}
