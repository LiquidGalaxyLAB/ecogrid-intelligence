import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:logger/logger.dart';
import 'package:ecogrid_intelligence/config/theme/app_theme.dart';
import 'package:ecogrid_intelligence/config/routes/app_routes.dart';
import 'package:ecogrid_intelligence/core/enums/plant_type.dart';
import 'package:ecogrid_intelligence/core/enums/risk_level.dart';
import 'package:ecogrid_intelligence/domain/model/region.dart';
import 'package:ecogrid_intelligence/domain/model/power_plant.dart';
import 'package:ecogrid_intelligence/di/di.dart';
import 'package:ecogrid_intelligence/core/constants/design_constants.dart';
import 'package:ecogrid_intelligence/presentation/explore/bloc/explore_bloc.dart';
import 'package:ecogrid_intelligence/presentation/explore/bloc/explore_event.dart';
import 'package:ecogrid_intelligence/presentation/explore/bloc/explore_state.dart';
import 'package:ecogrid_intelligence/presentation/lg_connection/bloc/lg_connection_bloc.dart';
import 'package:ecogrid_intelligence/core/enums/connection_status.dart';
import 'package:ecogrid_intelligence/presentation/components/app_search_bar.dart';

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
    return Scaffold(
      backgroundColor: DesignConstants.background(context),
      body: SafeArea(
        child: BlocBuilder<ExploreBloc, ExploreState>(
          builder: (context, state) {
            if (state is ExploreLoading) {
              return Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }
            if (state is ExploreError) {
              return Center(
                child: Text(state.message, style: AppTheme.bodyMedium),
              );
            }
            if (state is ExploreLoaded) {
              return _buildLoaded(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, ExploreLoaded state) {
    return Column(
      children: [
        // Step 1: Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: DesignConstants.cardSurface(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF0066FF),
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppSearchBar(
                  hintText:
                      'Search within ${state.region?.displayName ?? state.region?.name ?? 'Global'}...',
                  readOnly: true,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.search),
                ),
              ),
            ],
          ),
        ),

        // Step 2: Stats Row
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
                  color: DesignConstants.cardSurface(context),
                  border: Border.all(
                    color: DesignConstants.border(context),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Color(0xFF00C8FF), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${state.filteredPlants.length} Plants',
                      style: AppTheme.bodySmall.copyWith(
                        color: DesignConstants.secondaryText(context),
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
                  color: DesignConstants.cardSurface(context),
                  border: Border.all(
                    color: DesignConstants.border(context),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.layers,
                      color: Color(0xFF00C8FF),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${state.filteredPlants.map((p) => p.primaryFuel).toSet().length} Types',
                      style: AppTheme.bodySmall.copyWith(
                        color: DesignConstants.secondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Step 3: Filter Rows
        // Plant Type Row
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, bottom: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'PLANT TYPE',
              style: AppTheme.labelSmall.copyWith(
                color: DesignConstants.secondaryText(context),
                letterSpacing: 1.5,
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

        // Risk Level Row
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, bottom: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'RISK LEVEL',
              style: AppTheme.labelSmall.copyWith(
                color: DesignConstants.secondaryText(context),
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          child: Row(
            children: [
              _buildRiskChip(
                context,
                state,
                RiskLevel.high,
                'High Risk',
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

        const SizedBox(height: 8),

        // Step 4 & 7 & 8: Plant List
        Expanded(child: _buildListContent(context, state)),

        // Step 5: AI Climate Insight Card
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
                      value: true,
                      onChanged: (v) {},
                      activeThumbColor: const Color(0xFF00C8FF),
                      activeTrackColor: const Color(
                        0xFF0066FF,
                      ).withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.volume_up,
                      color: Color(0xFF8A9BAE),
                      size: 16,
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

        // Step 6: Analyse Region Button
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
            top: 8,
          ),
          child: GestureDetector(
            onTap: () {
              context.read<ExploreBloc>().add(
                const ExploreGenerateRegionalInsight(),
              );
            },
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0066FF), Color(0xFF00C8FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C8FF).withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Analyse Region Risk', // Or properly fetch region
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(
    BuildContext context,
    ExploreLoaded state,
    PlantType? type,
    String label,
    IconData iconData,
    Color iconColor,
  ) {
    final isSelected = state.activeTypeFilter == type;

    Widget icon = Icon(
      iconData,
      size: 16,
      color: isSelected ? Colors.white : iconColor,
    );

    return GestureDetector(
      onTap: () {
        context.read<ExploreBloc>().add(
          ExploreFilterChanged(typeFilter: type, clearTypeFilter: type == null),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF0066FF), Color(0xFF00C8FF)],
                )
              : null,
          color: isSelected ? null : DesignConstants.cardSurface(context),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00C8FF).withValues(alpha: 0.6)
                : DesignConstants.border(context),
            width: 1,
          ),
          boxShadow: isSelected
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
                    ? Colors.white
                    : DesignConstants.secondaryText(context),
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
    ExploreLoaded state,
    RiskLevel level,
    String label,
    Color riskColor,
  ) {
    final isSelected = state.activeRiskFilter == level;

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
          color: isSelected
              ? riskColor.withValues(alpha: 0.2)
              : DesignConstants.cardSurface(context),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? riskColor : DesignConstants.border(context),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.shield, size: 14, color: riskColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? riskColor
                    : DesignConstants.secondaryText(context),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListContent(BuildContext context, ExploreLoaded state) {
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
              return _PlantListTile(
                plant: plant,
                index: index + 1,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.plantDetail,
                    arguments: {'plant': plant},
                  );
                },
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
                    backgroundColor: AppTheme.primary,
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
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.5),
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
    Widget fuelIcon;

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
          color: DesignConstants.cardSurface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DesignConstants.border(context), width: 1),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Center-left - Fuel type icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DesignConstants.elevatedSurface(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: fuelIcon),
            ),
            const SizedBox(width: 12),
            // Center - Plant info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: TextStyle(
                      color: DesignConstants.primaryText(context),
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
                      color: DesignConstants.secondaryText(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Right - Chevron
            Icon(
              Icons.chevron_right,
              color: DesignConstants.mutedText(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
