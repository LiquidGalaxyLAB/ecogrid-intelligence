import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ecogrid_intelligence/domain/model/power_plant.dart';
import 'package:ecogrid_intelligence/domain/model/climate_data.dart';
import 'package:ecogrid_intelligence/domain/model/cvs_result.dart';
import 'package:ecogrid_intelligence/domain/model/plant_context_payload.dart';
import 'package:ecogrid_intelligence/domain/model/lg_settings.dart';
import 'package:ecogrid_intelligence/domain/repository/cvs_repository.dart';
import 'package:ecogrid_intelligence/domain/repository/ai_repository.dart';
import 'package:ecogrid_intelligence/service/lg_service.dart';
import 'package:ecogrid_intelligence/domain/repository/climate_repository.dart';
import 'package:ecogrid_intelligence/core/enums/connection_status.dart';
import 'package:ecogrid_intelligence/core/enums/lg_display_mode.dart';
import 'package:ecogrid_intelligence/core/utils/kml_generator.dart';

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
  final CvsRepository cvsRepository;
  final AIRepository aiRepository;
  final LGService lgService;
  final ClimateRepository climateRepository;

  /// Active chat session (in-memory only, not persisted).
  String? _chatSessionId;

  PlantDetailBloc({
    required this.cvsRepository,
    required this.aiRepository,
    required this.lgService,
    required this.climateRepository,
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
    final plant = event.plant;

    // Step 1: Use unified single source of truth score
    final activeCvs = cvsRepository.getUnifiedScore(plant);

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
      final cvsFetchResult = await cvsRepository
          .getCvsForPlant(plant)
          .timeout(const Duration(seconds: 35));

      cvsFetchResult.fold(
        (failure) {
          debugPrint('[CVS] API climate fetch failed: ${failure.message}');
        },
        (computationResult) {
          if (state is PlantDetailLoaded) {
            emit(
              (state as PlantDetailLoaded).copyWith(
                climateData: computationResult.currentClimate,
                historicalData: computationResult.historicalData,
                // cvsResult is NOT replaced — unified score stays
                isLoadingCvs: false,
              ),
            );
          }
        },
      );
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
    // Guard: if LG is not connected, inform the UI and do nothing else.
    if (lgService.connectionStatus != ConnectionStatus.connected) {
      if (state is PlantDetailLoaded) {
        emit(
          (state as PlantDetailLoaded).copyWith(
            lgError: 'Liquid Galaxy not connected',
          ),
        );
      }
      return;
    }

    try {
      // 1. Always clear everything first.
      await lgService.clearKml();

      // 2. Fly camera to the exact plant location at tight zoom.
      //    altitude=50000m, heading=0, tilt=45°, range=50000.
      await lgService.flyTo(
        plant.latitude,
        plant.longitude,
        0, // altitude=0: target is at ground level (the plant itself)
        0, // heading=0: north-up
        45, // tilt=45: angled aerial perspective
        1000, // range=1000m: eye alt ≈ 707m — whole facility visible
      );

      // 3. Send single colour-coded pin to master screen.
      final pinKml = KMLGenerator.plantPinKml(
        plant: plant,
        riskLevel: cvs.riskLevel,
      );
      await lgService.sendKmlToMaster(pinKml);

      // 4. Load settings to get rightmost screen (generalised formula, no hardcoding).
      final settingsResult = await lgService.loadSettings();
      int screenCount = LGSettings.empty.screenCount;
      int rightmostScreen = LGSettings.empty.rightmostScreen;
      settingsResult.fold((_) => null, (settings) {
        screenCount = settings.screenCount;
        rightmostScreen = settings.rightmostScreen;
      });

      // 5. Compute the lon offset for the rightmost slave screen (same formula as region overlay).
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
      final balloonKml = KMLGenerator.plantDetailBalloon(
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
      // LG errors must never crash the plant analysis screen.
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
      final insightResult = await aiRepository
          .generatePlantInsight(context: context, isUserInitiated: true)
          .timeout(const Duration(seconds: 12));

      insightResult.fold(
        (failure) {
          if (state is PlantDetailLoaded) {
            emit(
              (state as PlantDetailLoaded).copyWith(
                isLoadingInsight: false,
                insightError: failure.message,
              ),
            );
          }
        },
        (insight) {
          if (state is PlantDetailLoaded) {
            emit(
              (state as PlantDetailLoaded).copyWith(
                aiInsight: insight,
                isLoadingInsight: false,
              ),
            );
          }
        },
      );
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
      final insightResult = await aiRepository.generateScenarioAnalysis(
        context: context,
        projectedCvs: event.projectedCvs,
        scenarioType: event.scenarioType,
      );

      insightResult.fold(
        (failure) {
          if (state is PlantDetailLoaded) {
            emit(
              (state as PlantDetailLoaded).copyWith(
                isLoadingInsight: false,
                insightError: failure.message,
              ),
            );
          }
        },
        (insight) {
          if (state is PlantDetailLoaded) {
            emit(
              (state as PlantDetailLoaded).copyWith(
                scenarioInsight: insight,
                isLoadingInsight: false,
              ),
            );
          }
        },
      );
    } catch (_) {
      if (state is PlantDetailLoaded) {
        emit((state as PlantDetailLoaded).copyWith(isLoadingInsight: false));
      }
    }
  }

  // ── Trend Data (unchanged — fetches climate data, not AI) ──

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
      final trendResult = await climateRepository
          .getMultiYearTrend(event.plant.latitude, event.plant.longitude)
          .timeout(const Duration(seconds: 75));

      trendResult.fold(
        (failure) {
          debugPrint('[Trend] Failed: ${failure.message}');
          if (state is PlantDetailLoaded) {
            emit((state as PlantDetailLoaded).copyWith(isLoadingTrend: false));
          }
        },
        (data) {
          if (state is PlantDetailLoaded) {
            emit(
              (state as PlantDetailLoaded).copyWith(
                trendData: data,
                isLoadingTrend: false,
              ),
            );
          }
        },
      );
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
      final result = await aiRepository
          .generateTrendInsight(context: context)
          .timeout(const Duration(seconds: 12));

      result.fold(
        (failure) {
          if (state is PlantDetailLoaded) {
            emit(
              (state as PlantDetailLoaded).copyWith(
                isLoadingTrendInsight: false,
              ),
            );
          }
        },
        (insight) {
          if (state is PlantDetailLoaded) {
            emit(
              (state as PlantDetailLoaded).copyWith(
                trendInsight: insight,
                isLoadingTrendInsight: false,
              ),
            );
          }
        },
      );
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
    _chatSessionId = aiRepository.startPlantChat(context: context);

    emit(currentState.copyWith(isChatActive: true, chatMessages: []));
  }

  Future<void> _onChatMessageSent(
    PlantDetailChatMessageSent event,
    Emitter<PlantDetailState> emit,
  ) async {
    if (state is! PlantDetailLoaded || _chatSessionId == null) return;
    final currentState = state as PlantDetailLoaded;

    // Add user message immediately
    final userMessage = ChatMessage(text: event.message, isUser: true);
    final updatedMessages = [...currentState.chatMessages, userMessage];

    emit(
      currentState.copyWith(chatMessages: updatedMessages, isChatLoading: true),
    );

    // Send to AI
    final result = await aiRepository.sendChatMessage(
      sessionId: _chatSessionId!,
      message: event.message,
    );

    result.fold(
      (failure) {
        final errorMessage = ChatMessage(
          text: 'Sorry, I encountered an error. Please try again.',
          isUser: false,
        );
        if (state is PlantDetailLoaded) {
          emit(
            (state as PlantDetailLoaded).copyWith(
              chatMessages: [
                ...(state as PlantDetailLoaded).chatMessages,
                errorMessage,
              ],
              isChatLoading: false,
            ),
          );
        }
      },
      (response) {
        final aiMessage = ChatMessage(text: response, isUser: false);
        if (state is PlantDetailLoaded) {
          emit(
            (state as PlantDetailLoaded).copyWith(
              chatMessages: [
                ...(state as PlantDetailLoaded).chatMessages,
                aiMessage,
              ],
              isChatLoading: false,
            ),
          );
        }
      },
    );
  }
}
