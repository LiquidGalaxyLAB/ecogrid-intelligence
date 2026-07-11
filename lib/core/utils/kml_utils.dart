import 'dart:math' as math;
import '../enums/risk_level.dart';
import '../../domain/model/power_plant.dart';
import '../../domain/model/cvs_result.dart';
import '../../domain/model/climate_data.dart';
import '../../domain/model/region.dart';

class KmlUtils {
  KmlUtils._();
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
        <screenXY x="0.02" y="0.98" xunits="fraction" yunits="fraction"/>
        <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
        <size x="554" y="500" xunits="pixels" yunits="pixels"/>
      </ScreenOverlay>
    ''';
    return wrapInKmlDocument(content, name: 'EcoGrid Logos');
  }

  static String createLogos() => screenOverlayKml();
  // Generates a KML polygon that fills the entire region bounding box.
  // Uses clampToGround so the fill drapes on the terrain and is visible at
  // any camera altitude — from street-level to watching the whole planet.
  // Only 5 corner points — keeps the SSH command short and reliable.
  static String regionPlacemark(Region region) {
    final name = region.displayName ?? region.name;
    final minLat = region.minLat;
    final minLon = region.minLon;
    final maxLat = region.maxLat;
    final maxLon = region.maxLon;

    // KML color format: aabbggrr  (alpha, blue, green, red in hex)
    // EcoGrid cyan #38BDF8 → KML component order: f8bd38
    // Fill: 0xcc = 204/255 = 80% opacity  → solid, deeply visible like the reference image
    // Outline: 0xff = 100% opaque bright cyan border
    const fillColor    = 'ccf8bd38';
    const outlineColor = 'fff8bd38';

    // 5 points closing the ring — clampToGround handles curvature automatically.
    final coordStr =
        '$minLon,$minLat,0 '
        '$maxLon,$minLat,0 '
        '$maxLon,$maxLat,0 '
        '$minLon,$maxLat,0 '
        '$minLon,$minLat,0';

    final content = '''
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
        <altitudeMode>clampToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>$coordStr</coordinates>
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
        ),
      );
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

  static String orbitTour({
    required double lat,
    required double lon,
    double range = 15000,
    double tilt = 60,
    int steps = 36,
    double stepDuration = 1.2,
  }) {
    final buffer = StringBuffer();
    for (int i = 0; i < steps; i++) {
      final heading = (360.0 * i / steps);
      buffer.writeln(
        flyTo(
          lat: lat,
          lon: lon,
          altitude: 0,
          heading: heading,
          tilt: tilt,
          range: range,
          duration: stepDuration,
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
    String? aiInsight,
  }) {
    final top3Html = top3Plants.isEmpty
        ? '<p style="color:#94A3B8;font-size:22px;">No critical plants identified.</p>'
        : top3Plants
              .map((p) => '<p style="color:#F87171;font-size:22px;margin:6px 0;">&#9888; $p</p>')
              .join('');
    final formattedAiInsight = aiInsight?.replaceAll('\\n', '<br/>') ?? '';
    final aiSection = aiInsight != null && aiInsight.isNotEmpty
        ? '''
          <div style="margin-top:18px;border-top:2px solid #334155;padding-top:14px;">
            <p style="color:#A855F7;font-size:26px;font-weight:bold;margin:0 0 10px;">&#10024; AI Risk Analysis</p>
            <p style="color:#E2E8F0;font-size:21px;line-height:1.5;">$formattedAiInsight</p>
          </div>'''
        : '';

    final highPct  = totalPlants > 0 ? (highRiskCount   * 100 ~/ totalPlants) : 0;
    final medPct   = totalPlants > 0 ? (mediumRiskCount * 100 ~/ totalPlants) : 0;
    final lowPct   = totalPlants > 0 ? (lowRiskCount    * 100 ~/ totalPlants) : 0;

    final highPctRemain = 100 - highPct;
    final medPctRemain = 100 - medPct;
    final lowPctRemain = 100 - lowPct;

    final content = '''
    <Style id="dashboard_style">
      <IconStyle><scale>0</scale></IconStyle>
      <BalloonStyle>
        <bgColor>ff0d1117</bgColor>
        <textColor>ffffffff</textColor>
        <text><![CDATA[
          <div style="font-family:Arial,sans-serif;width:720px;background:#0d1117;color:#fff;border-radius:12px;overflow:hidden;">

            <!-- ── Header gradient strip ─────────────────────────────── -->
            <div style="background:linear-gradient(135deg,#0f4c75 0%,#1b262c 100%);padding:22px 28px 18px;border-bottom:3px solid #38BDF8;">
              <p style="font-size:15px;color:#38BDF8;margin:0 0 4px;letter-spacing:3px;text-transform:uppercase;">EcoGrid Intelligence</p>
              <p style="font-size:36px;font-weight:bold;color:#fff;margin:0;">&#127757; $regionName</p>
              <p style="font-size:20px;color:#94A3B8;margin:6px 0 0;">Climate Risk Dashboard</p>
            </div>

            <!-- ── Stats row ─────────────────────────────────────────── -->
            <div style="display:flex;padding:20px 28px;border-bottom:1px solid #1e293b;">
              <div style="flex:1;text-align:center;">
                <p style="font-size:48px;font-weight:bold;color:#fff;margin:0;">$totalPlants</p>
                <p style="font-size:18px;color:#64748B;margin:4px 0 0;">Monitored Plants</p>
              </div>
              <div style="flex:1;text-align:center;border-left:1px solid #334155;">
                <p style="font-size:48px;font-weight:bold;color:#EF4444;margin:0;">$highRiskCount</p>
                <p style="font-size:18px;color:#64748B;margin:4px 0 0;">High Risk</p>
              </div>
              <div style="flex:1;text-align:center;border-left:1px solid #334155;">
                <p style="font-size:48px;font-weight:bold;color:#F59E0B;margin:0;">$mediumRiskCount</p>
                <p style="font-size:18px;color:#64748B;margin:4px 0 0;">Medium Risk</p>
              </div>
              <div style="flex:1;text-align:center;border-left:1px solid #334155;">
                <p style="font-size:48px;font-weight:bold;color:#10B981;margin:0;">$lowRiskCount</p>
                <p style="font-size:18px;color:#64748B;margin:4px 0 0;">Low Risk</p>
              </div>
            </div>

            <!-- ── Risk bars ──────────────────────────────────────────── -->
            <div style="padding:20px 28px;border-bottom:1px solid #1e293b;">
              <p style="font-size:20px;color:#94A3B8;margin:0 0 14px;font-weight:bold;">&#128202; Risk Distribution</p>
              <table width="100%" cellpadding="4">
                <tr>
                  <td width="120"><font color="#EF4444" style="font-size:20px;">&#9679; High</font></td>
                  <td><table width="100%" cellpadding="0" cellspacing="0"><tr>
                    <td width="$highPct%" bgcolor="#EF4444" height="16" style="border-radius:4px 0 0 4px;"></td>
                    <td width="$highPctRemain%" bgcolor="#1E293B" height="16"></td>
                  </tr></table></td>
                  <td width="60" align="right"><font color="#EF4444" style="font-size:20px;font-weight:bold;">$highPct%</font></td>
                </tr>
                <tr><td colspan="3" height="6"></td></tr>
                <tr>
                  <td><font color="#F59E0B" style="font-size:20px;">&#9679; Med</font></td>
                  <td><table width="100%" cellpadding="0" cellspacing="0"><tr>
                    <td width="$medPct%" bgcolor="#F59E0B" height="16"></td>
                    <td width="$medPctRemain%" bgcolor="#1E293B" height="16"></td>
                  </tr></table></td>
                  <td align="right"><font color="#F59E0B" style="font-size:20px;font-weight:bold;">$medPct%</font></td>
                </tr>
                <tr><td colspan="3" height="6"></td></tr>
                <tr>
                  <td><font color="#10B981" style="font-size:20px;">&#9679; Low</font></td>
                  <td><table width="100%" cellpadding="0" cellspacing="0"><tr>
                    <td width="$lowPct%" bgcolor="#10B981" height="16" style="border-radius:4px 0 0 4px;"></td>
                    <td width="$lowPctRemain%" bgcolor="#1E293B" height="16"></td>
                  </tr></table></td>
                  <td align="right"><font color="#10B981" style="font-size:20px;font-weight:bold;">$lowPct%</font></td>
                </tr>
              </table>
            </div>

            <!-- ── Dominant threat + critical plants ──────────────────── -->
            <div style="padding:20px 28px;">
              <table width="100%">
                <tr>
                  <td width="50%" valign="top">
                    <p style="font-size:20px;color:#94A3B8;margin:0 0 8px;font-weight:bold;">&#9888; Primary Regional Threat</p>
                    <p style="font-size:30px;color:#EF4444;font-weight:bold;margin:0;">$dominantRisk</p>
                  </td>
                  <td width="50%" valign="top" style="padding-left:24px;border-left:1px solid #334155;">
                    <p style="font-size:20px;color:#94A3B8;margin:0 0 8px;font-weight:bold;">&#128205; Critical Infrastructure</p>
                    $top3Html
                  </td>
                </tr>
              </table>
            </div>

            $aiSection
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

  /// Plant pin KML: 4 concentric donut rings clamped to the terrain, sized to
  /// be fully visible at plant-detail zoom (camera range 400 – 15 000 m).
  /// Rings are coloured by climate risk level with decreasing opacity outward.
  static String plantPinKml({
    required PowerPlant plant,
    required RiskLevel riskLevel,
  }) {
    final lat = plant.latitude;
    final lon = plant.longitude;

    // ── Risk colour in KML aabbggrr format ────────────────────────────────
    // Colours match the app palette: high=red #EF4444, med=amber #F59E0B, low=green #10B981
    // KML byte order: alpha · blue · green · red  (all hex)
    //   #EF4444 → r=ef g=44 b=44 → KML bbggrr = 4444ef
    //   #F59E0B → r=f5 g=9e b=0b → KML bbggrr = 0b9ef5
    //   #10B981 → r=10 g=b9 b=81 → KML bbggrr = 81b910
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

    // ── Ring geometry ──────────────────────────────────────────────────────
    // radii in degrees: 0.0009° ≈ 100 m, 0.0018° ≈ 200 m,
    //                   0.0032° ≈ 350 m, 0.0045° ≈ 500 m
    // inner = 72 % of outer → 28 % ring width
    // alphas decrease from innermost (ff) to outermost (55)
    const rings = [
      (outerDeg: 0.0009, innerDeg: 0.000648, alpha: 'ff'),
      (outerDeg: 0.0018, innerDeg: 0.001296, alpha: 'cc'),
      (outerDeg: 0.0032, innerDeg: 0.002304, alpha: '99'),
      (outerDeg: 0.0045, innerDeg: 0.003240, alpha: '55'),
    ];

    final buf = StringBuffer();

    // Draw outermost first so inner rings paint on top
    for (int r = rings.length - 1; r >= 0; r--) {
      final ring = rings[r];
      final fillKml    = '${ring.alpha}$colorBBGGRR';
      final outlineKml = 'ff$colorBBGGRR';

      // Circular approximation with 64 segments → smooth rings
      final outerPts = _circleKmlCoords(lat: lat, lon: lon,
          radiusDeg: ring.outerDeg, clockwise: false);
      final innerPts = _circleKmlCoords(lat: lat, lon: lon,
          radiusDeg: ring.innerDeg, clockwise: true); // reversed for hole

      buf.writeln('''
    <Placemark>
      <name></name>
      <Style>
        <PolyStyle>
          <color>$fillKml</color>
          <fill>1</fill>
          <outline>1</outline>
        </PolyStyle>
        <LineStyle>
          <color>$outlineKml</color>
          <width>1.5</width>
        </LineStyle>
        <LabelStyle><scale>0</scale></LabelStyle>
        <IconStyle><scale>0</scale></IconStyle>
      </Style>
      <Polygon>
        <altitudeMode>clampToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing><coordinates>$outerPts</coordinates></LinearRing>
        </outerBoundaryIs>
        <innerBoundaryIs>
          <LinearRing><coordinates>$innerPts</coordinates></LinearRing>
        </innerBoundaryIs>
      </Polygon>
    </Placemark>''');
    }

    // Plant icon pin on top of the rings
    buf.writeln('''
    <Placemark id="plant_pin_${plant.id}">
      <name>${_escapeXml(plant.name)}</name>
      <Style>
        <IconStyle>
          <scale>1.8</scale>
          <Icon><href>$iconHref</href></Icon>
          <hotSpot x="0.5" y="0" xunits="fraction" yunits="fraction"/>
        </IconStyle>
        <LabelStyle><scale>0</scale></LabelStyle>
      </Style>
      <Point>
        <altitudeMode>relativeToGround</altitudeMode>
        <coordinates>$lon,$lat,0</coordinates>
      </Point>
    </Placemark>''');

    return wrapInKmlDocument(buf.toString(), name: plant.name);
  }

  /// 64-point circular approximation for KML ring polygons.
  /// [clockwise]=true reverses winding for use as an inner-boundary hole.
  static String _circleKmlCoords({
    required double lat,
    required double lon,
    required double radiusDeg,
    bool clockwise = false,
    int steps = 64,
  }) {
    final pts = <String>[];
    for (int i = 0; i <= steps; i++) {
      final angle = (clockwise ? -1 : 1) * 2 * math.pi * i / steps;
      final dLon = radiusDeg * math.cos(angle);
      final dLat = radiusDeg * math.sin(angle);
      pts.add('${lon + dLon},${lat + dLat},0');
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
    final capacityStr = plant.capacityMw != null
        ? '${plant.capacityMw!.toStringAsFixed(0)} MW'
        : 'N/A';

    // Stress bar rows — large, clear, readable at arm's length
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
                  <td align="right" style="font-size:24px;font-weight:bold;color:$barColor;">$scaled</td>
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

    final hasWeather = climateData?.temperature != null;
    final weatherSection = hasWeather ? '''
            <div style="margin-top:4px;border-top:1px solid #1e293b;padding-top:16px;">
              <p style="font-size:22px;color:#38BDF8;font-weight:bold;margin:0 0 10px;">&#9729; Current Conditions</p>
              <table width="100%" cellpadding="4">
                <tr>
                  <td style="font-size:21px;color:#CBD5E1;">Temperature</td>
                  <td align="right" style="font-size:21px;color:#fff;font-weight:bold;">${climateData!.temperature!.toStringAsFixed(1)}&#176;C</td>
                </tr>
                ${climateData.windSpeed != null ? '<tr><td style="font-size:21px;color:#CBD5E1;">Wind Speed</td><td align="right" style="font-size:21px;color:#fff;font-weight:bold;">${climateData.windSpeed!.toStringAsFixed(1)} km/h</td></tr>' : ''}
              </table>
            </div>''' : '';

    final content = '''
    <Style id="plant_detail_style">
      <IconStyle><scale>0</scale></IconStyle>
      <BalloonStyle>
        <bgColor>ff0d1117</bgColor>
        <textColor>ffffffff</textColor>
        <text><![CDATA[
          <div style="font-family:Arial,sans-serif;width:720px;background:#0d1117;color:#fff;border-radius:12px;overflow:hidden;">

            <!-- ── Coloured header by risk ────────────────────────────── -->
            <div style="background:linear-gradient(135deg,$riskGradient 0%,#1b262c 100%);padding:22px 28px 18px;border-bottom:3px solid $riskColor;">
              <p style="font-size:15px;color:$riskColor;margin:0 0 6px;letter-spacing:3px;text-transform:uppercase;">$typeIcon ${_escapeXml(plant.primaryFuel.displayName)}</p>
              <p style="font-size:34px;font-weight:bold;color:#fff;margin:0;">${_escapeXml(plant.name)}</p>
              <p style="font-size:19px;color:#94A3B8;margin:8px 0 0;">&#127758; ${_escapeXml(plant.countryLong ?? plant.country)} &nbsp;&nbsp; &#9889; $capacityStr</p>
            </div>

            <!-- ── CVS score + risk badge ────────────────────────────── -->
            <div style="display:flex;align-items:center;padding:22px 28px;border-bottom:1px solid #1e293b;">
              <div style="flex:1;">
                <p style="font-size:16px;color:#64748B;margin:0 0 4px;text-transform:uppercase;letter-spacing:2px;">Climate Vulnerability Score</p>
                <p style="font-size:72px;font-weight:bold;color:$riskColor;margin:0;line-height:1;">${cvs.score.toStringAsFixed(1)}</p>
                <p style="font-size:16px;color:#475569;margin:4px 0 0;">out of 100</p>
              </div>
              <div style="text-align:center;padding:18px 32px;background:$riskColor;border-radius:10px;margin-left:20px;">
                <p style="font-size:28px;font-weight:bold;color:#fff;margin:0;">${cvs.riskLevel.label}</p>
                <p style="font-size:15px;color:rgba(255,255,255,0.8);margin:4px 0 0;">RISK</p>
              </div>
            </div>

            <!-- ── Stress drivers ────────────────────────────────────── -->
            <div style="padding:20px 28px;border-bottom:1px solid #1e293b;">
              <p style="font-size:22px;color:#F59E0B;font-weight:bold;margin:0 0 14px;">&#9888; Key Risk Drivers</p>
              <table width="100%" cellpadding="0" cellspacing="0">
$dimRows
              </table>
            </div>

            <!-- ── Weather (if available) ────────────────────────────── -->
            <div style="padding:20px 28px;">
              $weatherSection
            </div>
          </div>
        ]]></text>
      </BalloonStyle>
    </Style>
    <Placemark id="plant_detail_placemark">
      <name>${_escapeXml(plant.name)}</name>
      <description>Plant Detail</description>
      <styleUrl>#plant_detail_style</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point><coordinates>$lon,$lat,0</coordinates></Point>
    </Placemark>''';
    return wrapInKmlDocument(content, name: 'Plant Detail — ${plant.name}');
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

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
}
