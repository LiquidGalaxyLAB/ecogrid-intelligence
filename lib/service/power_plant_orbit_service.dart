import '../core/utils/kml_utils.dart';

class PowerPlantOrbitService {
  PowerPlantOrbitService._();

  /// Default orbit parameters.
  static const int _defaultHeadingStep = 15;
  static const double _defaultFlyToDuration = 1.2;

  /// Total duration of a single plant orbit tour in milliseconds.
  /// (360 / headingStep + 1) steps × flyToDuration seconds × 1000.
  static const int plantOrbitDurationMs = 30000; // 25 × 1.2s

  /// Builds a smooth 360-degree KML orbit tour around a specific power plant.
  /// 
  /// The camera perfectly centers on the target coordinates while incrementally
  /// changing the heading to produce a seamless orbit.
  static String buildPowerPlantOrbit({
    required double latitude,
    required double longitude,
    required double range,
    double tilt = 65,
    int headingStep = _defaultHeadingStep,
    double flyToDuration = _defaultFlyToDuration,
    double startHeading = 30, // The default heading we use in flyTo
  }) {
    final tour = buildPlantOrbitTour(
      latitude: latitude,
      longitude: longitude,
      range: range,
      tilt: tilt,
      headingStep: headingStep,
      flyToDuration: flyToDuration,
      startHeading: startHeading,
    );

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
$tour
</kml>''';
  }

  /// Returns just the `<gx:Tour>` XML content (not wrapped in `<kml>`),
  /// suitable for embedding inside another KML document.
  /// This mirrors `KmlUtils.orbitAround(standalone: false)` for regions.
  static String buildPlantOrbitTour({
    required double latitude,
    required double longitude,
    required double range,
    double tilt = 65,
    int headingStep = _defaultHeadingStep,
    double flyToDuration = _defaultFlyToDuration,
    double startHeading = 30,
  }) {
    final buffer = StringBuffer();
    final int steps = (360 / headingStep).floor();

    for (int i = 0; i <= steps; i++) {
      // Add the startHeading so we don't jump backwards. 
      // Google Earth handles headings > 360 seamlessly as continued rotation!
      double heading = startHeading + (i * headingStep).toDouble();

      buffer.writeln(
        KmlUtils.flyTo(
          lat: latitude,
          lon: longitude,
          altitude: 0,
          heading: heading,
          tilt: tilt,
          range: range,
          duration: flyToDuration,
        ),
      );
    }

    return '''
    <gx:Tour>
      <name>Orbit</name>
      <gx:Playlist>
${buffer.toString()}    </gx:Playlist>
    </gx:Tour>''';
  }
}
