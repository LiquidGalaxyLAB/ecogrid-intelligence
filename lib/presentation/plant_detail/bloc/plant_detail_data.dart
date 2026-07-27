import 'package:equatable/equatable.dart';
import '../../../domain/model/power_plant.dart';
import '../../../domain/model/climate_data.dart';
import '../../../domain/model/cvs_result.dart';

class ChatMessage extends Equatable {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
  @override
  List<Object?> get props => [text, isUser, timestamp];
}

class PlantDetailData extends Equatable {
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
  final List<ChatMessage> chatMessages;
  final bool isChatLoading;
  final bool isChatActive;
  final bool isOrbiting;
  final String? lgError;
  const PlantDetailData({
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
  PlantDetailData copyWith({
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
    bool clearAiInsight = false,
    bool clearScenarioInsight = false,
    bool clearTrendInsight = false,
  }) {
    return PlantDetailData(
      plant: plant ?? this.plant,
      climateData: climateData ?? this.climateData,
      cvsResult: cvsResult ?? this.cvsResult,
      aiInsight: clearAiInsight ? null : (aiInsight ?? this.aiInsight),
      historicalData: historicalData ?? this.historicalData,
      trendData: trendData ?? this.trendData,
      projectedCvs: projectedCvs ?? this.projectedCvs,
      scenarioInsight: clearScenarioInsight ? null : (scenarioInsight ?? this.scenarioInsight),
      trendInsight: clearTrendInsight ? null : (trendInsight ?? this.trendInsight),
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
