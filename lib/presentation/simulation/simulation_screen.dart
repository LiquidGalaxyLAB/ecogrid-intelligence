import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../config/theme/app_theme.dart';
import '../plant_detail/bloc/plant_detail_bloc.dart';
import '../../core/enums/risk_level.dart';
import '../../core/enums/plant_type.dart';
import '../../core/utils/cvs_calculator.dart';

enum SimulationMode { simulateImpact, pathToDanger }

class ScenarioSimulationScreen extends StatefulWidget {
  final PlantDetailBloc bloc;
  const ScenarioSimulationScreen({super.key, required this.bloc});

  @override
  State<ScenarioSimulationScreen> createState() =>
      _ScenarioSimulationScreenState();
}

class _ScenarioSimulationScreenState extends State<ScenarioSimulationScreen> {
  @override
  void initState() {
    super.initState();
    Logger().i('[UI] Opened ScenarioSimulationScreen');
  }

  SimulationMode _currentMode = SimulationMode.simulateImpact;
  String _selectedScenario = 'Business as Usual';
  double _tempMultiplier = 1.0;
  double _waterMultiplier = 1.0;
  double _windMultiplier = 1.0;

  void _generateInsight(double projectedCvs) {
    widget.bloc.add(
      PlantDetailScenarioInsightRequested(
        tempMultiplier: _tempMultiplier,
        waterMultiplier: _waterMultiplier,
        windMultiplier: _windMultiplier,
        scenarioType: _selectedScenario,
        projectedCvs: projectedCvs,
      ),
    );
  }

  void _selectPreset(String scenario, double temp, double water, double wind) {
    setState(() {
      _selectedScenario = scenario;
      _tempMultiplier = temp;
      _waterMultiplier = water;
      _windMultiplier = wind;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: BlocBuilder<PlantDetailBloc, PlantDetailState>(
        builder: (context, state) {
          if (state is! PlantDetailLoaded) {
            return Scaffold(
              backgroundColor: AppTheme.background,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final plant = state.plant;
          final baseCvs = state.cvsResult?.score ?? 0.0;
          final baseAnomalies = CVSCalculator.generateBaseAnomalies(
            plant.latitude,
            plant.longitude,
          );

          final projectedCvs = CVSCalculator.simulateScenario(
            plantType: plant.primaryFuel,
            tempAnomaly: baseAnomalies['temp'] ?? 0.15,
            waterAnomaly: baseAnomalies['water'] ?? 0.15,
            windAnomaly: baseAnomalies['wind'] ?? 0.15,
            tempMultiplier: _tempMultiplier,
            waterMultiplier: _waterMultiplier,
            windMultiplier: _windMultiplier,
          );

          final worstCaseCvs = CVSCalculator.calculateWorstCase(
            plant.primaryFuel,
            baseAnomalies,
          );

          final consequences = CVSCalculator.calculateHumanConsequences(
            plantType: plant.primaryFuel,
            baseCvs: baseCvs,
            projectedCvs: projectedCvs,
            tempMultiplier: _tempMultiplier,
            waterMultiplier: _waterMultiplier,
            windMultiplier: _windMultiplier,
          );

          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              backgroundColor: AppTheme.surface,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Climate Scenario Simulation',
                style: AppTheme.headingSmall,
              ),
              centerTitle: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.primary.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mode Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _ModeToggle(
                                  title: 'Simulate Impact',
                                  isSelected:
                                      _currentMode ==
                                      SimulationMode.simulateImpact,
                                  onTap: () => setState(
                                    () => _currentMode =
                                        SimulationMode.simulateImpact,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _ModeToggle(
                                  title: 'Path to Danger',
                                  isSelected:
                                      _currentMode ==
                                      SimulationMode.pathToDanger,
                                  onTap: () => setState(
                                    () => _currentMode =
                                        SimulationMode.pathToDanger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingLG),

                        if (_currentMode == SimulationMode.simulateImpact) ...[
                          // 3-Column Comparison
                          Text(
                            'Scenario Comparison',
                            style: AppTheme.labelSmall,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _ScoreColumn(
                                  title: 'Current',
                                  score: baseCvs,
                                  subtitle: 'Baseline',
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: AppTheme.cardBorder,
                              ),
                              Expanded(
                                child: _ScoreColumn(
                                  title: 'Simulated',
                                  score: projectedCvs,
                                  subtitle: _selectedScenario,
                                  isHighlight: true,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: AppTheme.cardBorder,
                              ),
                              Expanded(
                                child: _ScoreColumn(
                                  title: 'Worst Case',
                                  score: worstCaseCvs,
                                  subtitle: 'Catastrophic shutdown likely',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppTheme.spacingLG),

                          // Tangible Human Consequences
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingMD),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: AppTheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Estimated Real-world Impact',
                                      style: AppTheme.headingSmall.copyWith(
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _ConsequenceRow(
                                  icon: Icons.bolt,
                                  label: 'Output Capacity',
                                  value: consequences['outputReduction']!,
                                ),
                                const SizedBox(height: 8),
                                _ConsequenceRow(
                                  icon: Icons.water_drop,
                                  label: 'Cooling Demand',
                                  value: consequences['waterDemand']!,
                                ),
                                const SizedBox(height: 8),
                                _ConsequenceRow(
                                  icon: Icons.health_and_safety,
                                  label: 'Operational Risk',
                                  value: consequences['operationalRisk']!,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingLG),

                          // Presets
                          Text('Select Scenario', style: AppTheme.labelSmall),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _PresetCard(
                                icon: Icons.auto_graph,
                                title: 'Business as Usual',
                                subtitle: 'Current trajectory',
                                isSelected:
                                    _selectedScenario == 'Business as Usual',
                                onTap: () => _selectPreset(
                                  'Business as Usual',
                                  1.0,
                                  1.0,
                                  1.0,
                                ),
                              ),
                              _PresetCard(
                                icon: Icons.trending_up,
                                title: '2050 Projection',
                                subtitle: 'IPCC RCP8.5',
                                isSelected:
                                    _selectedScenario == '2050 Projection',
                                onTap: () => _selectPreset(
                                  '2050 Projection',
                                  1.8,
                                  1.4,
                                  1.2,
                                ),
                              ),
                              _PresetCard(
                                icon: Icons.local_fire_department,
                                title: 'Extreme Heatwave',
                                subtitle: '+12°C peak',
                                isSelected:
                                    _selectedScenario == 'Extreme Heatwave',
                                onTap: () => _selectPreset(
                                  'Extreme Heatwave',
                                  2.5,
                                  1.5,
                                  1.0,
                                ),
                              ),
                              _PresetCard(
                                icon: Icons.water_drop,
                                title: 'Severe Drought',
                                subtitle: '-60% rainfall',
                                isSelected:
                                    _selectedScenario == 'Severe Drought',
                                onTap: () => _selectPreset(
                                  'Severe Drought',
                                  1.2,
                                  2.5,
                                  1.0,
                                ),
                              ),
                              _PresetCard(
                                icon: Icons.storm,
                                title: 'Monsoon Flood',
                                subtitle: 'Extreme precipitation',
                                isSelected:
                                    _selectedScenario == 'Monsoon Flood',
                                onTap: () => _selectPreset(
                                  'Monsoon Flood',
                                  1.0,
                                  2.0,
                                  2.5,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppTheme.spacingLG),
                        ] else ...[
                          // Path to Danger Mode
                          _PathToDangerView(
                            plantType: plant.primaryFuel,
                            baseAnomalies: baseAnomalies,
                            currentCvs: baseCvs,
                            onApplyScenario: (tMult, wMult) {
                              setState(() {
                                _currentMode = SimulationMode.simulateImpact;
                                _selectedScenario = 'Threshold Scenario';
                                _tempMultiplier = tMult;
                                _waterMultiplier = wMult;
                                _windMultiplier = 1.0;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Fixed bottom action container
                if (_currentMode == SimulationMode.simulateImpact)
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLG),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: Border(
                        top: BorderSide(color: AppTheme.cardBorder, width: 1.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          offset: const Offset(0, -4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child:
                        (state.scenarioInsight != null ||
                            state.isLoadingInsight)
                        ? _ShareableInsightCard(
                            plantName: plant.name,
                            scenarioName: _selectedScenario,
                            baseCvs: baseCvs,
                            projectedCvs: projectedCvs,
                            consequence: consequences['outputReduction']!,
                            insight: state.scenarioInsight,
                            isLoading: state.isLoadingInsight,
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              icon: Icon(
                                Icons.auto_awesome,
                                color: AppTheme.primary,
                              ),
                              label: Text(
                                'Generate AI Analysis',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 1.5,
                                ),
                                backgroundColor: AppTheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => _generateInsight(projectedCvs),
                            ),
                          ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeToggle({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: AppTheme.bodySmall.copyWith(
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _ScoreColumn extends StatelessWidget {
  final String title;
  final double score;
  final String subtitle;
  final bool isHighlight;

  const _ScoreColumn({
    required this.title,
    required this.score,
    required this.subtitle,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        children: [
          Text(title, style: AppTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            score.toStringAsFixed(1),
            style: isHighlight
                ? AppTheme.headingLarge.copyWith(
                    color: RiskLevel.fromScore(score).color,
                    fontSize: 32,
                  )
                : AppTheme.headingMedium.copyWith(
                    color: RiskLevel.fromScore(score).color,
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTheme.labelSmall.copyWith(
              fontSize: 10,
              color: AppTheme.textMuted,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ConsequenceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ConsequenceRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTheme.bodySmall,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PresetCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 50% width minus spacing
    final width =
        (MediaQuery.of(context).size.width - (AppTheme.spacingLG * 2) - 12) / 2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTheme.labelSmall.copyWith(
                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textMuted,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PathToDangerView extends StatelessWidget {
  final PlantType plantType;
  final Map<String, double> baseAnomalies;
  final double currentCvs;
  final Function(double tMult, double wMult) onApplyScenario;

  const _PathToDangerView({
    required this.plantType,
    required this.baseAnomalies,
    required this.currentCvs,
    required this.onApplyScenario,
  });

  @override
  Widget build(BuildContext context) {
    final result = CVSCalculator.findPathToDanger(
      plantType,
      baseAnomalies,
      currentCvs,
    );

    if (result == null) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "This plant is already in the High Risk category.",
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.error),
        ),
      );
    }

    final isResilient = result['tempMultiplier'] == 3.0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isResilient ? Icons.shield : Icons.warning_rounded,
                color: isResilient ? AppTheme.success : Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Threshold Analysis',
                  style: AppTheme.headingMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            result['message'],
            style: AppTheme.bodyMedium.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          if (!isResilient)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => onApplyScenario(
                  result['tempMultiplier'],
                  result['waterMultiplier'],
                ),
                child: Text('Apply This Scenario'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShareableInsightCard extends StatelessWidget {
  final String plantName;
  final String scenarioName;
  final double baseCvs;
  final double projectedCvs;
  final String consequence;
  final String? insight;
  final bool isLoading;

  const _ShareableInsightCard({
    required this.plantName,
    required this.scenarioName,
    required this.baseCvs,
    required this.projectedCvs,
    required this.consequence,
    required this.insight,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ECOGRID INTELLIGENCE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppTheme.primary,
                ),
              ),
              Icon(Icons.share, size: 16, color: AppTheme.textMuted),
            ],
          ),
          const SizedBox(height: 12),
          Text(plantName, style: AppTheme.headingMedium),
          Text(
            'Scenario: $scenarioName',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniScore(label: 'Baseline', score: baseCvs),
              Icon(Icons.arrow_forward, size: 16, color: AppTheme.textMuted),
              _MiniScore(label: 'Projected', score: projectedCvs),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(child: Text(consequence, style: AppTheme.bodySmall)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else
            Text(
              insight ?? '',
              style: AppTheme.bodySmall.copyWith(
                height: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  final String label;
  final double score;

  const _MiniScore({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTheme.labelSmall),
        Text(
          score.toStringAsFixed(1),
          style: AppTheme.headingMedium.copyWith(
            color: RiskLevel.fromScore(score).color,
          ),
        ),
      ],
    );
  }
}
