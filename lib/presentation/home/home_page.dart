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
import 'package:permission_handler/permission_handler.dart';
import '../../service/speech_to_text_service.dart';
import 'widgets/stt_listening_overlay.dart';
import '../components/atmospheric_globe_painter.dart';
import '../components/lg_connection_pill.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../service/tour_service.dart';
import '../../core/enums/tour_phase.dart';
import '../../core/constants/tour_keys.dart';
import '../components/eco_showcase.dart';

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

class _HomePageBody extends StatefulWidget {
  const _HomePageBody();
  @override
  State<_HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<_HomePageBody> {
  bool _isListening = false;
  double _soundLevel = 0.0;
  String _partialText = '';
  
  SpeechToTextService get _stt => sl<SpeechToTextService>();
  final TourService _tourService = sl<TourService>();

  @override
  void initState() {
    super.initState();
    // Listen for both tour activation AND phase changes.
    // checkAndStartTour() is async (SharedPreferences), so isTourActive
    // may flip to true at any point after the home page is built.
    _tourService.isTourActive.addListener(_onTourStateChanged);
    _tourService.currentPhase.addListener(_onTourPhaseChanged);
    // Fire once after first frame in case the tour is already active
    // (e.g. returning to home mid-tour).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onTourStateChanged();
    });
  }

  @override
  void dispose() {
    _tourService.isTourActive.removeListener(_onTourStateChanged);
    _tourService.currentPhase.removeListener(_onTourPhaseChanged);
    super.dispose();
  }

  /// Called when [isTourActive] changes. Triggers the current phase.
  void _onTourStateChanged() {
    if (!mounted || !_tourService.isTourActive.value) return;
    _triggerCurrentPhase();
  }

  /// Called when [currentPhase] changes. Triggers the new phase.
  void _onTourPhaseChanged() {
    if (!mounted || !_tourService.isTourActive.value) return;
    _triggerCurrentPhase();
  }

  /// Triggers the showcase for the current tour phase on the home screen.
  /// Waits for the route animation to complete + an extra frame to ensure
  /// all widgets are laid out.
  void _triggerCurrentPhase() {
    final phase = _tourService.currentPhase.value;
    
    void trigger() {
      if (!mounted) return;
      switch (phase) {
        case TourPhase.homeSettings:
          _tourService.showIfPhase(context, TourPhase.homeSettings, [TourKeys.settings]);
          break;
        case TourPhase.homeRegion:
          _tourService.showIfPhase(context, TourPhase.homeRegion, [TourKeys.region]);
          break;
        case TourPhase.homeInfraMap:
          _tourService.showIfPhase(context, TourPhase.homeInfraMap, [TourKeys.infraMap]);
          break;
        default:
          break;
      }
    }

    // Wait for route animation + two extra frames to ensure layout is settled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && route.animation != null && !route.animation!.isCompleted) {
        route.animation!.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) trigger();
                });
              }
            });
          }
        });
      } else {
        // Animation already complete — wait one more frame to be safe.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) trigger();
        });
      }
    });
  }

  void _startListening() async {
    setState(() {
      _partialText = '';
      _soundLevel = 0.0;
    });

    final status = await _stt.startListening(
      onResult: (words) {
        if (mounted) {
          setState(() {
            _partialText = words;
          });
        }
      },
      onListening: (listening) {
        if (mounted) {
          setState(() => _isListening = listening);
          if (!listening && _partialText.isNotEmpty) {
            Navigator.pushNamed(
              context,
              AppRoutes.search,
              arguments: {'initialQuery': _partialText},
            );
          }
        }
      },
      onSoundLevelChange: (level) {
        if (mounted) {
          final normalized = ((level + 40) / 50).clamp(0.0, 1.0);
          setState(() => _soundLevel = normalized);
        }
      },
    );

    if (mounted) {
      if (status == SttPermissionStatus.permanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Microphone permission permanently denied. Please enable it in Settings.'),
            backgroundColor: AppTheme.surface,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      } else if (status == SttPermissionStatus.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Microphone unavailable or permission denied.'),
            backgroundColor: AppTheme.surface,
          ),
        );
      }
    }
  }

  void _stopListening() async {
    await _stt.stopListening();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeModeNotifier,
      builder: (context, preset, _) {
        final isDark = ThemeController.instance.isDarkMode;
        final screenWidth = MediaQuery.of(context).size.width;
        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: isDark ? AppTheme.background : Colors.white,
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
              isDark
                  ? Positioned(
                      bottom: -screenWidth * 0.3,
                      left: 0,
                      right: 0,
                      height: screenWidth * 0.9,
                      child: ShaderMask(
                        shaderCallback: (rect) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.white],
                            stops: [0.0, 0.35],
                          ).createShader(rect);
                        },
                        blendMode: BlendMode.dstIn,
                        child: FuturisticGlobeBackground(isDark: isDark),
                      ),
                    )
                  : Positioned(
                      bottom: -screenWidth * 0.18,
                      left: -screenWidth * 0.15,
                      right: -screenWidth * 0.15,
                      height: screenWidth * 1.15,
                      child: Image.asset(
                        'assets/images/hero_globe_light.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.spacingMD),
                    _HeaderSection(isDark: isDark),
                    const SizedBox(height: AppTheme.spacingLG),
                    _SearchBarSection(
                      isDark: isDark,
                      onMicTap: _startListening,
                    ),
                    const SizedBox(height: AppTheme.spacingXL),
                    _QuickExploreSection(isDark: isDark),
                    
                    const Spacer(),
                    
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
                                ? AppTheme.textSecondary
                                : const Color(0xFF6B80A0),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 3),
                    
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: EcoShowcase(
                        showcaseKey: TourKeys.infraMap,
                        title: 'Infrastructure Map',
                        description: 'Tap to view the global infrastructure map',
                        targetBorderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        disposeOnTap: false,
                        onTargetClick: () {},
                        onNextClick: () {
                          ShowCaseWidget.of(context).dismiss();
                          sl<TourService>().advancePhase();
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) Navigator.pushNamed(context, AppRoutes.infrastructureMap);
                          });
                        },
                        child: _InfrastructureMapButton(isDark: isDark),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXL),
                  ],
                ),
              ),
              
              if (_isListening)
                SttListeningOverlay(
                  soundLevel: _soundLevel,
                  partialText: _partialText,
                  onStop: _stopListening,
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
                  color: isDark ? AppTheme.surfaceLight : Colors.white,
                  border: Border.all(
                    color: isDark ? AppTheme.cardBorder : Colors.transparent,
                    width: 1.0,
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Center(
                  child: Icon(
                    Icons.public,
                    color: isDark ? AppTheme.primary : const Color(0xFF00C8FF),
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
                      color: isDark
                          ? AppTheme.textPrimary
                          : const Color(0xFF0D1F4A),
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    'Intelligence',
                    style: AppTheme.bodySmall.copyWith(
                      color: isDark
                          ? AppTheme.primary
                          : const Color(0xFF0066FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          EcoShowcase(
            showcaseKey: TourKeys.settings,
            title: 'Connect to Liquid Galaxy',
            description: 'Tap here to connect to your Liquid Galaxy rig',
            targetBorderRadius: BorderRadius.circular(AppTheme.radiusFull),
            disposeOnTap: false,
            onTargetClick: () {},
            onNextClick: () {
              ShowCaseWidget.of(context).dismiss();
              sl<TourService>().advancePhase();
              Future.delayed(const Duration(milliseconds: 300), () {
                if (context.mounted) Navigator.pushNamed(context, AppRoutes.lgSettings);
              });
            },
            child: const LgConnectionPill(),
          ),
        ],
      ),
    );
  }
}

class _SearchBarSection extends StatelessWidget {
  final bool isDark;
  final VoidCallback onMicTap;
  const _SearchBarSection({required this.isDark, required this.onMicTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: AppSearchBar(
        hintText: 'Search regions or power plants...',
        readOnly: true,
        onTap: () => Navigator.pushNamed(context, AppRoutes.search),
        onMicTap: onMicTap,
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
                  color: isDark ? AppTheme.primary : const Color(0xFF0066FF),
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.auto_awesome,
                color: isDark ? AppTheme.primary : const Color(0xFF0066FF),
                size: 14,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Builder(
            builder: (context) {
              final crossAxisCount = MediaQuery.of(context).size.width < 340 ? 2 : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 0.78,
                ),
                itemCount: Region.quickRegions.length,
                itemBuilder: (context, index) {
                  final region = Region.quickRegions[index];
                  final card = _RegionCard(region: region, isDark: isDark);
                  if (index == 0) {
                    return EcoShowcase(
                      showcaseKey: TourKeys.region,
                      title: 'Pick a Region',
                      description: 'Tap a region to explore its energy infrastructure',
                      targetBorderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      disposeOnTap: false,
                      onTargetClick: () {},
                      onNextClick: () {
                        ShowCaseWidget.of(context).dismiss();
                        sl<TourService>().advancePhase();
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (context.mounted) {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.explore,
                              arguments: {'region': region},
                            );
                          }
                        });
                      },
                      child: card,
                    );
                  }
                  return card;
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RegionCard extends StatefulWidget {
  final Region region;
  final bool isDark;
  const _RegionCard({required this.region, required this.isDark});
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
      case 'italy':
        return const Color(0xFF00C8FF);
      case 'usa':
        return const Color(0xFF4A90D9);
      case 'china':
        return const Color(0xFF7B8FD4);
      case 'kenya':
        return const Color(0xFF00C8FF);
      case 'spain':
        return const Color(0xFFB388FF);
      case 'south_asia':
        return const Color(0xFFB388FF);
      default:
        return AppTheme.primary;
    }
  }

  double _getRegionImageScale(String regionId, {bool isDark = false}) {
    if (isDark) {
      switch (regionId) {
        case 'kenya': return 1.35;
        case 'italy': return 1.40;
        case 'spain':  return 1.0;
        default: return 1.0;
      }
    }
    // Light theme — keep original values
    if (regionId == 'italy') return 1.25;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
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
        child: widget.isDark
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
                child: _buildCard(regionColor),
              )
            : _buildLightCard(regionColor),
      ),
    );
  }

  Widget _buildLightCard(Color regionColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Transform.scale(
                scale: _getRegionImageScale(widget.region.id, isDark: false),
                child: Image.asset(
                  RegionAssetResolver.getRegionImage(
                    widget.region.id,
                    ThemeMode.light,
                  ),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.region.name,
                  style: AppTheme.bodyMedium.copyWith(
                    color: const Color(0xFF1A3D63),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: 3,
                  decoration: BoxDecoration(
                    color: regionColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Color regionColor) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 24,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Transform.scale(
              scale: _getRegionImageScale(widget.region.id, isDark: true),
              child: Image.asset(
                RegionAssetResolver.getRegionImage(widget.region.id),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
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
}

class _InfrastructureMapButton extends StatefulWidget {
  final bool isDark;
  const _InfrastructureMapButton({required this.isDark});
  @override
  State<_InfrastructureMapButton> createState() =>
      _InfrastructureMapButtonState();
}

class _InfrastructureMapButtonState extends State<_InfrastructureMapButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Light theme: static bright-blue gradient, narrower width ──────────
    if (!widget.isDark) {
      return Padding(
        padding: const EdgeInsets.only(
          left: 32,
          right: 32,
          bottom: 0,
        ),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            Navigator.pushNamed(context, AppRoutes.infrastructureMap);
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeInOut,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0055EE), Color(0xFF0099FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0066FF).withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Icon(Icons.public, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Show Infrastructure Map',
                        style: AppTheme.labelLarge.copyWith(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.0,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        softWrap: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── Dark theme: animated flowing navy shimmer ──────────────────────────
    return Padding(
      padding: const EdgeInsets.only(
        left: 32,
        right: 32,
        bottom: 0,
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          Navigator.pushNamed(context, AppRoutes.infrastructureMap);
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeInOut,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: const [
                      Color(0xFF1A3FBF),
                      Color(0xFF1E5CE6),
                      Color(0xFF2979FF),
                      Color(0xFF1E5CE6),
                      Color(0xFF1A3FBF),
                    ],
                    stops: [
                      (t - 0.5).clamp(0.0, 1.0),
                      (t - 0.25).clamp(0.0, 1.0),
                      t.clamp(0.0, 1.0),
                      (t + 0.25).clamp(0.0, 1.0),
                      (t + 0.5).clamp(0.0, 1.0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A3FBF).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        child: Align(
                          alignment: Alignment(-1.8 + t * 3.6, 0),
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.12),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.public, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Show Infrastructure Map',
                              style: AppTheme.labelLarge.copyWith(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.0,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                              softWrap: false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

