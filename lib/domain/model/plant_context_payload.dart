import 'package:ecogrid_intelligence/domain/model/power_plant.dart';
import 'package:ecogrid_intelligence/domain/model/cvs_result.dart';
import 'package:ecogrid_intelligence/domain/model/climate_data.dart';
import 'package:ecogrid_intelligence/core/enums/risk_level.dart';

/// Structured context payload sent to Gemini alongside every AI request.
/// Contains the full data profile of the plant being analysed so the AI
/// can produce genuinely specific, contextual responses.
class PlantContextPayload {
  final String plantName;
  final String fuelType;
  final double? capacityMw;
  final String country;
  final String? countryLong;
  final double latitude;
  final double longitude;
  final double cvsScore;
  final RiskLevel riskLevel;
  final double temperatureStress;
  final double waterStress;
  final double windStress;

  /// Year-by-year CVS-proxy scores (optional, only if trend data loaded).
  final List<double>? historicalScores;

  /// Active scenario parameters (optional, only if scenario is configured).
  final String? activeScenarioType;
  final double? scenarioProjectedCvs;

  const PlantContextPayload({
    required this.plantName,
    required this.fuelType,
    this.capacityMw,
    required this.country,
    this.countryLong,
    required this.latitude,
    required this.longitude,
    required this.cvsScore,
    required this.riskLevel,
    required this.temperatureStress,
    required this.waterStress,
    required this.windStress,
    this.historicalScores,
    this.activeScenarioType,
    this.scenarioProjectedCvs,
  });

  /// Build from existing domain entities.
  factory PlantContextPayload.fromEntities({
    required PowerPlant plant,
    required CVSResult cvs,
    List<ClimateData>? trendData,
    String? activeScenarioType,
    double? scenarioProjectedCvs,
  }) {
    // Derive per-year risk-proxy scores from trend data if available.
    List<double>? historicalScores;
    if (trendData != null && trendData.isNotEmpty) {
      historicalScores = trendData.map((d) {
        // Simple proxy: average of available metrics normalised to 0-100
        double sum = 0;
        int count = 0;
        if (d.temperature != null) {
          sum += d.temperature!.clamp(0, 50) * 2;
          count++;
        }
        if (d.precipitation != null) {
          sum += (100 - d.precipitation!.clamp(0, 100));
          count++;
        }
        if (d.windSpeed != null) {
          sum += d.windSpeed!.clamp(0, 50) * 2;
          count++;
        }
        return count > 0 ? (sum / count).clamp(0.0, 100.0) : 50.0;
      }).toList();
    }

    return PlantContextPayload(
      plantName: plant.name,
      fuelType: plant.primaryFuel.displayName,
      capacityMw: plant.capacityMw,
      country: plant.countryLong ?? plant.country,
      countryLong: plant.countryLong,
      latitude: plant.latitude,
      longitude: plant.longitude,
      cvsScore: cvs.score,
      riskLevel: cvs.riskLevel,
      temperatureStress: cvs.temperatureStress,
      waterStress: cvs.waterStress,
      windStress: cvs.windStress,
      historicalScores: historicalScores,
      activeScenarioType: activeScenarioType,
      scenarioProjectedCvs: scenarioProjectedCvs,
    );
  }

  /// Renders a structured text block for inclusion in Gemini prompts.
  String toPromptContext() {
    final buffer = StringBuffer();
    buffer.writeln('**Plant:** $plantName');
    buffer.writeln('**Type:** $fuelType');
    if (capacityMw != null)
      buffer.writeln('**Capacity:** ${capacityMw!.toStringAsFixed(0)} MW');
    buffer.writeln(
      '**Location:** ${countryLong ?? country} (${latitude.toStringAsFixed(2)}°, ${longitude.toStringAsFixed(2)}°)',
    );
    buffer.writeln(
      '**Climate Vulnerability Score (CVS):** ${cvsScore.toStringAsFixed(1)}/100',
    );
    buffer.writeln('**Risk Level:** ${riskLevel.label}');
    buffer.writeln(
      '**Temperature Stress:** ${temperatureStress.toStringAsFixed(1)}%',
    );
    buffer.writeln('**Water Stress:** ${waterStress.toStringAsFixed(1)}%');
    buffer.writeln('**Wind Stress:** ${windStress.toStringAsFixed(1)}%');

    if (historicalScores != null && historicalScores!.isNotEmpty) {
      buffer.writeln(
        '**Historical Trend (yearly risk proxy):** ${historicalScores!.map((s) => s.toStringAsFixed(1)).join(', ')}',
      );
    }

    if (activeScenarioType != null) {
      buffer.writeln('**Active Scenario:** $activeScenarioType');
      if (scenarioProjectedCvs != null) {
        buffer.writeln(
          '**Projected CVS Under Scenario:** ${scenarioProjectedCvs!.toStringAsFixed(1)}/100',
        );
      }
    }

    return buffer.toString();
  }
}
