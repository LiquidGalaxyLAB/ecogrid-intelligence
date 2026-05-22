import 'package:flutter/material.dart';
import 'package:ecogrid_intelligence/config/theme.dart';

class ClimateDashboardScreen extends StatelessWidget {
  const ClimateDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.dashboard, color: AppTheme.primary, size: 64),
              const SizedBox(height: 16),
              Text('Climate Dashboard', style: AppTheme.headingMedium),
              const SizedBox(height: 8),
              Text('Coming in Phase 7', style: AppTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
