import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ecogrid_intelligence/config/theme.dart';
import 'package:ecogrid_intelligence/core/enums/risk_level.dart';
import 'package:ecogrid_intelligence/domain/entities/power_plant.dart';
import 'package:ecogrid_intelligence/di/injection_container.dart';
import 'package:ecogrid_intelligence/presentation/blocs/plant_detail/plant_detail_bloc.dart';
import 'package:ecogrid_intelligence/service/tts_service.dart';
import 'package:ecogrid_intelligence/domain/entities/cvs_result.dart';

class PlantDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? arguments;
  const PlantDetailScreen({super.key, this.arguments});

  @override
  Widget build(BuildContext context) {
    final plant = arguments?['plant'] as PowerPlant?;
    if (plant == null) {
      return const Scaffold(
        body: Center(child: Text('Plant not found')),
      );
    }

    return BlocProvider(
      create: (_) =>
          sl<PlantDetailBloc>()..add(PlantDetailLoadRequested(plant)),
      child: const _PlantDetailBody(),
    );
  }
}

class _PlantDetailBody extends StatelessWidget {
  const _PlantDetailBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: BlocBuilder<PlantDetailBloc, PlantDetailState>(
          builder: (context, state) {
            if (state is PlantDetailLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }
            if (state is PlantDetailError) {
              return Center(
                child: Text(state.message, style: AppTheme.bodyMedium),
              );
            }
            if (state is PlantDetailLoaded) {
              return _buildLoaded(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, PlantDetailLoaded state) {
    final plant = state.plant;
    final cvs = state.cvsResult;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Nav Bar ──────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        size: 18, color: AppTheme.textPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight.withValues(alpha: 0.5),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(
                          color: AppTheme.cardBorder.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt,
                            color: AppTheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            plant.name,
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Plant Overview Card ──────────────────
          _buildOverviewCard(plant),
          const SizedBox(height: 16),

          // ── CVS + Environmental Stress Card ──────
          if (cvs != null) _buildCVSCard(cvs),
          const SizedBox(height: 16),

          // ── AI Climate Insight ───────────────────
          _buildAIInsightPanel(context, state),
          const SizedBox(height: 16),

          // ── Historical Climate Trends ────────────
          if (state.historicalData.isNotEmpty)
            _buildHistoricalChart(state),
          const SizedBox(height: 16),

          // ── Scenario Simulation ──────────────────
          _buildScenarioSection(context, state),
          const SizedBox(height: AppTheme.spacingXXL),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(PowerPlant plant) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PLANT OVERVIEW',
                style: AppTheme.labelSmall
                    .copyWith(letterSpacing: 2, color: AppTheme.textMuted)),
            const SizedBox(height: 12),
            Text(plant.name, style: AppTheme.headingMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.location_on,
                  label: plant.countryLong ?? plant.country,
                ),
                _InfoChip(
                  icon: Icons.category,
                  label: plant.primaryFuel.displayName,
                ),
                if (plant.capacityMw != null)
                  _InfoChip(
                    icon: Icons.bolt,
                    label: '${plant.capacityMw!.toStringAsFixed(0)} MW',
                  ),
                if (plant.commissioningYear != null)
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: '${plant.commissioningYear}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCVSCard(CVSResult cvs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: cvs.riskLevel.color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CVS SCORE',
                        style: AppTheme.labelSmall
                            .copyWith(letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text(
                      cvs.score.toStringAsFixed(1),
                      style: AppTheme.headingLarge.copyWith(
                        fontSize: 48,
                        color: cvs.riskLevel.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: cvs.riskLevel.color.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: cvs.riskLevel.color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    cvs.riskLevel.label,
                    style: AppTheme.labelLarge.copyWith(
                      color: cvs.riskLevel.color,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _StressBar(
                label: 'Temperature Stress',
                value: cvs.temperatureStress,
                color: const Color(0xFFFF6B6B)),
            const SizedBox(height: 10),
            _StressBar(
                label: 'Water Stress',
                value: cvs.waterStress,
                color: const Color(0xFF4ECDC4)),
            const SizedBox(height: 10),
            _StressBar(
                label: 'Wind Stress',
                value: cvs.windStress,
                color: const Color(0xFF45B7D1)),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsightPanel(
      BuildContext context, PlantDetailLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: AppTheme.cardDecorationGlow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('AI CLIMATE INSIGHT',
                    style: AppTheme.labelSmall
                        .copyWith(letterSpacing: 2)),
                const Spacer(),
                if (state.aiInsight != null)
                  GestureDetector(
                    onTap: () {
                      sl<TTSService>().speak(state.aiInsight!);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color:
                            AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Icon(Icons.volume_up,
                          color: AppTheme.primary, size: 18),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.isLoadingInsight)
              const LinearProgressIndicator(
                color: AppTheme.primary,
                backgroundColor: AppTheme.surfaceLight,
              )
            else if (state.aiInsight != null)
              Text(
                state.aiInsight!,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              )
            else
              Text('Analysis unavailable.',
                  style: AppTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricalChart(PlantDetailLoaded state) {
    final data = state.historicalData;
    if (data.isEmpty) return const SizedBox.shrink();

    // Sample every 30 days for chart readability
    final sampled = <FlSpot>[];
    for (int i = 0; i < data.length; i += 30) {
      if (data[i].temperature != null) {
        sampled.add(FlSpot(i.toDouble(), data[i].temperature!));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HISTORICAL CLIMATE TRENDS',
                style:
                    AppTheme.labelSmall.copyWith(letterSpacing: 2)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.cardBorder.withValues(alpha: 0.3),
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}°',
                          style: AppTheme.caption.copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: sampled,
                      isCurved: true,
                      color: AppTheme.riskHigh,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.riskHigh.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioSection(
      BuildContext context, PlantDetailLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SCENARIO SIMULATION',
                style:
                    AppTheme.labelSmall.copyWith(letterSpacing: 2)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ScenarioButton(
                  label: '🔥 Heatwave',
                  onTap: () => context.read<PlantDetailBloc>().add(
                        const PlantDetailScenarioSimulated(
                          tempMultiplier: 1.8,
                          scenarioType: 'Extreme Heatwave',
                        ),
                      ),
                ),
                _ScenarioButton(
                  label: '🏜️ Drought',
                  onTap: () => context.read<PlantDetailBloc>().add(
                        const PlantDetailScenarioSimulated(
                          waterMultiplier: 2.0,
                          scenarioType: 'Severe Drought',
                        ),
                      ),
                ),
                _ScenarioButton(
                  label: '🌪️ Wind Event',
                  onTap: () => context.read<PlantDetailBloc>().add(
                        const PlantDetailScenarioSimulated(
                          windMultiplier: 2.5,
                          scenarioType: 'Extreme Wind Event',
                        ),
                      ),
                ),
              ],
            ),
            if (state.projectedCvs != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  children: [
                    Text('Projected CVS: ',
                        style: AppTheme.bodyMedium),
                    Text(
                      state.projectedCvs!.toStringAsFixed(1),
                      style: AppTheme.headingSmall.copyWith(
                        color: RiskLevel.fromScore(state.projectedCvs!)
                            .color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: RiskLevel.fromScore(state.projectedCvs!)
                            .color
                            .withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        RiskLevel.fromScore(state.projectedCvs!).label,
                        style: AppTheme.caption.copyWith(
                          color: RiskLevel.fromScore(state.projectedCvs!)
                              .color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (state.scenarioInsight != null) ...[
              const SizedBox(height: 12),
              Text(
                state.scenarioInsight!,
                style: AppTheme.bodySmall.copyWith(height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Shared Widgets ─────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.bodySmall),
      ],
    );
  }
}

class _StressBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _StressBar(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.bodySmall),
            Text('${value.toStringAsFixed(1)}%',
                style: AppTheme.labelLarge
                    .copyWith(color: color, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: AppTheme.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _ScenarioButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ScenarioButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child:
            Text(label, style: AppTheme.bodySmall.copyWith(fontSize: 13)),
      ),
    );
  }
}

