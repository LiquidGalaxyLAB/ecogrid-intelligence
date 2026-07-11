import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/model/power_plant.dart';
import '../../../core/enums/plant_type.dart';
import '../../../domain/model/climate_data.dart';
import '../../../domain/model/cvs_result.dart';
import '../../../domain/model/plant_context_payload.dart';
import '../../../domain/model/lg_settings.dart';
import '../../../service/lg_service.dart';
import '../../../domain/usecases/cvs/services/get_unified_score_usecase.dart';
import '../../../domain/usecases/cvs/services/get_cvs_for_plant_usecase.dart';
import '../../../domain/usecases/ai/services/generate_plant_insight_usecase.dart';
import '../../../domain/usecases/ai/services/generate_scenario_analysis_usecase.dart';
import '../../../domain/usecases/climate/services/get_multi_year_trend_usecase.dart';
import '../../../domain/usecases/ai/services/generate_trend_insight_usecase.dart';
import '../../../domain/usecases/ai/services/start_plant_chat_usecase.dart';
import '../../../domain/usecases/ai/services/send_chat_message_usecase.dart';
import '../../../core/resources/data_state.dart';
import '../../../core/resources/app_state.dart';
import '../../../domain/repository/cvs_repository.dart';
import '../../../core/enums/connection_status.dart';
import '../../../core/enums/lg_display_mode.dart';
import '../../../core/enums/historical_data_mode.dart';
import '../../../core/utils/kml_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'plant_detail_event.dart';
import 'plant_detail_data.dart';

class PlantDetailBloc
    extends Bloc<PlantDetailEvent, AppState<PlantDetailData>> {
  final LGService lgService;
  final GetUnifiedScoreUsecase getUnifiedScoreUsecase;
  final GetCvsForPlantUsecase getCvsForPlantUsecase;
  final GeneratePlantInsightUsecase generatePlantInsightUsecase;
  final GenerateScenarioAnalysisUsecase generateScenarioAnalysisUsecase;
  final GetMultiYearTrendUsecase getMultiYearTrendUsecase;
  final GenerateTrendInsightUsecase generateTrendInsightUsecase;
  final StartPlantChatUsecase startPlantChatUsecase;
  final SendChatMessageUsecase sendChatMessageUsecase;
  String? _chatSessionId;
  PlantDetailBloc({
    required this.lgService,
    required this.getUnifiedScoreUsecase,
    required this.getCvsForPlantUsecase,
    required this.generatePlantInsightUsecase,
    required this.generateScenarioAnalysisUsecase,
    required this.getMultiYearTrendUsecase,
    required this.generateTrendInsightUsecase,
    required this.startPlantChatUsecase,
    required this.sendChatMessageUsecase,
  }) : super(const AppLoading()) {
    on<PlantDetailLoadRequested>(_onLoadRequested);
    on<PlantDetailGenerateInsightRequested>(_onGenerateInsightRequested);
    on<PlantDetailScenarioInsightRequested>(_onScenarioInsightRequested);
    on<PlantDetailTrendRequested>(_onTrendRequested);
    on<PlantDetailTrendInsightRequested>(_onTrendInsightRequested);
    on<PlantDetailChatStarted>(_onChatStarted);
    on<PlantDetailChatMessageSent>(_onChatMessageSent);
    on<PlantDetailClearLGError>((event, emit) {
      if (state is AppSuccess<PlantDetailData>) {
        final data = (state as AppSuccess<PlantDetailData>).data!;
        emit(AppSuccess(data.copyWith(clearLgError: true)));
      }
    });
    on<PlantDetailStartOrbitRequested>(_onStartOrbitRequested);
    on<PlantDetailStopOrbitRequested>(_onStopOrbitRequested);
  }
  PlantContextPayload? _buildContext() {
    if (state is! AppSuccess<PlantDetailData>) return null;
    final s = (state as AppSuccess<PlantDetailData>).data!;
    if (s.cvsResult == null) return null;
    return PlantContextPayload.fromEntities(
      plant: s.plant,
      cvs: s.cvsResult!,
      trendData: s.trendData.isNotEmpty ? s.trendData : null,
      activeScenarioType: s.scenarioInsight != null ? 'Custom' : null,
      scenarioProjectedCvs: s.projectedCvs,
    );
  }

  Future<void> _onLoadRequested(
    PlantDetailLoadRequested event,
    Emitter<AppState<PlantDetailData>> emit,
  ) async {
    emit(const AppLoading<PlantDetailData>());
    final plant = event.plant;
    final activeCvs = getUnifiedScoreUsecase(plant);
    emit(
      AppSuccess<PlantDetailData>(
        PlantDetailData(
          plant: plant,
          cvsResult: activeCvs,
          isLoadingCvs: false,
          isLoadingInsight: false,
        ),
      ),
    );
    // Await the LG fly-to + KML sequence BEFORE starting the CVS stream.
    // Running both concurrently caused SFTP channel races that silently
    // dropped the plant KML (LG stayed stuck on the region view).
    await _triggerPlantLGSequence(plant, activeCvs, emit);
    await emit.forEach<DataState<CvsComputationResult>>(
      getCvsForPlantUsecase(params: plant),
      onData: (dataState) {
        if (dataState is DataLoading<CvsComputationResult>) {
          if (state is AppSuccess<PlantDetailData>) {
            final data = (state as AppSuccess<PlantDetailData>).data!;
            return AppSuccess<PlantDetailData>(
              data.copyWith(isLoadingCvs: true),
            );
          }
          return const AppLoading<PlantDetailData>();
        } else if (dataState is DataSuccess<CvsComputationResult>) {
          if (state is AppSuccess<PlantDetailData>) {
            final data = (state as AppSuccess<PlantDetailData>).data!;
            return AppSuccess<PlantDetailData>(
              data.copyWith(
                climateData: dataState.data!.currentClimate,
                historicalData: dataState.data!.historicalData,
                isLoadingCvs: false,
              ),
            );
          }
          return state;
        } else {
          debugPrint('[CVS] Stream failure: ${dataState.exception}');
          if (state is AppSuccess<PlantDetailData>) {
            final data = (state as AppSuccess<PlantDetailData>).data!;
            return AppSuccess<PlantDetailData>(
              data.copyWith(isLoadingCvs: false),
            );
          }
          return state;
        }
      },
      onError: (error, _) {
        debugPrint('[CVS] Stream error: $error');
        if (state is AppSuccess<PlantDetailData>) {
          final data = (state as AppSuccess<PlantDetailData>).data!;
          return AppSuccess<PlantDetailData>(
            data.copyWith(isLoadingCvs: false),
          );
        }
        return state;
      },
    );
  }

  Future<void> _triggerPlantLGSequence(
    PowerPlant plant,
    CVSResult cvs,
    Emitter<AppState<PlantDetailData>> emit,
  ) async {
    if (lgService.connectionStatus != ConnectionStatus.connected) {
      debugPrint('[LG] Skipping plant sequence — not connected');
      return;
    }
    try {
      debugPrint('[LG] Starting plant sequence for ${plant.name}');

      // 1. Clear screen + fly to plant in parallel (independent operations).
      await Future.wait([
        lgService.clearKml(),
        lgService.flyTo(
          plant.latitude,
          plant.longitude,
          0, 0, 0,
          _calculateOptimalRange(plant),
        ),
      ]);
      debugPrint('[LG] clearKml + flyTo done');

      // 2. Send concentric ring KML.
      final pinKml = KmlUtils.plantPinKml(
        plant: plant,
        riskLevel: cvs.riskLevel,
      );
      await lgService.sendKmlToMaster(pinKml);
      debugPrint('[LG] pinKml sent');

      // 3. Load settings once to position the balloon on the correct screen.
      final settingsResult = await lgService.loadSettings();
      int rightmostScreen = LGSettings.empty.rightmostScreen;
      int screenCount = LGSettings.empty.screenCount;
      if (settingsResult is DataSuccess<LGSettings>) {
        rightmostScreen = settingsResult.data!.rightmostScreen;
        screenCount = settingsResult.data!.screenCount;
      }

      // 4. Offset balloon to rightmost LG screen.
      const offsetPerSideScreen = 10.0;
      final sideScreens = (screenCount - 1) / 2;
      final rawLon = plant.longitude + (offsetPerSideScreen * sideScreens);
      final adjustedLon = rawLon > 180.0 ? rawLon - 360.0 : rawLon;

      // 5. Build + send balloon.
      ClimateData? currentClimate;
      if (state is AppSuccess<PlantDetailData>) {
        currentClimate = (state as AppSuccess<PlantDetailData>).data!.climateData;
      }
      final balloonKml = KmlUtils.plantDetailBalloon(
        plant: plant,
        cvs: cvs,
        lat: plant.latitude,
        lon: adjustedLon,
        climateData: currentClimate,
      );
      await lgService.showBalloonOnSlave(rightmostScreen, balloonKml);
      lgService.setCurrentMode(LGDisplayMode.plantDetail);
      debugPrint('[LG] Plant detail sequence complete for ${plant.name}');
    } catch (e, st) {
      debugPrint('[LG] Plant detail sequence FAILED for ${plant.name}: $e\n$st');
    }
  }


  Future<void> _onGenerateInsightRequested(
    PlantDetailGenerateInsightRequested event,
    Emitter<AppState<PlantDetailData>> emit,
  ) async {
    if (state is! AppSuccess<PlantDetailData>) return;
    final currentData = (state as AppSuccess<PlantDetailData>).data!;
    final context = _buildContext();
    if (context == null) {
      emit(
        AppSuccess(
          currentData.copyWith(
            insightError:
                'CVS data not yet available. Please wait for scoring to complete.',
          ),
        ),
      );
      return;
    }
    emit(
      AppSuccess(
        currentData.copyWith(isLoadingInsight: true, clearInsightError: true),
      ),
    );
    final insightResult =
        await generatePlantInsightUsecase(
          params: {'context': context, 'isUserInitiated': true},
        ).last.timeout(
          const Duration(seconds: 12),
          onTimeout: () => const DataFailure(_TimeoutException()),
        );
    if (insightResult is DataSuccess<String>) {
      if (state is AppSuccess<PlantDetailData>) {
        final d = (state as AppSuccess<PlantDetailData>).data!;
        emit(
          AppSuccess(
            d.copyWith(aiInsight: insightResult.data!, isLoadingInsight: false),
          ),
        );
      }
    } else {
      if (state is AppSuccess<PlantDetailData>) {
        final d = (state as AppSuccess<PlantDetailData>).data!;
        emit(
          AppSuccess(
            d.copyWith(
              isLoadingInsight: false,
              insightError:
                  insightResult.exception?.toString() ?? 'AI insight failed',
            ),
          ),
        );
      }
    }
  }

  Future<void> _onScenarioInsightRequested(
    PlantDetailScenarioInsightRequested event,
    Emitter<AppState<PlantDetailData>> emit,
  ) async {
    if (state is! AppSuccess<PlantDetailData>) return;
    final currentData = (state as AppSuccess<PlantDetailData>).data!;
    final context = _buildContext();
    if (context == null) return;
    emit(
      AppSuccess(
        currentData.copyWith(
          projectedCvs: event.projectedCvs,
          isLoadingInsight: true,
        ),
      ),
    );
    final insightResult = await generateScenarioAnalysisUsecase(
      params: {
        'context': context,
        'projectedCvs': event.projectedCvs,
        'scenarioType': event.scenarioType,
      },
    ).last;
    if (insightResult is DataSuccess<String>) {
      if (state is AppSuccess<PlantDetailData>) {
        final d = (state as AppSuccess<PlantDetailData>).data!;
        emit(
          AppSuccess(
            d.copyWith(
              scenarioInsight: insightResult.data!,
              isLoadingInsight: false,
            ),
          ),
        );
      }
    } else {
      if (state is AppSuccess<PlantDetailData>) {
        final d = (state as AppSuccess<PlantDetailData>).data!;
        emit(
          AppSuccess(
            d.copyWith(
              isLoadingInsight: false,
              insightError:
                  insightResult.exception?.toString() ??
                  'Scenario analysis failed',
            ),
          ),
        );
      }
    }
  }

  List<ClimateData> _aggregateByYear(List<ClimateData> rawData) {
    final Map<int, List<ClimateData>> byYear = {};
    for (final d in rawData) {
      byYear.putIfAbsent(d.timestamp.year, () => []).add(d);
    }
    return byYear.entries.map((entry) {
      final year = entry.key;
      final points = entry.value;
      final temps = points
          .where((d) => d.temperature != null)
          .map((d) => d.temperature!)
          .toList();
      final precips = points
          .where((d) => d.precipitation != null)
          .map((d) => d.precipitation!)
          .toList();
      final winds = points
          .where((d) => d.windSpeed != null)
          .map((d) => d.windSpeed!)
          .toList();
      return ClimateData(
        latitude: points.first.latitude,
        longitude: points.first.longitude,
        timestamp: DateTime(year, 7, 1),
        temperature: temps.isNotEmpty
            ? temps.reduce((a, b) => a + b) / temps.length
            : null,
        precipitation: precips.isNotEmpty
            ? precips.reduce((a, b) => a + b) / precips.length
            : null,
        windSpeed: winds.isNotEmpty
            ? winds.reduce((a, b) => a + b) / winds.length
            : null,
      );
    }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> _onTrendRequested(
    PlantDetailTrendRequested event,
    Emitter<AppState<PlantDetailData>> emit,
  ) async {
    if (state is! AppSuccess<PlantDetailData>) return;
    final currentData = (state as AppSuccess<PlantDetailData>).data!;
    if (currentData.trendData.isNotEmpty || currentData.isLoadingTrend) {
      return;
    }
    emit(AppSuccess(currentData.copyWith(isLoadingTrend: true)));
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex =
          prefs.getInt('historical_data_mode') ?? HistoricalDataMode.fast.index;
      final mode = HistoricalDataMode.values[modeIndex];
      final now = DateTime.now();
      final trendResult = await getMultiYearTrendUsecase(
        params: {
          'lat': event.plant.latitude,
          'lon': event.plant.longitude,
          'startDate': mode.startDate,
          'endDate': DateTime(now.year, 1, 1).subtract(const Duration(days: 1)),
        },
      ).last.timeout(const Duration(seconds: 75));
      if (trendResult is DataSuccess<List<ClimateData>>) {
        final aggregatedData = _aggregateByYear(trendResult.data!);
        if (state is AppSuccess<PlantDetailData>) {
          final d = (state as AppSuccess<PlantDetailData>).data!;
          emit(
            AppSuccess(
              d.copyWith(trendData: aggregatedData, isLoadingTrend: false),
            ),
          );
        }
      } else {
        debugPrint('[Trend] Failed: ${trendResult.exception}');
        if (state is AppSuccess<PlantDetailData>) {
          final d = (state as AppSuccess<PlantDetailData>).data!;
          emit(AppSuccess(d.copyWith(isLoadingTrend: false)));
        }
      }
    } catch (e) {
      debugPrint('[Trend] Error: $e');
      if (state is AppSuccess<PlantDetailData>) {
        final d = (state as AppSuccess<PlantDetailData>).data!;
        emit(AppSuccess(d.copyWith(isLoadingTrend: false)));
      }
    }
  }

  Future<void> _onTrendInsightRequested(
    PlantDetailTrendInsightRequested event,
    Emitter<AppState<PlantDetailData>> emit,
  ) async {
    if (state is! AppSuccess<PlantDetailData>) return;
    final currentData = (state as AppSuccess<PlantDetailData>).data!;
    final context = _buildContext();
    if (context == null) return;
    emit(AppSuccess(currentData.copyWith(isLoadingTrendInsight: true)));
    final result = await generateTrendInsightUsecase(params: context).last
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => const DataFailure(_TimeoutException()),
        );
    if (result is DataSuccess<String>) {
      if (state is AppSuccess<PlantDetailData>) {
        final d = (state as AppSuccess<PlantDetailData>).data!;
        emit(
          AppSuccess(
            d.copyWith(
              trendInsight: result.data!,
              isLoadingTrendInsight: false,
            ),
          ),
        );
      }
    } else {
      if (state is AppSuccess<PlantDetailData>) {
        final d = (state as AppSuccess<PlantDetailData>).data!;
        emit(AppSuccess(d.copyWith(isLoadingTrendInsight: false)));
      }
    }
  }

  Future<void> _onChatStarted(
    PlantDetailChatStarted event,
    Emitter<AppState<PlantDetailData>> emit,
  ) async {
    if (state is! AppSuccess<PlantDetailData>) return;
    final currentData = (state as AppSuccess<PlantDetailData>).data!;
    final context = _buildContext();
    if (context == null) return;
    _chatSessionId = startPlantChatUsecase(context: context);
    emit(
      AppSuccess(currentData.copyWith(isChatActive: true, chatMessages: [])),
    );
  }

  Future<void> _onChatMessageSent(
    PlantDetailChatMessageSent event,
    Emitter<AppState<PlantDetailData>> emit,
  ) async {
    if (state is! AppSuccess<PlantDetailData> || _chatSessionId == null) return;
    final currentData = (state as AppSuccess<PlantDetailData>).data!;
    final userMessage = ChatMessage(text: event.message, isUser: true);
    final updatedMessages = [...currentData.chatMessages, userMessage];
    emit(
      AppSuccess(
        currentData.copyWith(
          chatMessages: updatedMessages,
          isChatLoading: true,
        ),
      ),
    );
    final result = await sendChatMessageUsecase(
      params: {'sessionId': _chatSessionId!, 'message': event.message},
    ).last;
    if (result is DataSuccess<String>) {
      final aiMessage = ChatMessage(text: result.data!, isUser: false);
      if (state is AppSuccess<PlantDetailData>) {
        final d = (state as AppSuccess<PlantDetailData>).data!;
        emit(
          AppSuccess(
            d.copyWith(
              chatMessages: [...d.chatMessages, aiMessage],
              isChatLoading: false,
            ),
          ),
        );
      }
    } else {
      final errorMessage = ChatMessage(
        text: 'Sorry, I encountered an error. Please try again.',
        isUser: false,
      );
      if (state is AppSuccess<PlantDetailData>) {
        final d = (state as AppSuccess<PlantDetailData>).data!;
        emit(
          AppSuccess(
            d.copyWith(
              chatMessages: [...d.chatMessages, errorMessage],
              isChatLoading: false,
            ),
          ),
        );
      }
    }
  }

  Future<void> _onStartOrbitRequested(
    PlantDetailStartOrbitRequested event,
    Emitter<AppState<PlantDetailData>> emit,
  ) async {
    if (state is! AppSuccess<PlantDetailData>) return;
    final currentData = (state as AppSuccess<PlantDetailData>).data!;
    emit(AppSuccess(currentData.copyWith(isOrbiting: true)));
    try {
      final optimalRange = _calculateOptimalRange(currentData.plant);
      await lgService.startOrbit(
        currentData.plant.latitude,
        currentData.plant.longitude,
        optimalRange,
        60,
      );
    } catch (e) {
      debugPrint('[LG] Failed to start orbit: $e');
      if (state is AppSuccess<PlantDetailData>) {
        final d = (state as AppSuccess<PlantDetailData>).data!;
        emit(AppSuccess(d.copyWith(isOrbiting: false)));
      }
    }
  }

  Future<void> _onStopOrbitRequested(
    PlantDetailStopOrbitRequested event,
    Emitter<AppState<PlantDetailData>> emit,
  ) async {
    if (state is! AppSuccess<PlantDetailData>) return;
    final currentData = (state as AppSuccess<PlantDetailData>).data!;
    emit(AppSuccess(currentData.copyWith(isOrbiting: false)));
    await lgService.stopOrbit();
  }

  double _calculateOptimalRange(PowerPlant plant) {
    double baseRange = 800;
    if (plant.capacityMw != null) {
      baseRange += 40 * math.sqrt(plant.capacityMw!);
    }
    switch (plant.primaryFuel) {
      case PlantType.hydro:
        baseRange *= 1.5;
        break;
      case PlantType.nuclear:
        baseRange *= 1.2;
        break;
      case PlantType.solar:
        baseRange *= 1.3;
        break;
      case PlantType.wind:
        baseRange *= 2.0;
        break;
      default:
        break;
    }
    if (baseRange < 400) return 400;
    if (baseRange > 15000) return 15000;
    return baseRange;
  }
}

class _TimeoutException implements Exception {
  const _TimeoutException();
  @override
  String toString() => 'Request timed out. Please try again.';
}
