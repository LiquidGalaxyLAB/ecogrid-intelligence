import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:logger/logger.dart';
import '../../config/theme/app_theme.dart';
import '../../config/routes/app_routes.dart';
import '../../core/enums/plant_type.dart';
import '../../core/enums/risk_level.dart';
import '../../domain/model/region.dart';
import '../../domain/model/power_plant.dart';
import '../../di/di.dart';
import '../../config/theme/design_constants.dart';
import 'bloc/explore_bloc.dart';
import 'bloc/explore_event.dart';
import 'bloc/explore_data.dart';
import '../../core/resources/app_state.dart';
import '../lg_connection/bloc/lg_connection_bloc.dart';
import '../../core/enums/connection_status.dart';
import '../components/app_search_bar.dart';
import '../../service/tts_service.dart';
import '../../di/di.dart' show sl;
import '../../config/theme/theme_controller.dart';
import 'plant_comparison_screen.dart';
import '../../domain/repository/cvs_repository.dart';

class ExploreScreen extends StatelessWidget {
  final Map<String, dynamic>? arguments;
  const ExploreScreen({super.key, this.arguments});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final bloc = sl<ExploreBloc>();
            final isGlobal = arguments?['global'] == true;
            if (isGlobal) {
              bloc.add(const ExploreGlobalLoaded());
            } else {
              final region = arguments?['region'] as Region?;
              if (region != null) {
                bloc.add(ExploreRegionLoaded(region));
              }
            }
            return bloc;
          },
        ),
        BlocProvider.value(value: sl<LGConnectionBloc>()),
      ],
      child: const _ExploreScreenBody(),
    );
  }
}

class _ExploreScreenBody extends StatefulWidget {
  const _ExploreScreenBody();
  @override
  State<_ExploreScreenBody> createState() => _ExploreScreenBodyState();
}

class _ExploreScreenBodyState extends State<_ExploreScreenBody> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isNarrating = false;
  bool _isMuted = false;

  // ── Compare mode state ─────────────────────────────────────────────────
  bool _isCompareMode = false;
  final List<PowerPlant> _selectedPlants = [];

  void _toggleCompareMode() {
    setState(() {
      _isCompareMode = !_isCompareMode;
      if (!_isCompareMode) _selectedPlants.clear();
    });
  }

  void _togglePlantSelection(PowerPlant plant) {
    setState(() {
      if (_selectedPlants.contains(plant)) {
        _selectedPlants.remove(plant);
      } else if (_selectedPlants.length < 4) {
        _selectedPlants.add(plant);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 4 plants can be compared'),
          ),
        );
      }
    });
  }

  void _openComparisonScreen() {
    // CvsRepository is a get_it singleton — capture it directly rather than
    // via context.read (which would fail since there's no RepositoryProvider
    // for CvsRepository in the explore route's widget tree).
    final cvsRepo = sl<CvsRepository>();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, animation, route) => PlantComparisonScreen(
          plants: List.from(_selectedPlants),
          cvsRepository: cvsRepo,
        ),
        transitionsBuilder: (ctx, animation, route, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    Logger().i('[UI] Opened ExploreScreen');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    return Scaffold(
      backgroundColor: isDark
          ? DesignConstants.background(context)
          : Colors.white,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Compare FAB ────────────────────────────────────────────────
          FloatingActionButton.extended(
            heroTag: 'compare_fab',
            onPressed: _toggleCompareMode,
            backgroundColor: AppTheme.secondary,
            icon: Icon(
              _isCompareMode ? Icons.close_rounded : Icons.compare_arrows_rounded,
              color: Colors.white,
            ),
            label: Text(
              _isCompareMode
                  ? (_selectedPlants.isEmpty
                      ? 'Cancel'
                      : 'Compare (${_selectedPlants.length})')
                  : 'Compare',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          if (_isCompareMode && _selectedPlants.length >= 2)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FloatingActionButton.extended(
                heroTag: 'open_compare_fab',
                onPressed: _openComparisonScreen,
                backgroundColor: const Color(0xFF22C55E),
                icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                label: const Text(
                  'View',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          const SizedBox(height: 10),
          // ── AI Insight FAB ─────────────────────────────────────────────
          BlocBuilder<ExploreBloc, AppState<ExploreData>>(
            builder: (context, state) {
              if (state is AppSuccess<ExploreData>) {
                final data = state.data!;
                if (data.isLoadingInsight || data.aiInsight != null) {
                  return const SizedBox.shrink();
                }
              }
              return FloatingActionButton(
                heroTag: 'ai_fab',
                onPressed: () {
                  context.read<ExploreBloc>().add(
                        const ExploreGenerateRegionalInsight(),
                      );
                },
                backgroundColor: AppTheme.secondary,
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              );
            },
          ),
        ],
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
            child: BlocConsumer<ExploreBloc, AppState<ExploreData>>(
              listenWhen: (prev, curr) {
                if (prev is AppSuccess<ExploreData> && curr is AppSuccess<ExploreData>) {
                  return prev.data!.isLoadingInsight && !curr.data!.isLoadingInsight && curr.data!.aiInsight != null;
                }
                return false;
              },
              listener: (context, state) {
                if (state is AppSuccess<ExploreData>) {
                  final insight = state.data!.aiInsight;
                  if (insight != null) {
                    if (mounted) {
                      setState(() {
                         _isNarrating = true;
                         _isMuted = false;
                      });
                    }
                    sl<TTSService>().speak(insight).then((_) {
                      if (mounted && !_isMuted) {
                        setState(() => _isNarrating = false);
                      }
                    });
                  }
                }
              },
              builder: (context, state) {
                if (state is AppLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }
                if (state is AppFailure<ExploreData>) {
                  return Center(
                    child: Text(
                      state.exception?.toString() ?? 'Something went wrong',
                      style: AppTheme.bodyMedium,
                    ),
                  );
                }
                if (state is AppSuccess<ExploreData>) {
                  return _buildLoaded(context, state.data!, isDark);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, ExploreData state, bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: AppSearchBar(
            hintText:
                'Search within ${state.region?.displayName ?? state.region?.name ?? 'Global'}...',
            readOnly: true,
            onTap: () => Navigator.pushNamed(context, AppRoutes.search),
            prefixIcon: Icons.arrow_back_ios_new,
            onPrefixIconTap: () => Navigator.pop(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? DesignConstants.cardSurface(context)
                      : Colors.white,
                  border: Border.all(
                    color: isDark
                        ? DesignConstants.border(context)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bolt,
                      color: isDark
                          ? const Color(0xFF00C8FF)
                          : const Color(0xFF0066FF),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${state.filteredPlants.length} Plants',
                      style: AppTheme.bodySmall.copyWith(
                        color: isDark
                            ? DesignConstants.secondaryText(context)
                            : const Color(0xFF0D1F4A),
                        fontWeight: isDark
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? DesignConstants.cardSurface(context)
                      : Colors.white,
                  border: Border.all(
                    color: isDark
                        ? DesignConstants.border(context)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.layers,
                      color: isDark
                          ? const Color(0xFF00C8FF)
                          : const Color(0xFF0066FF),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${state.filteredPlants.map((p) => p.primaryFuel).toSet().length} Types',
                      style: AppTheme.bodySmall.copyWith(
                        color: isDark
                            ? DesignConstants.secondaryText(context)
                            : const Color(0xFF0D1F4A),
                        fontWeight: isDark
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, bottom: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'PLANT TYPE',
              style: AppTheme.labelSmall.copyWith(
                color: isDark
                    ? DesignConstants.secondaryText(context)
                    : const Color(0xFF6B80A0),
                letterSpacing: 1.5,
                fontWeight: isDark ? FontWeight.normal : FontWeight.w700,
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Row(
            children: [
              _buildTypeChip(
                context,
                state,
                null,
                'All',
                FluentIcons.grid_24_filled,
                Colors.white,
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                context,
                state,
                PlantType.hydro,
                'Hydro',
                FluentIcons.water_24_filled,
                const Color(0xFF2196F3),
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                context,
                state,
                PlantType.nuclear,
                'Nuclear',
                FluentIcons.warning_24_filled,
                const Color(0xFF00BCD4),
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                context,
                state,
                PlantType.coal,
                'Thermal',
                FluentIcons.fire_24_filled,
                const Color(0xFFFF5722),
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                context,
                state,
                PlantType.solar,
                'Solar',
                FluentIcons.weather_sunny_24_filled,
                const Color(0xFFFFC107),
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                context,
                state,
                PlantType.wind,
                'Wind',
                FluentIcons.weather_squalls_24_filled,
                const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                context,
                state,
                PlantType.gas,
                'Gas',
                FluentIcons.gas_24_filled,
                const Color(0xFFF44336),
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                context,
                state,
                PlantType.oil,
                'Oil',
                FluentIcons.drop_24_filled,
                const Color(0xFF795548),
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                context,
                state,
                PlantType.biomass,
                'Biomass',
                FluentIcons.leaf_one_24_filled,
                const Color(0xFF8BC34A),
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                context,
                state,
                PlantType.geothermal,
                'Geothermal',
                FluentIcons.temperature_24_filled,
                const Color(0xFFFF9800),
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                context,
                state,
                PlantType.waste,
                'Waste',
                FluentIcons.delete_24_filled,
                const Color(0xFF9E9E9E),
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                context,
                state,
                PlantType.wave,
                'Wave/Tidal',
                FluentIcons.cloud_flow_24_filled,
                const Color(0xFF00ACC1),
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                context,
                state,
                PlantType.storage,
                'Storage',
                FluentIcons.battery_charge_24_filled,
                const Color(0xFF9C27B0),
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                context,
                state,
                PlantType.cogeneration,
                'Cogeneration',
                FluentIcons.building_24_filled,
                const Color(0xFF607D8B),
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                context,
                state,
                PlantType.petcoke,
                'Petcoke',
                FluentIcons.cube_24_filled,
                const Color(0xFF616161),
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                context,
                state,
                PlantType.other,
                'Other',
                FluentIcons.flash_24_filled,
                const Color(0xFF607D8B),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, bottom: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'RISK LEVEL',
              style: AppTheme.labelSmall.copyWith(
                color: isDark
                    ? DesignConstants.secondaryText(context)
                    : const Color(0xFF6B80A0),
                letterSpacing: 1.5,
                fontWeight: isDark ? FontWeight.normal : FontWeight.w700,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Row(
              children: [
                _buildRiskChip(
                  context,
                  state,
                  null,
                  'All',
                  Colors.white,
                  iconData: FluentIcons.grid_24_filled,
                ),
                const SizedBox(width: 8),
                _buildRiskChip(
                  context,
                  state,
                  RiskLevel.high,
                  'High',
                  const Color(0xFFFF3B30),
                ),
                const SizedBox(width: 8),
                _buildRiskChip(
                  context,
                  state,
                  RiskLevel.medium,
                  'Medium',
                  const Color(0xFFFF9500),
                ),
                const SizedBox(width: 8),
                _buildRiskChip(
                  context,
                  state,
                  RiskLevel.low,
                  'Low',
                  const Color(0xFF34C759),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildListContent(context, state, isDark)),
        if (state.aiInsight != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DesignConstants.cardSurface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00C8FF).withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF00C8FF),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Climate Insight',
                      style: AppTheme.labelLarge.copyWith(
                        color: const Color(0xFF00C8FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Narration',
                      style: AppTheme.bodySmall.copyWith(
                        color: const Color(0xFF8A9BAE),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _isNarrating,
                      onChanged: (v) async {
                        final tts = sl<TTSService>();
                        if (v) {
                          setState(() {
                            _isNarrating = true;
                            _isMuted = false;
                          });
                          await tts.speak(state.aiInsight!);
                          if (mounted && !_isMuted) setState(() => _isNarrating = false);
                        } else {
                          setState(() => _isNarrating = false);
                          await tts.stop();
                        }
                      },
                      activeThumbColor: const Color(0xFF00C8FF),
                      activeTrackColor: const Color(0xFF0066FF).withValues(alpha: 0.5),
                    ),
                    if (_isNarrating) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          if (!_isMuted) {
                            setState(() => _isMuted = true);
                            await sl<TTSService>().stop();
                          } else {
                            setState(() => _isMuted = false);
                            await sl<TTSService>().speak(state.aiInsight!);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _isMuted
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isMuted ? Icons.volume_off : Icons.volume_up,
                            color: _isMuted ? Colors.red : Colors.grey,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final bloc = context.read<ExploreBloc>();
                        if (_isNarrating) {
                          await sl<TTSService>().stop();
                          if (mounted) setState(() => _isNarrating = false);
                        }
                        bloc.add(const ExploreDismissInsight());
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF8A9BAE,
                          ).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Color(0xFF8A9BAE),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  state.aiInsight!,
                  style: AppTheme.bodySmall.copyWith(
                    color: const Color(0xFF8A9BAE),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTypeChip(
    BuildContext context,
    ExploreData state,
    PlantType? type,
    String label,
    IconData iconData,
    Color iconColor,
  ) {
    final isSelected = state.activeTypeFilter == type;
    final isDark = ThemeController.instance.isDarkMode;
    Widget icon = Icon(
      iconData,
      size: 16,
      color: isSelected
          ? (isDark ? Colors.white : const Color(0xFF0066FF))
          : (isDark ? iconColor : iconColor),
    );
    return GestureDetector(
      onTap: () {
        context.read<ExploreBloc>().add(
          ExploreFilterChanged(
            typeFilter: isSelected ? null : type,
            clearTypeFilter: isSelected || type == null,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? const Color(0xFF0066FF).withValues(alpha: 0.2)
                    : const Color(0xFFE8F4FC))
              : (isDark ? DesignConstants.cardSurface(context) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? (isDark
                      ? const Color(0xFF00C8FF).withValues(alpha: 0.6)
                      : Colors.transparent)
                : (isDark
                      ? DesignConstants.border(context)
                      : const Color(0xFFE2E8F0)),
            width: 1,
          ),
          boxShadow: isSelected && isDark
              ? [
                  BoxShadow(
                    color: const Color(0xFF00C8FF).withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0066FF))
                    : (isDark
                          ? DesignConstants.secondaryText(context)
                          : const Color(0xFF0D1F4A)),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskChip(
    BuildContext context,
    ExploreData state,
    RiskLevel? level,
    String label,
    Color riskColor, {
    IconData iconData = Icons.shield,
  }) {
    final isSelected = state.activeRiskFilter == level;
    final isAllPill = level == null;
    final isDark = ThemeController.instance.isDarkMode;
    return GestureDetector(
      onTap: () {
        final newRisk = isSelected ? null : level;
        context.read<ExploreBloc>().add(
          ExploreRiskFilterChanged(riskLevel: newRisk),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: (isSelected && !isAllPill)
              ? (isDark
                    ? riskColor.withValues(alpha: 0.2)
                    : riskColor.withValues(alpha: 0.1))
              : (isSelected && isAllPill)
              ? (isDark
                    ? const Color(0xFF0066FF).withValues(alpha: 0.2)
                    : const Color(0xFFE8F4FC))
              : (isDark ? DesignConstants.cardSurface(context) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: (isSelected && isAllPill)
                ? (isDark
                      ? const Color(0xFF00C8FF).withValues(alpha: 0.6)
                      : Colors.transparent)
                : isSelected
                ? riskColor
                : (isDark
                      ? DesignConstants.border(context)
                      : const Color(0xFFE2E8F0)),
            width: 1,
          ),
          boxShadow: (isSelected && isAllPill && isDark)
              ? [
                  BoxShadow(
                    color: const Color(0xFF00C8FF).withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              iconData,
              size: 14,
              color: (isSelected && isAllPill)
                  ? (isDark ? Colors.white : const Color(0xFF0066FF))
                  : riskColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: (isSelected && isAllPill)
                    ? (isDark ? Colors.white : const Color(0xFF0066FF))
                    : isSelected
                    ? riskColor
                    : (isDark
                          ? DesignConstants.secondaryText(context)
                          : const Color(0xFF0D1F4A)),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListContent(
    BuildContext context,
    ExploreData state,
    bool isDark,
  ) {
    if (state.filteredPlants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: Color(0xFF4A5568), size: 48),
            const SizedBox(height: 8),
            Text(
              'No plants match your filters',
              style: AppTheme.bodyMedium.copyWith(
                color: const Color(0xFF8A9BAE),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting the filters above',
              style: AppTheme.bodySmall.copyWith(
                color: const Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      );
    }
    return BlocBuilder<LGConnectionBloc, LGConnectionState>(
      builder: (context, lgState) {
        final isLgConnected = lgState.status == ConnectionStatus.connected;
        final showLgButton =
            state.region != null &&
            state.activeRiskFilter != null &&
            isLgConnected &&
            state.filteredPlants.isNotEmpty;
        final plantsCount = state.filteredPlants.length;
        final showLoadMore = plantsCount > state.displayLimit;
        final displayCount = showLoadMore ? state.displayLimit : plantsCount;
        int totalItems = displayCount;
        if (showLgButton) totalItems++;
        if (showLoadMore) totalItems++;
        return ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            if (index < displayCount) {
              final plant = state.filteredPlants[index];
              final isSelected = _selectedPlants.contains(plant);
              return _CompareListItemWrapper(
                isCompareMode: _isCompareMode,
                isSelected: isSelected,
                onTap: () {
                  if (_isCompareMode) {
                    _togglePlantSelection(plant);
                  } else {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.plantDetail,
                      arguments: {'plant': plant},
                    );
                  }
                },
                child: _PlantListTile(
                  plant: plant,
                  index: index + 1,
                  onTap: () {
                    if (_isCompareMode) {
                      _togglePlantSelection(plant);
                    } else {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.plantDetail,
                        arguments: {'plant': plant},
                      );
                    }
                  },
                ),
              );
            }
            final isLgButtonIndex = showLgButton && index == displayCount;
            final isLoadMoreIndex = showLoadMore && index == (totalItems - 1);
            if (isLgButtonIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<ExploreBloc>().add(
                      const ExploreShowPlantsOnLG(),
                    );
                  },
                  icon: const Icon(Icons.public, size: 20),
                  label: const Text('Show Plants on LG'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppTheme.primary
                        : const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                  ),
                ),
              );
            }
            if (isLoadMoreIndex) {
              return Padding(
                padding: const EdgeInsets.only(
                  top: 8,
                  bottom: 20,
                  left: 16,
                  right: 16,
                ),
                child: Center(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? AppTheme.primary
                          : const Color(0xFF0066FF),
                      side: BorderSide(
                        color: isDark
                            ? AppTheme.primary.withValues(alpha: 0.5)
                            : const Color(0xFF0066FF).withValues(alpha: 0.3),
                      ),
                    ),
                    onPressed: () {
                      context.read<ExploreBloc>().add(const ExploreLoadMore());
                    },
                    child: const Text('Load More Plants'),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}

class _PlantListTile extends StatelessWidget {
  final PowerPlant plant;
  final int index;
  final VoidCallback onTap;
  const _PlantListTile({
    required this.plant,
    required this.index,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    Icon fuelIcon = const Icon(Icons.bolt, color: Colors.grey, size: 24);
    final isDark = ThemeController.instance.isDarkMode;
    switch (plant.primaryFuel) {
      case PlantType.hydro:
        fuelIcon = const Icon(
          FluentIcons.water_24_filled,
          color: Color(0xFF2196F3),
          size: 24,
        );
        break;
      case PlantType.nuclear:
        fuelIcon = const Icon(
          FluentIcons.warning_24_filled,
          color: Color(0xFF00BCD4),
          size: 24,
        );
        break;
      case PlantType.coal:
        fuelIcon = const Icon(
          FluentIcons.fire_24_filled,
          color: Color(0xFFFF5722),
          size: 24,
        );
        break;
      case PlantType.solar:
        fuelIcon = const Icon(
          FluentIcons.weather_sunny_24_filled,
          color: Color(0xFFFFC107),
          size: 24,
        );
        break;
      case PlantType.wind:
        fuelIcon = const Icon(
          FluentIcons.weather_squalls_24_filled,
          color: Color(0xFF4CAF50),
          size: 24,
        );
        break;
      case PlantType.gas:
        fuelIcon = const Icon(
          FluentIcons.gas_24_filled,
          color: Color(0xFFF44336),
          size: 24,
        );
        break;
      case PlantType.oil:
        fuelIcon = const Icon(
          FluentIcons.drop_24_filled,
          color: Color(0xFF795548),
          size: 24,
        );
        break;
      case PlantType.biomass:
        fuelIcon = const Icon(
          FluentIcons.leaf_one_24_filled,
          color: Color(0xFF8BC34A),
          size: 24,
        );
        break;
      case PlantType.geothermal:
        fuelIcon = const Icon(
          FluentIcons.temperature_24_filled,
          color: Color(0xFFFF9800),
          size: 24,
        );
        break;
      case PlantType.waste:
        fuelIcon = const Icon(
          FluentIcons.delete_24_filled,
          color: Color(0xFF9E9E9E),
          size: 24,
        );
        break;
      case PlantType.wave:
        fuelIcon = const Icon(
          FluentIcons.cloud_flow_24_filled,
          color: Color(0xFF00ACC1),
          size: 24,
        );
        break;
      case PlantType.storage:
        fuelIcon = const Icon(
          FluentIcons.battery_charge_24_filled,
          color: Color(0xFF9C27B0),
          size: 24,
        );
        break;
      case PlantType.cogeneration:
        fuelIcon = const Icon(
          FluentIcons.building_24_filled,
          color: Color(0xFF607D8B),
          size: 24,
        );
        break;
      case PlantType.petcoke:
        fuelIcon = const Icon(
          FluentIcons.cube_24_filled,
          color: Color(0xFF616161),
          size: 24,
        );
        break;
      case PlantType.other:
        fuelIcon = const Icon(
          FluentIcons.flash_24_filled,
          color: Color(0xFF607D8B),
          size: 24,
        );
        break;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? DesignConstants.cardSurface(context) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? DesignConstants.border(context)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? DesignConstants.elevatedSurface(context)
                    : fuelIcon.color!.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: fuelIcon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: TextStyle(
                      color: isDark
                          ? DesignConstants.primaryText(context)
                          : const Color(0xFF0D1F4A),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${plant.primaryFuel.displayName} • ${plant.capacityMw?.toStringAsFixed(0) ?? '?'} MW',
                    style: TextStyle(
                      color: isDark
                          ? DesignConstants.secondaryText(context)
                          : const Color(0xFF6B80A0),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? DesignConstants.mutedText(context)
                  : const Color(0xFF0066FF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compare selection wrapper — slides in a checkbox when compare mode is active
// ─────────────────────────────────────────────────────────────────────────────

class _CompareListItemWrapper extends StatelessWidget {
  final bool isCompareMode;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  const _CompareListItemWrapper({
    required this.isCompareMode,
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          child,
          if (isCompareMode)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.secondary
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.secondary
                            : AppTheme.cardBorder,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
