import 'package:ecogrid_intelligence/core/utils/anomaly_engine.dart';
import 'package:ecogrid_intelligence/domain/model/climate_data.dart';
import 'package:flutter_test/flutter_test.dart';

ClimateData observation({
  double? temperature,
  double? precipitation,
  double? windSpeed,
}) => ClimateData(
  latitude: 0,
  longitude: 0,
  timestamp: DateTime.utc(2026, 1, 1),
  temperature: temperature,
  precipitation: precipitation,
  windSpeed: windSpeed,
);

void main() {
  group('AnomalyEngine.computeAnomalies', () {
    test('returns all three zero scores for no observations', () {
      expect(AnomalyEngine.computeAnomalies([]), {
        'temp': 0.0,
        'water': 0.0,
        'wind': 0.0,
      });
    });

    test('returns zero scores when all measurements are missing', () {
      expect(AnomalyEngine.computeAnomalies([observation()]), {
        'temp': 0.0,
        'water': 0.0,
        'wind': 0.0,
      });
    });

    test('ignores missing measurements separately for each dimension', () {
      final complete = observation(
        temperature: 30,
        precipitation: 2,
        windSpeed: 20,
      );
      final separate = [
        observation(temperature: 30),
        observation(precipitation: 2),
        observation(windSpeed: 20),
        observation(),
      ];
      expect(
        AnomalyEngine.computeAnomalies(separate),
        AnomalyEngine.computeAnomalies([complete]),
      );
    });

    test('computes scores for a mild constant series', () {
      final scores = AnomalyEngine.computeAnomalies([
        observation(temperature: 18, precipitation: 2, windSpeed: 10),
        observation(temperature: 18, precipitation: 2, windSpeed: 10),
      ]);
      expect(scores['temp'], 0.0);
      expect(scores['water'], closeTo(0.04, 1e-12));
      expect(scores['wind'], 0.0);
    });

    test('distinguishes zero rainfall from missing rainfall', () {
      final dry = AnomalyEngine.computeAnomalies([
        observation(precipitation: 0),
      ]);
      final missing = AnomalyEngine.computeAnomalies([observation()]);
      expect(dry['water'], closeTo(0.35, 1e-12));
      expect(missing['water'], 0.0);
    });

    test(
      'scores are independent of observation order without sorting input',
      () {
        final observations = [
          observation(temperature: 50, precipitation: 15, windSpeed: 60),
          observation(temperature: 18, precipitation: 2, windSpeed: 10),
          observation(temperature: 30, precipitation: 0, windSpeed: 20),
        ];
        final original = List<ClimateData>.of(observations);
        final scores = AnomalyEngine.computeAnomalies(observations);
        expect(
          scores,
          AnomalyEngine.computeAnomalies(observations.reversed.toList()),
        );
        for (var i = 0; i < original.length; i++) {
          expect(identical(observations[i], original[i]), isTrue);
        }
      },
    );
  });
}
