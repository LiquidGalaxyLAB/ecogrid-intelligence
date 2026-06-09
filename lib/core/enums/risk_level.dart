import 'package:flutter/material.dart';

/// Risk classification based on Climate Vulnerability Score (CVS).
enum RiskLevel {
  low(0, 33, 'LOW', Color(0xFF00E5A0)),
  medium(34, 66, 'MEDIUM', Color(0xFFFFB020)),
  high(67, 100, 'HIGH', Color(0xFFFF4D4D));

  final int minScore;
  final int maxScore;
  final String label;
  final Color color;

  const RiskLevel(this.minScore, this.maxScore, this.label, this.color);

  /// Determine risk level from a CVS score (0-100).
  static RiskLevel fromScore(double score) {
    final clamped = score.clamp(0, 100).toInt();
    if (clamped <= 33) return RiskLevel.low;
    if (clamped <= 66) return RiskLevel.medium;
    return RiskLevel.high;
  }
}
