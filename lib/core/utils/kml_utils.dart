import '../enums/risk_level.dart';
import '../../domain/model/power_plant.dart';
import '../../domain/model/cvs_result.dart';
import '../../domain/model/climate_data.dart';

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
  static String regionPlacemark({
    required String regionName,
    required double lat,
    required double lon,
  }) {
    final content =
        '''
    <Placemark>
      <name>$regionName</name>
      <Style>
        <IconStyle>
          <color>ffff0000</color>
          <scale>1.8</scale>
          <Icon>
            <href>http://maps.google.com/mapfiles/kml/paddle/wht-blank.png</href>
          </Icon>
          <hotSpot x="0.5" y="0" xunits="fraction" yunits="fraction"/>
        </IconStyle>
        <LabelStyle>
          <color>ffffffff</color>
          <scale>1.0</scale>
        </LabelStyle>
      </Style>
      <Point>
        <altitudeMode>relativeToGround</altitudeMode>
        <coordinates>$lon,$lat,0</coordinates>
      </Point>
    </Placemark>''';
    return wrapInKmlDocument(content, name: regionName);
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
        ? '<p><font color="#94A3B8">No critical plants.</font></p>'
        : top3Plants
              .map((p) => '<p><font color="#FF5555">&#9888;</font> $p</p>')
              .join('');
    final formattedAiInsight = aiInsight?.replaceAll('\\n', '<br/>') ?? '';
    final aiSection = aiInsight != null && aiInsight.isNotEmpty
        ? '<br/><hr color="#334155" /><h3><font color="#A855F7">&#10024; AI Risk Analysis</font></h3><p><font color="#E2E8F0">$formattedAiInsight</font></p>'
        : '';
    final content =
        '''
    <Style id="dashboard_style">
      <IconStyle>
        <scale>0</scale>
      </IconStyle>
      <BalloonStyle>
        <bgColor>ff1a0e0a</bgColor>
        <textColor>ffffffff</textColor>
        <text><![CDATA[
          <table width="380" cellpadding="8" cellspacing="0"><tr><td>
          <h2><font color="#38BDF8">🌍 $regionName Climate Risk Dashboard</font></h2>
          <hr color="#334155" />
          <font size="+2">
            <p><b>🏭 Total Monitored Plants:</b> <font color="#FFFFFF">$totalPlants</font></p>
            <br/>
            <h3><font color="#94A3B8">📊 Risk Breakdown</font></h3>
            <p><font color="#EF4444">&#9679;</font> <b>High Risk:</b> <font color="#EF4444">$highRiskCount</font></p>
            <p><font color="#F59E0B">&#9679;</font> <b>Medium Risk:</b> <font color="#F59E0B">$mediumRiskCount</font></p>
            <p><font color="#10B981">&#9679;</font> <b>Low Risk:</b> <font color="#10B981">$lowRiskCount</font></p>
            <br/>
            <h3><font color="#94A3B8">⚠️ Primary Regional Threat</font></h3>
            <p><font color="#EF4444" size="+2"><b>$dominantRisk</b></font></p>
            <br/>
            <h3><font color="#94A3B8">📍 Critical Infrastructure (Top 3)</font></h3>
            $top3Html
          </font>
          $aiSection
          </td></tr></table>
        ]]></text>
      </BalloonStyle>
    </Style>
    <Placemark id="dashboard_placemark">
      <name>EcoGrid</name>
      <description>Dashboard</description>
      <styleUrl>#dashboard_style</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point>
        <coordinates>$lon,$lat,0</coordinates>
      </Point>
    </Placemark>''';
    return wrapInKmlDocument(content, name: 'EcoGrid Dashboard');
  }

  static String plantPinKml({
    required PowerPlant plant,
    required RiskLevel riskLevel,
  }) {
    final String iconHref;
    switch (riskLevel) {
      case RiskLevel.high:
        iconHref = 'http://maps.google.com/mapfiles/kml/paddle/red-blank.png';
        break;
      case RiskLevel.medium:
        iconHref = 'http://maps.google.com/mapfiles/kml/paddle/ylw-blank.png';
        break;
      case RiskLevel.low:
        iconHref = 'http://maps.google.com/mapfiles/kml/paddle/grn-blank.png';
        break;
    }
    final content =
        '''
    <Placemark id="plant_pin_${plant.id}">
      <name>${_escapeXml(plant.name)}</name>
      <Style>
        <IconStyle>
          <scale>1.8</scale>
          <Icon>
            <href>$iconHref</href>
          </Icon>
          <hotSpot x="0.5" y="0" xunits="fraction" yunits="fraction"/>
        </IconStyle>
        <LabelStyle>
          <scale>0</scale>
        </LabelStyle>
      </Style>
      <Point>
        <altitudeMode>relativeToGround</altitudeMode>
        <coordinates>${plant.longitude},${plant.latitude},0</coordinates>
      </Point>
    </Placemark>''';
    return wrapInKmlDocument(content, name: plant.name);
  }

  static String plantDetailBalloon({
    required PowerPlant plant,
    required CVSResult cvs,
    required double lat,
    required double lon,
    ClimateData? climateData,
  }) {
    final String riskBadgeColor;
    switch (cvs.riskLevel) {
      case RiskLevel.high:
        riskBadgeColor = '#EF4444';
        break;
      case RiskLevel.medium:
        riskBadgeColor = '#F59E0B';
        break;
      case RiskLevel.low:
        riskBadgeColor = '#10B981';
        break;
    }
    final typeIcon = _plantTypeIcon(plant.primaryFuel.csvLabel);
    final dims = [
      ('🌡️ Temperature Stress', cvs.temperatureStress),
      ('💧 Water Stress', cvs.waterStress),
      ('🌪️ Wind Stress', cvs.windStress),
    ];
    final dimRows = dims
        .map((d) {
          final name = d.$1;
          final raw = d.$2;
          final scaled = raw / 10.0;
          final barColor = scaled > 7
              ? '#EF4444'
              : (scaled >= 4 ? '#F59E0B' : '#10B981');
          final barPct = (raw.clamp(0, 100)).toInt();
          return '''
              <tr>
                <td><font color="#CBD5E1">$name</font></td>
                <td align="right">
                  <font color="$barColor"><b>${scaled.toStringAsFixed(1)}</b></font>
                </td>
              </tr>
              <tr>
                <td colspan="2">
                  <table width="100%" cellpadding="0" cellspacing="0">
                    <tr>
                      <td width="$barPct%" bgcolor="$barColor" height="6"></td>
                      <td width="${100 - barPct}%" bgcolor="#1E293B" height="6"></td>
                    </tr>
                  </table>
                </td>
              </tr>''';
        })
        .join('\n');
    final capacityStr = plant.capacityMw != null
        ? '${plant.capacityMw!.toStringAsFixed(0)} MW'
        : 'N/A';
    final hasWeather = climateData?.temperature != null;
    final weatherSection = hasWeather
        ? '''
          <br/>
          <table width="100%" cellpadding="4">
            <tr>
              <td colspan="2"><font color="#38BDF8"><b>&#9729; Current Conditions</b></font></td>
            </tr>
            <tr>
              <td><font color="#CBD5E1">Temperature</font></td>
              <td align="right"><font color="#FFFFFF"><b>${climateData!.temperature!.toStringAsFixed(1)}&#176;C</b></font></td>
            </tr>
            ${climateData.windSpeed != null ? '<tr><td><font color="#CBD5E1">Wind Speed</font></td><td align="right"><font color="#FFFFFF"><b>${climateData.windSpeed!.toStringAsFixed(1)} km/h</b></font></td></tr>' : ''}
          </table>'''
        : '';
    final content =
        '''
    <Style id="plant_detail_style">
      <IconStyle>
        <scale>0</scale>
      </IconStyle>
      <BalloonStyle>
        <bgColor>ff15151a</bgColor>
        <textColor>ffffffff</textColor>
        <text><![CDATA[
          <table width="380" cellpadding="8" cellspacing="0"><tr><td>
          <font face="Arial" size="+1">
          <!-- HEADER -->
          <table width="100%" cellpadding="4">
            <tr>
              <td>
                <font size="+2" color="#FFFFFF"><b>${_escapeXml(plant.name)}</b></font><br/>
                <font color="#38BDF8">$typeIcon ${_escapeXml(plant.primaryFuel.displayName)}</font><br/>
                <font color="#94A3B8">🌍 ${_escapeXml(plant.countryLong ?? plant.country)}</font>
              </td>
            </tr>
          </table>
          <hr color="#334155"/>
          <!-- RISK BADGE + CVS SCORE -->
          <table width="100%" cellpadding="6">
            <tr>
              <td align="center" width="40%">
                <table cellpadding="8" bgcolor="$riskBadgeColor" width="80">
                  <tr><td align="center">
                    <font color="#FFFFFF" size="+1"><b>${cvs.riskLevel.label}</b></font>
                  </td></tr>
                </table>
              </td>
              <td width="60%">
                <font color="$riskBadgeColor" size="+3"><b>${cvs.score.toStringAsFixed(1)}</b></font><br/>
                <font color="#94A3B8">Climate Vulnerability Score</font>
              </td>
            </tr>
          </table>
          <hr color="#334155"/>
          <!-- CAPACITY -->
          <table width="100%" cellpadding="4">
            <tr>
              <td><font color="#CBD5E1">⚡ Installed Capacity</font></td>
              <td align="right"><font color="#FFFFFF"><b>$capacityStr</b></font></td>
            </tr>
          </table>
          <hr color="#334155"/>
          <!-- KEY RISK DRIVERS -->
          <table width="100%" cellpadding="4">
            <tr>
              <td colspan="2"><font color="#F59E0B"><b>⚠️ Key Risk Drivers</b></font></td>
            </tr>
$dimRows
          </table>
$weatherSection
          </font>
          </td></tr></table>
        ]]></text>
      </BalloonStyle>
    </Style>
    <Placemark id="plant_detail_placemark">
      <name>${_escapeXml(plant.name)}</name>
      <description>Plant Detail</description>
      <styleUrl>#plant_detail_style</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point>
        <coordinates>$lon,$lat,0</coordinates>
      </Point>
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
