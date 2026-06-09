// ignore_for_file: prefer_initializing_formals

import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:ecogrid_intelligence/core/exception/failures.dart';
import 'package:ecogrid_intelligence/core/constants/cache_constants.dart';
import 'package:ecogrid_intelligence/core/constants/api_constants.dart';
import 'package:logger/logger.dart';
import 'package:ecogrid_intelligence/core/utils/cache_manager.dart';
import 'package:ecogrid_intelligence/data/data_sources/remote/ai_data_source.dart';
import 'package:ecogrid_intelligence/domain/repository/ai_repository.dart';
import 'package:ecogrid_intelligence/domain/model/plant_context_payload.dart';
import 'package:ecogrid_intelligence/data/data_sources/local/app_database.dart';

class AIRepositoryImpl implements AIRepository {
  final AIDataSource dataSource;
  final AiCacheDao _aiCacheDao;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// CVS delta threshold: if the cached insight was generated at a CVS that
  /// differs from the current CVS by more than this, invalidate the cache.
  static const double _cvsDeltaThreshold = 1.0;

  /// In-memory chat history, keyed by session ID.
  /// Each session is a list of messages in OpenAI-compatible format.
  final Map<String, List<Map<String, String>>> _chatSessions = {};

  static const _uuid = Uuid();

  AIRepositoryImpl({required this.dataSource, required AiCacheDao aiCacheDao})
    : _aiCacheDao = aiCacheDao;

  // ─── Plant Insight ────────────────────────────────────

  @override
  Future<Either<Failure, String>> generatePlantInsight({
    required PlantContextPayload context,
    bool isUserInitiated = false,
  }) async {
    if (!isUserInitiated) {
      _logger.e(
        '[AIRepository] BLOCKED: AI Insight called without explicit user initiation for ${context.plantName}\n'
        'Caller StackTrace:\n${StackTrace.current}',
      );
      return Left(
        ServerFailure(
          message:
              'Auto-fetching insights is strictly prohibited by security policy.',
        ),
      );
    }

    final cacheKey = 'plant_insight_${context.plantName.hashCode}';

    // Check cache — also validate CVS delta
    final cached = await _getCachedInsight(cacheKey);
    if (cached != null && cached.isFresh) {
      final cachedCvs = await _getCachedCvsScore(cacheKey);
      if (cachedCvs != null &&
          (cachedCvs - context.cvsScore).abs() <= _cvsDeltaThreshold) {
        _logger.i(
          '[AIRepository] Cache Hit -- returning stored insight for ${context.plantName}',
        );
        return Right(cached.data);
      }
    }

    _logger.i(
      '[AIRepository] Cache Miss -- calling AI for ${context.plantName}',
    );

    final prompt =
        '''
You are EcoGrid Intelligence, an AI climate risk analyst for global energy infrastructure.

Analyze the following power plant's climate vulnerability:

${context.toPromptContext()}

Provide a concise 3-4 sentence climate risk assessment explaining:
1. Why this plant is vulnerable based on its type and environmental stresses
2. The primary climate threat to its operations
3. A brief recommendation for resilience improvement

Be specific to the plant type's operational characteristics. Use professional, data-driven language.
''';

    try {
      final insight = await dataSource.generateInsight(
        prompt: prompt,
        source: '[PlantDetailScreen] - Insight Card',
      );

      await _cacheInsight(cacheKey, insight, context.cvsScore);
      return Right(insight);
    } catch (e) {
      if (cached != null) return Right(cached.data);
      return Left(ServerFailure(message: 'AI insight generation failed: $e'));
    }
  }

  // ─── Regional Insight ─────────────────────────────────

  @override
  Future<Either<Failure, String>> generateRegionalInsight({
    required String regionName,
    required String riskFilterName,
    required int totalPlants,
    required Map<String, int> riskBreakdown,
    required String dominantRiskDimension,
    required String commonHighRiskType,
    required List<String> top3Plants,
  }) async {
    final cacheKey = 'region_${regionName.hashCode}_${riskFilterName.hashCode}';
    final cached = await _getCachedInsight(cacheKey);
    if (cached != null && cached.isFresh) {
      _logger.i(
        '[AIRepository] Cache Hit -- returning stored insight for Region: $regionName ($riskFilterName)',
      );
      return Right(cached.data);
    }

    _logger.i(
      '[AIRepository] Cache Miss -- calling AI for Region: $regionName ($riskFilterName)',
    );

    final breakdownStr = riskBreakdown.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
    final top3Str = top3Plants.join('\n- ');

    final prompt =
        '''
You are EcoGrid Intelligence, an AI climate risk analyst.

Provide a regional climate risk overview based on this summary data:

**Region:** $regionName
**Active Filter:** $riskFilterName
**Total Power Plants:** $totalPlants
**Risk Breakdown:** $breakdownStr
**Dominant Climate Threat:** $dominantRiskDimension
**Most Vulnerable Plant Type:** $commonHighRiskType
**Top 3 Highest Risk Plants:**
- $top3Str

Provide a concise 3-4 sentence regional assessment covering:
1. Overall infrastructure vulnerability profile for this region
2. Why the dominant climate threat is dangerous to the most vulnerable plant types here
3. A brief mention of the top risk plants as prime targets for resilience upgrades

Be specific and data-driven. Do not list the plants, just weave them naturally into the analysis.
''';

    try {
      final insight = await dataSource.generateInsight(
        prompt: prompt,
        source: '[ExploreScreen] - Regional Analysis',
      );
      await _cacheInsight(cacheKey, insight, null);
      return Right(insight);
    } catch (e) {
      if (cached != null) return Right(cached.data);
      return Left(ServerFailure(message: 'Regional insight failed: $e'));
    }
  }

  // ─── Scenario Analysis ────────────────────────────────

  @override
  Future<Either<Failure, String>> generateScenarioAnalysis({
    required PlantContextPayload context,
    required double projectedCvs,
    required String scenarioType,
  }) async {
    final prompt =
        '''
You are EcoGrid Intelligence, an AI climate risk analyst.

Analyze this climate scenario simulation:

${context.toPromptContext()}
**Scenario:** $scenarioType
**Projected CVS:** ${projectedCvs.toStringAsFixed(1)}/100
**Change:** ${(projectedCvs - context.cvsScore) >= 0 ? '+' : ''}${(projectedCvs - context.cvsScore).toStringAsFixed(1)} points

In 2-3 sentences, explain the projected impact of this scenario on the plant's operations and what specific risks would increase.
''';

    try {
      final analysis = await dataSource.generateInsight(
        prompt: prompt,
        source: '[ScenarioSheet] - Impact Analysis',
      );
      return Right(analysis);
    } catch (e) {
      return Left(ServerFailure(message: 'Scenario analysis failed: $e'));
    }
  }

  // ─── Trend Insight ────────────────────────────────────

  @override
  Future<Either<Failure, String>> generateTrendInsight({
    required PlantContextPayload context,
  }) async {
    final cacheKey = 'trend_${context.plantName.hashCode}';
    final cached = await _getCachedInsight(cacheKey);
    if (cached != null && cached.isFresh) {
      _logger.i(
        '[AIRepository] Cache Hit -- returning stored insight for Trend: ${context.plantName}',
      );
      return Right(cached.data);
    }

    _logger.i(
      '[AIRepository] Cache Miss -- calling AI for Trend: ${context.plantName}',
    );

    final prompt =
        '''
You are EcoGrid Intelligence, an AI climate risk analyst.

Analyze the historical climate trend for this power plant:

${context.toPromptContext()}

In 3-4 sentences, explain:
1. Whether climate conditions for this plant are worsening, stable, or improving over the observed period
2. What the primary trend drivers are (temperature, precipitation, wind changes)
3. What the operational implications are for this specific plant type over the coming decade

Be specific, data-driven, and reference the actual trend data provided.
''';

    try {
      final insight = await dataSource.generateInsight(
        prompt: prompt,
        source: '[PlantDetailScreen] - Trend Sheet',
      );
      await _cacheInsight(cacheKey, insight, null);
      return Right(insight);
    } catch (e) {
      if (cached != null) return Right(cached.data);
      return Left(ServerFailure(message: 'Trend insight failed: $e'));
    }
  }

  // ─── Chat ─────────────────────────────────────────────

  @override
  String startPlantChat({required PlantContextPayload context}) {
    final sessionId = _uuid.v4();

    final systemPrompt =
        '''
You are EcoGrid Intelligence, an AI climate risk analyst specialised in power plant vulnerability assessment.

You are currently advising on the following power plant. Every response you give must be specific to THIS plant, not generic.

${context.toPromptContext()}

Guidelines:
- Always reference the plant's specific data when answering.
- If the user asks about scenarios, factor in the plant's fuel type, location, and current stress levels.
- Keep responses concise (3-5 sentences) unless the user asks for more detail.
- Use professional, data-driven language.
- If you don't have enough information to answer precisely, say so rather than guessing.
''';

    _chatSessions[sessionId] = [
      {'role': 'system', 'content': systemPrompt},
      {
        'role': 'assistant',
        'content':
            'Understood. I am now advising on ${context.plantName}, '
            'a ${context.fuelType} plant in ${context.countryLong ?? context.country} '
            'with a CVS of ${context.cvsScore.toStringAsFixed(1)}/100 '
            '(${context.riskLevel.label} risk). How can I help?',
      },
    ];

    final tokenCount = systemPrompt.length ~/ 4;
    _logger.i(
      'AI Chat Session Started\n'
      'Session: $sessionId\n'
      'Source: [PlantDetailScreen] - Chat Panel\n'
      'Model: ${ApiConstants.groqChatModel}\n'
      'System Prompt Approx Tokens: ~$tokenCount',
    );

    return sessionId;
  }

  @override
  Future<Either<Failure, String>> sendChatMessage({
    required String sessionId,
    required String message,
  }) async {
    final history = _chatSessions[sessionId];
    if (history == null) {
      return Left(
        ServerFailure(
          message: 'Chat session not found. Please start a new chat.',
        ),
      );
    }

    try {
      final response = await dataSource.sendChatMessage(
        history: history,
        message: message,
        source: '[PlantChatPanel]',
      );

      // Append the exchange to history for context continuity
      history.add({'role': 'user', 'content': message});
      history.add({'role': 'assistant', 'content': response});

      return Right(response);
    } catch (e) {
      return Left(ServerFailure(message: 'Chat message failed: $e'));
    }
  }

  // ─── Cache Helpers (now async — Drift reads are async) ─

  Future<CachedData<String>?> _getCachedInsight(String key) async {
    final row = await _aiCacheDao.getCached(key);
    if (row == null) return null;
    return CachedData<String>(
      data: row.insight,
      cachedAt: row.cachedAt, // Already a DateTime — no parsing needed
      staleDuration: CacheConstants.aiInsightStaleDuration,
      expireDuration: CacheConstants.aiInsightExpireDuration,
    );
  }

  Future<double?> _getCachedCvsScore(String key) async {
    final row = await _aiCacheDao.getCached(key);
    return row?.cvsScore;
  }

  Future<void> _cacheInsight(String key, String data, double? cvsScore) =>
      _aiCacheDao.cache(key, data, cvsScore);
}
