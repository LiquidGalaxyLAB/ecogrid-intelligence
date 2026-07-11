import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../config/theme/app_theme.dart';
import '../../config/theme/theme_controller.dart';
import '../../domain/model/power_plant.dart';
import '../../di/di.dart';
import '../../service/lg_service.dart';
import 'bloc/plant_detail_bloc.dart';
import 'bloc/plant_detail_data.dart';
import 'bloc/plant_detail_event.dart';
import '../../core/resources/app_state.dart';
import '../explore/bloc/explore_bloc.dart';
import '../explore/bloc/explore_event.dart';
import '../../service/tts_service.dart';
import '../components/historical_trends_sheet.dart';
import '../../domain/model/cvs_result.dart';
import '../../config/routes/app_routes.dart';
import '../components/plant_chat_bottom_sheet.dart';
import '../components/lg_connection_pill.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/enums/historical_data_mode.dart';

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
        sl<LGService>().clearKml();
        try {
          context.read<ExploreBloc>().add(const ExploreLGRestoreRequested());
        } catch (_) {}
      },
      child: BlocProvider(
        create: (_) {
          Logger().i('[UI] Opened PlantDetailScreen');
          return sl<PlantDetailBloc>()..add(PlantDetailLoadRequested(plant));
        },
        child: BlocListener<PlantDetailBloc, AppState<PlantDetailData>>(
          listenWhen: (prev, curr) {
            if (curr is! AppSuccess<PlantDetailData>) return false;
            final currData = curr.data!;
            if (prev is! AppSuccess<PlantDetailData>) {
              return currData.lgError != null;
            }
            final prevData = prev.data!;
            return currData.lgError != null &&
                currData.lgError != prevData.lgError;
          },
          listener: (context, state) {
            if (state is AppSuccess<PlantDetailData>) {
              final data = state.data!;
              if (data.lgError != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(data.lgError!),
                    backgroundColor: AppTheme.surface,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
                context.read<PlantDetailBloc>().add(
                  const PlantDetailClearLGError(),
                );
              }
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
    final isDark = ThemeController.instance.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.background : Colors.white,
      floatingActionButton:
          BlocBuilder<PlantDetailBloc, AppState<PlantDetailData>>(
            builder: (context, state) {
              if (state is! AppSuccess<PlantDetailData>) {
                return const SizedBox.shrink();
              }
              final data = state.data!;
              if (data.cvsResult == null) {
                return const SizedBox.shrink();
              }
              return FloatingActionButton(
                onPressed: () {
                  context.read<PlantDetailBloc>().add(
                    const PlantDetailChatStarted(),
                  );
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BlocProvider.value(
                      value: context.read<PlantDetailBloc>(),
                      child: PlantChatBottomSheet(plantName: data.plant.name),
                    ),
                  );
                },
                backgroundColor: AppTheme.secondary,
                child: const Icon(Icons.chat, color: Colors.white),
              );
            },
          ),
      body: Stack(
        children: [
          if (!isDark)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFE8F4FC),
                      const Color(0xFFF4F9FD),
                      Colors.white,
                    ],
                    stops: const [0.0, 0.4, 0.7],
                  ),
                ),
              ),
            ),
          SafeArea(
            child: BlocBuilder<PlantDetailBloc, AppState<PlantDetailData>>(
              builder: (context, state) {
                if (state is AppLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }
                if (state is AppFailure<PlantDetailData>) {
                  return Center(
                    child: Text(
                      state.exception?.toString() ?? 'Something went wrong',
                      style: AppTheme.bodyMedium,
                    ),
                  );
                }
                if (state is AppSuccess<PlantDetailData>) {
                  return _buildLoaded(context, state.data!);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, PlantDetailData state) {
    final plant = state.plant;
    final cvs = state.cvsResult;
    return Column(
      children: [
        _buildTopHeader(),
        _buildSearchBar(context, plant.name),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildOverviewCard(plant)),
                    SizedBox(width: AppTheme.spacingMD),
                    Expanded(
                      child: state.isLoadingCvs
                          ? _buildCvsLoadingCard()
                          : (cvs != null
                                ? _buildCVSCard(context, cvs)
                                : _buildCvsUnavailableCard()),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingMD),
                _AIInsightPanel(state: state),
                SizedBox(height: AppTheme.spacingMD),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildHistoricalCard(context, state)),
                    SizedBox(width: AppTheme.spacingMD),
                    Expanded(child: _buildScenarioCard(context, state)),
                  ],
                ),
                SizedBox(height: AppTheme.spacingXL),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMD,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (state.isOrbiting) {
                          context.read<PlantDetailBloc>().add(
                            const PlantDetailStopOrbitRequested(),
                          );
                        } else {
                          context.read<PlantDetailBloc>().add(
                            const PlantDetailStartOrbitRequested(),
                          );
                        }
                      },
                      icon: Icon(
                        state.isOrbiting
                            ? Icons.stop_circle_outlined
                            : Icons.threesixty,
                        size: 18,
                      ),
                      label: Text(
                        state.isOrbiting ? 'Stop Orbit' : 'Start Orbit',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.isOrbiting
                            ? AppTheme.surfaceLight
                            : AppTheme.secondary,
                        foregroundColor: state.isOrbiting
                            ? AppTheme.textPrimary
                            : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
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

  Widget _buildCVSCard(BuildContext context, CVSResult cvs) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      Text('CVS + Stress', style: AppTheme.headingSmall),
                      const SizedBox(height: 24),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: cvs.score / 100,
                              strokeWidth: 12,
                              color: cvs.riskLevel.color,
                              backgroundColor: AppTheme.surfaceLight,
                            ),
                          ),
                          Text(
                            cvs.score.toStringAsFixed(1),
                            style: AppTheme.headingLarge.copyWith(
                              color: cvs.riskLevel.color,
                              fontSize: 32,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        cvs.riskLevel.label,
                        style: AppTheme.bodyLarge.copyWith(
                          color: cvs.riskLevel.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Vulnerability Level', style: AppTheme.bodyMedium),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMiniStressBar(
                              'Temp',
                              cvs.temperatureStress,
                              const Color(0xFFFF6B6B),
                            ),
                            const SizedBox(height: 12),
                            _buildMiniStressBar(
                              'Water',
                              cvs.waterStress,
                              const Color(0xFF4ECDC4),
                            ),
                            const SizedBox(height: 12),
                            _buildMiniStressBar(
                              'Wind',
                              cvs.windStress,
                              const Color(0xFF45B7D1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                  Positioned(
                    right: -8,
                    top: -8,
                    child: IconButton(
                      icon: Icon(Icons.close, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
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
                        value: cvs.score / 100,
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
            _buildMiniStressBar(
              'Wind',
              cvs.windStress,
              const Color(0xFF45B7D1),
            ),
          ],
        ),
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
}

class _AIInsightPanel extends StatefulWidget {
  final PlantDetailData state;
  const _AIInsightPanel({required this.state});
  @override
  State<_AIInsightPanel> createState() => _AIInsightPanelState();
}

class _AIInsightPanelState extends State<_AIInsightPanel> {
  bool _isSpeaking = false;
  void _toggleSpeech() async {
    if (_isSpeaking) {
      await sl<TTSService>().stop();
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    } else {
      if (mounted) {
        setState(() => _isSpeaking = true);
      }
      await sl<TTSService>().speak(widget.state.aiInsight!);
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  @override
  void dispose() {
    if (_isSpeaking) {
      sl<TTSService>().stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              if (widget.state.aiInsight != null)
                GestureDetector(
                  onTap: _toggleSpeech,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      _isSpeaking
                          ? Icons.stop_circle_outlined
                          : Icons.volume_up,
                      color: AppTheme.secondary,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.state.isLoadingInsight)
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
          else if (widget.state.aiInsight != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRadarIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.state.aiInsight!,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            )
          else if (widget.state.insightError != null)
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
                        widget.state.insightError!,
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
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: widget.state.cvsResult != null
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
}

Widget _buildHistoricalCard(BuildContext context, PlantDetailData state) {
  return GestureDetector(
    onTap: () {
      context.read<PlantDetailBloc>().add(
        PlantDetailTrendRequested(state.plant),
      );
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BlocProvider.value(
          value: context.read<PlantDetailBloc>(),
          child: BlocBuilder<PlantDetailBloc, AppState<PlantDetailData>>(
            builder: (context, blocState) {
              if (blocState is AppSuccess<PlantDetailData> &&
                  blocState.data!.trendData.isNotEmpty) {
                return HistoricalTrendsSheet(
                  historicalData: blocState.data!.trendData,
                );
              }
              return Container(
                height: 300,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primary),
                      const SizedBox(height: 16),
                      FutureBuilder<SharedPreferences>(
                        future: SharedPreferences.getInstance(),
                        builder: (context, snapshot) {
                          int years = 5;
                          if (snapshot.hasData) {
                            final modeIndex =
                                snapshot.data!.getInt('historical_data_mode') ??
                                HistoricalDataMode.fast.index;
                            if (modeIndex >= 0 &&
                                modeIndex < HistoricalDataMode.values.length) {
                              years = HistoricalDataMode
                                  .values[modeIndex]
                                  .yearsBack;
                            }
                          }
                          return Text(
                            'Loading $years-year climate trend...',
                            style: TextStyle(color: AppTheme.textSecondary),
                          );
                        },
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
                child: Icon(Icons.bar_chart, color: AppTheme.primary, size: 16),
              ),
            ],
          ),
          const Spacer(),
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

Widget _buildScenarioCard(BuildContext context, PlantDetailData state) {
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
