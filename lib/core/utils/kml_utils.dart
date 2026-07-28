import 'dart:math' as math;
import '../enums/risk_level.dart';
import '../../domain/model/power_plant.dart';
import '../../domain/model/cvs_result.dart';
import '../../domain/model/climate_data.dart';
import '../../domain/model/region.dart';

class KmlUtils {
  KmlUtils._();
  static String wrapInKmlDocument(String content, {String name = 'EcoGrid'}) {
    final safeName = name
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>$safeName</name>
    $content
  </Document>
</kml>''';
  }

  static String emptyKml() {
    return wrapInKmlDocument('', name: 'Empty');
  }

  static String emptyBalloon() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
    <kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
      <Document>
       <name>None</name>
       <Style id="blank">
         <BalloonStyle>
           <textColor>ffffffff</textColor>
           <text><font size="+2"></font></text>
           <bgColor>ff15151a</bgColor>
         </BalloonStyle>
       </Style>
       <Placemark id="bb">
         <description></description>
         <styleUrl>#blank</styleUrl>
         <gx:balloonVisibility>0</gx:balloonVisibility>
         <Point>
           <coordinates>0,0,0</coordinates>
         </Point>
       </Placemark>
      </Document>
    </kml>''';
  }

  static String screenOverlayKml() {
    final content = '''
      <ScreenOverlay id="logos_overlay">
        <name>EcoGrid Intelligence Logos</name>
        <Icon>
          <href>http://lg1:81/logos.png</href>
        </Icon>
        <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
        <screenXY x="0.025" y="0.95" xunits="fraction" yunits="fraction"/>
        <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
        <size x="814" y="630" xunits="pixels" yunits="pixels"/>
      </ScreenOverlay>
    ''';
    return wrapInKmlDocument(content, name: 'EcoGrid Logos');
  }

  static String createLogos() => screenOverlayKml();
  /// Height in metres for 3D region polygon extrusion.
  /// 75 km — dramatically visible on Liquid Galaxy at country-level zoom.
  static const double regionExtrusionHeight = 75000;

  // Generates a **3D extruded** KML polygon that fills the region bounding
  // box. Uses relativeToGround with extrude=1 so the polygon rises from
  // the terrain as a translucent glowing wall — impressive on Liquid Galaxy.
  // Includes a LookAt camera at tilt=55° for cinematic oblique view.
  static String regionPlacemark(Region region) {
    final name = _escapeXml(region.displayName ?? region.name);
    final minLat = region.minLat;
    final minLon = region.minLon;
    final maxLat = region.maxLat;
    final maxLon = region.maxLon;
    final centerLat = (minLat + maxLat) / 2;
    final centerLon = (minLon + maxLon) / 2;

    // KML color format: aabbggrr  (alpha, blue, green, red in hex)
    // EcoGrid cyan #38BDF8 → KML component order: f8bd38
    // Fill: 0xa0 = ~63% opacity — semi-transparent, shows terrain through
    // Outline: 0xff = fully opaque bright cyan border, thick for big screens
    const fillColor    = 'a0f8bd38';
    const outlineColor = 'fff8bd38';
    const glowColor    = '5affffff';
    final h = regionExtrusionHeight;

    // 5 points closing the ring with altitude for 3D extrusion.
    final coordStr =
        '$minLon,$minLat,$h '
        '$maxLon,$minLat,$h '
        '$maxLon,$maxLat,$h '
        '$minLon,$maxLat,$h '
        '$minLon,$minLat,$h';

    // Ground outline for glow effect at base.
    final groundCoordStr =
        '$minLon,$minLat,0 '
        '$maxLon,$minLat,0 '
        '$maxLon,$maxLat,0 '
        '$minLon,$maxLat,0 '
        '$minLon,$minLat,0';

    // Camera range from region span
    final latDiff = maxLat - minLat;
    final lonDiff = maxLon - minLon;
    final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;
    double camRange = maxDiff * 111000.0 * 1.4;
    if (camRange < 400000) camRange = 400000;
    if (camRange > 12000000) camRange = 12000000;

    final content = '''
    ${lookAt(lat: centerLat, lon: centerLon, altitude: 0, heading: 0, tilt: 55, range: camRange)}
    <Placemark>
      <name>$name</name>
      <Style>
        <PolyStyle>
          <color>$fillColor</color>
          <fill>1</fill>
          <outline>1</outline>
        </PolyStyle>
        <LineStyle>
          <color>$outlineColor</color>
          <width>4</width>
        </LineStyle>
        <LabelStyle><scale>0</scale></LabelStyle>
        <IconStyle><scale>0</scale></IconStyle>
      </Style>
      <Polygon>
        <extrude>1</extrude>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>$coordStr</coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
    <Placemark>
      <name></name>
      <Style>
        <PolyStyle>
          <color>$fillColor</color>
          <fill>1</fill>
          <outline>1</outline>
        </PolyStyle>
        <LineStyle>
          <color>$glowColor</color>
          <width>6</width>
        </LineStyle>
        <LabelStyle><scale>0</scale></LabelStyle>
        <IconStyle><scale>0</scale></IconStyle>
      </Style>
      <Polygon>
        <altitudeMode>clampToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>$groundCoordStr</coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>''';
    return wrapInKmlDocument(content, name: name);
  }

  static String plantPlacemarksBatch({
    required List<PowerPlant> plants,
    required List<CVSResult> scores,
    required List<RiskLevel> risks,
    String title = 'Plants',
  }) {
    final buffer = StringBuffer();
    final count = plants.length > 100 ? 100 : plants.length;
    for (int i = 0; i < count; i++) {
      final p = plants[i];
      buffer.writeln(
        plantPlacemark(
          id: p.id,
          name: p.name,
          lat: p.latitude,
          lon: p.longitude,
          plantType: p.primaryFuel.displayName,
          cvsScore: scores[i].score,
          riskLevel: risks[i],
          altitude: 500,
        ),
      );
    }
    return wrapInKmlDocument(buffer.toString(), name: title);
  }

  static String plantComparisonNetworkKml({
    required List<PowerPlant> plants,
    required List<CVSResult> scores,
    required List<RiskLevel> risks,
    String title = 'Comparison Network',
  }) {
    final buffer = StringBuffer();
    final count = plants.length;

    // 1. Add all placemarks (3D pins with embedded balloons)
    for (int i = 0; i < count; i++) {
      final p = plants[i];
      buffer.writeln(
        _plantPinContent(
          plant: p,
          riskLevel: risks[i],
          cvs: scores[i],
          includeLookAt: false,
        ),
      );
    }

    // 2. Add connection lines (grid)
    for (int i = 0; i < count; i++) {
      for (int j = i + 1; j < count; j++) {
        final p1 = plants[i];
        final p2 = plants[j];

        buffer.writeln('''
    <Placemark>
      <name>Connection ${p1.id}-${p2.id}</name>
      <Style>
        <LineStyle>
          <color>7f00c8ff</color> <!-- semi-transparent cyan -->
          <width>4</width>
        </LineStyle>
      </Style>
      <LineString>
        <tessellate>1</tessellate>
        <altitudeMode>clampToGround</altitudeMode>
        <coordinates>
          ${p1.longitude},${p1.latitude},0
          ${p2.longitude},${p2.latitude},0
        </coordinates>
      </LineString>
    </Placemark>''');
      }
    }

    return wrapInKmlDocument(buffer.toString(), name: title);
  }

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
            <href>http://maps.google.com/mapfiles/kml/paddle/wht-blank.png</href>
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

  static String flyTo({
    required double lat,
    required double lon,
    double altitude = 10000,
    double heading = 0,
    double tilt = 60,
    double range = 15000,
    double duration = 3.0,
    String flyToMode = 'smooth',
  }) {
    return '''
    <gx:FlyTo>
      <gx:duration>$duration</gx:duration>
      <gx:flyToMode>$flyToMode</gx:flyToMode>
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

  /// Regional dashboard balloon — fluid sizing via calc(px + vw) on the
  /// outer font-size, everything else in em so it scales as one unit.
  static String slaveScreenBalloon({
    required double lat,
    required double lon,
    required String regionName,
    required int totalPlants,
    required int highRiskCount,
    required int mediumRiskCount,
    required int lowRiskCount,
    required String dominantRisk,
    required List<String> top3Plants,
  }) {
    final top3Html = top3Plants.isEmpty
        ? '<p style="color:#94A3B8;margin:0;">No critical plants identified.</p>'
        : top3Plants
              .map((p) => '<p style="color:#F87171;margin:0.6em 0;font-weight:bold;">&#9888; ${_escapeXml(p)}</p>')
              .join('');

    final highPct = totalPlants > 0 ? (highRiskCount * 100 ~/ totalPlants) : 0;
    final medPct  = totalPlants > 0 ? (mediumRiskCount * 100 ~/ totalPlants) : 0;
    final lowPct  = totalPlants > 0 ? (lowRiskCount * 100 ~/ totalPlants) : 0;
    final highRemain = 100 - highPct;
    final medRemain  = 100 - medPct;
    final lowRemain  = 100 - lowPct;

    String barRow(String label, String color, int pct, int remain) => '''
                <tr>
                  <td style="font-size:1.3em;color:$color;font-weight:bold;padding:0 0.7em 0.5em 0;white-space:nowrap;">&#9679; $label</td>
                  <td width="100%">
                    <table width="100%" cellpadding="0" cellspacing="0"><tr>
                      <td width="$pct%" bgcolor="$color" style="line-height:1.3em;font-size:0;">&nbsp;</td>
                      <td width="$remain%" bgcolor="#1E293B" style="line-height:1.3em;font-size:0;">&nbsp;</td>
                    </tr></table>
                  </td>
                  <td align="right" style="font-size:1.3em;font-weight:bold;color:$color;padding:0 0 0.5em 0.7em;white-space:nowrap;">$pct%</td>
                </tr>
                <tr><td colspan="3" style="line-height:0.6em;">&nbsp;</td></tr>''';

    final content = '''
    <Style id="dashboard_style">
      <IconStyle><scale>0</scale></IconStyle>
      <BalloonStyle>
        <bgColor>ff0d1117</bgColor>
        <textColor>ffffffff</textColor>
        <text><![CDATA[
          <script>
            var bId = 'regional_dashboard';
            window.onload = function() {
              if(localStorage.getItem('lg_bId') === bId) {
                var pos = localStorage.getItem('lg_sPos');
                if (pos) window.scrollTo(0, parseInt(pos, 10));
              } else {
                localStorage.setItem('lg_bId', bId);
                localStorage.setItem('lg_sPos', 0);
              }
              setInterval(function() {
                var pos = window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop || 0;
                localStorage.setItem('lg_sPos', pos);
              }, 100);
            };
          </script>

          <div style="font-family:Arial,sans-serif;width:700px;background:#0d1117;color:#fff;font-size:14px;border:2px solid #38BDF8;border-radius:12px;">

            <table width="100%" cellpadding="0" cellspacing="0" bgcolor="#0f2a3d" style="border-bottom:4px solid #38BDF8;">
              <tr><td style="padding:1.4em 1.6em 1.1em;">
                <p style="font-size:0.9em;color:#38BDF8;margin:0 0 0.4em;letter-spacing:0.2em;font-weight:bold;">ECOGRID INTELLIGENCE</p>
                <p style="font-size:2.2em;font-weight:bold;color:#fff;margin:0;">&#127757; ${_escapeXml(regionName)}</p>
                <p style="font-size:1.15em;color:#94A3B8;margin:0.4em 0 0;">Climate Risk Dashboard</p>
              </td></tr>
            </table>

            <table width="100%" cellpadding="0" cellspacing="0" style="border-bottom:1px solid #1e293b;">
              <tr>
                <td width="25%" align="center" style="padding:1.4em 0.5em;border-left:4px solid #38BDF8;">
                  <p style="font-size:2.6em;font-weight:bold;color:#fff;margin:0;line-height:1;">$totalPlants</p>
                  <p style="font-size:1.05em;color:#94A3B8;margin:0.4em 0 0;">Monitored Plants</p>
                </td>
                <td width="25%" align="center" style="padding:1.4em 0.5em;border-left:4px solid #EF4444;">
                  <p style="font-size:2.6em;font-weight:bold;color:#EF4444;margin:0;line-height:1;">$highRiskCount</p>
                  <p style="font-size:1.05em;color:#94A3B8;margin:0.4em 0 0;">High Risk</p>
                </td>
                <td width="25%" align="center" style="padding:1.4em 0.5em;border-left:4px solid #F59E0B;">
                  <p style="font-size:2.6em;font-weight:bold;color:#F59E0B;margin:0;line-height:1;">$mediumRiskCount</p>
                  <p style="font-size:1.05em;color:#94A3B8;margin:0.4em 0 0;">Medium Risk</p>
                </td>
                <td width="25%" align="center" style="padding:1.4em 0.5em;border-left:4px solid #10B981;">
                  <p style="font-size:2.6em;font-weight:bold;color:#10B981;margin:0;line-height:1;">$lowRiskCount</p>
                  <p style="font-size:1.05em;color:#94A3B8;margin:0.4em 0 0;">Low Risk</p>
                </td>
              </tr>
            </table>

            <table width="100%" cellpadding="0" cellspacing="0" style="border-bottom:1px solid #1e293b;">
              <tr><td style="padding:1.7em 1.8em 1em;">
                <p style="font-size:1.5em;color:#94A3B8;font-weight:bold;margin:0 0 1em;border-bottom:2px solid #334155;padding-bottom:0.4em;display:inline-block;">&#128202; Risk Distribution</p>
                <table width="100%" cellpadding="0" cellspacing="0" style="margin-top:0.6em;">
                  ${barRow('High', '#EF4444', highPct, highRemain)}
                  ${barRow('Med', '#F59E0B', medPct, medRemain)}
                  ${barRow('Low', '#10B981', lowPct, lowRemain)}
                </table>
              </td></tr>
            </table>

            <table width="100%" cellpadding="0" cellspacing="0">
              <tr><td style="padding:1.7em 1.8em;">
                <table width="100%" cellpadding="0" cellspacing="0">
                  <tr>
                    <td width="50%" valign="top">
                      <p style="font-size:1.35em;color:#94A3B8;margin:0 0 0.6em;font-weight:bold;border-bottom:2px solid #334155;padding-bottom:0.4em;display:inline-block;">&#9888; Primary Threat</p>
                      <p style="font-size:2.3em;color:#EF4444;font-weight:bold;margin:0.6em 0 0;">${_escapeXml(dominantRisk)}</p>
                    </td>
                    <td width="50%" valign="top" style="padding-left:1.4em;border-left:1px solid #334155;">
                      <p style="font-size:1.35em;color:#94A3B8;margin:0 0 0.6em;font-weight:bold;border-bottom:2px solid #334155;padding-bottom:0.4em;display:inline-block;">&#128205; Critical Infrastructure</p>
                      <div style="margin-top:0.6em;font-size:1.2em;">$top3Html</div>
                    </td>
                  </tr>
                </table>
              </td></tr>
            </table>
          </div>
        ]]></text>
      </BalloonStyle>
    </Style>
    <Placemark id="dashboard_placemark">
      <name>EcoGrid</name>
      <description>Dashboard</description>
      <styleUrl>#dashboard_style</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point><coordinates>$lon,$lat,0</coordinates></Point>
    </Placemark>''';

    return wrapInKmlDocument(content, name: 'EcoGrid Dashboard');
  }

  static String regionalAiInsightBalloon({
    required String regionName,
    required String aiInsight,
    required double lat,
    required double lon,
  }) {
    final formattedAiInsight = aiInsight.replaceAll('\n', '<br/><br/>').replaceAll("'", "&#8217;");
    
    final content = '''
    <Style id="ai_insight_style">
      <IconStyle><scale>0</scale></IconStyle>
      <BalloonStyle>
        <bgColor>ff17110d</bgColor>
        <textColor>ffffffff</textColor>
        <text><![CDATA[
          <script>
            var bId = 'ai_insight_regional';
            window.onload = function() {
              if(localStorage.getItem('lg_bId') === bId) {
                var pos = localStorage.getItem('lg_sPos');
                if (pos) window.scrollTo(0, parseInt(pos, 10));
              } else {
                localStorage.setItem('lg_bId', bId);
                localStorage.setItem('lg_sPos', 0);
              }
              setInterval(function() {
                var pos = window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop || 0;
                localStorage.setItem('lg_sPos', pos);
              }, 100);
            };
          </script>
          
          <div style="font-family:Arial,sans-serif;width:700px;background:#0d1117;color:#fff;font-size:14px;border:2px solid #1e293b;">
            <table width="100%" cellpadding="0" cellspacing="0" bgcolor="#0F766E" style="border-bottom:3px solid #10b981;">
              <tr><td style="padding:1.4em 1.6em;">
                <p style="font-size:1.8em;font-weight:bold;color:#fff;margin:0;">&#10024; AI Regional Risk Analysis</p>
                <p style="font-size:1.1em;color:#ccfbf1;margin:0.3em 0 0;">ECOGRID INTELLIGENCE</p>
              </td></tr>
            </table>

            <table width="100%" cellpadding="0" cellspacing="0" bgcolor="#111827" style="border-bottom:1px solid #1e293b;">
              <tr><td style="padding:1.4em 1.6em;">
                <p style="font-size:2.5em;font-weight:bold;color:#fff;margin:0;">&#127757; ${_escapeXml(regionName)}</p>
                <p style="font-size:1.1em;color:#94a3b8;margin:0.5em 0 0;">Climate Risk Dashboard</p>
              </td></tr>
            </table>

            <table width="100%" cellpadding="0" cellspacing="0">
              <tr><td style="padding:1.8em 1.6em;">
                <p style="color:#a855f7;font-size:1.8em;font-weight:bold;margin:0 0 0.6em;">&#10024; Regional AI Assessment</p>
                <p style="color:#e2e8f0;font-size:1.3em;line-height:1.7;margin:0;">$formattedAiInsight</p>
              </td></tr>
            </table>
          </div>
        ]]></text>
      </BalloonStyle>
    </Style>
    <Placemark id="ai_insight_placemark">
      <name>AI Insight</name>
      <styleUrl>#ai_insight_style</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point><coordinates>$lon,$lat,0</coordinates></Point>
    </Placemark>''';
    return wrapInKmlDocument(content, name: 'AI Insight - ${_escapeXml(regionName)}');
  }



  static String plantPinKml({
    required PowerPlant plant,
    required RiskLevel riskLevel,
  }) {
    return wrapInKmlDocument(
      _plantPinContent(plant: plant, riskLevel: riskLevel, cvs: null, includeLookAt: true),
      name: plant.name,
    );
  }

  static String buildPlantNetworkKml(
    List<PowerPlant> plants,
    CVSResult Function(PowerPlant) scoreGetter,
  ) {
    final buf = StringBuffer();
    for (final plant in plants) {
      final cvs = scoreGetter(plant);
      buf.writeln(_plantPinContent(
        plant: plant,
        riskLevel: cvs.riskLevel,
        cvs: cvs,
        includeLookAt: false,
      ));
    }
    return buf.toString();
  }

  static String _plantPinContent({
    required PowerPlant plant,
    required RiskLevel riskLevel,
    CVSResult? cvs,
    bool includeLookAt = false,
  }) {
    final lat = plant.latitude;
    final lon = plant.longitude;

    // ── Risk colour in KML aabbggrr format ────────────────────────────────
    final String colorBBGGRR;
    final String iconHref;
    switch (riskLevel) {
      case RiskLevel.high:
        colorBBGGRR = '4444ef';
        iconHref = 'http://maps.google.com/mapfiles/kml/paddle/red-blank.png';
        break;
      case RiskLevel.medium:
        colorBBGGRR = '0b9ef5';
        iconHref = 'http://maps.google.com/mapfiles/kml/paddle/ylw-blank.png';
        break;
      case RiskLevel.low:
        colorBBGGRR = '81b910';
        iconHref = 'http://maps.google.com/mapfiles/kml/paddle/grn-blank.png';
        break;
    }

    // ── Dynamic height based on plant capacity ───────────────────────────
    final capacity = plant.capacityMw ?? 50;
    final beaconHeight = (150 + math.sqrt(capacity) * 20).clamp(150.0, 600.0);

    final buf = StringBuffer();

    if (includeLookAt) {
      final viewRange = (beaconHeight * 3.0).clamp(800.0, 5000.0);
      buf.writeln('''
    <LookAt>
      <longitude>$lon</longitude>
      <latitude>$lat</latitude>
      <altitude>0</altitude>
      <heading>0</heading>
      <tilt>60</tilt>
      <range>$viewRange</range>
      <altitudeMode>relativeToGround</altitudeMode>
    </LookAt>''');
    }

    // ── 1. Ground glow — large translucent disc at ground level ──────────
    final groundGlowPts = _circleKmlCoords(
      lat: lat, lon: lon, radiusDeg: 0.005, altitude: 2,
    );
    buf.writeln('''
    <Placemark>
      <name></name>
      <Style>
        <PolyStyle><color>44$colorBBGGRR</color><fill>1</fill><outline>0</outline></PolyStyle>
        <LabelStyle><scale>0</scale></LabelStyle>
        <IconStyle><scale>0</scale></IconStyle>
      </Style>
      <Polygon>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs><LinearRing><coordinates>$groundGlowPts</coordinates></LinearRing></outerBoundaryIs>
      </Polygon>
    </Placemark>''');

    // ── 2. Central pillar — extruded narrow polygon rising from ground ───
    // A small hexagonal base extruded to beaconHeight creates a solid pillar
    const pillarRadius = 0.0003; // ~33m radius
    const pillarSteps = 6; // hexagonal cross-section
    final pillarBasePts = _circleKmlCoords(
      lat: lat, lon: lon, radiusDeg: pillarRadius,
      steps: pillarSteps, altitude: beaconHeight,
    );
    // Create the balloon HTML if cvs is provided
    String styleContent = '';
    String descriptionTag = '';
    
    if (cvs != null) {
      final String riskColor;
      final String riskGradient;
      switch (cvs.riskLevel) {
        case RiskLevel.high:
          riskColor    = '#EF4444';
          riskGradient = '#7f1d1d';
          break;
        case RiskLevel.medium:
          riskColor    = '#F59E0B';
          riskGradient = '#78350f';
          break;
        case RiskLevel.low:
          riskColor    = '#10B981';
          riskGradient = '#064e3b';
          break;
      }
      final typeIcon = _plantTypeIcon(plant.primaryFuel.csvLabel);
      final capacityStr = plant.capacityMw != null ? '${plant.capacityMw!.toStringAsFixed(0)} MW' : 'N/A';
      
      final dims = [
        ('&#127777; Temperature', cvs.temperatureStress),
        ('&#128166; Water', cvs.waterStress),
        ('&#127788; Wind', cvs.windStress),
      ];
      final dimRows = dims.map((d) {
        final label  = d.$1;
        final raw    = d.$2;
        final scaled = raw / 10.0;
        final barColor = scaled > 7 ? '#EF4444' : (scaled >= 4 ? '#F59E0B' : '#10B981');
        final barPct   = (raw.clamp(0, 100)).toInt();
        return '''
                  <tr>
                    <td style="font-size:21px;color:#CBD5E1;padding:4px 0;">$label</td>
                    <td align="right" style="font-size:24px;font-weight:bold;color:$barColor;">${scaled.toStringAsFixed(1)}</td>
                  </tr>
                  <tr>
                    <td colspan="2" style="padding-bottom:10px;">
                      <table width="100%" cellpadding="0" cellspacing="0"><tr>
                        <td width="$barPct%" bgcolor="$barColor" height="14" style="border-radius:4px 0 0 4px;"></td>
                        <td bgcolor="#1E293B" height="14"></td>
                      </tr></table>
                    </td>
                  </tr>''';
      }).join('\n');
      
      styleContent = '''
      <Style id="plant_style_${plant.id}">
        <PolyStyle><color>bb$colorBBGGRR</color><fill>1</fill><outline>1</outline></PolyStyle>
        <LineStyle><color>ff$colorBBGGRR</color><width>2</width></LineStyle>
        <IconStyle><scale>0</scale></IconStyle>
        <LabelStyle><scale>0</scale></LabelStyle>
        <!-- TODO: duplicate of plantDetailBalloon() — consider consolidating -->
        <BalloonStyle>
          <bgColor>ff0d1117</bgColor>
          <textColor>ffffffff</textColor>
          <text><![CDATA[
          <div style="font-family:Arial,sans-serif;width:700px;background:#0d1117;color:#fff;font-size:14px;border:2px solid #0f766e;border-radius:12px;overflow:hidden;">

            <table width="100%" cellpadding="0" cellspacing="0" bgcolor="#115e59" style="border-bottom:4px solid #10b981;">
              <tr><td style="padding:1.4em 1.6em;">
                <p style="font-size:1.8em;font-weight:bold;color:#fff;margin:0;">&#127981; Strategic Energy Assessment</p>
                <p style="font-size:1.1em;color:#ccfbf1;margin:0.3em 0 0;">Network Resilience & Risk Profile</p>
              </td></tr>
            </table>

            <table width="100%" cellpadding="0" cellspacing="0" style="border-bottom:1px solid #1e293b;">
              <tr><td style="padding:1.4em 1.6em;">
                <p style="font-size:2.5em;font-weight:bold;color:#fff;margin:0;">${_escapeXml(plant.name)}</p>
                <p style="font-size:1.1em;color:#94a3b8;margin:0.5em 0 0;">📍 ${_escapeXml(plant.countryLong ?? plant.country)} &nbsp; • &nbsp; $typeIcon ${_escapeXml(plant.primaryFuel.displayName)} &nbsp; • &nbsp; ⚙ $capacityStr</p>
              </td></tr>
            </table>

            <table width="100%" cellpadding="0" cellspacing="0" bgcolor="#1e293b" style="border-bottom:1px solid #0d1117;">
              <tr><td style="padding:1.4em 1.6em;">
                <p style="font-size:1.3em;color:#e2e8f0;font-weight:bold;margin:0 0 0.7em;">Climate Vulnerability Score (CVS)</p>
                <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:0.7em;"><tr>
                  <td width="${cvs.score.round()}%" bgcolor="$riskColor" style="line-height:1.8em;font-size:0;border-radius:6px 0 0 6px;">&nbsp;</td>
                  <td width="${100 - cvs.score.round()}%" bgcolor="#334155" style="line-height:1.8em;font-size:0;border-radius:0 6px 6px 0;">&nbsp;</td>
                </tr></table>
                <table width="100%" cellpadding="0" cellspacing="0"><tr>
                  <td><p style="color:$riskColor;font-size:2.5em;font-weight:bold;margin:0;">${cvs.score.toStringAsFixed(1)} / 100</p></td>
                  <td align="right"><p style="color:#f8fafc;font-size:1.5em;font-weight:bold;margin:0;">${cvs.riskLevel.label} RISK</p></td>
                </tr></table>
              </td></tr>
            </table>

            <table width="100%" cellpadding="0" cellspacing="0">
              <tr><td style="padding:1.4em 1.6em;">
                <p style="font-size:1.3em;color:#e2e8f0;font-weight:bold;margin:0 0 0.7em;">&#9888; Key Risk Drivers</p>
                <table width="100%" cellpadding="0" cellspacing="0" style="border:1px solid #334155;">
                  <tr bgcolor="#111827"><td style="padding:0.6em 0.9em;"><p style="color:#94a3b8;font-size:1.15em;margin:0;">&#127777; Temp Stress</p></td><td align="right" style="padding:0.6em 0.9em;"><p style="color:#fff;font-size:1.15em;font-weight:bold;margin:0;">${cvs.temperatureStress.toStringAsFixed(1)}</p></td></tr>
                  <tr><td style="padding:0.6em 0.9em;"><p style="color:#94a3b8;font-size:1.15em;margin:0;">&#128166; Water Stress</p></td><td align="right" style="padding:0.6em 0.9em;"><p style="color:#fff;font-size:1.15em;font-weight:bold;margin:0;">${cvs.waterStress.toStringAsFixed(1)}</p></td></tr>
                  <tr bgcolor="#111827"><td style="padding:0.6em 0.9em;"><p style="color:#94a3b8;font-size:1.15em;margin:0;">&#127788; Wind Stress</p></td><td align="right" style="padding:0.6em 0.9em;"><p style="color:#fff;font-size:1.15em;font-weight:bold;margin:0;">${cvs.windStress.toStringAsFixed(1)}</p></td></tr>
                </table>
              </td></tr>
            </table>
          </div>
          ]]></text>
        </BalloonStyle>
      </Style>''';
      descriptionTag = '<description>Click for info</description>';
    } else {
      styleContent = '''
      <Style id="plant_style_${plant.id}">
        <PolyStyle><color>bb$colorBBGGRR</color><fill>1</fill><outline>1</outline></PolyStyle>
        <LineStyle><color>ff$colorBBGGRR</color><width>2</width></LineStyle>
        <IconStyle><scale>0</scale></IconStyle>
        <LabelStyle><scale>0</scale></LabelStyle>
      </Style>''';
    }

    // Extruded pillar base
    buf.writeln('''
    $styleContent
    <Placemark id="plant_pin_${plant.id}">
      <name>${_escapeXml(plant.name)}</name>
      $descriptionTag
      <styleUrl>#plant_style_${plant.id}</styleUrl>
      <Polygon>
        <extrude>1</extrude>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs><LinearRing><coordinates>$pillarBasePts</coordinates></LinearRing></outerBoundaryIs>
      </Polygon>
    </Placemark>''');

    // ── 3. Floating beacon rings at ascending altitudes ──────────────────
    // 4 rings that float at 25%, 50%, 75%, 95% of beacon height
    // Radius decreases and alpha decreases as they go higher
    final beaconRings = [
      (altFraction: 0.25, radiusDeg: 0.0035, alpha: 'aa'),
      (altFraction: 0.50, radiusDeg: 0.0028, alpha: '88'),
      (altFraction: 0.75, radiusDeg: 0.0020, alpha: '66'),
      (altFraction: 0.95, radiusDeg: 0.0012, alpha: '55'),
    ];

    for (final ring in beaconRings) {
      final ringAlt = beaconHeight * ring.altFraction;
      final outerPts = _circleKmlCoords(
        lat: lat, lon: lon, radiusDeg: ring.radiusDeg,
        altitude: ringAlt,
      );
      final innerPts = _circleKmlCoords(
        lat: lat, lon: lon, radiusDeg: ring.radiusDeg * 0.65,
        clockwise: true, altitude: ringAlt,
      );
      buf.writeln('''
    <Placemark>
      <name></name>
      <Style>
        <PolyStyle><color>${ring.alpha}$colorBBGGRR</color><fill>1</fill><outline>1</outline></PolyStyle>
        <LineStyle><color>ff$colorBBGGRR</color><width>2</width></LineStyle>
        <LabelStyle><scale>0</scale></LabelStyle>
        <IconStyle><scale>0</scale></IconStyle>
      </Style>
      <Polygon>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs><LinearRing><coordinates>$outerPts</coordinates></LinearRing></outerBoundaryIs>
        <innerBoundaryIs><LinearRing><coordinates>$innerPts</coordinates></LinearRing></innerBoundaryIs>
      </Polygon>
    </Placemark>''');
    }

    // ── 4. Vertical beam lines — 4 lines from ground to top ─────────────
    // Creates the "energy beam" effect connecting ground to pinnacle
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2; // 0°, 90°, 180°, 270°
      final latRad = lat * math.pi / 180.0;
      final cosLat = math.cos(latRad).abs().clamp(0.01, 1.0);
      final dLon = (0.0002 * math.cos(angle)) / cosLat;
      final dLat = 0.0002 * math.sin(angle);
      final basePt = '${lon + dLon},${lat + dLat},0';
      final topPt = '${lon + dLon * 0.3},${lat + dLat * 0.3},$beaconHeight';
      buf.writeln('''
    <Placemark>
      <name></name>
      <Style>
        <LineStyle><color>cc$colorBBGGRR</color><width>3</width></LineStyle>
        <LabelStyle><scale>0</scale></LabelStyle>
        <IconStyle><scale>0</scale></IconStyle>
      </Style>
      <LineString>
        <altitudeMode>relativeToGround</altitudeMode>
        <coordinates>$basePt $topPt</coordinates>
      </LineString>
    </Placemark>''');
    }// ── 5. Pinnacle icon at the top of the beacon ────────────────────────


    return buf.toString();
  }

  /// 64-point circular approximation for KML ring polygons.
  /// [clockwise]=true reverses winding for use as an inner-boundary hole.
  static String _circleKmlCoords({
    required double lat,
    required double lon,
    required double radiusDeg,
    bool clockwise = false,
    int steps = 64,
    double altitude = 15, // Hover slightly to avoid clipping on water/terrain
  }) {
    final pts = <String>[];
    
    // Correct for spherical distortion at extreme latitudes (e.g. Antarctica)
    // by dividing longitude changes by the cosine of the latitude.
    final latRadians = lat * math.pi / 180.0;
    final cosLat = math.cos(latRadians).abs();
    // Clamp to prevent division by zero exactly at the poles
    final lonCorrection = cosLat < 0.01 ? 0.01 : cosLat;

    for (int i = 0; i < steps; i++) {
      final angle = (clockwise ? -1 : 1) * 2 * math.pi * i / steps;
      final dLon = (radiusDeg * math.cos(angle)) / lonCorrection;
      final dLat = radiusDeg * math.sin(angle);
      pts.add('${lon + dLon},${lat + dLat},$altitude');
    }
    // KML LinearRings must be perfectly closed. Append the exact first point.
    if (pts.isNotEmpty) {
      pts.add(pts.first);
    }
    return pts.join(' ');
  }



  static String plantDetailBalloon({
    required PowerPlant plant,
    required CVSResult cvs,
    required double lat,
    required double lon,
    ClimateData? climateData,
  }) {
    final score = cvs.score.round();
    
    String riskBadge = '🟢 Low Risk';
    String riskColor = '#388E3C';
    if (score >= 90) {
      riskBadge = '🔴 Critical Risk';
      riskColor = '#EF4444';
    } else if (score >= 70) {
      riskBadge = '🟠 High Risk';
      riskColor = '#F97316';
    } else if (score >= 40) {
      riskBadge = '🟡 Moderate Risk';
      riskColor = '#EAB308';
    }

    final fuelType = plant.primaryFuel.toString().split('.').last.toUpperCase();
    final capacity = plant.capacityMw != null ? '${plant.capacityMw!.toStringAsFixed(0)} MW' : 'N/A';
    
    final content = '''
    <Style id="plant_detail_style">
      <IconStyle><scale>0</scale></IconStyle>
      <BalloonStyle>
        <bgColor>ff17110d</bgColor> <!-- ABGR for #0d1117 -->
        <textColor>ffffffff</textColor>
        <text><![CDATA[
          <!-- Add LG scroll fix script just in case -->
          <script>
            var bId = 'plant_detail_${plant.id}';
            window.onload = function() {
              if(localStorage.getItem('lg_bId') === bId) {
                var pos = localStorage.getItem('lg_sPos');
                if (pos) window.scrollTo(0, parseInt(pos, 10));
              } else {
                localStorage.setItem('lg_bId', bId);
                localStorage.setItem('lg_sPos', 0);
              }
              setInterval(function() {
                var pos = window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop || 0;
                localStorage.setItem('lg_sPos', pos);
              }, 100);
            };
          </script>
          
          <div style="font-family:Arial,sans-serif;width:700px;background:#0d1117;color:#fff;font-size:14px;border:2px solid #0284c7;border-radius:12px;">

            <table width="100%" cellpadding="0" cellspacing="0" bgcolor="#0284c7" style="border-bottom:4px solid #38bdf8;">
              <tr><td style="padding:1.4em 1.6em;">
                <p style="font-size:1.8em;font-weight:bold;color:#fff;margin:0;">&#127981; Plant Analysis</p>
                <p style="font-size:1.1em;color:#e0f2fe;margin:0.3em 0 0;">Power Plant Diagnostics &amp; Risk Intelligence</p>
              </td></tr>
            </table>

            <table width="100%" cellpadding="0" cellspacing="0" style="border-bottom:1px solid #1e293b;">
              <tr><td style="padding:1.4em 1.6em;">
                <p style="font-size:2.5em;font-weight:bold;color:#fff;margin:0;">${_escapeXml(plant.name)}</p>
                <p style="font-size:1.1em;color:#94a3b8;margin:0.5em 0 0;">📍 ${_escapeXml(plant.country)} &nbsp; • &nbsp; 🏭 $fuelType &nbsp; • &nbsp; ⚙ $capacity</p>
              </td></tr>
            </table>

            <table width="100%" cellpadding="0" cellspacing="0" bgcolor="#1e293b" style="border-bottom:1px solid #0d1117;">
              <tr><td style="padding:1.4em 1.6em;">
                <p style="font-size:1.3em;color:#e2e8f0;font-weight:bold;margin:0 0 0.7em;">Climate Vulnerability Score (CVS)</p>
                <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:0.7em;"><tr>
                  <td width="$score%" bgcolor="$riskColor" style="line-height:1.8em;font-size:0;border-radius:6px 0 0 6px;">&nbsp;</td>
                  <td width="${100 - score}%" bgcolor="#334155" style="line-height:1.8em;font-size:0;border-radius:0 6px 6px 0;">&nbsp;</td>
                </tr></table>
                <table width="100%" cellpadding="0" cellspacing="0"><tr>
                  <td><p style="color:$riskColor;font-size:2.5em;font-weight:bold;margin:0;">$score / 100</p></td>
                  <td align="right"><p style="color:#f8fafc;font-size:1.5em;font-weight:bold;margin:0;">$riskBadge</p></td>
                </tr></table>
              </td></tr>
            </table>

            <table width="100%" cellpadding="0" cellspacing="0" style="border-bottom:1px solid #1e293b;">
              <tr><td style="padding:1.4em 1.6em;">
                <p style="font-size:1.3em;color:#e2e8f0;font-weight:bold;margin:0 0 0.7em;">Stress Analytics</p>
                <table width="100%" cellpadding="0" cellspacing="0" style="border:1px solid #334155;">
                  <tr bgcolor="#111827"><td style="padding:0.6em 0.9em;"><p style="color:#94a3b8;font-size:1.15em;margin:0;">🌡 Temp Stress</p></td><td align="right" style="padding:0.6em 0.9em;"><p style="color:#fff;font-size:1.15em;font-weight:bold;margin:0;">${cvs.temperatureStress.round()}%</p></td></tr>
                  <tr><td style="padding:0.6em 0.9em;"><p style="color:#94a3b8;font-size:1.15em;margin:0;">💧 Water Stress</p></td><td align="right" style="padding:0.6em 0.9em;"><p style="color:#fff;font-size:1.15em;font-weight:bold;margin:0;">${cvs.waterStress.round()}%</p></td></tr>
                  <tr bgcolor="#111827"><td style="padding:0.6em 0.9em;"><p style="color:#94a3b8;font-size:1.15em;margin:0;">💨 Wind Stress</p></td><td align="right" style="padding:0.6em 0.9em;"><p style="color:#fff;font-size:1.15em;font-weight:bold;margin:0;">${cvs.windStress.round()}%</p></td></tr>
                </table>
              </td></tr>
            </table>

            <table width="100%" cellpadding="0" cellspacing="0">
              <tr><td style="padding:1em 1.6em;text-align:center;border-top:1px solid #334155;">
                <p style="color:#94a3b8;font-size:1.1em;font-weight:bold;margin:0;">📍 Lat: ${lat.toStringAsFixed(4)} &nbsp;&nbsp;&nbsp; 📍 Lon: ${lon.toStringAsFixed(4)}</p>
              </td></tr>
            </table>
          </div>
        ]]></text>
      </BalloonStyle>
    </Style>
    <Placemark id="plant_detail_placemark">
      <name>${_escapeXml(plant.name)}</name>
      <description>Plant Details</description>
      <styleUrl>#plant_detail_style</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point><coordinates>$lon,$lat,0</coordinates></Point>
    </Placemark>''';
    
    return wrapInKmlDocument(content, name: 'Plant Detail - ${plant.name}');
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Public XML-escape accessor for use by external builders.
  static String escapeXml(String input) => _escapeXml(input);

  static String _plantTypeIcon(String csvLabel) {
    final lower = csvLabel.toLowerCase();
    if (lower.contains('solar')) return '&#9728;';
    if (lower.contains('wind')) return '&#127788;';
    if (lower.contains('hydro')) return '&#128166;';
    if (lower.contains('nuclear')) return '&#9762;';
    if (lower.contains('coal')) return '&#127981;';
    if (lower.contains('gas')) return '&#128293;';
    if (lower.contains('oil') || lower.contains('petrol')) return '&#128293;';
    if (lower.contains('biomass')) return '&#127807;';
    if (lower.contains('geo')) return '&#127755;';
    return '&#9889;';
  }

  static String _riskToKmlColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'ff00aa00';
      case RiskLevel.medium:
        return 'ff0078ff';
      case RiskLevel.high:
        return 'ff0000ff';
    }
  }

  static double _cvsToScale(double cvs) {
    if (cvs <= 33) return 1.0;
    if (cvs <= 66) return 1.4;
    return 1.8;
  }

  static String _anomalyTypeToColor(String type, double intensity) {
    final alpha = (intensity * 200).clamp(60, 200).toInt().toRadixString(16);
    switch (type.toLowerCase()) {
      case 'temperature':
        return '${alpha}0000ff';
      case 'water':
      case 'drought':
        return '${alpha}00a5ff';
      case 'wind':
        return '${alpha}ffff00';
      default:
        return '${alpha}a0e500';
    }
  }

  static String plantAiInsightBalloon({
    required PowerPlant plant,
    required String aiInsight,
    required double lat,
    required double lon,
  }) {
    final formattedAiInsight = aiInsight.replaceAll('\n', '<br/><br/>').replaceAll("'", "&#8217;");
    final fuelType = plant.primaryFuel.toString().split('.').last.toUpperCase();
    final capacity = plant.capacityMw != null ? '${plant.capacityMw!.toStringAsFixed(0)} MW' : 'N/A';

    final content = '''
    <Style id="ai_insight_style">
      <IconStyle><scale>0</scale></IconStyle>
      <BalloonStyle>
        <bgColor>ff17110d</bgColor> <!-- ABGR for #0d1117 -->
        <textColor>ffffffff</textColor>
        <text><![CDATA[
          <!-- Anti-blink script -->
          <script>
            var bId = 'ai_insight_${plant.id}';
            window.onload = function() {
              if(localStorage.getItem('lg_bId') === bId) {
                var pos = localStorage.getItem('lg_sPos');
                if (pos) window.scrollTo(0, parseInt(pos, 10));
              } else {
                localStorage.setItem('lg_bId', bId);
                localStorage.setItem('lg_sPos', 0);
              }
              setInterval(function() {
                var pos = window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop || 0;
                localStorage.setItem('lg_sPos', pos);
              }, 100);
            };
          </script>
          
          <div style="font-family:Arial,sans-serif;width:700px;background:#0d1117;color:#fff;font-size:14px;border:2px solid #1e293b;">

            <table width="100%" cellpadding="0" cellspacing="0" bgcolor="#0F766E" style="border-bottom:3px solid #10b981;">
              <tr><td style="padding:1.4em 1.6em;">
                <p style="font-size:1.8em;font-weight:bold;color:#fff;margin:0;">&#10024; AI Risk Analysis</p>
                <p style="font-size:1.1em;color:#ccfbf1;margin:0.3em 0 0;">AI Risk Analysis</p>
              </td></tr>
            </table>

            <table width="100%" cellpadding="0" cellspacing="0" bgcolor="#111827" style="border-bottom:1px solid #1e293b;">
              <tr><td style="padding:1.4em 1.6em;">
                <p style="font-size:2.5em;font-weight:bold;color:#fff;margin:0;">${_escapeXml(plant.name)}</p>
                <p style="font-size:1.1em;color:#94a3b8;margin:0.5em 0 0;">📍 ${_escapeXml(plant.countryLong ?? plant.country)} &nbsp; • &nbsp; 🏭 $fuelType &nbsp; • &nbsp; ⚙ $capacity</p>
              </td></tr>
            </table>

            <table width="100%" cellpadding="0" cellspacing="0">
              <tr><td style="padding:1.8em 1.6em;">
                <p style="color:#a855f7;font-size:1.8em;font-weight:bold;margin:0 0 0.6em;">&#10024; AI Expert Assessment</p>
                <p style="color:#e2e8f0;font-size:1.3em;line-height:1.7;margin:0;">$formattedAiInsight</p>
              </td></tr>
            </table>
          </div>
        ]]></text>
      </BalloonStyle>
    </Style>
    <Placemark id="ai_insight_placemark">
      <name>AI Insight</name>
      <styleUrl>#ai_insight_style</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point><coordinates>$lon,$lat,0</coordinates></Point>
    </Placemark>''';

    return wrapInKmlDocument(content, name: 'AI Insight - ${_escapeXml(plant.name)}');
  }

  static String plantTrendBalloon({
    required PowerPlant plant,
    required List<ClimateData> trendData,
    required double lat,
    required double lon,
  }) {
    if (trendData.isEmpty) return '';

    double sumTemp = 0, sumPrecip = 0, sumWind = 0;
    int countTemp = 0, countPrecip = 0, countWind = 0;
    for (var d in trendData) {
      if (d.temperature != null) { sumTemp += d.temperature!; countTemp++; }
      if (d.precipitation != null) { sumPrecip += d.precipitation!; countPrecip++; }
      if (d.windSpeed != null) { sumWind += d.windSpeed!; countWind++; }
    }
    final avgTemp = countTemp > 0 ? sumTemp / countTemp : 1.0;
    final avgPrecip = countPrecip > 0 ? sumPrecip / countPrecip : 1.0;
    final avgWind = countWind > 0 ? sumWind / countWind : 1.0;

    final tempVals = <double>[];
    final precipVals = <double>[];
    final windVals = <double>[];
    for (var d in trendData) {
      tempVals.add(d.temperature != null && avgTemp.abs() > 0.01 ? ((d.temperature! - avgTemp) / avgTemp) * 100 : 0);
      precipVals.add(d.precipitation != null && avgPrecip.abs() > 0.01 ? ((d.precipitation! - avgPrecip) / avgPrecip) * 100 : 0);
      windVals.add(d.windSpeed != null && avgWind.abs() > 0.01 ? ((d.windSpeed! - avgWind) / avgWind) * 100 : 0);
    }

    final allY = [...tempVals, ...precipVals, ...windVals];
    double minY = allY.reduce((a, b) => a < b ? a : b);
    double maxY = allY.reduce((a, b) => a > b ? a : b);
    final yPadding = ((maxY - minY) * 0.15).clamp(5.0, double.infinity);
    minY = (minY - yPadding).floorToDouble();
    maxY = (maxY + yPadding).ceilToDouble();
    final yRange = maxY - minY == 0 ? 1 : maxY - minY;
    
    final width = 1100;
    final height = 450;
    
    double scaleX(int i) => 80 + (i * (width - 120) / (trendData.length - 1 > 0 ? trendData.length - 1 : 1));
    double scaleY(double val) => height - 40 - ((val - minY) / yRange * (height - 80));

    String polylineTemp = '';
    String polylinePrecip = '';
    String polylineWind = '';
    String pointsHtml = '';
    String labelsHtml = '';

    for (int i = 0; i < trendData.length; i++) {
      final x = scaleX(i);
      final yt = scaleY(tempVals[i]);
      final yp = scaleY(precipVals[i]);
      final yw = scaleY(windVals[i]);
      
      if (i > 0) {
        polylineTemp += ' ';
        polylinePrecip += ' ';
        polylineWind += ' ';
      }
      polylineTemp += '$x,$yt';
      polylinePrecip += '$x,$yp';
      polylineWind += '$x,$yw';

      pointsHtml += '<circle cx="$x" cy="$yt" r="8" fill="#FF5252" />\n';
      pointsHtml += '<circle cx="$x" cy="$yp" r="8" fill="#448AFF" />\n';
      pointsHtml += '<circle cx="$x" cy="$yw" r="8" fill="#69F0AE" />\n';

      labelsHtml += '<text x="$x" y="${height - 5}" fill="#94A3B8" font-size="24" font-family="Arial" font-weight="bold" text-anchor="middle">${trendData[i].timestamp.year}</text>\n';
    }
    
    String gridHtml = '';
    final numSteps = 5;
    for(int i = 0; i <= numSteps; i++) {
        final val = minY + (i * yRange / numSteps);
        final y = scaleY(val);
        gridHtml += '<line x1="80" y1="$y" x2="${width - 40}" y2="$y" stroke="#334155" stroke-width="2" stroke-dasharray="6,6" />\n';
        final sign = val > 0 ? '+' : '';
        gridHtml += '<text x="70" y="${y + 8}" fill="#CBD5E1" font-size="22" font-family="Arial" text-anchor="end">$sign${val.toInt()}%</text>\n';
    }
    final yZero = scaleY(0);
    gridHtml += '<line x1="80" y1="$yZero" x2="${width - 40}" y2="$yZero" stroke="#64748B" stroke-width="3" />\n';

    final svgContent = '''
      <svg width="100%" height="286" viewBox="0 0 $width $height" xmlns="http://www.w3.org/2000/svg">
        $gridHtml
        <polyline points="$polylineTemp" fill="none" stroke="#FF5252" stroke-width="6" stroke-linecap="round" stroke-linejoin="round" />
        <polyline points="$polylinePrecip" fill="none" stroke="#448AFF" stroke-width="6" stroke-linecap="round" stroke-linejoin="round" />
        <polyline points="$polylineWind" fill="none" stroke="#69F0AE" stroke-width="6" stroke-linecap="round" stroke-linejoin="round" />
        $pointsHtml
        $labelsHtml
      </svg>
    ''';

    final content = '''
    <Style id="plant_trend_style">
      <IconStyle><scale>0</scale></IconStyle>
      <BalloonStyle>
        <bgColor>00000000</bgColor>
        <textColor>ffffffff</textColor>
        <text><![CDATA[
          <script>
            var bId = 'trend_${plant.id}';
            window.onload = function() {
              if(localStorage.getItem('lg_bId') === bId) {
                var pos = localStorage.getItem('lg_sPos');
                if (pos) window.scrollTo(0, parseInt(pos, 10));
              } else {
                localStorage.setItem('lg_bId', bId);
                localStorage.setItem('lg_sPos', 0);
              }
              setInterval(function() {
                var pos = window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop || 0;
                localStorage.setItem('lg_sPos', pos);
              }, 100);
            };
          </script>
          <div style="font-family:Arial,sans-serif;width:700px;background:#0d1117;color:#fff;font-size:14px;border:2px solid #1e293b;padding:1.8em;box-sizing:border-box;">
            <div style="padding-bottom:1em;border-bottom:2px solid #1e293b;margin-bottom:1.4em;">
              <p style="font-size:1.8em;font-weight:bold;color:#10B981;margin:0;">&#128200; Historical Trends</p>
              <p style="font-size:1.1em;color:#94A3B8;margin:0.4em 0 0;">${_escapeXml(plant.name)}</p>
            </div>
            <div style="margin-bottom:1em;display:flex;gap:1em;flex-wrap:wrap;">
               <p style="margin:0;font-size:1em;color:#fff;font-weight:bold;"><font color="#FF5252">&#9679;</font> Temp (% dev)</p>
               <p style="margin:0;font-size:1em;color:#fff;font-weight:bold;"><font color="#448AFF">&#9679;</font> Precip (% dev)</p>
               <p style="margin:0;font-size:1em;color:#fff;font-weight:bold;"><font color="#69F0AE">&#9679;</font> Wind (% dev)</p>
            </div>
            <div style="margin-top:0.8em;text-align:center;overflow-x:auto;">
              $svgContent
            </div>
          </div>
        ]]></text>
      </BalloonStyle>
    </Style>
    <Placemark id="plant_detail_placemark">
      <name>${_escapeXml(plant.name)} - Trends</name>
      <styleUrl>#plant_trend_style</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point><coordinates>$lon,$lat,0</coordinates></Point>
    </Placemark>''';
    return wrapInKmlDocument(content, name: 'Trends - ${plant.name}');
  }

  static String plantScenarioBalloon({
    required PowerPlant plant,
    required CVSResult cvs,
    required double projectedCvs,
    required String scenarioInsight,
    required String scenarioType,
    required double lat,
    required double lon,
  }) {
    final formattedAiInsight = scenarioInsight.replaceAll('\n', '<br/><br/>').replaceAll("'", "&#8217;");
    final fuelType = plant.primaryFuel.toString().split('.').last.toUpperCase();
    final capacity = plant.capacityMw != null ? '${plant.capacityMw!.toStringAsFixed(0)} MW' : 'N/A';
    
    final diff = projectedCvs - cvs.score;
    final diffColor = diff > 0 ? '#ef4444' : (diff < 0 ? '#10b981' : '#f59e0b');
    final diffSymbol = diff > 0 ? '&#8593; +' : (diff < 0 ? '&#8595; ' : '');

    final content = '''
    <Style id="scenario_insight_style">
      <IconStyle><scale>0</scale></IconStyle>
      <BalloonStyle>
        <bgColor>ff17110d</bgColor> <!-- ABGR for #0d1117 -->
        <textColor>ffffffff</textColor>
        <text><![CDATA[
          <!-- Anti-blink script -->
          <script>
            var bId = 'scenario_insight_${plant.id}';
            window.onload = function() {
              if(localStorage.getItem('lg_bId') === bId) {
                var pos = localStorage.getItem('lg_sPos');
                if (pos) window.scrollTo(0, parseInt(pos, 10));
              } else {
                localStorage.setItem('lg_bId', bId);
                localStorage.setItem('lg_sPos', 0);
              }
              setInterval(function() {
                var pos = window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop || 0;
                localStorage.setItem('lg_sPos', pos);
              }, 100);
            };
          </script>
          
          <div style="font-family:Arial,sans-serif;width:700px;background:#0d1117;color:#fff;font-size:14px;border:2px solid #1e293b;">

            <table width="100%" cellpadding="0" cellspacing="0" bgcolor="#0F766E" style="border-bottom:3px solid #10b981;">
              <tr><td style="padding:1.4em 1.6em;">
                <p style="font-size:1.8em;font-weight:bold;color:#fff;margin:0;">&#127757; ${_escapeXml(scenarioType)}</p>
                <p style="font-size:1.1em;color:#ccfbf1;margin:0.3em 0 0;">Climate Scenario Simulation</p>
              </td></tr>
            </table>

            <table width="100%" cellpadding="0" cellspacing="0" bgcolor="#111827" style="border-bottom:1px solid #1e293b;">
              <tr><td style="padding:1.4em 1.6em;">
                <p style="font-size:2.5em;font-weight:bold;color:#fff;margin:0;">${_escapeXml(plant.name)}</p>
                <p style="font-size:1.1em;color:#94a3b8;margin:0.5em 0 0;">📍 ${_escapeXml(plant.countryLong ?? plant.country)} &nbsp; • &nbsp; 🏭 $fuelType &nbsp; • &nbsp; ⚙ $capacity</p>
                <table width="100%" cellpadding="0" cellspacing="0" style="margin-top:1.2em;border:1px solid #334155;">
                  <tr bgcolor="#1e293b">
                    <td width="33%" align="center" style="padding:0.8em 0.4em;border-right:1px solid #334155;">
                      <p style="color:#94a3b8;font-size:1em;margin:0;">Current CVS</p>
                      <p style="color:#f8fafc;font-size:2.2em;font-weight:bold;margin:0.2em 0 0;">${cvs.score.toStringAsFixed(1)}</p>
                    </td>
                    <td width="33%" align="center" style="padding:0.8em 0.4em;border-right:1px solid #334155;">
                      <p style="color:#94a3b8;font-size:1em;margin:0;">Projected CVS</p>
                      <p style="color:#f8fafc;font-size:2.2em;font-weight:bold;margin:0.2em 0 0;">${projectedCvs.toStringAsFixed(1)}</p>
                    </td>
                    <td width="34%" align="center" style="padding:0.8em 0.4em;">
                      <p style="color:#94a3b8;font-size:1em;margin:0;">Impact</p>
                      <p style="color:$diffColor;font-size:2.2em;font-weight:bold;margin:0.2em 0 0;">$diffSymbol${diff.abs().toStringAsFixed(1)}</p>
                    </td>
                  </tr>
                </table>
              </td></tr>
            </table>

            <table width="100%" cellpadding="0" cellspacing="0">
              <tr><td style="padding:1.8em 1.6em;">
                <p style="color:#ef4444;font-size:1.8em;font-weight:bold;margin:0 0 0.6em;">&#128302; Scenario Impact Analysis</p>
                <p style="color:#e2e8f0;font-size:1.3em;line-height:1.7;margin:0;">$formattedAiInsight</p>
              </td></tr>
            </table>
          </div>
        ]]></text>
      </BalloonStyle>
    </Style>
    <Placemark id="scenario_insight_placemark">
      <name>Scenario Insight</name>
      <styleUrl>#scenario_insight_style</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point><coordinates>$lon,$lat,0</coordinates></Point>
    </Placemark>''';

    return wrapInKmlDocument(content, name: 'Scenario Insight - ${_escapeXml(plant.name)}');
  }
}
