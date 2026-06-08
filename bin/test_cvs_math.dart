// Quick verification of CVS score distribution after normalization fix.
// Run: dart run bin/test_cvs_math.dart

import 'dart:math';

// ignore_for_file: avoid_print

// Replicate the CVSCalculator logic
const weightTemperature = 0.40;
const weightWater = 0.35;
const weightWind = 0.25;

double computeCVS(
  List<double> sensitivities,
  double tempA,
  double waterA,
  double windA,
) {
  final tempC = weightTemperature * sensitivities[0] * tempA.clamp(0.0, 1.0);
  final waterC = weightWater * sensitivities[1] * waterA.clamp(0.0, 1.0);
  final windC = weightWind * sensitivities[2] * windA.clamp(0.0, 1.0);
  final rawSum = tempC + waterC + windC;
  final maxPossible =
      weightTemperature * sensitivities[0] +
      weightWater * sensitivities[1] +
      weightWind * sensitivities[2];
  final normalized = (rawSum / maxPossible).clamp(0.0, 1.0);
  // Apply a gentler curve (power of 0.75)
  final curved = pow(normalized, 0.75);
  return (curved * 100).clamp(0, 100).toDouble();
}

double gridRiskHash(double lat, double lon) {
  final latInt = (lat * 2).round();
  final lonInt = (lon * 2).round();
  final hash = ((latInt * 73856093) ^ (lonInt * 19349663)).abs() % 1000;
  return hash / 1000.0;
}

void main() {
  // Nuclear: [1.8, 2.0, 0.8]
  // Hydro:   [0.8, 2.2, 0.5]
  // Solar:   [1.4, 0.6, 1.8]
  // Coal:    [1.6, 1.5, 0.9]

  final plantTypes = {
    'Nuclear': [1.8, 2.0, 0.8],
    'Hydro': [0.8, 2.2, 0.5],
    'Solar': [1.4, 0.6, 1.8],
    'Coal': [1.6, 1.5, 0.9],
    'Gas': [1.4, 1.2, 1.0],
    'Wind': [0.5, 0.3, 2.2],
  };

  // Test several latitudes
  final latitudes = [5.0, 15.0, 25.0, 35.0, 45.0, 55.0];

  int highCount = 0, medCount = 0, lowCount = 0;

  for (final lat in latitudes) {
    for (double lon = -180; lon <= 180; lon += 10) {
      final gridLat = (lat * 2).round() / 2.0;
      final gridLon = (lon * 2).round() / 2.0;
      final absLat = gridLat.abs();

      final tempHash = gridRiskHash(gridLat, gridLon);
      final waterHash = gridRiskHash(gridLat + 0.1, gridLon + 0.1);
      final windHash = gridRiskHash(gridLat + 0.2, gridLon + 0.2);

      final tempM = 0.5 + (tempHash * 1.0);
      final waterM = 0.5 + (waterHash * 1.0);
      final windM = 0.5 + (windHash * 1.0);

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

      final tempA = (tempBase * tempM).clamp(0.05, 1.0);
      final waterA = (waterBase * waterM).clamp(0.05, 1.0);
      final windA = (windBase * windM).clamp(0.05, 1.0);

      for (final entry in plantTypes.entries) {
        final score = computeCVS(entry.value, tempA, waterA, windA);
        if (score <= 33) {
          lowCount++;
        } else if (score <= 66) {
          medCount++;
        } else {
          highCount++;
        }
      }
    }
  }

  final total = highCount + medCount + lowCount;
  print('Distribution across $total plant-location combos:');
  print(
    '  HIGH (67-100): $highCount (${(highCount / total * 100).toStringAsFixed(1)}%)',
  );
  print(
    '  MEDIUM (34-66): $medCount (${(medCount / total * 100).toStringAsFixed(1)}%)',
  );
  print(
    '  LOW (0-33): $lowCount (${(lowCount / total * 100).toStringAsFixed(1)}%)',
  );

  // Show a few example scores
  print('\nSample scores:');
  for (final entry in plantTypes.entries) {
    // Tropical plant (lat=10, lon=77 ~India)
    final gridLat = 10.0;
    final gridLon = 77.0;
    final absLat = gridLat.abs();

    final tempHash = gridRiskHash(gridLat, gridLon);
    final waterHash = gridRiskHash(gridLat + 0.1, gridLon + 0.1);
    final windHash = gridRiskHash(gridLat + 0.2, gridLon + 0.2);

    final tempM = 0.5 + (tempHash * 1.0);
    final waterM = 0.5 + (waterHash * 1.0);
    final windM = 0.5 + (windHash * 1.0);

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

    final tempA = (tempBase * tempM).clamp(0.05, 1.0);
    final waterA = (waterBase * waterM).clamp(0.05, 1.0);
    final windA = (windBase * windM).clamp(0.05, 1.0);

    final score = computeCVS(entry.value, tempA, waterA, windA);
    print(
      '  ${entry.key} @ lat=$gridLat,lon=$gridLon: CVS=${score.toStringAsFixed(1)} anomalies=[${tempA.toStringAsFixed(2)}, ${waterA.toStringAsFixed(2)}, ${windA.toStringAsFixed(2)}]',
    );
  }
}
