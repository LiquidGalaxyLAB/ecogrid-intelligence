import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material_symbols_icons/symbols.dart';
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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../service/lg_service.dart';
import 'plant_comparison_screen.dart';
import '../../domain/repository/cvs_repository.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../service/tour_service.dart';
import '../components/eco_showcase.dart';
import '../../core/enums/tour_phase.dart';
import '../../core/constants/tour_keys.dart';

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
          const SnackBar(content: Text('Maximum 4 plants can be compared')),
        );
      }
    });
    // During tour: show the Compare button coachmark when 2+ plants selected.
    if (_tourService.isTourActive.value &&
        _tourService.currentPhase.value == TourPhase.exploreCompareSelect &&
        _selectedPlants.length >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tourService.showIfPhase(context, TourPhase.exploreCompareSelect, [TourKeys.compareBtn]);
        }
      });
    }
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
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
  // ──────────────────────────────────────────────────────────────────────────

  final TourService _tourService = sl<TourService>();

  @override
  void initState() {
    super.initState();
    Logger().i('[UI] Opened ExploreScreen');
    _tourService.currentPhase.addListener(_onTourPhaseChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onTourPhaseChanged());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _tourService.currentPhase.removeListener(_onTourPhaseChanged);
    try {
      final lgService = sl<LGService>();
      lgService.clearKml();
      lgService.flyToDefault();
    } catch (_) {}
    super.dispose();
  }

  void _onTourPhaseChanged() {
    if (!mounted || !_tourService.isTourActive.value) return;
    final phase = _tourService.currentPhase.value;
    
    void trigger() {
      if (!mounted) return;
      switch (phase) {
        case TourPhase.exploreAiFab:
          _tourService.showIfPhase(context, TourPhase.exploreAiFab, [TourKeys.exploreAiFab]);
          break;
        case TourPhase.explorePlant:
          // Ensure scroll is at top before showing plant coachmark.
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          ).then((_) {
            if (mounted) {
              _tourService.showIfPhase(context, TourPhase.explorePlant, [TourKeys.plant]);
            }
          });
          break;
        case TourPhase.exploreCompareFab:
          _tourService.showIfPhase(context, TourPhase.exploreCompareFab, [TourKeys.compareFab]);
          break;
        case TourPhase.exploreCompareSelect:
          // Only show coachmark on Compare button when 2+ plants selected.
          if (_selectedPlants.length >= 2) {
            _tourService.showIfPhase(context, TourPhase.exploreCompareSelect, [TourKeys.compareBtn]);
          }
          break;
        default:
          break;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && route.animation != null) {
        if (route.animation!.isCompleted) {
          trigger();
        } else {
          route.animation!.addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              WidgetsBinding.instance.addPostFrameCallback((_) => trigger());
            }
          });
        }
      } else {
        trigger();
      }
    });
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
          if (!_isCompareMode)
            EcoShowcase(
              showcaseKey: TourKeys.compareFab,
              title: 'Compare Mode',
              description: 'Tap here to enter compare mode and select up to 4 power plants to contrast',
              targetBorderRadius: BorderRadius.circular(28),
              disposeOnTap: false,
              onTargetClick: () {}, // Required by showcaseview package even if disposeOnTap is false
              onNextClick: () {
                ShowCaseWidget.of(context).dismiss();
                // Delay popping the route and updating tour phase to allow showcase dismiss animation
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) Navigator.pop(context); // Go back to Home
                  _tourService.currentPhase.value = TourPhase.homeInfraMap;
                });
              },

              child: FloatingActionButton(
                heroTag: 'compare_fab',
                onPressed: _toggleCompareMode,
                backgroundColor: AppTheme.secondary,
                child: const Icon(
                  Symbols.folder_match,
                  fill: 1.0,
                  color: Colors.white,
                ),
              ),
            ),

          // ── AI Insight FAB ─────────────────────────────────────────────
          BlocBuilder<ExploreBloc, AppState<ExploreData>>(
            builder: (context, state) {
              if (_isCompareMode) return const SizedBox.shrink();
              if (state is AppSuccess<ExploreData>) {
                final data = state.data!;
                if (data.isLoadingInsight) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: EcoShowcase(
                    showcaseKey: TourKeys.exploreAiFab,
                    title: 'Regional Insight',
                    description: 'Tap here to view AI regional energy analysis and insights',
                    targetBorderRadius: BorderRadius.circular(28),
                    disposeOnTap: false,
                    onTargetClick: () {}, // Required by showcaseview package even if disposeOnTap is false
                    onNextClick: () {
                      ShowCaseWidget.of(context).dismiss();
                      if (mounted && _tourService.isTourActive.value) {
                        _tourService.advancePhase();
                      }
                    },
      
                    child: FloatingActionButton(
                      heroTag: 'ai_fab',
                      onPressed: () {
                        final bloc = context.read<ExploreBloc>();
                        if (data.aiInsight == null && !data.isLoadingInsight) {
                          bloc.add(const ExploreGenerateRegionalInsight());
                        }
                        _showRegionalInsightBottomSheet(context);
                      },
                      backgroundColor: AppTheme.secondary,
                      child: const Icon(Icons.auto_awesome, color: Colors.white),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
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
              listener: (context, state) {
                if (state is AppSuccess<ExploreData>) {
                  // After data loads and UI rebuilds, trigger the tour coachmarks again
                  WidgetsBinding.instance.addPostFrameCallback((_) => _onTourPhaseChanged());
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
          // ── Compare Bottom Bar ──────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              offset: _isCompareMode ? Offset.zero : const Offset(0, 1.5),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isCompareMode ? 1.0 : 0.0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: 16 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? DesignConstants.elevatedSurface(context)
                        : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_selectedPlants.length} / 4 Selected',
                              style: TextStyle(
                                color: isDark
                                    ? DesignConstants.primaryText(context)
                                    : const Color(0xFF0D1F4A),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (_selectedPlants.isNotEmpty)
                              Wrap(
                                spacing: 4,
                                children: _selectedPlants
                                    .map(
                                      (p) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          p.name.length > 10
                                              ? '${p.name.substring(0, 10)}...'
                                              : p.name,
                                          style: TextStyle(
                                            color: AppTheme.secondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              )
                            else
                              Text(
                                'Select at least 2 plants',
                                style: TextStyle(
                                  color: isDark
                                      ? DesignConstants.secondaryText(context)
                                      : const Color(0xFF6B80A0),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      AnimatedScale(
                        duration: const Duration(milliseconds: 300),
                        scale: _selectedPlants.length >= 2 ? 1.0 : 0.95,
                        child: EcoShowcase(
                          showcaseKey: TourKeys.compareBtn,
                          title: 'Launch Comparison',
                          description: 'Select at least 2 plants, then tap here to compare their metrics',
                          targetBorderRadius: BorderRadius.circular(32),
                          disposeOnTap: false,
                          onTargetClick: () {},
                          onNextClick: () {
                            ShowCaseWidget.of(context).dismiss();
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted) Navigator.pop(context); // Go back to Home
                              _tourService.currentPhase.value = TourPhase.homeInfraMap;
                            });
                          },
            
                          child: ElevatedButton(
                            onPressed: _selectedPlants.length >= 2
                                ? _openComparisonScreen
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.withValues(
                                alpha: 0.3,
                              ),
                              disabledForegroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            child: const Text(
                              'Compare',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _toggleCompareMode,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF6B80A0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
      ],
    );
  }

  Future<void> _showRegionalInsightBottomSheet(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    final bloc = context.read<ExploreBloc>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: bloc,
        child: _BottomSheetInsightContent(isDark: isDark),
      ),
    ).then((_) {
    if (bloc.state is AppSuccess<ExploreData>) {
      bloc.add(const ExploreDismissInsight());
    }
  });
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
              : (isDark
                    ? DesignConstants.cardSurface(context)
                    : const Color(0xFFF1F5F9)),
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
              : (isDark
                    ? DesignConstants.cardSurface(context)
                    : const Color(0xFFF1F5F9)),
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
        final plantsCount = state.filteredPlants.length;
        final showLoadMore = plantsCount > state.displayLimit;
        final displayCount = showLoadMore ? state.displayLimit : plantsCount;
        int totalItems = displayCount;
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
              Widget tile = _CompareListItemWrapper(
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
              if (index == 0) {
                tile = EcoShowcase(
                  showcaseKey: TourKeys.plant,
                  title: 'Power Plant Details',
                  description: 'Tap any plant to see deep insights, live stats, and satellite imagery',
                  targetBorderRadius: BorderRadius.circular(16),
                  disposeOnTap: false,
                  onTargetClick: () {},
                  onNextClick: () {
                    ShowCaseWidget.of(context).dismiss();
                    _tourService.advancePhase();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.plantDetail,
                          arguments: {'plant': plant},
                        );
                      }
                    });
                  },
                  child: tile,
                );
              }
              return tile;
            }
            final isLoadMoreIndex = showLoadMore && index == (totalItems - 1);
            if (isLoadMoreIndex) {
              return Padding(
                padding: const EdgeInsets.only(
                  top: 8,
                  bottom: 8,
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
                    child: const Text('Load More'),
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
        clipBehavior: Clip.none,
        children: [
          // Shrink the tile from the left
          AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(left: isCompareMode ? 32.0 : 0.0),
            child: Stack(
              children: [
                child,
                // Selection border overlay
                if (isCompareMode)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: 8,
                        left: 16,
                        right: 16,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.secondary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Checkbox sliding from left
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: isCompareMode ? 20 : -40,
            top: 0,
            bottom: 8, // adjust for child margin
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isCompareMode ? 1.0 : 0.0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.secondary : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.secondary
                          : const Color(0xFFE2E8F0),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        )
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

// ─────────────────────────────────────────────────────────────────────────────
// Regional Insight Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _BottomSheetInsightContent extends StatefulWidget {
  final bool isDark;

  const _BottomSheetInsightContent({
    required this.isDark,
  });

  @override
  State<_BottomSheetInsightContent> createState() =>
      _BottomSheetInsightContentState();
}

class _BottomSheetInsightContentState
    extends State<_BottomSheetInsightContent> {
  bool _isNarrating = false;
  bool _isMuted = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExploreBloc, AppState<ExploreData>>(
      builder: (context, state) {
        if (state is! AppSuccess<ExploreData>) return const SizedBox.shrink();
        final data = state.data!;
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.45,
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 16,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF00C8FF),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI Regional Analysis',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (data.aiInsight != null)
                    GestureDetector(
                      onTap: () async {
                        final tts = sl<TTSService>();
                        if (_isNarrating) {
                          await tts.stop();
                          if (mounted) setState(() => _isNarrating = false);
                        } else {
                          if (mounted) setState(() => _isNarrating = true);
                          await tts.speak(data.aiInsight!);
                          if (mounted) setState(() => _isNarrating = false);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C8FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          _isNarrating ? Icons.stop_circle_outlined : Icons.volume_up,
                          color: const Color(0xFF00C8FF),
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (data.isLoadingInsight)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF00C8FF)),
                        const SizedBox(height: 16),
                        Text(
                          "Generating AI Insight...",
                          style: TextStyle(
                            color: widget.isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (data.aiInsight != null)
                HtmlWidget(
                  data.aiInsight!,
                  textStyle: AppTheme.bodyMedium.copyWith(
                    color: widget.isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF334155),
                    height: 1.6,
                  ),
                ),
            ],
          ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    if (_isNarrating) {
      sl<TTSService>().stop();
    }
    super.dispose();
  }
}
