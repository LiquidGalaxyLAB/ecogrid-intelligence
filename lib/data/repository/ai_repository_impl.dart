import 'package:uuid/uuid.dart';
import '../../core/exception/invalid_response_exception.dart';
import '../../core/exception/unhandled_exception.dart';
import '../../core/resources/data_state.dart';
import '../../core/resources/network_state.dart';
import '../../core/constants/cache_constants.dart';
import '../../core/constants/api_constants.dart';
import 'package:logger/logger.dart';
import '../../core/utils/cache_manager.dart';
import '../remote/data_sources/ai_data_source.dart';
import '../../domain/repository/ai_repository.dart';
import '../../domain/model/plant_context_payload.dart';
import '../local/app_database.dart';

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
  static const double _cvsDeltaThreshold = 1.0;
  final Map<String, List<Map<String, String>>> _chatSessions = {};
  static const _uuid = Uuid();
  AIRepositoryImpl({required this.dataSource, required this._aiCacheDao});
  @override
  Stream<DataState<String>> generatePlantInsight({
    required PlantContextPayload context,
    bool isUserInitiated = false,
  }) async* {
    if (!isUserInitiated) {
      _logger.e(
        '[AIRepository] BLOCKED: AI Insight called without explicit user initiation for ${context.plantName}\n'
        'Caller StackTrace:\n${StackTrace.current}',
      );
      yield DataFailure(
        InvalidResponseException(
          message:
              'Auto-fetching insights is strictly prohibited by security policy.',
          response: null,
        ),
      );
      return;
    }
    yield const DataLoading();
    final cacheKey = 'plant_insight_${context.plantName.hashCode}';
    final cached = await _getCachedInsight(cacheKey);
    if (cached != null && cached.isFresh) {
      final cachedCvs = await _getCachedCvsScore(cacheKey);
      if (cachedCvs != null &&
          (cachedCvs - context.cvsScore).abs() <= _cvsDeltaThreshold) {
        _logger.i('[AIRepository] Cache Hit -- ${context.plantName}');
        yield DataSuccess(cached.data);
        return;
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
    final stream = dataSource.generateInsight(
      prompt: prompt,
      source: '[PlantDetailScreen] - Insight Card',
    );
    await for (final state in stream) {
      if (state is NetworkIdle || state is NetworkLoading) {
        if (cached == null) yield const DataLoading();
      } else if (state is NetworkSuccess<String>) {
        final insight = state.data;
        await _cacheInsight(cacheKey, insight, context.cvsScore);
        yield DataSuccess(insight);
      } else if (state is NetworkFailure) {
        if (cached != null) {
          yield DataSuccess(cached.data);
        } else {
          yield DataFailure(
            (state as NetworkFailure).exception ??
                UnhandledException(message: 'Unknown AI error'),
          );
        }
      }
    }
  }

  @override
  Stream<DataState<String>> generateRegionalInsight({
    required String regionName,
    required String riskFilterName,
    required int totalPlants,
    required Map<String, int> riskBreakdown,
    required String dominantRiskDimension,
    required String commonHighRiskType,
    required List<String> top3Plants,
  }) async* {
    yield const DataLoading();
    final cacheKey = 'region_${regionName.hashCode}_${riskFilterName.hashCode}';
    final cached = await _getCachedInsight(cacheKey);
    if (cached != null && cached.isFresh) {
      _logger.i('[AIRepository] Cache Hit -- Region: $regionName');
      yield DataSuccess(cached.data);
      return;
    }
    _logger.i('[AIRepository] Cache Miss -- Region: $regionName');
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
''';
    final stream = dataSource.generateInsight(
      prompt: prompt,
      source: '[ExploreScreen] - Regional Analysis',
    );
    await for (final state in stream) {
      if (state is NetworkIdle || state is NetworkLoading) {
        if (cached == null) yield const DataLoading();
      } else if (state is NetworkSuccess<String>) {
        final insight = state.data;
        await _cacheInsight(cacheKey, insight, null);
        yield DataSuccess(insight);
      } else if (state is NetworkFailure) {
        if (cached != null) {
          yield DataSuccess(cached.data);
        } else {
          yield DataFailure(
            (state as NetworkFailure).exception ??
                UnhandledException(message: 'Unknown AI error'),
          );
        }
      }
    }
  }

  @override
  Stream<DataState<String>> generateScenarioAnalysis({
    required PlantContextPayload context,
    required double projectedCvs,
    required String scenarioType,
  }) async* {
    yield const DataLoading();
    final prompt =
        '''
You are EcoGrid Intelligence, an AI climate risk analyst.
Analyze this climate scenario simulation:
${context.toPromptContext()}
**Scenario:** $scenarioType
**Projected CVS:** ${projectedCvs.toStringAsFixed(1)}/100
**Change:** ${(projectedCvs - context.cvsScore) >= 0 ? '+' : ''}${(projectedCvs - context.cvsScore).toStringAsFixed(1)} points
Focus ONLY on the impacts of the selected '$scenarioType' scenario. In 2-3 sentences, explain the projected impact of this specific scenario on the plant's operations and what specific risks would increase.
''';
    final stream = dataSource.generateInsight(
      prompt: prompt,
      source: '[ScenarioSheet] - Impact Analysis',
    );
    await for (final state in stream) {
      if (state is NetworkIdle || state is NetworkLoading) {
        yield const DataLoading();
      } else if (state is NetworkSuccess<String>) {
        yield DataSuccess(state.data);
      } else if (state is NetworkFailure) {
        yield DataFailure(
          (state as NetworkFailure).exception ??
              UnhandledException(message: 'Unknown AI error'),
        );
      }
    }
  }

  @override
  Stream<DataState<String>> generateTrendInsight({
    required PlantContextPayload context,
  }) async* {
    yield const DataLoading();
    final cacheKey = 'trend_${context.plantName.hashCode}';
    final cached = await _getCachedInsight(cacheKey);
    if (cached != null && cached.isFresh) {
      _logger.i('[AIRepository] Cache Hit -- Trend: ${context.plantName}');
      yield DataSuccess(cached.data);
      return;
    }
    _logger.i('[AIRepository] Cache Miss -- Trend: ${context.plantName}');
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
    final stream = dataSource.generateInsight(
      prompt: prompt,
      source: '[PlantDetailScreen] - Trend Sheet',
    );
    await for (final state in stream) {
      if (state is NetworkIdle || state is NetworkLoading) {
        if (cached == null) yield const DataLoading();
      } else if (state is NetworkSuccess<String>) {
        final insight = state.data;
        await _cacheInsight(cacheKey, insight, null);
        yield DataSuccess(insight);
      } else if (state is NetworkFailure) {
        if (cached != null) {
          yield DataSuccess(cached.data);
        } else {
          yield DataFailure(
            (state as NetworkFailure).exception ??
                UnhandledException(message: 'Unknown AI error'),
          );
        }
      }
    }
  }

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
      {'role': 'user', 'content': systemPrompt},
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
      'Model: ${ApiConstants.geminiChatModel}\n'
      'System Prompt Approx Tokens: ~$tokenCount',
    );
    return sessionId;
  }

  @override
  Stream<DataState<String>> sendChatMessage({
    required String sessionId,
    required String message,
  }) async* {
    yield const DataLoading();
    final history = _chatSessions[sessionId];
    if (history == null) {
      yield DataFailure(
        InvalidResponseException(
          message: 'Chat session not found. Please start a new chat.',
          response: null,
        ),
      );
      return;
    }
    final stream = dataSource.sendChatMessage(
      history: history,
      message: message,
      source: '[PlantChatPanel]',
    );
    await for (final state in stream) {
      if (state is NetworkIdle || state is NetworkLoading) {
        yield const DataLoading();
      } else if (state is NetworkSuccess<String>) {
        final response = state.data;
        history.add({'role': 'user', 'content': message});
        history.add({'role': 'assistant', 'content': response});
        yield DataSuccess(response);
      } else if (state is NetworkFailure) {
        yield DataFailure(
          (state as NetworkFailure).exception ??
              UnhandledException(message: 'Unknown AI error'),
        );
      }
    }
  }

  Future<CachedData<String>?> _getCachedInsight(String key) async {
    final row = await _aiCacheDao.getCached(key);
    if (row == null) return null;
    return CachedData<String>(
      data: row.insight,
      cachedAt: row.cachedAt,
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
