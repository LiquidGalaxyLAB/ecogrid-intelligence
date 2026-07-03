import 'package:flutter/material.dart';
import '../../config/theme/app_theme.dart';

enum RiskLevel {
  low(0, 33, 'LOW', AppTheme.riskLow),
  medium(34, 66, 'MEDIUM', AppTheme.riskMedium),
  high(67, 100, 'HIGH', AppTheme.riskHigh);

  final int minScore;
  final int maxScore;
  final String label;
  final Color color;
  const RiskLevel(this.minScore, this.maxScore, this.label, this.color);
  static RiskLevel fromScore(double score) {
    final clamped = score.clamp(0, 100).toInt();
    if (clamped <= 33) return RiskLevel.low;
    if (clamped <= 66) return RiskLevel.medium;
    return RiskLevel.high;
  }
}
