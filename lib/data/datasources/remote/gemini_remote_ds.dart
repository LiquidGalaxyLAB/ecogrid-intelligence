import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:ecogrid_intelligence/config/app_config.dart';


/// Remote data source for Google Gemini AI.
class GeminiRemoteDataSource {
  GenerativeModel? _model;

  GenerativeModel get model {
    _model ??= GenerativeModel(
      model: AppConfig.geminiModel,
      apiKey: AppConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topP: 0.9,
        maxOutputTokens: 1024,
      ),
    );
    return _model!;
  }

  /// Generate climate insight for a power plant.
  Future<String> generatePlantInsight({
    required String plantName,
    required String plantType,
    required double cvsScore,
    required double tempStress,
    required double waterStress,
    required double windStress,
    required String country,
  }) async {
    final prompt = '''
You are EcoGrid Intelligence, an AI climate risk analyst for global energy infrastructure.

Analyze the following power plant's climate vulnerability:

**Plant:** $plantName
**Type:** $plantType
**Country:** $country
**Climate Vulnerability Score (CVS):** ${cvsScore.toStringAsFixed(1)}/100
**Temperature Stress:** ${(tempStress).toStringAsFixed(1)}%
**Water Stress:** ${(waterStress).toStringAsFixed(1)}%
**Wind Stress:** ${(windStress).toStringAsFixed(1)}%

Provide a concise 3-4 sentence climate risk assessment explaining:
1. Why this plant is vulnerable based on its type and environmental stresses
2. The primary climate threat to its operations
3. A brief recommendation for resilience improvement

Be specific to the plant type's operational characteristics. Use professional, data-driven language.
''';

    return _generate(prompt);
  }

  /// Generate regional climate summary.
  Future<String> generateRegionalInsight({
    required String regionName,
    required int totalPlants,
    required int highRiskPlants,
    required Map<String, int> plantTypeDistribution,
  }) async {
    final typeBreakdown = plantTypeDistribution.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');

    final prompt = '''
You are EcoGrid Intelligence, an AI climate risk analyst.

Provide a regional climate risk overview:

**Region:** $regionName
**Total Power Plants:** $totalPlants
**High Risk Plants:** $highRiskPlants
**Plant Types:** $typeBreakdown

Provide a concise 3-4 sentence regional assessment covering:
1. Overall infrastructure vulnerability profile
2. Key climate threats facing this region's energy infrastructure
3. Which plant types are most at risk and why

Be specific and data-driven.
''';

    return _generate(prompt);
  }

  /// Generate scenario analysis.
  Future<String> generateScenarioAnalysis({
    required String plantName,
    required String plantType,
    required double currentCvs,
    required double projectedCvs,
    required String scenarioType,
  }) async {
    final prompt = '''
You are EcoGrid Intelligence, an AI climate risk analyst.

Analyze this climate scenario simulation:

**Plant:** $plantName
**Type:** $plantType
**Scenario:** $scenarioType
**Current CVS:** ${currentCvs.toStringAsFixed(1)}/100
**Projected CVS:** ${projectedCvs.toStringAsFixed(1)}/100
**Change:** +${(projectedCvs - currentCvs).toStringAsFixed(1)} points

In 2-3 sentences, explain the projected impact of this scenario on the plant's operations and what specific risks would increase.
''';

    return _generate(prompt);
  }

  Future<String> _generate(String prompt) async {
    try {
      if (AppConfig.geminiApiKey.isEmpty) {
        return _generateFallbackInsight(prompt);
      }

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? 'Unable to generate analysis.';
    } catch (e) {
      // Fallback to pre-generated insight on API failure
      return _generateFallbackInsight(prompt);
    }
  }

  /// Fallback when Gemini API is unavailable.
  String _generateFallbackInsight(String prompt) {
    if (prompt.contains('Nuclear')) {
      return 'This nuclear facility faces elevated climate vulnerability due to '
          'its high dependence on stable water supply for cooling operations. '
          'Rising temperatures and potential drought conditions may necessitate '
          'operational adjustments to maintain safety margins. '
          'Diversifying cooling water sources and enhancing thermal efficiency '
          'are recommended resilience measures.';
    }
    if (prompt.contains('Hydro')) {
      return 'This hydroelectric facility is particularly sensitive to '
          'precipitation anomalies and drought patterns. Changing rainfall '
          'patterns directly impact reservoir levels and generation capacity. '
          'Long-term water resource planning and reservoir management '
          'optimization are critical for sustained operations.';
    }
    return 'This energy infrastructure asset shows measurable climate '
        'vulnerability based on regional environmental stress indicators. '
        'Temperature fluctuations, water availability changes, and wind '
        'pattern shifts may impact operational efficiency. '
        'Climate adaptation planning should be prioritized.';
  }
}
