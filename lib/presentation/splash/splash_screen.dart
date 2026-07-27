import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/routes/app_routes.dart';
import '../../config/theme/theme_controller.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;
  late Animation<double> _fadeOut;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.30, curve: Curves.easeOutCubic),
      ),
    );
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.80, 1.0, curve: Curves.easeIn),
      ),
    );
    _controller.forward();
    _controller.addStatusListener((status) {
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
    _controller.dispose();
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
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeOut.value,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeTransition(
                        opacity: _fadeIn,
                        child: ScaleTransition(
                          scale: _scale,
                          child: Container(
                            width: 500,
                            height: 500,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: isDark
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF00D4AA).withValues(alpha: 0.3),
                                        blurRadius: 60,
                                        spreadRadius: 10,
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFF0066FF).withValues(alpha: 0.15),
                                        blurRadius: 60,
                                        spreadRadius: 10,
                                      ),
                                    ],
                            ),
                            child: Image.asset(
                              'assets/images/logos.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
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
