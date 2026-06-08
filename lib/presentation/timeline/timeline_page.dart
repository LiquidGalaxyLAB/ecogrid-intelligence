import 'package:flutter/material.dart';
import 'package:ecogrid_intelligence/config/theme/app_theme.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, color: AppTheme.primary, size: 64),
            const SizedBox(height: 16),
            Text('Climate Anomaly Timeline', style: AppTheme.headingMedium),
            const SizedBox(height: 8),
            Text('Coming in Phase 7', style: AppTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}
