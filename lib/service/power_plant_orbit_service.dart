import '../core/utils/kml_utils.dart';

class PowerPlantOrbitService {
  PowerPlantOrbitService._();

  /// Builds a smooth 360-degree KML orbit tour around a specific power plant.
  /// 
  /// The camera perfectly centers on the target coordinates while incrementally
  /// changing the heading to produce a seamless orbit.
  static String buildPowerPlantOrbit({
    required double latitude,
    required double longitude,
    required double range,
    double tilt = 65,
    int headingStep = 15,
    double flyToDuration = 1.2,
    double startHeading = 30, // The default heading we use in flyTo
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

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <gx:Tour>
    <name>Orbit</name>
    <gx:Playlist>
${buffer.toString()}    </gx:Playlist>
  </gx:Tour>
</kml>''';
  }
}
