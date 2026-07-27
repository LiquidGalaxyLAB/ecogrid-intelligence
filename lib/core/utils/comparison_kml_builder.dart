import 'dart:math' as math;
import '../../domain/model/power_plant.dart';
import '../../domain/model/cvs_result.dart';
import '../../core/enums/risk_level.dart';
import 'kml_utils.dart';

/// Builds comparison KML with 3D Energy Crystal markers for each plant
/// and elegant arc connection lines between them.
class ComparisonKmlBuilder {
  ComparisonKmlBuilder._();

  /// Generates the complete comparison master KML with crystals + connections.
  static String build({
    required List<PowerPlant> plants,
    required List<CVSResult?> cvsResults,
    String? tourKml,
  }) {
    final buf = StringBuffer();

    // 1. Generate 3D crystal marker for each plant
    for (int i = 0; i < plants.length; i++) {
      buf.writeln(_buildCrystalMarker(
        plant: plants[i],
        cvs: cvsResults[i],
      ));
    }

    // 2. Generate arc connections between all plant pairs
    for (int i = 0; i < plants.length; i++) {
      for (int j = i + 1; j < plants.length; j++) {
        buf.writeln(_buildArcConnection(
          from: plants[i],
          to: plants[j],
        ));
      }
    }

    if (tourKml != null) {
      buf.writeln(tourKml);
    }

    return KmlUtils.wrapInKmlDocument(
      buf.toString(),
      name: 'EcoGrid Comparison',
    );
  }

  // ── 3D Energy Crystal Marker ─────────────────────────────────────────────
  // Creates an octahedron (two inverted pyramids) effect using extruded
  // polygons + a ground glow disc + a pinnacle label.
  static String _buildCrystalMarker({
    required PowerPlant plant,
    required CVSResult? cvs,
  }) {
    final lat = plant.latitude;
    final lon = plant.longitude;
    final riskLevel = cvs?.riskLevel ?? RiskLevel.low;

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

    // Crystal height scales with CVS score (higher = more vulnerable = taller)
    final score = cvs?.score ?? 30;
    final crystalHeight = (200 + score * 5).clamp(200.0, 800.0);
    final midHeight = crystalHeight * 0.5;

    // Latitude correction for longitude distortion
    final latRad = lat * math.pi / 180.0;
    final cosLat = math.cos(latRad).abs().clamp(0.01, 1.0);

    final buf = StringBuffer();

    // ── Ground glow disc ─────────────────────────────────────────────────
    // Use clampToGround so the disc never clips below the terrain surface
    final glowPts = _circleCoords(lat, lon, cosLat, 0.004, 0);
    buf.writeln('''
    <Placemark>
      <name></name>
      <Style>
        <PolyStyle><color>55$colorBBGGRR</color><fill>1</fill><outline>0</outline></PolyStyle>
        <LabelStyle><scale>0</scale></LabelStyle>
        <IconStyle><scale>0</scale></IconStyle>
      </Style>
      <Polygon>
        <altitudeMode>clampToGround</altitudeMode>
        <outerBoundaryIs><LinearRing><coordinates>$glowPts</coordinates></LinearRing></outerBoundaryIs>
      </Polygon>
    </Placemark>''');

    // ── Lower pyramid (ground to mid) — wide base tapering up ────────────
    // 4 triangular faces using individual polygons for the crystal facets
    const baseRadius = 0.0015; // ~170m
    const topRadius = 0.0003; // ~33m at the waist
    final basePts = _diamondPoints(lat, lon, cosLat, baseRadius);
    final midPts = _diamondPoints(lat, lon, cosLat, topRadius);

    // Base at altitude 15 to prevent clipping into terrain
    const baseAlt = 15;
    for (int f = 0; f < 4; f++) {
      final next = (f + 1) % 4;
      final coords = '${basePts[f]},$baseAlt ${basePts[next]},$baseAlt ${midPts[next]},$midHeight ${midPts[f]},$midHeight ${basePts[f]},$baseAlt';
      buf.writeln('''
    <Placemark>
      <name></name>
      <Style>
        <PolyStyle><color>cc$colorBBGGRR</color><fill>1</fill><outline>1</outline></PolyStyle>
        <LineStyle><color>ff$colorBBGGRR</color><width>2</width></LineStyle>
        <LabelStyle><scale>0</scale></LabelStyle>
        <IconStyle><scale>0</scale></IconStyle>
      </Style>
      <Polygon>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs><LinearRing><coordinates>$coords</coordinates></LinearRing></outerBoundaryIs>
      </Polygon>
    </Placemark>''');
    }

    // ── Upper pyramid (mid to top) — narrow waist tapering to peak ───────
    for (int f = 0; f < 4; f++) {
      final next = (f + 1) % 4;
      final coords = '${midPts[f]},$midHeight ${midPts[next]},$midHeight $lon,$lat,$crystalHeight ${midPts[f]},$midHeight';
      buf.writeln('''
    <Placemark>
      <name></name>
      <Style>
        <PolyStyle><color>aa$colorBBGGRR</color><fill>1</fill><outline>1</outline></PolyStyle>
        <LineStyle><color>ff$colorBBGGRR</color><width>2</width></LineStyle>
        <LabelStyle><scale>0</scale></LabelStyle>
        <IconStyle><scale>0</scale></IconStyle>
      </Style>
      <Polygon>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs><LinearRing><coordinates>$coords</coordinates></LinearRing></outerBoundaryIs>
      </Polygon>
    </Placemark>''');
    }

    // ── Floating ring at the waist ───────────────────────────────────────
    final ringOuter = _circleCoords(lat, lon, cosLat, 0.0025, midHeight);
    final ringInner = _circleCoords(lat, lon, cosLat, 0.0018, midHeight, clockwise: true);
    buf.writeln('''
    <Placemark>
      <name></name>
      <Style>
        <PolyStyle><color>88$colorBBGGRR</color><fill>1</fill><outline>1</outline></PolyStyle>
        <LineStyle><color>ff$colorBBGGRR</color><width>2</width></LineStyle>
        <LabelStyle><scale>0</scale></LabelStyle>
        <IconStyle><scale>0</scale></IconStyle>
      </Style>
      <Polygon>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs><LinearRing><coordinates>$ringOuter</coordinates></LinearRing></outerBoundaryIs>
        <innerBoundaryIs><LinearRing><coordinates>$ringInner</coordinates></LinearRing></innerBoundaryIs>
      </Polygon>
    </Placemark>''');

    // ── Pinnacle icon + label ────────────────────────────────────────────
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
      final typeIcon = KmlUtils.escapeXml(plant.primaryFuel.displayName); // Simplified for safety
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
      <Style id="crystal_style_${plant.id}">
        <IconStyle>
          <scale>2.2</scale>
          <Icon><href>$iconHref</href></Icon>
          <hotSpot x="0.5" y="0" xunits="fraction" yunits="fraction"/>
        </IconStyle>
        <LabelStyle>
          <color>ffffffff</color>
          <scale>1.4</scale>
        </LabelStyle>
        <BalloonStyle>
          <bgColor>00000000</bgColor>
          <textColor>ffffffff</textColor>
          <text><![CDATA[
            <div style="font-family:Arial,sans-serif;width:75%;max-width:1000px;background:#0d1117;color:#fff;border-radius:12px;overflow:hidden;">
              <div style="background:linear-gradient(135deg,$riskGradient 0%,#1b262c 100%);padding:22px 28px 18px;border-bottom:3px solid $riskColor;">
                <p style="font-size:15px;color:$riskColor;margin:0 0 6px;letter-spacing:3px;text-transform:uppercase;">$typeIcon ${KmlUtils.escapeXml(plant.primaryFuel.displayName)}</p>
                <p style="font-size:34px;font-weight:bold;color:#fff;margin:0;">${KmlUtils.escapeXml(plant.name)}</p>
                <p style="font-size:19px;color:#94A3B8;margin:8px 0 0;">&#127758; ${KmlUtils.escapeXml(plant.countryLong ?? plant.country)} &nbsp;&nbsp; &#9889; $capacityStr</p>
              </div>
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
              <div style="padding:20px 28px;border-bottom:1px solid #1e293b;">
                <p style="font-size:22px;color:#F59E0B;font-weight:bold;margin:0 0 14px;">&#9888; Key Risk Drivers</p>
                <table width="100%" cellpadding="0" cellspacing="0">
  $dimRows
                </table>
              </div>
            </div>
          ]]></text>
        </BalloonStyle>
      </Style>''';
      
      descriptionTag = '<description>Click for info</description>';
    } else {
      styleContent = '''
      <Style id="crystal_style_${plant.id}">
        <IconStyle>
          <scale>2.2</scale>
          <Icon><href>$iconHref</href></Icon>
          <hotSpot x="0.5" y="0" xunits="fraction" yunits="fraction"/>
        </IconStyle>
        <LabelStyle>
          <color>ffffffff</color>
          <scale>1.4</scale>
        </LabelStyle>
      </Style>''';
    }

    buf.writeln('''
    $styleContent
    <Placemark>
      <name>${KmlUtils.escapeXml(plant.name)}</name>
      $descriptionTag
      <styleUrl>#crystal_style_${plant.id}</styleUrl>
      <Point>
        <altitudeMode>relativeToGround</altitudeMode>
        <coordinates>$lon,$lat,$crystalHeight</coordinates>
      </Point>
    </Placemark>''');

    return buf.toString();
  }

  // ── Arc Connection Between Two Plants ────────────────────────────────────
  static String _buildArcConnection({
    required PowerPlant from,
    required PowerPlant to,
  }) {
    // Generate a straight line between two plants, clamped to the ground
    return '''
    <Placemark>
      <name></name>
      <Style>
        <LineStyle>
          <color>ee00d4ff</color>
          <width>6</width>
        </LineStyle>
        <LabelStyle><scale>0</scale></LabelStyle>
        <IconStyle><scale>0</scale></IconStyle>
      </Style>
      <LineString>
        <extrude>0</extrude>
        <tessellate>1</tessellate>
        <altitudeMode>clampToGround</altitudeMode>
        <coordinates>${from.longitude},${from.latitude},0 ${to.longitude},${to.latitude},0</coordinates>
      </LineString>
    </Placemark>''';
  }

  // ── Geometry Helpers ─────────────────────────────────────────────────────

  /// 4 cardinal diamond points (N, E, S, W) for crystal facets.
  static List<String> _diamondPoints(
    double lat, double lon, double cosLat, double radius,
  ) {
    return [
      '$lon,${lat + radius}',       // North
      '${lon + radius / cosLat},$lat', // East
      '$lon,${lat - radius}',       // South
      '${lon - radius / cosLat},$lat', // West
    ];
  }

  /// Circle approximation with lat correction.
  static String _circleCoords(
    double lat, double lon, double cosLat, double radius, double altitude, {
    bool clockwise = false, int steps = 48,
  }) {
    final pts = <String>[];
    for (int i = 0; i <= steps; i++) {
      final angle = (clockwise ? -1 : 1) * 2 * math.pi * i / steps;
      final dLon = (radius * math.cos(angle)) / cosLat;
      final dLat = radius * math.sin(angle);
      pts.add('${lon + dLon},${lat + dLat},$altitude');
    }
    return pts.join(' ');
  }

  /// Haversine distance in km between two lat/lon points.
  static double _haversineDistance(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    const R = 6371.0; // Earth radius in km
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
