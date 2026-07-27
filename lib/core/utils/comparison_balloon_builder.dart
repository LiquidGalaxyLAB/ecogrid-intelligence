import '../../domain/model/power_plant.dart';
import '../../domain/model/cvs_result.dart';
import '../../core/enums/risk_level.dart';
import 'kml_utils.dart';

/// Builds a premium comparison balloon KML for the rightmost Liquid Galaxy screen.
///
/// Displays side-by-side plant cards with CVS scores, risk levels,
/// fuel types, capacities, and a stress comparison table using massive typography.
class ComparisonBalloonBuilder {
  ComparisonBalloonBuilder._();

  static String build({
    required List<PowerPlant> plants,
    required List<CVSResult?> cvsResults,
    required double lat,
    required double lon,
  }) {
    // Build plant cards
    final cardsHtml = StringBuffer();
    for (int i = 0; i < plants.length; i++) {
      cardsHtml.writeln(_buildPlantCard(plants[i], cvsResults[i], plants.length));
    }

    // Build stress comparison table
    final tableHtml = _buildStressTable(plants, cvsResults);

    final content = '''
    <Style id="comparison_balloon_style">
      <IconStyle><scale>0</scale></IconStyle>
      <BalloonStyle>
        <textColor>ffffffff</textColor>
        <bgColor>ff17110d</bgColor> <!-- ABGR for #0d1117 -->
        <text><![CDATA[
          <!-- Anti-blink script -->
          <script>
            var bId = 'comparison_dashboard';
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
          
          <div style="font-family:Arial,sans-serif;width:700px;padding:16px;box-sizing:border-box;background-color:#0d1117;color:#ffffff;">
            <table width="100%" cellpadding="14" cellspacing="0" style="border:2px solid #334155;border-collapse:collapse;border-radius:16px;background-color:#0d1117;">
              
              <!-- Header -->
              <tr bgcolor="#0F766E">
                <td style="padding:20px;border-top-left-radius:16px;border-top-right-radius:16px;">
                  <span style="color:white;font-size:26px;font-weight:bold;">&#9878; Plant Comparison</span>
                  <br><br>
                  <span style="color:#ccfbf1;font-size:15px;">Plant Comparison Dashboard • ${plants.length} Plants Selected</span>
                </td>
              </tr>
              
              <!-- Plant Cards Row -->
              <tr>
                <td style="padding:16px;">
                  <table width="100%" cellpadding="8" cellspacing="0">
                    <tr>
                      ${cardsHtml.toString()}
                    </tr>
                  </table>
                </td>
              </tr>
              
              <!-- Stress Comparison Table -->
              <tr bgcolor="#1e293b">
                <td style="padding:20px;border-top:2px solid #334155;border-bottom-left-radius:16px;border-bottom-right-radius:16px;">
                  <span style="font-size:22px;color:#e2e8f0;font-weight:bold;margin-bottom:16px;display:block;">&#128202; Stress Comparison</span>
                  <br>
                  $tableHtml
                </td>
              </tr>
              
            </table>
          </div>
        ]]></text>
      </BalloonStyle>
    </Style>
    <Placemark id="comparison_balloon_placemark">
      <name>Comparison</name>
      <styleUrl>#comparison_balloon_style</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point><coordinates>$lon,$lat,0</coordinates></Point>
    </Placemark>''';

    return KmlUtils.wrapInKmlDocument(content, name: 'Plant Comparison');
  }

  /// Builds a single plant card for the balloon.
  static String _buildPlantCard(PowerPlant plant, CVSResult? cvs, int totalPlants) {
    final riskLevel = cvs?.riskLevel ?? RiskLevel.low;
    final score = cvs?.score ?? 0;

    final String riskColor;
    final String riskLabel;
    switch (riskLevel) {
      case RiskLevel.high:
        riskColor = '#EF4444';
        riskLabel = 'HIGH';
        break;
      case RiskLevel.medium:
        riskColor = '#F59E0B';
        riskLabel = 'MEDIUM';
        break;
      case RiskLevel.low:
        riskColor = '#10B981';
        riskLabel = 'LOW';
        break;
    }

    final typeIcon = _plantTypeIcon(plant.primaryFuel.csvLabel);
    final capacity = plant.capacityMw != null
        ? '${plant.capacityMw!.toStringAsFixed(0)} MW'
        : 'N/A';
    final country = KmlUtils.escapeXml(plant.countryLong ?? plant.country);
    final name = KmlUtils.escapeXml(plant.name);
    
    // Distribute width evenly
    final widthPct = (100 / totalPlants).floor();

    return '''
      <td width="$widthPct%" valign="top" style="padding:8px;">
        <table width="100%" cellpadding="10" cellspacing="0" style="border:2px solid #334155;border-top:6px solid $riskColor;border-radius:10px;background:#111827;">
          <tr>
            <td align="center">
              <span style="font-size:14px;color:$riskColor;font-weight:bold;">$typeIcon ${KmlUtils.escapeXml(plant.primaryFuel.displayName).toUpperCase()}</span>
              <br><br>
              <span style="font-size:22px;font-weight:bold;color:#fff;">$name</span>
              <br><br>
              <span style="font-size:14px;color:#94a3b8;">&#127758; $country &nbsp; &#9889; $capacity</span>
              
              <br><br>
              
              <table width="100%" cellpadding="0" cellspacing="0" style="margin-top:10px;">
                <tr>
                  <td align="center" style="padding:12px;background:#1e293b;border-radius:8px;">
                    <span style="font-size:34px;font-weight:bold;color:$riskColor;">${score.toStringAsFixed(1)}</span>
                    <br>
                    <span style="font-size:13px;color:#94a3b8;">out of 100</span>
                  </td>
                </tr>
                <tr>
                  <td align="center" style="padding:8px;background:$riskColor;border-radius:8px;margin-top:8px;">
                    <span style="font-size:15px;font-weight:bold;color:#ffffff;">$riskLabel RISK</span>
                  </td>
                </tr>
              </table>
              
            </td>
          </tr>
        </table>
      </td>''';
  }

  /// Builds the stress comparison table.
  static String _buildStressTable(
    List<PowerPlant> plants,
    List<CVSResult?> cvsResults,
  ) {
    final headerCells = StringBuffer();
    headerCells.write('<th style="padding:10px;text-align:left;font-size:15px;color:#94A3B8;border-bottom:2px solid #334155;">Metric</th>');
    for (int i = 0; i < plants.length; i++) {
      final shortName = plants[i].name.length > 15
          ? '${plants[i].name.substring(0, 15)}...'
          : plants[i].name;
      headerCells.write(
        '<th style="padding:10px;text-align:center;font-size:15px;color:#E2E8F0;border-bottom:2px solid #334155;font-weight:bold;">${KmlUtils.escapeXml(shortName)}</th>',
      );
    }

    String stressRow(String label, double Function(CVSResult) getter) {
      final cells = StringBuffer();
      cells.write('<td style="padding:10px;font-size:15px;color:#CBD5E1;">$label</td>');
      for (int i = 0; i < cvsResults.length; i++) {
        final val = cvsResults[i] != null
            ? getter(cvsResults[i]!).toStringAsFixed(1)
            : 'N/A';
        final color = cvsResults[i] != null && getter(cvsResults[i]!) > 60
            ? '#EF4444'
            : cvsResults[i] != null && getter(cvsResults[i]!) > 35
                ? '#F59E0B'
                : '#10B981';
        cells.write(
          '<td style="padding:10px;text-align:center;font-size:18px;font-weight:bold;color:$color;">$val</td>',
        );
      }
      return '<tr>$cells</tr>';
    }

    return '''
      <table width="100%" cellpadding="0" cellspacing="0" style="border:2px solid #334155;border-radius:10px;background:#111827;">
        <tr>$headerCells</tr>
        ${stressRow('&#127777; Temp Stress', (c) => c.temperatureStress)}
        ${stressRow('&#128167; Water Stress', (c) => c.waterStress)}
        ${stressRow('&#127788; Wind Stress', (c) => c.windStress)}
        ${stressRow('&#9889; Overall CVS', (c) => c.score)}
      </table>''';
  }

  static String _plantTypeIcon(String csvLabel) {
    final lower = csvLabel.toLowerCase();
    if (lower.contains('solar')) return '&#9728;';
    if (lower.contains('wind')) return '&#127788;';
    if (lower.contains('hydro')) return '&#128166;';
    if (lower.contains('nuclear')) return '&#9762;';
    if (lower.contains('coal')) return '&#127981;';
    if (lower.contains('gas') || lower.contains('oil')) return '&#128293;';
    if (lower.contains('biomass')) return '&#127807;';
    return '&#9889;';
  }
}
