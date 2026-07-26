import 'dart:math' as math;

class KmlTestGenerators {
  static const double defaultLat = 40.4637;
  static const double defaultLon = -3.7492;

  static String _buildLookAt({
    double lat = defaultLat,
    double lon = defaultLon,
    double range = 3500.0,
    double tilt = 60.0,
    double heading = 0.0,
  }) {
    return '''
    <LookAt>
      <longitude>$lon</longitude>
      <latitude>$lat</latitude>
      <altitude>0</altitude>
      <heading>$heading</heading>
      <tilt>$tilt</tilt>
      <range>$range</range>
      <altitudeMode>relativeToGround</altitudeMode>
    </LookAt>''';
  }

  /// 1. 3D Cube (Extruded Square Box)
  static String buildCubeKml({double lat = defaultLat, double lon = defaultLon}) {
    const double delta = 0.005; // ~500m half-width
    const double height = 2000.0;

    final String coordinates = '''
      ${lon - delta},${lat - delta},$height
      ${lon + delta},${lat - delta},$height
      ${lon + delta},${lat + delta},$height
      ${lon - delta},${lat + delta},$height
      ${lon - delta},${lat - delta},$height
    ''';

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>LG 3D Cube Test</name>
    ${_buildLookAt(lat: lat, lon: lon, range: 3500, tilt: 60)}
    <Style id="cubeStyle">
      <LineStyle>
        <color>ff00ff00</color>
        <width>3</width>
      </LineStyle>
      <PolyStyle>
        <color>9f00ff00</color>
      </PolyStyle>
    </Style>
    <Placemark>
      <name>3D Cube</name>
      <styleUrl>#cubeStyle</styleUrl>
      <Polygon>
        <extrude>1</extrude>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              $coordinates
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
  </Document>
</kml>''';
  }

  /// 2. 3D Cylinder (Extruded 24-sided Polygon)
  static String buildCylinderKml({double lat = defaultLat, double lon = defaultLon}) {
    const double radius = 0.005;
    const double height = 3000.0;
    const int segments = 24;

    final StringBuffer coords = StringBuffer();
    for (int i = 0; i <= segments; i++) {
      final double angle = (i * 2 * math.pi) / segments;
      final double pLon = lon + radius * math.cos(angle);
      final double pLat = lat + radius * math.sin(angle);
      coords.writeln('$pLon,$pLat,$height');
    }

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>LG 3D Cylinder Test</name>
    ${_buildLookAt(lat: lat, lon: lon, range: 4000, tilt: 60)}
    <Style id="cylinderStyle">
      <LineStyle>
        <color>ffff00ff</color>
        <width>3</width>
      </LineStyle>
      <PolyStyle>
        <color>9fff00ff</color>
      </PolyStyle>
    </Style>
    <Placemark>
      <name>3D Cylinder</name>
      <styleUrl>#cylinderStyle</styleUrl>
      <Polygon>
        <extrude>1</extrude>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              ${coords.toString()}
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
  </Document>
</kml>''';
  }

  /// 3. 3D Pyramid (MultiGeometry faces meeting at apex)
  static String buildPyramidKml({double lat = defaultLat, double lon = defaultLon}) {
    const double delta = 0.006;
    const double apexHeight = 3000.0;

    final double swLon = lon - delta;
    final double swLat = lat - delta;
    final double seLon = lon + delta;
    final double seLat = lat - delta;
    final double neLon = lon + delta;
    final double neLat = lat + delta;
    final double nwLon = lon - delta;
    final double nwLat = lat + delta;

    String face(double lon1, double lat1, double lon2, double lat2) {
      return '''
      <Polygon>
        <extrude>1</extrude>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              $lon1,$lat1,0
              $lon2,$lat2,0
              $lon,$lat,$apexHeight
              $lon1,$lat1,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>''';
    }

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>LG 3D Pyramid Test</name>
    ${_buildLookAt(lat: lat, lon: lon, range: 4000, tilt: 65)}
    <Style id="pyramidStyle">
      <LineStyle>
        <color>ff0080ff</color>
        <width>3</width>
      </LineStyle>
      <PolyStyle>
        <color>9f0080ff</color>
      </PolyStyle>
    </Style>
    <Placemark>
      <name>3D Pyramid</name>
      <styleUrl>#pyramidStyle</styleUrl>
      <MultiGeometry>
        ${face(swLon, swLat, seLon, seLat)}
        ${face(seLon, seLat, neLon, neLat)}
        ${face(neLon, neLat, nwLon, nwLat)}
        ${face(nwLon, nwLat, swLon, swLat)}
      </MultiGeometry>
    </Placemark>
  </Document>
</kml>''';
  }

  /// 4. Orbit Tour KML
  static String buildOrbitTourKml({double lat = defaultLat, double lon = defaultLon}) {
    final StringBuffer playlist = StringBuffer();
    for (int i = 0; i <= 360; i += 15) {
      playlist.writeln('''
      <gx:FlyTo>
        <gx:duration>0.8</gx:duration>
        <gx:flyToMode>smooth</gx:flyToMode>
        <LookAt>
          <longitude>$lon</longitude>
          <latitude>$lat</latitude>
          <altitude>0</altitude>
          <heading>$i</heading>
          <tilt>60</tilt>
          <range>4000</range>
          <gx:altitudeMode>relativeToGround</gx:altitudeMode>
        </LookAt>
      </gx:FlyTo>''');
    }

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>LG Orbit Tour</name>
    <gx:Tour>
      <name>OrbitTour</name>
      <gx:Playlist>
        ${playlist.toString()}
      </gx:Playlist>
    </gx:Tour>
  </Document>
</kml>''';
  }

  /// 5. KML Balloon Test
  static String buildTestBalloonKml({double lat = defaultLat, double lon = defaultLon}) {
    const String htmlContent = '''
    <div style="background-color: #0F172A; color: #F8FAFC; padding: 24px; border-radius: 12px; font-family: sans-serif; border: 2px solid #38BDF8; width: 340px; box-shadow: 0 4px 20px rgba(0,0,0,0.5);">
      <h2 style="margin: 0 0 12px 0; color: #38BDF8; font-size: 20px;">LG KML Balloon Test</h2>
      <p style="margin: 0 0 16px 0; font-size: 14px; line-height: 1.5; color: #94A3B8;">This balloon verifies HTML/CSS rendering on Liquid Galaxy Google Earth screens.</p>
      <div style="background-color: #1E293B; padding: 12px; border-radius: 8px; border-left: 4px solid #4ADE80;">
        <span style="color: #4ADE80; font-weight: bold;">Status:</span> Connected &amp; Rendering Perfectly
      </div>
    </div>
    ''';

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>KML Balloon Test</name>
    ${_buildLookAt(lat: lat, lon: lon, range: 2500, tilt: 45)}
    <Style id="balloonStyle">
      <BalloonStyle>
        <text><![CDATA[$htmlContent]]></text>
        <bgColor>ff0f172a</bgColor>
      </BalloonStyle>
    </Style>
    <Placemark>
      <name>KML Balloon Test</name>
      <styleUrl>#balloonStyle</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point>
        <coordinates>$lon,$lat,0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>''';
  }
}
