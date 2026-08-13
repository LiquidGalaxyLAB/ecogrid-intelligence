import '../../domain/model/power_plant.dart';
import '../../domain/model/cvs_result.dart';
import '../../core/enums/risk_level.dart';
import 'kml_utils.dart';

class PlantDetailBalloonBuilder {
  PlantDetailBalloonBuilder._();

  static String build({
    required PowerPlant plant,
    required CVSResult? cvs,
    double? overrideLat,
    double? overrideLng,
  }) {
    final riskColor = _getRiskColorHex(cvs?.riskLevel);
    final riskText = cvs?.riskLevel.name.toUpperCase() ?? 'UNKNOWN';
    final cvsScore = cvs?.score.toStringAsFixed(1) ?? 'N/A';
    final fuelName = plant.primaryFuel.name.toUpperCase();
    final capacity = plant.capacityMw?.toStringAsFixed(0) ?? '?';
    final location = plant.countryLong ?? plant.country;
    
    // Calculate progress bar width (0-100%)
    final scoreValue = cvs?.score ?? 0.0;
    final progressWidth = scoreValue.clamp(0.0, 100.0);

    final content = '''
    <Style id="plant_detail_balloon_style">
      <IconStyle><scale>0</scale></IconStyle>
      <BalloonStyle>
        <textColor>ffffffff</textColor>
        <bgColor>ff17110d</bgColor>
        <text><![CDATA[
          <!-- Anti-blink script -->
          <script>
            var bId = 'plant_detail_dashboard';
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
          
          <div style="font-family:Arial,sans-serif;width:850px;padding:36px;box-sizing:border-box;background-color:#0d1117;color:#ffffff;border-radius:32px;border:2px solid #1e293b;">
            
            <!-- Header Row -->
            <table width="100%" cellpadding="0" cellspacing="0">
              <tr>
                <td width="110" valign="middle">
                  <div style="width:96px;height:96px;border-radius:48px;background-color:${riskColor}26;text-align:center;line-height:96px;font-size:48px;color:$riskColor;">
                    &#9889;
                  </div>
                </td>
                <td valign="middle" style="padding-left:24px;">
                  <span style="font-size:38px;font-weight:bold;color:#ffffff;">${plant.name}</span><br>
                  <span style="font-size:22px;color:#94a3b8;">$location • $fuelName</span>
                </td>
              </tr>
            </table>

            <br><br>
            
            <!-- Cards Row -->
            <table width="100%" cellpadding="0" cellspacing="0">
              <tr>
                <td width="48%">
                  <div style="background-color:#1e293b;border-radius:24px;padding:24px;border:2px solid #334155;">
                    <span style="font-size:20px;color:#94a3b8;">Capacity</span><br>
                    <span style="font-size:36px;font-weight:bold;color:#0ea5e9;">$capacity MW</span>
                  </div>
                </td>
                <td width="4%"></td>
                <td width="48%">
                  <div style="background-color:#1e293b;border-radius:24px;padding:24px;border:2px solid #334155;">
                    <span style="font-size:20px;color:#94a3b8;">Risk Level</span><br>
                    <span style="font-size:36px;font-weight:bold;color:$riskColor;">$riskText</span>
                  </div>
                </td>
              </tr>
            </table>
            
            <br><br>

            <!-- CVS Score Bar -->
            <div style="background-color:#1e293b;border-radius:24px;padding:24px;border:2px solid #334155;">
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="left"><span style="font-size:22px;color:#94a3b8;font-weight:bold;">Climate Vulnerability Score</span></td>
                  <td align="right"><span style="font-size:38px;font-weight:bold;color:$riskColor;">$cvsScore</span></td>
                </tr>
              </table>
              <div style="margin-top:20px;width:100%;height:20px;background-color:#0f172a;border-radius:10px;overflow:hidden;">
                <div style="width:$progressWidth%;height:100%;background-color:$riskColor;border-radius:10px;"></div>
              </div>
            </div>

          </div>
        ]]></text>
      </BalloonStyle>
    </Style>
    <Placemark id="plant_detail_balloon_placemark">
      <name>${plant.name}</name>
      <styleUrl>#plant_detail_balloon_style</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point><coordinates>${overrideLng ?? plant.longitude},${overrideLat ?? plant.latitude},0</coordinates></Point>
    </Placemark>'''
    ;

    return KmlUtils.wrapInKmlDocument(content, name: 'Plant Detail');
  }

  static String _getRiskColorHex(RiskLevel? level) {
    if (level == null) return '#94a3b8';
    switch (level) {
      case RiskLevel.low:
        return '#22c55e'; // green-500
      case RiskLevel.medium:
        return '#eab308'; // yellow-500
      case RiskLevel.high:
        return '#ef4444'; // red-500
    }
  }
}
