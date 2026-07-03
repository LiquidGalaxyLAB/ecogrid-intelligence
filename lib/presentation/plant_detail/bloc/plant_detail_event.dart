import 'package:equatable/equatable.dart';
import '../../../domain/model/power_plant.dart';

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

class PlantDetailTrendInsightRequested extends PlantDetailEvent {
  const PlantDetailTrendInsightRequested();
}

class PlantDetailChatMessageSent extends PlantDetailEvent {
  final String message;
  const PlantDetailChatMessageSent(this.message);
  @override
  List<Object?> get props => [message];
}

class PlantDetailChatStarted extends PlantDetailEvent {
  const PlantDetailChatStarted();
}

class PlantDetailClearLGError extends PlantDetailEvent {
  const PlantDetailClearLGError();
}

class PlantDetailStartOrbitRequested extends PlantDetailEvent {
  const PlantDetailStartOrbitRequested();
}

class PlantDetailStopOrbitRequested extends PlantDetailEvent {
  const PlantDetailStopOrbitRequested();
}
