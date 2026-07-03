import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/routes/app_routes.dart';
import '../../config/theme/theme_controller.dart';

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
      duration: const Duration(milliseconds: 3000),
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
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: isDark
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF00D4AA,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 60,
                                        spreadRadius: 10,
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF0066FF,
                                        ).withValues(alpha: 0.15),
                                        blurRadius: 60,
                                        spreadRadius: 10,
                                      ),
                                    ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/splashscreen_logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: _fadeIn,
                        child: Text(
                          'EcoGrid Intelligence',
                          style: GoogleFonts.outfit(
                            fontSize: 26,
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
                        opacity: _fadeIn,
                        child: Text(
                          'AI-Driven Climate Resilience on Liquid Galaxy',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF6B80A0),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      FadeTransition(
                        opacity: _fadeIn,
                        child: SizedBox(
                          width: 160,
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              final progress =
                                  ((_controller.value - 0.2) / 0.65).clamp(
                                    0.0,
                                    1.0,
                                  );
                              return Stack(
                                children: [
                                  Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white12
                                          : const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: progress,
                                    child: Container(
                                      height: 3,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isDark
                                              ? const [
                                                  Color(0xFF00D4AA),
                                                  Color(0xFF00A8FF),
                                                ]
                                              : const [
                                                  Color(0xFF0066FF),
                                                  Color(0xFF00C8FF),
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeIn,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.public,
                              size: 14,
                              color: isDark
                                  ? const Color(0xFF00D4AA)
                                  : const Color(0xFF0066FF),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Liquid Galaxy LAB Project',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF00D4AA)
                                    : const Color(0xFF0066FF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
