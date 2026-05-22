import 'package:flutter/material.dart';
import 'package:ecogrid_intelligence/config/theme.dart';

class SimulationScreen extends StatelessWidget {
  final Map<String, dynamic>? arguments;
  const SimulationScreen({super.key, this.arguments});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    body: SafeArea(child: Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.science, color: AppTheme.primary, size: 64),
        const SizedBox(height: 16),
        Text('Scenario Simulation', style: AppTheme.headingMedium),
        const SizedBox(height: 8),
        Text('Coming in Phase 7', style: AppTheme.bodySmall),
      ],
    ))),
  );
}
