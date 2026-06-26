import '../explore/bloc/explore_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_theme.dart';
import '../../config/theme/theme_controller.dart';
import '../../config/theme/region_asset_resolver.dart';
import '../../config/routes/app_routes.dart';
import '../../domain/model/region.dart';
import '../../di/di.dart';
import 'bloc/home_bloc.dart';
import 'bloc/home_event.dart';
import '../components/app_search_bar.dart';
import '../components/atmospheric_globe_painter.dart';
import '../components/lg_connection_pill.dart';

const Color bgWhite = Color(0xFFF6FAFD); // screen background
const Color deepNavy = Color(0xFF0A1931); // card base
const Color midNavy = Color(0xFF1A3D63); // card border, elevated
const Color steelBlue = Color(0xFF4A7FA7); // glow, accents, icons
const Color powder = Color(0xFFB3CFE5); // muted text, subtle tints
const Color snowWhite = Color(0xFFF6FAFD);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<HomeBloc>()..add(const HomeLoadRequested()),
        ),
        BlocProvider(create: (_) => sl<ExploreBloc>()),
      ],
      child: const _HomePageBody(),
    );
  }
}

class _HomePageBody extends StatelessWidget {
  const _HomePageBody();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeModeNotifier,
      builder: (context, preset, _) {
        final isDark = ThemeController.instance.isDarkMode;
        final screenWidth = MediaQuery.of(context).size.width;

        return Scaffold(
          backgroundColor: isDark ? AppTheme.background : bgWhite,
          body: Stack(
            children: [
              isDark
                  ? Positioned(
                      bottom: -screenWidth * 0.3,
                      left: 0,
                      right: 0,
                      height: screenWidth * 0.9,
                      child: Opacity(
                        opacity: 1.0,
                        child: FuturisticGlobeBackground(isDark: isDark),
                      ),
                    )
                  : const SizedBox.shrink(),
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppTheme.spacingMD),
                          _HeaderSection(isDark: isDark),
                          const SizedBox(height: AppTheme.spacingLG),
                          _SearchBarSection(isDark: isDark),
                          const SizedBox(height: AppTheme.spacingXL),
                          _QuickExploreSection(isDark: isDark),
                          const SizedBox(height: AppTheme.spacingLG + 16),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingXL,
                              ),
                              child: Text(
                                'Explore global energy infrastructure\nand climate risk',
                                textAlign: TextAlign.center,
                                style: AppTheme.bodySmall.copyWith(
                                  color: isDark
                                      ? const Color(0xFF4A5568)
                                      : steelBlue.withValues(alpha: 0.65),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: AppTheme.spacingLG),
                            _GlobalOverviewButton(isDark: isDark),
                            const SizedBox(height: AppTheme.spacingXL),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final bool isDark;
  const _HeaderSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceLight,
                  border: Border.all(color: AppTheme.cardBorder, width: 1.0),
                ),
                child: Center(
                  child: Icon(
                    Icons.public,
                    color: isDark ? const Color(0xFF00C8FF) : midNavy,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EcoGrid',
                    style: AppTheme.headingSmall.copyWith(
                      color: isDark ? Colors.white : deepNavy,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    'Intelligence',
                    style: AppTheme.bodySmall.copyWith(
                      color: isDark ? const Color(0xFF00C8FF) : steelBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 1,
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
}

class _SearchBarSection extends StatelessWidget {
  final bool isDark;
  const _SearchBarSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: AppSearchBar(
        hintText: 'Search regions or power plants...',
        readOnly: true,
        onTap: () => Navigator.pushNamed(context, AppRoutes.search),
      ),
    );
  }
}

class _QuickExploreSection extends StatelessWidget {
  final bool isDark;
  const _QuickExploreSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
          child: Row(
            children: [
              Text(
                'QUICK EXPLORE',
                style: AppTheme.labelSmall.copyWith(
                  color: isDark ? const Color(0xFF00C8FF) : midNavy,
                  letterSpacing: isDark ? 2.5 : 2.0,
                  fontWeight: isDark ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.auto_awesome,
                color: isDark ? const Color(0xFF00C8FF) : steelBlue,
                size: 14,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 0.78,
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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getRegionColor(String regionId) {
    switch (regionId) {
      case 'india':
        return const Color(0xFF00C853);
      case 'europe':
        return const Color(0xFF00C8FF);
      case 'usa':
        return const Color(0xFF4A90D9);
      case 'china':
        return const Color(0xFF7B8FD4);
      case 'africa':
        return const Color(0xFF00C8FF); // Teal/Cyan for Africa in screenshot
      case 'spain':
        return const Color(0xFFB388FF); // Purple for Spain
      case 'south_asia':
        return const Color(0xFFB388FF);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    final regionColor = _getRegionColor(widget.region.id);

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
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: isDark
            ? Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.cardBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildDarkCard(regionColor),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: Container(
                  decoration: BoxDecoration(
                    color: deepNavy,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: steelBlue.withValues(alpha: 0.55),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: deepNavy.withValues(alpha: 0.28),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: steelBlue.withValues(alpha: 0.20),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildLightCard(regionColor),
                ),
              ),
      ),
    );
  }

  Widget _buildDarkCard(Color regionColor) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 24,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              RegionAssetResolver.getRegionImage(widget.region.id),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.region.name,
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 24,
                height: 2,
                decoration: BoxDecoration(
                  color: regionColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLightCard(Color regionColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: powder.withValues(alpha: 0.18),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMedium),
                topRight: Radius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMedium),
                topRight: Radius.circular(AppTheme.radiusMedium),
              ),
              child: Image.asset(
                RegionAssetResolver.getRegionImage(widget.region.id),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.region.name,
                  style: AppTheme.labelLarge.copyWith(
                    fontSize: 15,
                    color: snowWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: midNavy,
                    border: Border.all(
                      color: steelBlue.withValues(alpha: 0.60),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: steelBlue.withValues(alpha: 0.45),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: powder,
                    size: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlobalOverviewButton extends StatefulWidget {
  final bool isDark;
  const _GlobalOverviewButton({required this.isDark});

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
    final isDark = widget.isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.infrastructureMap);
        },
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: isDark
                ? BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0066FF), Color(0xFF00C8FF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C8FF).withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  )
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    gradient: const LinearGradient(
                      colors: [deepNavy, midNavy, steelBlue, powder],
                      stops: [0.0, 0.35, 0.70, 1.0],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: midNavy.withValues(alpha: 0.45),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: steelBlue.withValues(alpha: 0.30),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: powder.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.public,
                      color: isDark ? Colors.white : snowWhite,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Show Infrastructure Map',
                      style: AppTheme.labelLarge.copyWith(
                        color: isDark ? Colors.white : snowWhite,
                        fontSize: 16,
                        fontWeight: isDark ? FontWeight.w600 : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward,
                      color: isDark ? Colors.white : snowWhite,
                      size: 16,
                    ),
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
