import 'package:flutter/material.dart';
import '../../config/routes/app_routes.dart';
import '../../config/theme/theme_controller.dart';
import '../../config/theme/app_theme.dart';
import '../../service/lg_service.dart';
import '../../domain/model/lg_settings.dart';
import '../../core/resources/data_state.dart';
import '../../di/di.dart';
import '../lg_connection/bloc/lg_connection_bloc.dart';
import '../../service/tour_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logosController;
  late Animation<double> _logosFade;

  late AnimationController _appSplashController;
  late Animation<double> _appFadeIn;
  late Animation<double> _appScale;

  bool _showAppSplash = false;

  @override
  void initState() {
    super.initState();
    _logosController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _logosFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logosController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _appSplashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _appFadeIn = CurvedAnimation(
      parent: _appSplashController,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    );
    _appScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _appSplashController,
        curve: const Interval(0.0, 0.30, curve: Curves.easeOutCubic),
      ),
    );

    _logosController.forward();
    _logosController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _showAppSplash = true;
        });
        _appSplashController.forward();
      }
    });

    _appSplashController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        // Kick off the FTUE tour if this is a first launch.
        sl<TourService>().checkAndStartTour();
        final lgService = sl<LGService>();
        lgService.loadSettings().then((result) {
          if (result is DataSuccess<LGSettings> && result.data!.host.isNotEmpty) {
            sl<LGConnectionBloc>().add(LGConnectRequested(result.data!));
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _logosController.dispose();
    _appSplashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : Colors.white,
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: !_showAppSplash
                ? AnimatedBuilder(
                    key: const ValueKey('logos_splash'),
                    animation: _logosController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _logosFade,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          child: Image.asset(
                            'assets/images/splash_screen.png',
                            fit: BoxFit.fill,
                          ),
                        ),
                      );
                    },
                  )
                : AnimatedBuilder(
                    key: const ValueKey('app_loading_splash'),
                    animation: _appSplashController,
                    builder: (context, child) {
                      final glowProgress = (_appSplashController.value / 0.75)
                          .clamp(0.0, 1.0);
                      final easedGlow = Curves.easeOutCubic.transform(
                        glowProgress,
                      );
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FadeTransition(
                              opacity: _appFadeIn,
                              child: ScaleTransition(
                                scale: _appScale,
                                child: Container(
                                  width: 240,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? const Color(0xFF141C2E)
                                        : Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00D4AA)
                                            .withValues(
                                              alpha: 0.55 * easedGlow,
                                            ),
                                        blurRadius: 20 + (60 * easedGlow),
                                        spreadRadius: 2 + (18 * easedGlow),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Transform.scale(
                                      scale: 1.45,
                                      child: Image.asset(
                                        'assets/images/app_logo.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),
                            FadeTransition(
                              opacity: _appFadeIn,
                              child: Text(
                                'EcoGrid Intelligence',
                                style: AppTheme.headingLarge.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0D1F4A),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FadeTransition(
                              opacity: _appFadeIn,
                              child: Text(
                                'AI-Driven Climate Resilience on Liquid Galaxy',
                                textAlign: TextAlign.center,
                                style: AppTheme.bodySmall.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: isDark
                                      ? Colors.white54
                                      : const Color(0xFF6B80A0),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 50),
                            FadeTransition(
                              opacity: _appFadeIn,
                              child: SizedBox(
                                width: 180,
                                child: AnimatedBuilder(
                                  animation: _appSplashController,
                                  builder: (context, _) {
                                    final progress =
                                        ((_appSplashController.value - 0.1) /
                                                0.8)
                                            .clamp(0.0, 1.0);
                                    return Stack(
                                      children: [
                                        Container(
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white12
                                                : const Color(0xFFE2E8F0),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: progress,
                                          child: Container(
                                            height: 4,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF00D4AA),
                                                  Color(0xFF00A8FF),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF00D4AA)
                                                      .withValues(alpha: 0.6),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            FadeTransition(
                              opacity: _appFadeIn,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.public,
                                    size: 16,
                                    color: Color(0xFF00D4AA),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Liquid Galaxy LAB Project',
                                    style: AppTheme.labelLarge.copyWith(
                                      fontSize: 13,
                                      color: const Color(0xFF00D4AA),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

