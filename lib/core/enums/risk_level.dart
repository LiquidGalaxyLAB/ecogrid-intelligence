import 'package:flutter/material.dart';
import 'package:ecogrid_intelligence/config/theme.dart';

/// Risk classification based on Climate Vulnerability Score (CVS).
enum RiskLevel {
  low(0, 25, 'LOW', AppTheme.riskLow),
  medium(26, 50, 'MEDIUM', AppTheme.riskMedium),
  high(51, 75, 'HIGH', AppTheme.riskHigh),
  critical(76, 100, 'CRITICAL', AppTheme.riskCritical);

  final int minScore;
  final int maxScore;
  final String label;
  final Color color;

  const RiskLevel(this.minScore, this.maxScore, this.label, this.color);

  /// Determine risk level from a CVS score (0-100).
  static RiskLevel fromScore(double score) {
    final clamped = score.clamp(0, 100).toInt();
    if (clamped <= 25) return RiskLevel.low;
    if (clamped <= 50) return RiskLevel.medium;
    if (clamped <= 75) return RiskLevel.high;
    return RiskLevel.critical;
  }
}
