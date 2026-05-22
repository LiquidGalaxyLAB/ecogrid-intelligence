import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:ecogrid_intelligence/core/errors/failures.dart';
import 'package:ecogrid_intelligence/core/constants/app_constants.dart';
import 'package:ecogrid_intelligence/core/utils/cache_manager.dart';
import 'package:ecogrid_intelligence/data/datasources/remote/gemini_remote_ds.dart';
import 'package:ecogrid_intelligence/domain/repositories/ai_repository.dart';

class AIRepositoryImpl implements AIRepository {
  final GeminiRemoteDataSource remoteDataSource;
  final Box cacheBox;

  AIRepositoryImpl({required this.remoteDataSource, required this.cacheBox});

  @override
  Future<Either<Failure, String>> generatePlantInsight({
    required String plantName,
    required String plantType,
    required double cvsScore,
    required double tempStress,
    required double waterStress,
    required double windStress,
    required String country,
  }) async {
    final cacheKey = 'plant_${plantName.hashCode}';

    // Check cache
    final cached = _getCachedInsight(cacheKey);
    if (cached != null && cached.isFresh) {
      return Right(cached.data);
    }

    try {
      final insight = await remoteDataSource.generatePlantInsight(
        plantName: plantName,
        plantType: plantType,
        cvsScore: cvsScore,
        tempStress: tempStress,
        waterStress: waterStress,
        windStress: windStress,
        country: country,
      );

      await _cacheInsight(cacheKey, insight);
      return Right(insight);
    } catch (e) {
      if (cached != null) return Right(cached.data);
      return Left(ServerFailure(message: 'AI insight generation failed: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> generateRegionalInsight({
    required String regionName,
    required int totalPlants,
    required int highRiskPlants,
    required Map<String, int> plantTypeDistribution,
  }) async {
    final cacheKey = 'region_${regionName.hashCode}';
    final cached = _getCachedInsight(cacheKey);
    if (cached != null && cached.isFresh) return Right(cached.data);

    try {
      final insight = await remoteDataSource.generateRegionalInsight(
        regionName: regionName,
        totalPlants: totalPlants,
        highRiskPlants: highRiskPlants,
        plantTypeDistribution: plantTypeDistribution,
      );
      await _cacheInsight(cacheKey, insight);
      return Right(insight);
    } catch (e) {
      if (cached != null) return Right(cached.data);
      return Left(ServerFailure(message: 'Regional insight failed: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> generateScenarioAnalysis({
    required String plantName,
    required String plantType,
    required double currentCvs,
    required double projectedCvs,
    required String scenarioType,
  }) async {
    // Scenarios change with inputs, don't cache
    try {
      final analysis = await remoteDataSource.generateScenarioAnalysis(
        plantName: plantName,
        plantType: plantType,
        currentCvs: currentCvs,
        projectedCvs: projectedCvs,
        scenarioType: scenarioType,
      );
      return Right(analysis);
    } catch (e) {
      return Left(ServerFailure(message: 'Scenario analysis failed: $e'));
    }
  }

  CachedData<String>? _getCachedInsight(String key) {
    final raw = cacheBox.get(key);
    if (raw == null) return null;
    try {
      final map = Map<String, dynamic>.from(raw as Map);
      return CachedData<String>(
        data: map['data'] as String,
        cachedAt: DateTime.parse(map['cachedAt'] as String),
        staleDuration: AppConstants.aiInsightStaleDuration,
        expireDuration: AppConstants.aiInsightExpireDuration,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheInsight(String key, String data) async {
    await cacheBox.put(key, {
      'data': data,
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }
}
