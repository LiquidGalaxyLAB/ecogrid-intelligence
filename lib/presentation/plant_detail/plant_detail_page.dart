import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:ecogrid_intelligence/config/theme/app_theme.dart';
import 'package:ecogrid_intelligence/domain/model/power_plant.dart';
import 'package:ecogrid_intelligence/di/di.dart';
import 'package:ecogrid_intelligence/service/lg_service.dart';
import 'package:ecogrid_intelligence/presentation/plant_detail/bloc/plant_detail_bloc.dart';
import 'package:ecogrid_intelligence/presentation/explore/bloc/explore_bloc.dart';
import 'package:ecogrid_intelligence/presentation/explore/bloc/explore_event.dart';
import 'package:ecogrid_intelligence/service/tts_service.dart';
import 'package:ecogrid_intelligence/presentation/components/historical_trends_sheet.dart';
import 'package:ecogrid_intelligence/domain/model/cvs_result.dart';
import 'package:ecogrid_intelligence/config/routes/app_routes.dart';
import 'package:ecogrid_intelligence/presentation/components/plant_chat_bottom_sheet.dart';
import 'package:ecogrid_intelligence/presentation/components/lg_connection_pill.dart';

class PlantDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? arguments;
  const PlantDetailScreen({super.key, this.arguments});

  @override
  Widget build(BuildContext context) {
    final plant = arguments?['plant'] as PowerPlant?;
    if (plant == null) {
      return const Scaffold(body: Center(child: Text('Plant not found')));
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        // Clear LG screens when leaving plant detail (fire-and-forget).
        sl<LGService>().clearKml();
        // If ExploreBloc is available in the widget tree (came from regional list),
        // restore the region LG view.
        try {
          context.read<ExploreBloc>().add(const ExploreLGRestoreRequested());
        } catch (_) {
          // ExploreBloc is not in scope (came from search). Silently ignore.
        }
      },
      child: BlocProvider(
        create: (_) {
          Logger().i('[UI] Opened PlantDetailScreen');
          return sl<PlantDetailBloc>()..add(PlantDetailLoadRequested(plant));
        },
        child: BlocListener<PlantDetailBloc, PlantDetailState>(
          listenWhen: (prev, curr) {
            if (curr is! PlantDetailLoaded) return false;
            if (prev is! PlantDetailLoaded) return curr.lgError != null;
            return curr.lgError != null && curr.lgError != prev.lgError;
          },
          listener: (context, state) {
            if (state is PlantDetailLoaded && state.lgError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.lgError!),
                  backgroundColor: AppTheme.surface,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
              // Clear the error so it does not re-trigger.
              context.read<PlantDetailBloc>().add(
                const PlantDetailClearLGError(),
              );
            }
          },
          child: const _PlantDetailBody(),
        ),
      ),
    );
  }
}

class _PlantDetailBody extends StatelessWidget {
  const _PlantDetailBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      // Chat FAB
      floatingActionButton: BlocBuilder<PlantDetailBloc, PlantDetailState>(
        builder: (context, state) {
          if (state is! PlantDetailLoaded || state.cvsResult == null) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: () {
              // Start a new chat session
              context.read<PlantDetailBloc>().add(
                const PlantDetailChatStarted(),
              );
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => BlocProvider.value(
                  value: context.read<PlantDetailBloc>(),
                  child: PlantChatBottomSheet(plantName: state.plant.name),
                ),
              );
            },
            backgroundColor: AppTheme.secondary,
            child: const Icon(Icons.chat, color: Colors.white),
          );
        },
      ),
      body: SafeArea(
        child: BlocBuilder<PlantDetailBloc, PlantDetailState>(
          builder: (context, state) {
            if (state is PlantDetailLoading) {
              return Center(
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

    return Column(
      children: [
        // Top Logo Header
        _buildTopHeader(),

        // Search bar area
        _buildSearchBar(context, plant.name),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ROW 1: Plant Overview & CVS
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildOverviewCard(plant)),
                    SizedBox(width: AppTheme.spacingMD),
                    Expanded(
                      child: state.isLoadingCvs
                          ? _buildCvsLoadingCard()
                          : (cvs != null
                                ? _buildCVSCard(cvs)
                                : _buildCvsUnavailableCard()),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingMD),

                // ROW 2: AI Climate Insight (button-triggered)
                _buildAIInsightPanel(context, state),
                SizedBox(height: AppTheme.spacingMD),

                // ROW 3: Historical Trends & Scenario Simulation
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildHistoricalCard(context, state)),
                    SizedBox(width: AppTheme.spacingMD),
                    Expanded(child: _buildScenarioCard(context, state)),
                  ],
                ),
                SizedBox(height: AppTheme.spacingXXL),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMD,
        vertical: AppTheme.spacingSM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 32,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.public, color: AppTheme.primary, size: 32),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EcoGrid', style: AppTheme.headingSmall),
                  Text(
                    'Intelligence',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.primary,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const LgConnectionPill(),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, String plantName) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: AppTheme.cardBorder.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.arrow_back,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                plantName,
                style: AppTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.close, color: AppTheme.textMuted, size: 18),
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 16, color: AppTheme.cardBorder),
            const SizedBox(width: 12),
            Icon(Icons.tune, color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(PowerPlant plant) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '1. Plant Overview',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  Icons.factory_outlined,
                  color: AppTheme.primary,
                  size: 16,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            plant.name,
            style: AppTheme.headingSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            plant.primaryFuel.displayName,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.primary),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  plant.countryLong ?? plant.country,
                  style: AppTheme.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.bolt, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  plant.capacityMw != null
                      ? '${plant.capacityMw!.toStringAsFixed(0)} MW'
                      : 'N/A',
                  style: AppTheme.caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCVSCard(CVSResult cvs) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '2. CVS + Stress',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  Icons.eco_outlined,
                  color: AppTheme.secondary,
                  size: 16,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: cvs.score / 10,
                      strokeWidth: 6,
                      color: cvs.riskLevel.color,
                      backgroundColor: AppTheme.surfaceLight,
                    ),
                  ),
                  Text(
                    cvs.score.toStringAsFixed(1),
                    style: AppTheme.labelLarge.copyWith(
                      color: cvs.riskLevel.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cvs.riskLevel.label,
                      style: AppTheme.bodyMedium.copyWith(
                        color: cvs.riskLevel.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Vulnerability Level', style: AppTheme.caption),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildMiniStressBar(
            'Temp',
            cvs.temperatureStress,
            const Color(0xFFFF6B6B),
          ),
          const SizedBox(height: 4),
          _buildMiniStressBar(
            'Water',
            cvs.waterStress,
            const Color(0xFF4ECDC4),
          ),
          const SizedBox(height: 4),
          _buildMiniStressBar('Wind', cvs.windStress, const Color(0xFF45B7D1)),
        ],
      ),
    );
  }

  Widget _buildMiniStressBar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 35,
          child: Text(label, style: AppTheme.caption.copyWith(fontSize: 10)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: AppTheme.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCvsLoadingCard() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: AppTheme.cardDecoration,
      child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );
  }

  Widget _buildCvsUnavailableCard() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: AppTheme.cardDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, color: AppTheme.textMuted, size: 24),
          const SizedBox(height: 8),
          Text('Data Unavailable', style: AppTheme.caption),
        ],
      ),
    );
  }

  /// AI Insight Panel — ONLY generates on explicit button tap.
  Widget _buildAIInsightPanel(BuildContext context, PlantDetailLoaded state) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '3. AI Climate Insight',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (state.aiInsight != null)
                GestureDetector(
                  onTap: () {
                    sl<TTSService>().speak(state.aiInsight!);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      Icons.volume_up,
                      color: AppTheme.secondary,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (state.isLoadingInsight)
            // Loading state
            Row(
              children: [
                _buildRadarIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: LinearProgressIndicator(
                    color: AppTheme.secondary,
                    backgroundColor: AppTheme.surfaceLight,
                  ),
                ),
              ],
            )
          else if (state.aiInsight != null)
            // Insight loaded
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRadarIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    state.aiInsight!,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            )
          else if (state.insightError != null)
            // Error state with retry
            Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.riskHigh,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.insightError!,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<PlantDetailBloc>().add(
                        const PlantDetailGenerateInsightRequested(),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondary,
                      side: BorderSide(
                        color: AppTheme.secondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            // No insight yet — show generate button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: state.cvsResult != null
                    ? () {
                        context.read<PlantDetailBloc>().add(
                          const PlantDetailGenerateInsightRequested(),
                        );
                      }
                    : null,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Generate Insight'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.surfaceLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRadarIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.radar, color: AppTheme.secondary, size: 18),
        ),
      ),
    );
  }

  Widget _buildHistoricalCard(BuildContext context, PlantDetailLoaded state) {
    return GestureDetector(
      onTap: () {
        // Trigger lazy fetch of multi-year trend data if not already loaded
        context.read<PlantDetailBloc>().add(
          PlantDetailTrendRequested(state.plant),
        );

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => BlocProvider.value(
            value: context.read<PlantDetailBloc>(),
            child: BlocBuilder<PlantDetailBloc, PlantDetailState>(
              builder: (context, blocState) {
                if (blocState is PlantDetailLoaded &&
                    blocState.trendData.isNotEmpty) {
                  return HistoricalTrendsSheet(
                    historicalData: blocState.trendData,
                  );
                }
                return Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Loading 14-year climate trend...',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '4. Historical Climate Trends',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    Icons.bar_chart,
                    color: AppTheme.primary,
                    size: 16,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Mock mini chart
            SizedBox(
              height: 40,
              width: double.infinity,
              child: CustomPaint(
                painter: _MiniSparklinePainter(color: AppTheme.primary),
              ),
            ),
            const Spacer(),
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 80,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioCard(BuildContext context, PlantDetailLoaded state) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.simulation,
          arguments: {'bloc': context.read<PlantDetailBloc>()},
        );
      },
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '5. Scenario Simulation',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB388FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.account_tree,
                    color: Color(0xFFB388FF),
                    size: 16,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Mock branching nodes
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB388FF).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB388FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB388FF).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB388FF).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB388FF).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniSparklinePainter extends CustomPainter {
  final Color color;
  _MiniSparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.4,
      size.width * 0.4,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.8,
      size.width * 0.8,
      size.height * 0.2,
    );
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.0,
      size.width,
      size.height * 0.4,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
