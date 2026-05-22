import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ecogrid_intelligence/config/theme.dart';
import 'package:ecogrid_intelligence/config/routes.dart';
import 'package:ecogrid_intelligence/core/enums/connection_status.dart';
import 'package:ecogrid_intelligence/domain/entities/region.dart';
import 'package:ecogrid_intelligence/di/injection_container.dart';
import 'package:ecogrid_intelligence/presentation/blocs/home/home_bloc.dart';
import 'package:ecogrid_intelligence/presentation/blocs/home/home_event.dart';
import 'package:ecogrid_intelligence/presentation/blocs/home/home_state.dart';
import 'package:ecogrid_intelligence/presentation/blocs/search/search_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<HomeBloc>()..add(const HomeLoadRequested())),
        BlocProvider(create: (_) => sl<SearchBloc>()),
      ],
      child: const _HomeScreenBody(),
    );
  }
}

class _HomeScreenBody extends StatelessWidget {
  const _HomeScreenBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacingMD),
              // ─── Header: Logo + LG Status ────────────────
              const _HeaderSection(),
              const SizedBox(height: AppTheme.spacingLG),
              // ─── Search Bar ──────────────────────────────
              const _SearchBarSection(),
              const SizedBox(height: AppTheme.spacingXL),
              // ─── Quick Explore ───────────────────────────
              const _QuickExploreSection(),
              const SizedBox(height: AppTheme.spacingLG),
              // ─── Tagline ────────────────────────────────
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingXL),
                  child: Text(
                    'Explore global energy infrastructure\nand climate risk',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textMuted,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              // ─── View Global Overview Button ─────────────
              const _GlobalOverviewButton(),
              const SizedBox(height: AppTheme.spacingXXL),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Header: EcoGrid Logo + LG Connection Status
// ─────────────────────────────────────────────────────────
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: AppTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.eco,
                  color: AppTheme.background,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EcoGrid',
                    style: AppTheme.headingSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Intelligence',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // LG Connection Status Badge
          BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              final status = state is HomeLoaded
                  ? state.lgStatus
                  : ConnectionStatus.disconnected;
              final isConnected = status == ConnectionStatus.connected;

              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.lgSettings),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: isConnected
                          ? AppTheme.connectedGreen.withValues(alpha: 0.4)
                          : AppTheme.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected
                              ? AppTheme.connectedGreen
                              : AppTheme.riskCritical,
                          boxShadow: isConnected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.connectedGreen
                                        .withValues(alpha: 0.6),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Liquid Galaxy',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            status.label,
                            style: AppTheme.labelSmall.copyWith(
                              color: isConnected
                                  ? AppTheme.connectedGreen
                                  : AppTheme.textMuted,
                              fontSize: 11,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.tv,
                        size: 20,
                        color: isConnected
                            ? AppTheme.connectedGreen
                            : AppTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────────────────────
class _SearchBarSection extends StatelessWidget {
  const _SearchBarSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: GestureDetector(
        onTap: () {
          // TODO: Navigate to full search screen
          _showSearchOverlay(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(
              color: AppTheme.cardBorder.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: AppTheme.textMuted, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search region or power plant...',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.tune, color: AppTheme.textMuted, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<SearchBloc>(),
        child: const _SearchOverlay(),
      ),
    );
  }
}

class _SearchOverlay extends StatefulWidget {
  const _SearchOverlay();

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Search input
            TextField(
              controller: _controller,
              autofocus: true,
              style: AppTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search regions or power plants...',
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.textMuted),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () {
                    _controller.clear();
                    context.read<SearchBloc>().add(const SearchCleared());
                  },
                ),
              ),
              onChanged: (query) {
                context.read<SearchBloc>().add(SearchQueryChanged(query));
              },
            ),
            const SizedBox(height: 16),
            // Results
            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  if (state.isSearching) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                      ),
                    );
                  }
                  if (state.results.isEmpty && state.query.isNotEmpty) {
                    return Center(
                      child: Text(
                        'No results found',
                        style: AppTheme.bodyMedium
                            .copyWith(color: AppTheme.textMuted),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: state.results.length,
                    itemBuilder: (context, index) {
                      final plant = state.results[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Icon(
                            _plantTypeIcon(plant.primaryFuel.displayName),
                            color: AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(plant.name, style: AppTheme.bodyMedium),
                        subtitle: Text(
                          '${plant.primaryFuel.displayName} • ${plant.countryLong ?? plant.country}',
                          style: AppTheme.caption,
                        ),
                        trailing:
                            Icon(Icons.chevron_right, color: AppTheme.textMuted),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            AppRoutes.plantDetail,
                            arguments: {'plant': plant},
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _plantTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'nuclear':
        return Icons.science;
      case 'hydroelectric':
        return Icons.water;
      case 'solar':
        return Icons.wb_sunny;
      case 'wind':
        return Icons.air;
      case 'coal/thermal':
        return Icons.factory;
      case 'natural gas':
        return Icons.local_fire_department;
      default:
        return Icons.bolt;
    }
  }
}

// ─────────────────────────────────────────────────────────
// Quick Explore Grid
// ─────────────────────────────────────────────────────────
class _QuickExploreSection extends StatelessWidget {
  const _QuickExploreSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
          child: Text(
            'QUICK EXPLORE',
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.textSecondary,
              letterSpacing: 2.5,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: Region.quickRegions.length,
            itemBuilder: (context, index) {
              final region = Region.quickRegions[index];
              return _RegionCard(region: region);
            },
          ),
        ),
      ],
    );
  }
}

class _RegionCard extends StatefulWidget {
  final Region region;
  const _RegionCard({required this.region});

  @override
  State<_RegionCard> createState() => _RegionCardState();
}

class _RegionCardState extends State<_RegionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        Navigator.pushNamed(
          context,
          AppRoutes.explore,
          arguments: {'region': widget.region},
        );
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Region illustration
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusMedium),
                  ),
                  child: widget.region.imageAsset != null
                      ? Image.asset(
                          widget.region.imageAsset!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => _fallbackIcon(),
                        )
                      : _fallbackIcon(),
                ),
              ),
              // Region name
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  widget.region.name,
                  style: AppTheme.labelLarge.copyWith(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              // Accent underline
              Container(
                width: 24,
                height: 2,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      color: AppTheme.surfaceLight,
      child: Center(
        child: Icon(
          Icons.public,
          color: AppTheme.primary.withValues(alpha: 0.5),
          size: 36,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// View Global Overview Button
// ─────────────────────────────────────────────────────────
class _GlobalOverviewButton extends StatefulWidget {
  const _GlobalOverviewButton();

  @override
  State<_GlobalOverviewButton> createState() => _GlobalOverviewButtonState();
}

class _GlobalOverviewButtonState extends State<_GlobalOverviewButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.explore,
              arguments: {'global': true});
        },
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color(0xFF00E5A0),
                  Color(0xFF00B4D8),
                  Color(0xFF00C9FF),
                ],
                stops: [
                  (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                  _shimmerController.value,
                  (_shimmerController.value + 0.3).clamp(0.0, 1.0),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.public, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  'View Global Overview',
                  style: AppTheme.labelLarge.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
