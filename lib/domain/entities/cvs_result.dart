import 'package:equatable/equatable.dart';
import 'package:ecogrid_intelligence/core/enums/risk_level.dart';

/// Domain entity representing a computed Climate Vulnerability Score.
class CVSResult extends Equatable {
  final String plantId;
  final double score;
  final RiskLevel riskLevel;
  final double temperatureStress;
  final double waterStress;
  final double windStress;
  final DateTime computedAt;

  const CVSResult({
    required this.plantId,
    required this.score,
    required this.riskLevel,
    required this.temperatureStress,
    required this.waterStress,
    required this.windStress,
    required this.computedAt,
  });

  @override
  List<Object?> get props => [plantId, score, computedAt];
}
