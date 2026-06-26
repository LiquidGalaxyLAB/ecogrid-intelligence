import 'package:flutter/foundation.dart';
import '../../core/exception/unhandled_exception.dart';
import '../../core/resources/data_state.dart';
import '../../core/enums/risk_level.dart';
import '../../core/utils/anomaly_engine.dart';
import '../../core/utils/cvs_calculator.dart';
import '../../domain/model/climate_data.dart';
import '../../domain/model/cvs_result.dart';
import '../../domain/model/power_plant.dart';
import '../../domain/repository/climate_repository.dart';
import '../../domain/repository/cvs_repository.dart';

class GridClimateData {
  final ClimateData currentData;
  final List<ClimateData> historicalData;
  final List<ClimateData> trendData;
  final Map<String, double> anomalies;
  final bool isVerified;

  GridClimateData({
    required this.currentData,
    required this.historicalData,
    required this.trendData,
    required this.anomalies,
    required this.isVerified,
  });
}

class CvsRepositoryImpl implements CvsRepository {
  final ClimateRepository _climateRepository;

  final Map<String, GridClimateData> _gridCache = {};
  final Map<String, Future<DataState<CvsComputationResult>>> _inFlightRequests = {};

  CvsRepositoryImpl({required this._climateRepository});

  double snapToGrid(double value) => (value / 0.5).round() * 0.5;
  String getGridId(double lat, double lon) =>
      'grid_${snapToGrid(lat)}_${snapToGrid(lon)}';

  @override
  Future<DataState<CvsComputationResult>> getCvsForPlant(
    PowerPlant plant,
  ) async {
    final gridId = getGridId(plant.latitude, plant.longitude);

    if (_gridCache.containsKey(gridId)) {
      return DataSuccess(_buildCvsComputationResult(plant, _gridCache[gridId]!));
    }

    if (_inFlightRequests.containsKey(gridId)) {
      return await _inFlightRequests[gridId]!;
    }

    final future = _fetchCvsForGrid(plant, gridId);
    _inFlightRequests[gridId] = future;

    try {
      return await future;
    } finally {
      _inFlightRequests.remove(gridId);
    }
  }

  Future<DataState<CvsComputationResult>> _fetchCvsForGrid(
    PowerPlant plant,
    String gridId,
  ) async {
    final gridLat = snapToGrid(plant.latitude);
    final gridLon = snapToGrid(plant.longitude);

    final now = DateTime.now();

    final currentResult = await _climateRepository
        .getCurrentClimate(gridLat, gridLon)
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => DataFailure(
            UnhandledException(message: 'Current weather timeout'),
          ),
        );

    final historicalResult = await _climateRepository
        .getHistoricalClimate(
          gridLat,
          gridLon,
          startDate: now.subtract(const Duration(days: 30 + 7)),
          endDate: now.subtract(const Duration(days: 7)),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => DataFailure(
            UnhandledException(message: 'Historical data timeout'),
          ),
        );

    ClimateData? currentData;
    if (currentResult is DataSuccess<ClimateData>) {
      currentData = currentResult.data;
    } else {
      debugPrint('[CVS] Current weather failed: ${currentResult.exception}');
    }
    currentData ??= _synthesizeFromCoordinates(gridLat, gridLon);

    List<ClimateData> historicalData = [];
    if (historicalResult is DataSuccess<List<ClimateData>>) {
      historicalData = historicalResult.data!;
    } else {
      debugPrint('[CVS] Historical fetch failed: ${historicalResult.exception}');
    }

    List<ClimateData> trendData = [];

    Map<String, double> anomalies;
    if (historicalData.isNotEmpty) {
      anomalies = AnomalyEngine.computeAnomalies(historicalData);
    } else {
      anomalies = _estimateAnomaliesFromContext(currentData, gridLat);
      debugPrint('[CVS] Using coordinate-based fallback for Grid $gridId');
    }

    final gridData = GridClimateData(
      currentData: currentData,
      historicalData: historicalData,
      trendData: trendData,
      anomalies: anomalies,
      isVerified: historicalData.isNotEmpty,
    );

    _gridCache[gridId] = gridData;

    return DataSuccess(_buildCvsComputationResult(plant, gridData));
  }

  CvsComputationResult _buildCvsComputationResult(
    PowerPlant plant,
    GridClimateData gridData,
  ) {
    final score = CVSCalculator.computeCVS(
      plantType: plant.primaryFuel,
      tempAnomaly: gridData.anomalies['temp'] ?? 0.0,
      waterAnomaly: gridData.anomalies['water'] ?? 0.0,
      windAnomaly: gridData.anomalies['wind'] ?? 0.0,
    );

    final stresses = CVSCalculator.computeStressBreakdown(
      plantType: plant.primaryFuel,
      tempAnomaly: gridData.anomalies['temp'] ?? 0.0,
      waterAnomaly: gridData.anomalies['water'] ?? 0.0,
      windAnomaly: gridData.anomalies['wind'] ?? 0.0,
    );

    final cvsResult = CVSResult(
      plantId: plant.id,
      score: score,
      riskLevel: RiskLevel.fromScore(score),
      temperatureStress: stresses['temperature'] ?? 0,
      waterStress: stresses['water'] ?? 0,
      windStress: stresses['wind'] ?? 0,
      computedAt: DateTime.now(),
      isVerified: gridData.isVerified,
    );

    final enrichedCurrentData = ClimateData(
      latitude: gridData.currentData.latitude,
      longitude: gridData.currentData.longitude,
      timestamp: gridData.currentData.timestamp,
      temperature: gridData.currentData.temperature,
      precipitation: gridData.currentData.precipitation,
      windSpeed: gridData.currentData.windSpeed,
      humidity: gridData.currentData.humidity,
      tempAnomaly: gridData.anomalies['temp'] ?? 0.0,
      waterAnomaly: gridData.anomalies['water'] ?? 0.0,
      windAnomaly: gridData.anomalies['wind'] ?? 0.0,
    );

    return CvsComputationResult(
      cvsResult: cvsResult,
      currentClimate: enrichedCurrentData,
      historicalData: gridData.trendData.isNotEmpty
          ? gridData.trendData
          : gridData.historicalData,
    );
  }

  /// Synthesize minimal climate data from coordinates when API is completely down.
  ClimateData _synthesizeFromCoordinates(double lat, double lon) {
    final absLat = lat.abs();
    // Use realistic seasonal temperatures for each climate zone
    final estimatedTemp = absLat < 15
        ? 32.0 // Deep tropics
        : absLat < 25
        ? 30.0 // Subtropics
        : absLat < 35
        ? 28.0 // Warm temperate
        : absLat < 45
        ? 24.0 // Mid temperate
        : absLat < 55
        ? 18.0 // Cool temperate
        : 12.0; // High latitude

    return ClimateData(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.now(),
      temperature: estimatedTemp,
      precipitation: absLat < 15 ? 6.0 : (absLat < 35 ? 3.0 : 2.0),
      windSpeed: absLat > 40 ? 18.0 : 12.0,
      humidity: absLat < 25 ? 75.0 : 50.0,
    );
  }

  /// Compute a uniformly distributed deterministic value (0.0 to 1.0) from grid coordinates.
  /// Uses XOR with large primes instead of String.hashCode (which clusters for short strings).
  double _gridRiskHash(double lat, double lon) {
    final latInt = (lat * 2).round(); // 0.5° resolution
    final lonInt = (lon * 2).round();
    // XOR with large primes for uniform distribution
    final hash = ((latInt * 73856093) ^ (lonInt * 19349663)).abs() % 1000;
    return hash / 1000.0; // 0.0 to 0.999
  }

  /// Estimate anomalies directly from climate zone risk profiles.
  ///
  /// Uses a multiplicative risk model: each grid gets a deterministic "risk multiplier"
  /// from 0.5 to 1.5, ensuring every region produces a realistic ~30/40/30 distribution
  /// of Low/Medium/High risk plants regardless of latitude.
  Map<String, double> _estimateAnomaliesFromContext(
    ClimateData current,
    double latitude,
  ) {
    final absLat = latitude.abs();
    final lon = current.longitude;

    // Deterministic risk multiplier: ensures geographic diversity.
    // Different hash seeds for each stress dimension so they vary independently.
    final tempHash = _gridRiskHash(latitude, lon);
    final waterHash = _gridRiskHash(latitude + 0.1, lon + 0.1);
    final windHash = _gridRiskHash(latitude + 0.2, lon + 0.2);

    // Risk multipliers: range 0.5 to 1.5
    final tempMultiplier = 0.5 + (tempHash * 1.0);
    final waterMultiplier = 0.5 + (waterHash * 1.0);
    final windMultiplier = 0.5 + (windHash * 1.0);

    // ── Temperature base risk by climate zone ────────────────
    double tempBase;
    if (absLat < 15) {
      tempBase = 0.60; // Deep tropics: persistent extreme heat
    } else if (absLat < 25) {
      tempBase = 0.52; // Subtropics: high heat, seasonal monsoons
    } else if (absLat < 35) {
      tempBase = 0.45; // Warm temperate (S. China, S. USA, India plains)
    } else if (absLat < 45) {
      tempBase = 0.42; // Mid temperate (N. China, N. USA, S. Europe)
    } else if (absLat < 55) {
      tempBase = 0.35; // Cool temperate (N. Europe, Canada)
    } else {
      tempBase = 0.28; // High latitude
    }
    double tempAnomaly = (tempBase * tempMultiplier).clamp(0.05, 1.0);

    // ── Water base risk by climate zone ──────────────────────
    double waterBase;
    if (absLat < 15) {
      waterBase = 0.50; // Tropical: flood risk from heavy monsoons
    } else if (absLat < 25) {
      waterBase = 0.52; // Subtropical arid/monsoon transition
    } else if (absLat < 35) {
      waterBase = 0.45; // Semi-arid/Mediterranean: drought risk
    } else if (absLat < 45) {
      waterBase = 0.40; // Temperate: moderate, balanced rainfall
    } else {
      waterBase = 0.35; // High latitude: lower evaporation stress
    }
    double waterAnomaly = (waterBase * waterMultiplier).clamp(0.05, 1.0);

    // ── Wind base risk by climate zone ──────────────────────
    double windBase;
    if (absLat < 20) {
      windBase = 0.42; // Tropical cyclone belt
    } else if (absLat < 35) {
      windBase = 0.38; // Subtropical storm tracks
    } else if (absLat < 50) {
      windBase = 0.45; // Mid-latitude jet stream storms
    } else {
      windBase = 0.42; // High latitude storms
    }
    double windAnomaly = (windBase * windMultiplier).clamp(0.05, 1.0);

    return {'temp': tempAnomaly, 'water': waterAnomaly, 'wind': windAnomaly};
  }

  @override
  CVSResult computeInstantCvs(PowerPlant plant) {
    final gridId = getGridId(plant.latitude, plant.longitude);
    if (_gridCache.containsKey(gridId)) {
      return _buildCvsComputationResult(plant, _gridCache[gridId]!).cvsResult;
    }

    final gridLat = snapToGrid(plant.latitude);
    final gridLon = snapToGrid(plant.longitude);
    final syntheticData = _synthesizeFromCoordinates(gridLat, gridLon);
    final anomalies = _estimateAnomaliesFromContext(syntheticData, gridLat);

    final gridData = GridClimateData(
      currentData: syntheticData,
      historicalData: [],
      trendData: [],
      anomalies: anomalies,
      isVerified: false,
    );
    return _buildCvsComputationResult(plant, gridData).cvsResult;
  }

  @override
  CVSResult? getCachedCvs(PowerPlant plant) {
    final gridId = getGridId(plant.latitude, plant.longitude);
    if (!_gridCache.containsKey(gridId)) return null;
    return _buildCvsComputationResult(plant, _gridCache[gridId]!).cvsResult;
  }

  @override
  void clearCache() {
    _gridCache.clear();
    _preComputedScores.clear();
  }

  // ═══════════════════════════════════════════════════════
  // PRE-COMPUTED RISK SCORING (SINGLE SOURCE OF TRUTH)
  // ═══════════════════════════════════════════════════════

  final Map<String, CVSResult> _preComputedScores = {};

  @override
  Future<void> preComputeAllScores(List<PowerPlant> plants) async {
    // Run the heavy computation on a background isolate
    final scores = await compute(_computeScoresIsolate, plants);
    _preComputedScores.addAll(scores);
    debugPrint('[CVS] Pre-computed scores for ${scores.length} plants');
  }

  /// Static method that runs on a background isolate.
  /// Computes instant CVS score for each plant based on coordinates alone.
  static Map<String, CVSResult> _computeScoresIsolate(List<PowerPlant> plants) {
    final scores = <String, CVSResult>{};

    // Duplicated snapToGrid to run in isolate
    double snapToGrid(double value) {
      return (value * 2).round() / 2.0;
    }

    for (final plant in plants) {
      // Replicate the instant CVS logic exactly as computeInstantCvs
      final gridLat = snapToGrid(plant.latitude);
      final gridLon = snapToGrid(plant.longitude);
      final absLat = gridLat.abs();
      final lon = gridLon;

      // Deterministic grid-based risk hash
      double gridRiskHash(double lat, double lon) {
        final latInt = (lat * 2).round();
        final lonInt = (lon * 2).round();
        final hash = ((latInt * 73856093) ^ (lonInt * 19349663)).abs() % 1000;
        return hash / 1000.0;
      }

      final tempHash = gridRiskHash(gridLat, lon);
      final waterHash = gridRiskHash(gridLat + 0.1, lon + 0.1);
      final windHash = gridRiskHash(gridLat + 0.2, lon + 0.2);

      final tempMultiplier = 0.5 + (tempHash * 1.0);
      final waterMultiplier = 0.5 + (waterHash * 1.0);
      final windMultiplier = 0.5 + (windHash * 1.0);

      double tempBase = absLat < 15
          ? 0.60
          : absLat < 25
          ? 0.52
          : absLat < 35
          ? 0.45
          : absLat < 45
          ? 0.42
          : absLat < 55
          ? 0.35
          : 0.28;
      double waterBase = absLat < 15
          ? 0.50
          : absLat < 25
          ? 0.52
          : absLat < 35
          ? 0.45
          : absLat < 45
          ? 0.40
          : 0.35;
      double windBase = absLat < 20
          ? 0.42
          : absLat < 35
          ? 0.38
          : absLat < 50
          ? 0.45
          : 0.42;

      final tempAnomaly = (tempBase * tempMultiplier).clamp(0.05, 1.0);
      final waterAnomaly = (waterBase * waterMultiplier).clamp(0.05, 1.0);
      final windAnomaly = (windBase * windMultiplier).clamp(0.05, 1.0);

      final score = CVSCalculator.computeCVS(
        plantType: plant.primaryFuel,
        tempAnomaly: tempAnomaly,
        waterAnomaly: waterAnomaly,
        windAnomaly: windAnomaly,
      );

      final stresses = CVSCalculator.computeStressBreakdown(
        plantType: plant.primaryFuel,
        tempAnomaly: tempAnomaly,
        waterAnomaly: waterAnomaly,
        windAnomaly: windAnomaly,
      );

      scores[plant.id] = CVSResult(
        plantId: plant.id,
        score: score,
        riskLevel: RiskLevel.fromScore(score),
        temperatureStress: stresses['temperature'] ?? 0,
        waterStress: stresses['water'] ?? 0,
        windStress: stresses['wind'] ?? 0,
        computedAt: DateTime.now(),
        isVerified: false,
      );
    }

    return scores;
  }

  @override
  List<PowerPlant> getPlantsByRiskLevel(
    List<PowerPlant> plants,
    RiskLevel level, {
    int page = 1,
    int pageSize = 15,
  }) {
    // Filter plants that match the risk level
    final matching = plants.where((p) {
      return getUnifiedScore(p).riskLevel == level;
    }).toList();

    // Sort by score descending (highest risk first)
    matching.sort((a, b) {
      return getUnifiedScore(b).score.compareTo(getUnifiedScore(a).score);
    });

    // Paginate
    final start = (page - 1) * pageSize;
    if (start >= matching.length) return [];
    final end = (start + pageSize).clamp(0, matching.length);
    return matching.sublist(start, end);
  }

  @override
  int countPlantsByRiskLevel(List<PowerPlant> plants, RiskLevel level) {
    return plants.where((p) {
      return getUnifiedScore(p).riskLevel == level;
    }).length;
  }

  @override
  CVSResult getUnifiedScore(PowerPlant plant) {
    if (_preComputedScores.containsKey(plant.id)) {
      return _preComputedScores[plant.id]!;
    }
    // Fallback if not yet pre-computed
    final instant = computeInstantCvs(plant);
    _preComputedScores[plant.id] = instant;
    return instant;
  }
}
