import 'package:flutter/material.dart';

enum HistoricalDataMode {
  fast,
  balanced,
  accurate,
}

extension HistoricalDataModeExtension on HistoricalDataMode {
  int get yearsBack {
    switch (this) {
      case HistoricalDataMode.fast:
        return 5;
      case HistoricalDataMode.balanced:
        return 10;
      case HistoricalDataMode.accurate:
        return 15;
    }
  }

  String get displayName {
    switch (this) {
      case HistoricalDataMode.fast:
        return 'Fast';
      case HistoricalDataMode.balanced:
        return 'Balanced';
      case HistoricalDataMode.accurate:
        return 'Accurate';
    }
  }

  String get description {
    switch (this) {
      case HistoricalDataMode.fast:
        return 'Last 5 years · Loads instantly';
      case HistoricalDataMode.balanced:
        return 'Last 10 years · Moderate detail';
      case HistoricalDataMode.accurate:
        return 'Last 15 years · Full picture';
    }
  }

  DateTime get startDate {
    final now = DateTime.now();
    return DateTime(now.year - yearsBack, 1, 1);
  }

  IconData get icon {
    switch (this) {
      case HistoricalDataMode.fast:
        return Icons.bolt_rounded;
      case HistoricalDataMode.balanced:
        return Icons.balance_rounded;
      case HistoricalDataMode.accurate:
        return Icons.track_changes_rounded;
    }
  }
}
