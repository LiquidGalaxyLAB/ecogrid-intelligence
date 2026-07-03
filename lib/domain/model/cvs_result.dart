import 'package:equatable/equatable.dart';
import '../../core/enums/risk_level.dart';

class CVSResult extends Equatable {
  final String plantId;
  final double score;
  final RiskLevel riskLevel;
  final double temperatureStress;
  final double waterStress;
  final double windStress;
  final DateTime computedAt;
  final bool isVerified;
  const CVSResult({
    required this.plantId,
    required this.score,
    required this.riskLevel,
    required this.temperatureStress,
    required this.waterStress,
    required this.windStress,
    required this.computedAt,
    this.isVerified = false,
  });
  @override
  List<Object?> get props => [plantId, score, computedAt, isVerified];
}
