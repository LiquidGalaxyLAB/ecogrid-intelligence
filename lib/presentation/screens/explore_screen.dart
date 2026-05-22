import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ecogrid_intelligence/config/theme.dart';
import 'package:ecogrid_intelligence/config/routes.dart';
import 'package:ecogrid_intelligence/core/enums/plant_type.dart';
import 'package:ecogrid_intelligence/domain/entities/region.dart';
import 'package:ecogrid_intelligence/domain/entities/power_plant.dart';
import 'package:ecogrid_intelligence/di/injection_container.dart';
import 'package:ecogrid_intelligence/presentation/blocs/explore/explore_bloc.dart';
import 'package:ecogrid_intelligence/presentation/blocs/explore/explore_event.dart';
import 'package:ecogrid_intelligence/presentation/blocs/explore/explore_state.dart';

class ExploreScreen extends StatelessWidget {
  final Map<String, dynamic>? arguments;
  const ExploreScreen({super.key, this.arguments});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
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
      child: const _ExploreScreenBody(),
    );
  }
}

class _ExploreScreenBody extends StatelessWidget {
  const _ExploreScreenBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: BlocBuilder<ExploreBloc, ExploreState>(
          builder: (context, state) {
            if (state is ExploreLoading) {
              return const Center(
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
        // ── Top Bar with Search ──────────────────────
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
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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
                      const Icon(Icons.search,
                          color: AppTheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        state.region?.displayName ??
                            state.region?.name ??
                            'Global Overview',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Region Stats ────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
          child: Row(
            children: [
              _StatChip(
                label: 'Plants',
                value: '${state.filteredPlants.length}',
                icon: Icons.bolt,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Types',
                value: '${state.filteredPlants.map((p) => p.primaryFuel).toSet().length}',
                icon: Icons.category,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Filter Chips ────────────────────────────
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
            children: [
              for (final type in [
                PlantType.hydro,
                PlantType.nuclear,
                PlantType.coal,
                PlantType.solar,
                PlantType.wind,
                PlantType.gas,
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: type.displayName,
                    isActive:
                        state.activeTypeFilters.contains(type),
                    onTap: () {
                      final newFilters =
                          Set<PlantType>.from(state.activeTypeFilters);
                      if (newFilters.contains(type)) {
                        newFilters.remove(type);
                      } else {
                        newFilters.add(type);
                      }
                      context.read<ExploreBloc>().add(
                            ExploreFilterChanged(typeFilters: newFilters),
                          );
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Plant List ──────────────────────────────
        Expanded(
          child: ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
            itemCount: state.filteredPlants.length,
            itemBuilder: (context, index) {
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
            },
          ),
        ),

        // ── AI Insight Bottom Strip ─────────────────
        if (state.aiInsight != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              border: Border(
                  top: BorderSide(
                      color: AppTheme.primary.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome,
                    color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.aiInsight!,
                    style: AppTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: AppTheme.cardDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primary, size: 16),
          const SizedBox(width: 6),
          Text(value,
              style:
                  AppTheme.labelLarge.copyWith(color: AppTheme.primary)),
          const SizedBox(width: 4),
          Text(label, style: AppTheme.caption),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isActive
                ? AppTheme.primary.withValues(alpha: 0.5)
                : AppTheme.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: isActive ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _PlantListTile extends StatelessWidget {
  final PowerPlant plant;
  final int index;
  final VoidCallback onTap;

  const _PlantListTile(
      {required this.plant, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '$index',
                style: AppTheme.labelLarge.copyWith(
                    color: AppTheme.primary, fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.name,
                      style: AppTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${plant.primaryFuel.displayName} • ${plant.capacityMw?.toStringAsFixed(0) ?? '?'} MW',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
