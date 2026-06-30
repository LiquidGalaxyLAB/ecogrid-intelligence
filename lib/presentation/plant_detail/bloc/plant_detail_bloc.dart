import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
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
import '../../../domain/repository/cvs_repository.dart';

import '../../../core/enums/connection_status.dart';
import '../../../core/enums/lg_display_mode.dart';
import '../../../core/enums/historical_data_mode.dart';
import '../../../core/utils/kml_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Events ──────────────────────────────────────────────

abstract class PlantDetailEvent extends Equatable {
  const PlantDetailEvent();
  @override
  List<Object?> get props => [];
}

class PlantDetailLoadRequested extends PlantDetailEvent {
  final PowerPlant plant;
  const PlantDetailLoadRequested(this.plant);
  @override
  List<Object?> get props => [plant];
}

/// User explicitly tapped "Generate Insight" — this is the ONLY way
/// an AI insight call can fire on the plant detail screen.
class PlantDetailGenerateInsightRequested extends PlantDetailEvent {
  const PlantDetailGenerateInsightRequested();
}

class PlantDetailScenarioInsightRequested extends PlantDetailEvent {
  final double tempMultiplier;
  final double waterMultiplier;
  final double windMultiplier;
  final String scenarioType;
  final double projectedCvs;

  const PlantDetailScenarioInsightRequested({
    this.tempMultiplier = 1.0,
    this.waterMultiplier = 1.0,
    this.windMultiplier = 1.0,
    this.scenarioType = 'Custom',
    required this.projectedCvs,
  });

  @override
  List<Object?> get props => [
    tempMultiplier,
    waterMultiplier,
    windMultiplier,
    scenarioType,
    projectedCvs,
  ];
}

class PlantDetailTrendRequested extends PlantDetailEvent {
  final PowerPlant plant;
  const PlantDetailTrendRequested(this.plant);
  @override
  List<Object?> get props => [plant];
}

/// User explicitly tapped "Explain Trend" button.
class PlantDetailTrendInsightRequested extends PlantDetailEvent {
  const PlantDetailTrendInsightRequested();
}

/// User sent a chat message.
class PlantDetailChatMessageSent extends PlantDetailEvent {
  final String message;
  const PlantDetailChatMessageSent(this.message);
  @override
  List<Object?> get props => [message];
}

/// User opened the chat panel — initialise a new session.
class PlantDetailChatStarted extends PlantDetailEvent {
  const PlantDetailChatStarted();
}

/// Internal: Clears the lgError field after the UI has shown the SnackBar.
class PlantDetailClearLGError extends PlantDetailEvent {
  const PlantDetailClearLGError();
}

/// User requested to start LG orbit around the plant.
class PlantDetailStartOrbitRequested extends PlantDetailEvent {
  const PlantDetailStartOrbitRequested();
}

/// User requested to stop LG orbit.
class PlantDetailStopOrbitRequested extends PlantDetailEvent {
  const PlantDetailStopOrbitRequested();
}

// ─── Chat Message Model ──────────────────────────────────

class ChatMessage extends Equatable {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [text, isUser, timestamp];
}

// ─── States ──────────────────────────────────────────────

abstract class PlantDetailState extends Equatable {
  const PlantDetailState();
  @override
  List<Object?> get props => [];
}

class PlantDetailInitial extends PlantDetailState {
  const PlantDetailInitial();
}

class PlantDetailLoading extends PlantDetailState {
  const PlantDetailLoading();
}

class PlantDetailLoaded extends PlantDetailState {
  final PowerPlant plant;
  final ClimateData? climateData;
  final CVSResult? cvsResult;
  final String? aiInsight;
  final List<ClimateData> historicalData;
  final List<ClimateData> trendData;
  final double? projectedCvs;
  final String? scenarioInsight;
  final String? trendInsight;
  final bool isLoadingInsight;
  final bool isLoadingCvs;
  final bool isLoadingTrend;
  final bool isLoadingTrendInsight;
  final String? insightError;

  // Chat state
  final List<ChatMessage> chatMessages;
  final bool isChatLoading;
  final bool isChatActive;
  
  // LG interaction state
  final bool isOrbiting;

  /// Set when the LG sequence is skipped due to LG not being connected.
  /// The UI listens for this and shows a SnackBar, then it is cleared.
  final String? lgError;

  const PlantDetailLoaded({
    required this.plant,
    this.climateData,
    this.cvsResult,
    this.aiInsight,
    this.historicalData = const [],
    this.trendData = const [],
    this.projectedCvs,
    this.scenarioInsight,
    this.trendInsight,
    this.isLoadingInsight = false,
    this.isLoadingCvs = false,
    this.isLoadingTrend = false,
    this.isLoadingTrendInsight = false,
    this.insightError,
    this.chatMessages = const [],
    this.isChatLoading = false,
    this.isChatActive = false,
    this.isOrbiting = false,
    this.lgError,
  });

  @override
  List<Object?> get props => [
    plant,
    climateData,
    cvsResult,
    aiInsight,
    historicalData,
    trendData,
    projectedCvs,
    scenarioInsight,
    trendInsight,
    isLoadingInsight,
    isLoadingCvs,
    isLoadingTrend,
    isLoadingTrendInsight,
    insightError,
    chatMessages,
    isChatLoading,
    isChatActive,
    isOrbiting,
    lgError,
  ];

  PlantDetailLoaded copyWith({
    PowerPlant? plant,
    ClimateData? climateData,
    CVSResult? cvsResult,
    String? aiInsight,
    List<ClimateData>? historicalData,
    List<ClimateData>? trendData,
    double? projectedCvs,
    String? scenarioInsight,
    String? trendInsight,
    bool? isLoadingInsight,
    bool? isLoadingCvs,
    bool? isLoadingTrend,
    bool? isLoadingTrendInsight,
    String? insightError,
    List<ChatMessage>? chatMessages,
    bool? isChatLoading,
    bool? isChatActive,
    bool? isOrbiting,
    bool clearInsightError = false,
    String? lgError,
    bool clearLgError = false,
  }) {
    return PlantDetailLoaded(
      plant: plant ?? this.plant,
      climateData: climateData ?? this.climateData,
      cvsResult: cvsResult ?? this.cvsResult,
      aiInsight: aiInsight ?? this.aiInsight,
      historicalData: historicalData ?? this.historicalData,
      trendData: trendData ?? this.trendData,
      projectedCvs: projectedCvs ?? this.projectedCvs,
      scenarioInsight: scenarioInsight ?? this.scenarioInsight,
      trendInsight: trendInsight ?? this.trendInsight,
      isLoadingInsight: isLoadingInsight ?? this.isLoadingInsight,
      isLoadingCvs: isLoadingCvs ?? this.isLoadingCvs,
      isLoadingTrend: isLoadingTrend ?? this.isLoadingTrend,
      isLoadingTrendInsight:
          isLoadingTrendInsight ?? this.isLoadingTrendInsight,
      insightError: clearInsightError
          ? null
          : (insightError ?? this.insightError),
      chatMessages: chatMessages ?? this.chatMessages,
      isChatLoading: isChatLoading ?? this.isChatLoading,
      isChatActive: isChatActive ?? this.isChatActive,
      isOrbiting: isOrbiting ?? this.isOrbiting,
      lgError: clearLgError ? null : (lgError ?? this.lgError),
    );
  }
}

class PlantDetailError extends PlantDetailState {
  final String message;
  const PlantDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ────────────────────────────────────────────────

class PlantDetailBloc extends Bloc<PlantDetailEvent, PlantDetailState> {
  final LGService lgService;

  final GetUnifiedScoreUsecase getUnifiedScoreUsecase;
  final GetCvsForPlantUsecase getCvsForPlantUsecase;
  final GeneratePlantInsightUsecase generatePlantInsightUsecase;
  final GenerateScenarioAnalysisUsecase generateScenarioAnalysisUsecase;
  final GetMultiYearTrendUsecase getMultiYearTrendUsecase;
  final GenerateTrendInsightUsecase generateTrendInsightUsecase;
  final StartPlantChatUsecase startPlantChatUsecase;
  final SendChatMessageUsecase sendChatMessageUsecase;

  /// Active chat session (in-memory only, not persisted).
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
  }) : super(const PlantDetailInitial()) {
    on<PlantDetailLoadRequested>(_onLoadRequested);
    on<PlantDetailGenerateInsightRequested>(_onGenerateInsightRequested);
    on<PlantDetailScenarioInsightRequested>(_onScenarioInsightRequested);
    on<PlantDetailTrendRequested>(_onTrendRequested);
    on<PlantDetailTrendInsightRequested>(_onTrendInsightRequested);
    on<PlantDetailChatStarted>(_onChatStarted);
    on<PlantDetailChatMessageSent>(_onChatMessageSent);
    on<PlantDetailClearLGError>((event, emit) {
      if (state is PlantDetailLoaded) {
        emit((state as PlantDetailLoaded).copyWith(clearLgError: true));
      }
    });
    on<PlantDetailStartOrbitRequested>(_onStartOrbitRequested);
    on<PlantDetailStopOrbitRequested>(_onStopOrbitRequested);
  }

  /// Builds the PlantContextPayload from current state.
  PlantContextPayload? _buildContext() {
    if (state is! PlantDetailLoaded) return null;
    final s = state as PlantDetailLoaded;
    if (s.cvsResult == null) return null;

    return PlantContextPayload.fromEntities(
      plant: s.plant,
      cvs: s.cvsResult!,
      trendData: s.trendData.isNotEmpty ? s.trendData : null,
      activeScenarioType: s.scenarioInsight != null ? 'Custom' : null,
      scenarioProjectedCvs: s.projectedCvs,
    );
  }

  // ── Load Plant ──────────────────────────────────────────
  // CRITICAL: No AI calls here. Zero. Only CVS + climate data.

  Future<void> _onLoadRequested(
    PlantDetailLoadRequested event,
    Emitter<PlantDetailState> emit,
  ) async {
    emit(const PlantDetailLoading());



    final plant = event.plant;

    // Step 1: Use unified single source of truth score
    final activeCvs = getUnifiedScoreUsecase(plant);

    emit(
      PlantDetailLoaded(
        plant: plant,
        cvsResult: activeCvs,
        isLoadingCvs: false,
        // isLoadingInsight is FALSE — no auto-fetch
        isLoadingInsight: false,
      ),
    );

    // LG Sequence — fire-and-forget alongside data loading.
    // The plant analysis screen and LG sequence fire at the same time.
    _triggerPlantLGSequence(plant, activeCvs, emit);

    // Step 2: Try to fetch supplementary climate data
    // IMPORTANT: Do NOT replace cvsResult. The unified score is the single source of truth.
    try {
      final cvsFetchResult = await getCvsForPlantUsecase(params: plant)
          .timeout(const Duration(seconds: 35));

      if (cvsFetchResult is DataSuccess<CvsComputationResult>) {
        if (state is PlantDetailLoaded) {
          emit(
            (state as PlantDetailLoaded).copyWith(
              climateData: cvsFetchResult.data!.currentClimate,
              historicalData: cvsFetchResult.data!.historicalData,
              isLoadingCvs: false,
            ),
          );
        }
      } else {
        debugPrint('[CVS] API climate fetch failed: ${cvsFetchResult.exception}');
      }
    } catch (e) {
      debugPrint('[CVS] API climate fetch failed for ${plant.name}. Error: $e');
      if (state is PlantDetailLoaded) {
        emit((state as PlantDetailLoaded).copyWith(isLoadingCvs: false));
      }
    }

    // NO Step 3 — AI insight is NOT generated automatically.
    // The user must explicitly tap "Generate Insight".
  }

  // ── LG Plant Detail Sequence ────────────────────────────
  // Fires automatically when the plant analysis screen opens.
  // Sequence: clearKml → flyToPlant → sendPlantPin → showDetailOnRightScreen
  // If LG is not connected, emits lgError so the UI can show a SnackBar.

  Future<void> _triggerPlantLGSequence(
    PowerPlant plant,
    CVSResult cvs,
    Emitter<PlantDetailState> emit,
  ) async {
    // Guard: LG auto-sequence fires silently when not connected.
    // Only explicit user-triggered LG actions show the "not connected" toast.
    if (lgService.connectionStatus != ConnectionStatus.connected) return;

    try {
      // 1. Always clear everything first.
      await lgService.clearKml();

      // 2. Fly camera to the exact plant location.
      final optimalRange = _calculateOptimalRange(plant);
      await lgService.flyTo(
        plant.latitude,
        plant.longitude,
        0,
        0,
        0,
        optimalRange,
      );

      // 3. Send single colour-coded pin to master screen.
      final pinKml = KmlUtils.plantPinKml(
        plant: plant,
        riskLevel: cvs.riskLevel,
      );
      await lgService.sendKmlToMaster(pinKml);

      // 4. Load settings to get rightmost screen.
      final settingsResult = await lgService.loadSettings();
      int screenCount = LGSettings.empty.screenCount;
      int rightmostScreen = LGSettings.empty.rightmostScreen;
      if (settingsResult is DataSuccess<LGSettings>) {
        screenCount = settingsResult.data!.screenCount;
        rightmostScreen = settingsResult.data!.rightmostScreen;
      }

      // 5. Compute the lon offset for the rightmost slave screen.
      const offsetPerSideScreen = 10.0;
      final sideScreens = (screenCount - 1) / 2;
      final rightmostLonOffset =
          plant.longitude + (offsetPerSideScreen * sideScreens);
      final adjustedLon = rightmostLonOffset > 180.0
          ? rightmostLonOffset - 360.0
          : rightmostLonOffset;

      // 6. Get current climate data from state if already available.
      ClimateData? currentClimate;
      if (state is PlantDetailLoaded) {
        currentClimate = (state as PlantDetailLoaded).climateData;
      }

      // 7. Send full detail card to rightmost slave screen.
      final balloonKml = KmlUtils.plantDetailBalloon(
        plant: plant,
        cvs: cvs,
        lat: plant.latitude,
        lon: adjustedLon,
        climateData: currentClimate,
      );
      await lgService.showBalloonOnSlave(rightmostScreen, balloonKml);

      // 8. Update LG display mode tracker.
      lgService.setCurrentMode(LGDisplayMode.plantDetail);

      debugPrint('[LG] Plant detail sequence complete for ${plant.name}');
    } catch (e) {
      debugPrint('[LG] Plant detail sequence failed: $e');
    }
  }

  // ── Generate Plant Insight (button-triggered only) ─────

  Future<void> _onGenerateInsightRequested(
    PlantDetailGenerateInsightRequested event,
    Emitter<PlantDetailState> emit,
  ) async {
    if (state is! PlantDetailLoaded) return;
    final currentState = state as PlantDetailLoaded;

    final context = _buildContext();
    if (context == null) {
      emit(
        currentState.copyWith(
          insightError:
              'CVS data not yet available. Please wait for scoring to complete.',
        ),
      );
      return;
    }

    emit(
      currentState.copyWith(isLoadingInsight: true, clearInsightError: true),
    );

    try {
      final insightResult = await generatePlantInsightUsecase(
        params: {'context': context, 'isUserInitiated': true},
      ).timeout(const Duration(seconds: 12));

      if (insightResult is DataSuccess<String>) {
        if (state is PlantDetailLoaded) {
          emit((state as PlantDetailLoaded).copyWith(
            aiInsight: insightResult.data!,
            isLoadingInsight: false,
          ));
        }
      } else {
        if (state is PlantDetailLoaded) {
          emit((state as PlantDetailLoaded).copyWith(
            isLoadingInsight: false,
            insightError: insightResult.exception?.toString(),
          ));
        }
      }
    } catch (_) {
      if (state is PlantDetailLoaded) {
        emit(
          (state as PlantDetailLoaded).copyWith(
            isLoadingInsight: false,
            insightError: 'Request timed out. Please try again.',
          ),
        );
      }
    }
  }

  // ── Scenario Insight (already button-triggered) ────────

  Future<void> _onScenarioInsightRequested(
    PlantDetailScenarioInsightRequested event,
    Emitter<PlantDetailState> emit,
  ) async {
    if (state is! PlantDetailLoaded) return;
    final currentState = state as PlantDetailLoaded;

    final context = _buildContext();
    if (context == null) return;

    emit(
      currentState.copyWith(
        projectedCvs: event.projectedCvs,
        isLoadingInsight: true,
      ),
    );

    try {
      final insightResult = await generateScenarioAnalysisUsecase(
        params: {
          'context': context,
          'projectedCvs': event.projectedCvs,
          'scenarioType': event.scenarioType,
        },
      );

      if (insightResult is DataSuccess<String>) {
        if (state is PlantDetailLoaded) {
          emit((state as PlantDetailLoaded).copyWith(
            scenarioInsight: insightResult.data!,
            isLoadingInsight: false,
          ));
        }
      } else {
        if (state is PlantDetailLoaded) {
          emit((state as PlantDetailLoaded).copyWith(
            isLoadingInsight: false,
            insightError: insightResult.exception?.toString(),
          ));
        }
      }
    } catch (_) {
      if (state is PlantDetailLoaded) {
        emit((state as PlantDetailLoaded).copyWith(isLoadingInsight: false));
      }
    }
  }

  // ── Trend Data (unchanged — fetches climate data, not AI) ──

  List<ClimateData> _aggregateByYear(List<ClimateData> rawData) {
    final Map<int, List<ClimateData>> byYear = {};

    for (final d in rawData) {
      byYear.putIfAbsent(d.timestamp.year, () => []).add(d);
    }

    return byYear.entries.map((entry) {
      final year = entry.key;
      final points = entry.value;

      // Annual average for each metric
      final temps = points.where((d) => d.temperature != null)
          .map((d) => d.temperature!).toList();
      final precips = points.where((d) => d.precipitation != null)
          .map((d) => d.precipitation!).toList();
      final winds = points.where((d) => d.windSpeed != null)
          .map((d) => d.windSpeed!).toList();

      return ClimateData(
        latitude: points.first.latitude,
        longitude: points.first.longitude,
        timestamp: DateTime(year, 7, 1), // mid-year anchor point
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
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> _onTrendRequested(
    PlantDetailTrendRequested event,
    Emitter<PlantDetailState> emit,
  ) async {
    if (state is! PlantDetailLoaded) return;
    final currentState = state as PlantDetailLoaded;

    // Don't re-fetch if we already have trend data
    if (currentState.trendData.isNotEmpty || currentState.isLoadingTrend) {
      return;
    }

    emit(currentState.copyWith(isLoadingTrend: true));

    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt('historical_data_mode') ?? HistoricalDataMode.fast.index;
      final mode = HistoricalDataMode.values[modeIndex];

      final now = DateTime.now();
      final trendResult = await getMultiYearTrendUsecase(
        params: {
          'lat': event.plant.latitude,
          'lon': event.plant.longitude,
          'startDate': mode.startDate,
          'endDate': DateTime(now.year, 1, 1).subtract(const Duration(days: 1)),
        },
      ).timeout(const Duration(seconds: 75));

      if (trendResult is DataSuccess<List<ClimateData>>) {
        final aggregatedData = _aggregateByYear(trendResult.data!);
        if (state is PlantDetailLoaded) {
          emit((state as PlantDetailLoaded).copyWith(
            trendData: aggregatedData,
            isLoadingTrend: false,
          ));
        }
      } else {
        debugPrint('[Trend] Failed: ${trendResult.exception}');
        if (state is PlantDetailLoaded) {
          emit((state as PlantDetailLoaded).copyWith(isLoadingTrend: false));
        }
      }
    } catch (e) {
      debugPrint('[Trend] Error: $e');
      if (state is PlantDetailLoaded) {
        emit((state as PlantDetailLoaded).copyWith(isLoadingTrend: false));
      }
    }
  }

  // ── Trend Insight (button-triggered only) ──────────────

  Future<void> _onTrendInsightRequested(
    PlantDetailTrendInsightRequested event,
    Emitter<PlantDetailState> emit,
  ) async {
    if (state is! PlantDetailLoaded) return;
    final currentState = state as PlantDetailLoaded;

    final context = _buildContext();
    if (context == null) return;

    emit(currentState.copyWith(isLoadingTrendInsight: true));

    try {
      final result = await generateTrendInsightUsecase(
        params: context,
      ).timeout(const Duration(seconds: 12));

      if (result is DataSuccess<String>) {
        if (state is PlantDetailLoaded) {
          emit((state as PlantDetailLoaded).copyWith(
            trendInsight: result.data!,
            isLoadingTrendInsight: false,
          ));
        }
      } else {
        if (state is PlantDetailLoaded) {
          emit((state as PlantDetailLoaded).copyWith(isLoadingTrendInsight: false));
        }
      }
    } catch (_) {
      if (state is PlantDetailLoaded) {
        emit(
          (state as PlantDetailLoaded).copyWith(isLoadingTrendInsight: false),
        );
      }
    }
  }

  // ── Chat ───────────────────────────────────────────────

  Future<void> _onChatStarted(
    PlantDetailChatStarted event,
    Emitter<PlantDetailState> emit,
  ) async {
    if (state is! PlantDetailLoaded) return;
    final currentState = state as PlantDetailLoaded;

    final context = _buildContext();
    if (context == null) return;

    // Start a fresh chat session (not persisted between sessions)
    _chatSessionId = startPlantChatUsecase(context: context);

    emit(currentState.copyWith(isChatActive: true, chatMessages: []));
  }

  Future<void> _onChatMessageSent(
    PlantDetailChatMessageSent event,
    Emitter<PlantDetailState> emit,
  ) async {
    if (state is! PlantDetailLoaded || _chatSessionId == null) return;
    final currentState = state as PlantDetailLoaded;

    emit(const PlantDetailLoading());



    // Add user message immediately
    final userMessage = ChatMessage(text: event.message, isUser: true);
    final updatedMessages = [...currentState.chatMessages, userMessage];

    emit(
      currentState.copyWith(chatMessages: updatedMessages, isChatLoading: true),
    );

    // Send to AI
    final result = await sendChatMessageUsecase(
      params: {
        'sessionId': _chatSessionId!,
        'message': event.message,
      },
    );

    if (result is DataSuccess<String>) {
      final aiMessage = ChatMessage(text: result.data!, isUser: false);
      if (state is PlantDetailLoaded) {
        emit((state as PlantDetailLoaded).copyWith(
          chatMessages: [...(state as PlantDetailLoaded).chatMessages, aiMessage],
          isChatLoading: false,
        ));
      }
    } else {
      final errorMessage = ChatMessage(
        text: 'Sorry, I encountered an error. Please try again.',
        isUser: false,
      );
      if (state is PlantDetailLoaded) {
        emit((state as PlantDetailLoaded).copyWith(
          chatMessages: [...(state as PlantDetailLoaded).chatMessages, errorMessage],
          isChatLoading: false,
        ));
      }
    }
  }

  // ── LG Orbit ───────────────────────────────────────────

  Future<void> _onStartOrbitRequested(
    PlantDetailStartOrbitRequested event,
    Emitter<PlantDetailState> emit,
  ) async {
    if (state is! PlantDetailLoaded) return;
    final currentState = state as PlantDetailLoaded;
    
    emit(currentState.copyWith(isOrbiting: true));
    
    try {
      final optimalRange = _calculateOptimalRange(currentState.plant);
      await lgService.startOrbit(
        currentState.plant.latitude,
        currentState.plant.longitude,
        optimalRange,
        60,   // tilt
      );
    } catch (e) {
      debugPrint('[LG] Failed to start orbit: $e');
      if (state is PlantDetailLoaded) {
        emit((state as PlantDetailLoaded).copyWith(isOrbiting: false));
      }
    }
  }

  Future<void> _onStopOrbitRequested(
    PlantDetailStopOrbitRequested event,
    Emitter<PlantDetailState> emit,
  ) async {
    if (state is! PlantDetailLoaded) return;
    final currentState = state as PlantDetailLoaded;
    
    // Update state immediately so button shows "Start Orbit" at once
    emit(currentState.copyWith(isOrbiting: false));
    
    // Just stop the tour — don't re-trigger the full plant sequence
    // which would cause the camera to fly back to start position
    await lgService.stopOrbit();
  }

  /// Calculates the optimal camera altitude (range) based on plant capacity and type.
  /// Larger capacity plants (e.g., nuclear, large hydro) require wider fields of view.
  double _calculateOptimalRange(PowerPlant plant) {
    double baseRange = 800; // Minimum default range

    // Scale linearly with the square root of capacity to match area expansion
    if (plant.capacityMw != null) {
      baseRange += 40 * math.sqrt(plant.capacityMw!);
    }

    // Apply plant-type specific scaling multipliers
    switch (plant.primaryFuel) {
      case PlantType.hydro:
        baseRange *= 1.5; // Dams/reservoirs stretch very far
        break;
      case PlantType.nuclear:
        baseRange *= 1.2; // Large exclusion zones
        break;
      case PlantType.solar:
        baseRange *= 1.3; // Solar farms are horizontally sprawling
        break;
      case PlantType.wind:
        baseRange *= 2.0; // Wind farms take up vast geographic areas
        break;
      default:
        break;
    }

    // Clamp the range to reasonable minimum and maximum altitudes
    if (baseRange < 400) return 400;
    if (baseRange > 15000) return 15000;
    
    return baseRange;
  }
}
