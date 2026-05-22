import 'package:ecogrid_intelligence/core/enums/risk_level.dart';

/// KML generation utilities for Liquid Galaxy visualization.
///
/// Generates KML strings for placemarks, FlyTo, LookAt, orbits,
/// 3D extrusions, and heatmap overlays.
class KMLGenerator {
  KMLGenerator._();

  /// Generate a complete KML document wrapping content.
  static String wrapInKmlDocument(String content, {String name = 'EcoGrid'}) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>$name</name>
    $content
  </Document>
</kml>''';
  }

  /// Generate a styled placemark for a power plant.
  static String plantPlacemark({
    required String id,
    required String name,
    required double lat,
    required double lon,
    required String plantType,
    required double cvsScore,
    required RiskLevel riskLevel,
    double altitude = 0,
  }) {
    final color = _riskToKmlColor(riskLevel);
    final scale = _cvsToScale(cvsScore);

    return '''
    <Placemark id="plant_$id">
      <name>$name</name>
      <description><![CDATA[
        <b>Type:</b> $plantType<br/>
        <b>CVS Score:</b> ${cvsScore.toStringAsFixed(1)}<br/>
        <b>Risk Level:</b> ${riskLevel.label}
      ]]></description>
      <Style>
        <IconStyle>
          <color>$color</color>
          <scale>$scale</scale>
          <Icon>
            <href>https://maps.google.com/mapfiles/kml/shapes/electricity.png</href>
          </Icon>
        </IconStyle>
        <LabelStyle>
          <color>ffffffff</color>
          <scale>0.8</scale>
        </LabelStyle>
      </Style>
      <Point>
        <altitudeMode>relativeToGround</altitudeMode>
        <coordinates>$lon,$lat,$altitude</coordinates>
      </Point>
    </Placemark>''';
  }

  /// Generate a 3D extruded polygon for climate anomaly visualization.
  static String anomalyExtrusion({
    required double lat,
    required double lon,
    required double intensity,
    required String type,
    double sizeKm = 25,
  }) {
    final height = (intensity * 50000).clamp(1000, 100000);
    final color = _anomalyTypeToColor(type, intensity);
    final halfSize = sizeKm / 111.32;

    final coords = [
      '${lon - halfSize},${lat - halfSize},$height',
      '${lon + halfSize},${lat - halfSize},$height',
      '${lon + halfSize},${lat + halfSize},$height',
      '${lon - halfSize},${lat + halfSize},$height',
      '${lon - halfSize},${lat - halfSize},$height',
    ].join(' ');

    return '''
    <Placemark>
      <name>${type}_anomaly</name>
      <Style>
        <PolyStyle>
          <color>$color</color>
          <fill>1</fill>
          <outline>1</outline>
        </PolyStyle>
        <LineStyle>
          <color>${color.replaceRange(0, 2, 'ff')}</color>
          <width>1</width>
        </LineStyle>
      </Style>
      <Polygon>
        <extrude>1</extrude>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>$coords</coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>''';
  }

  /// Generate a FlyTo command as a KML tour step.
  static String flyTo({
    required double lat,
    required double lon,
    double altitude = 10000,
    double heading = 0,
    double tilt = 60,
    double range = 15000,
    double duration = 3.0,
  }) {
    return '''
    <gx:FlyTo>
      <gx:duration>$duration</gx:duration>
      <gx:flyToMode>smooth</gx:flyToMode>
      <LookAt>
        <longitude>$lon</longitude>
        <latitude>$lat</latitude>
        <altitude>$altitude</altitude>
        <heading>$heading</heading>
        <tilt>$tilt</tilt>
        <range>$range</range>
        <altitudeMode>relativeToGround</altitudeMode>
      </LookAt>
    </gx:FlyTo>''';
  }

  /// Generate a LookAt element (not as part of a tour).
  static String lookAt({
    required double lat,
    required double lon,
    double altitude = 0,
    double heading = 0,
    double tilt = 60,
    double range = 15000,
  }) {
    return '''
    <LookAt>
      <longitude>$lon</longitude>
      <latitude>$lat</latitude>
      <altitude>$altitude</altitude>
      <heading>$heading</heading>
      <tilt>$tilt</tilt>
      <range>$range</range>
      <altitudeMode>relativeToGround</altitudeMode>
    </LookAt>''';
  }

  /// Generate a complete orbit tour around a point.
  static String orbitTour({
    required double lat,
    required double lon,
    double range = 15000,
    double tilt = 60,
    int steps = 36,
    double stepDuration = 1.2,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<gx:Tour>');
    buffer.writeln('  <name>Orbit</name>');
    buffer.writeln('  <gx:Playlist>');

    for (int i = 0; i < steps; i++) {
      final heading = (360.0 * i / steps);
      buffer.writeln(flyTo(
        lat: lat,
        lon: lon,
        heading: heading,
        tilt: tilt,
        range: range,
        duration: stepDuration,
      ));
    }

    buffer.writeln('  </gx:Playlist>');
    buffer.writeln('</gx:Tour>');
    return buffer.toString();
  }

  /// Generate the LG query.txt flyto content.
  static String queryFlyTo({
    required double lat,
    required double lon,
    double altitude = 0,
    double heading = 0,
    double tilt = 60,
    double range = 15000,
  }) {
    return 'flytoview=<LookAt><longitude>$lon</longitude>'
        '<latitude>$lat</latitude><altitude>$altitude</altitude>'
        '<heading>$heading</heading><tilt>$tilt</tilt>'
        '<range>$range</range>'
        '<altitudeMode>relativeToGround</altitudeMode></LookAt>';
  }

  /// Generate HTML content for slave/rightmost rig screens.
  static String slaveScreenHTML({
    required String title,
    required String content,
    String backgroundColor = '#0A0E1A',
    String accentColor = '#00E5A0',
  }) {
    return '''<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      margin: 0; padding: 32px;
      background: $backgroundColor;
      color: white;
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    }
    .title {
      font-size: 28px; font-weight: bold;
      color: $accentColor;
      margin-bottom: 16px;
      border-bottom: 2px solid ${accentColor}40;
      padding-bottom: 8px;
    }
    .content { font-size: 18px; line-height: 1.6; opacity: 0.9; }
    .metric { font-size: 48px; font-weight: bold; color: $accentColor; }
    .label { font-size: 14px; text-transform: uppercase; letter-spacing: 2px; opacity: 0.6; }
  </style>
</head>
<body>
  <div class="title">$title</div>
  <div class="content">$content</div>
</body>
</html>''';
  }

  // ─── Helpers ─────────────────────────────────────────

  static String _riskToKmlColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'ff00e5a0'; // green (AABBGGRR in KML)
      case RiskLevel.medium:
        return 'ff00d7ff'; // yellow
      case RiskLevel.high:
        return 'ff008cff'; // orange
      case RiskLevel.critical:
        return 'ff3b3bff'; // red
    }
  }

  static double _cvsToScale(double cvs) {
    if (cvs <= 25) return 1.0;
    if (cvs <= 50) return 1.3;
    if (cvs <= 75) return 1.6;
    return 2.0;
  }

  static String _anomalyTypeToColor(String type, double intensity) {
    final alpha = (intensity * 200).clamp(60, 200).toInt().toRadixString(16);
    switch (type.toLowerCase()) {
      case 'temperature':
        return '${alpha}0000ff'; // red
      case 'water':
      case 'drought':
        return '${alpha}00a5ff'; // orange
      case 'wind':
        return '${alpha}ffff00'; // cyan
      default:
        return '${alpha}a0e500'; // green
    }
  }
}
