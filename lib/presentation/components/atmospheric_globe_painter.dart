import 'dart:math' as math;
import 'package:flutter/material.dart';

class FuturisticGlobeBackground extends StatefulWidget {
  final bool isDark;
  final bool animate;
  const FuturisticGlobeBackground({
    super.key,
    required this.isDark,
    this.animate = true,
  });
  @override
  State<FuturisticGlobeBackground> createState() =>
      _FuturisticGlobeBackgroundState();
}

class _FuturisticGlobeBackgroundState extends State<FuturisticGlobeBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _particleController;
  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (widget.animate) {
      _particleController.repeat();
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, _) {
        return CustomPaint(
          painter: _GlobePainter(
            isDark: widget.isDark,
            animValue: _particleController.value,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _GlobePainter extends CustomPainter {
  final bool isDark;
  final double animValue;
  _GlobePainter({required this.isDark, required this.animValue});
  static const _cyan = Color(0xFF00C8FF);
  static const _blue = Color(0xFF0066FF);
  static const _deepBlue = Color(0xFF030A1A);
  static const _midBlue = Color(0xFF061C35);
  @override
  void paint(Canvas canvas, Size size) {
    if (isDark) {
      _layer1SpaceBackground(canvas, size);
      _layer2PlanetHorizon(canvas, size);
      _layer3LatitudeLines(canvas, size);
      _layer4LongitudeLines(canvas, size);
      _layer5AtmosphericGlow(canvas, size);
      _layer6Particles(canvas, size);
      _layer7EnergyBeams(canvas, size);
    } else {
      _lightBackground(canvas, size);
    }
  }

  void _layer1SpaceBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_deepBlue, _midBlue],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    final centerGlowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 1.2),
        radius: 1.0,
        colors: [
          _cyan.withValues(alpha: 0.07),
          _blue.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      centerGlowPaint,
    );
  }

  void _layer2PlanetHorizon(Canvas canvas, Size size) {
    final globeR = size.width * 1.05;
    final globeCenter = Offset(
      size.width / 2,
      size.height * 0.62 + globeR * 0.72,
    );
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.40),
        radius: 1.0,
        colors: [
          const Color(0xFF0D3D52),
          const Color(0xFF082A3A),
          const Color(0xFF041C28),
          const Color(0xFF020E18),
        ],
        stops: const [0.0, 0.30, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: globeCenter, radius: globeR));
    canvas.drawCircle(globeCenter, globeR, bodyPaint);
    _drawContinents(canvas, globeCenter, globeR);
    for (int i = 5; i >= 0; i--) {
      final extra = [80.0, 55.0, 35.0, 20.0, 8.0, 0.0][i];
      final alpha = [0.02, 0.04, 0.08, 0.14, 0.22, 0.0][i];
      final stroke = [40.0, 28.0, 18.0, 10.0, 4.0, 1.5][i];
      if (i == 5) continue;
      final glowPaint = Paint()
        ..color = _cyan.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawCircle(globeCenter, globeR + extra, glowPaint);
    }
    final rimData = [
      [3.0, 0.55],
      [6.0, 0.30],
      [12.0, 0.15],
      [22.0, 0.07],
      [36.0, 0.03],
    ];
    for (final r in rimData) {
      final rimPaint = Paint()
        ..color = _cyan.withValues(alpha: r[1])
        ..style = PaintingStyle.stroke
        ..strokeWidth = r[0];
      canvas.drawCircle(globeCenter, globeR, rimPaint);
    }
    canvas.drawCircle(
      globeCenter,
      globeR,
      Paint()
        ..color = _cyan.withValues(alpha: 0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final highlightPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF80EEFF).withValues(alpha: 0.18),
              const Color(0xFF40CCEE).withValues(alpha: 0.08),
              Colors.transparent,
            ],
            stops: const [0.0, 0.40, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                globeCenter.dx - globeR * 0.28,
                globeCenter.dy - globeR * 0.35,
              ),
              radius: globeR * 0.42,
            ),
          );
    canvas.drawCircle(
      Offset(globeCenter.dx - globeR * 0.28, globeCenter.dy - globeR * 0.35),
      globeR * 0.42,
      highlightPaint,
    );
  }

  void _drawContinents(Canvas canvas, Offset center, double radius) {
    final continents = [
      _Continent(
        center.dx - radius * 0.30,
        center.dy - radius * 0.32,
        radius * 0.24,
        radius * 0.17,
        const Color(0xFF0F5A70),
        0.50,
      ),
      _Continent(
        center.dx + radius * 0.18,
        center.dy - radius * 0.25,
        radius * 0.30,
        radius * 0.16,
        const Color(0xFF0D4E62),
        0.42,
      ),
      _Continent(
        center.dx + radius * 0.08,
        center.dy + radius * 0.06,
        radius * 0.16,
        radius * 0.22,
        const Color(0xFF0A4455),
        0.38,
      ),
      _Continent(
        center.dx - radius * 0.22,
        center.dy + radius * 0.08,
        radius * 0.13,
        radius * 0.20,
        const Color(0xFF0C4E60),
        0.35,
      ),
    ];
    for (final c in continents) {
      final bounds = Rect.fromCenter(
        center: Offset(c.x, c.y),
        width: c.w * 2,
        height: c.h * 2,
      );
      canvas.drawOval(
        bounds,
        Paint()
          // A gradient gives the same soft edge without MaskFilter. Large
          // blurred ovals can disappear on older Android Vulkan drivers.
          ..shader = RadialGradient(
            colors: [
              c.color.withValues(alpha: c.opacity),
              c.color.withValues(alpha: c.opacity * 0.55),
              Colors.transparent,
            ],
            stops: const [0.0, 0.65, 1.0],
          ).createShader(bounds),
      );
    }
  }

  void _layer3LatitudeLines(Canvas canvas, Size size) {
    final globeR = size.width * 1.05;
    final globeCenter = Offset(
      size.width / 2,
      size.height * 0.62 + globeR * 0.72,
    );
    final paint = Paint()
      ..color = _cyan.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (int i = 1; i <= 6; i++) {
      final latFraction = i / 7.0;
      final yOffset = globeCenter.dy - globeR * (1.0 - latFraction * 1.6);
      if (yOffset > size.height || yOffset < 0) continue;
      final halfW = math.sqrt(
        math.max(0, globeR * globeR - math.pow(globeCenter.dy - yOffset, 2)),
      );
      if (halfW < 1) continue;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(globeCenter.dx, yOffset),
          width: halfW * 2,
          height: halfW * 0.30,
        ),
        paint,
      );
    }
  }

  void _layer4LongitudeLines(Canvas canvas, Size size) {
    final globeR = size.width * 1.05;
    final globeCenter = Offset(
      size.width / 2,
      size.height * 0.62 + globeR * 0.72,
    );
    final paint = Paint()
      ..color = _cyan.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8.0) * math.pi;
      canvas.save();
      canvas.translate(globeCenter.dx, globeCenter.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: globeR * 0.35,
          height: globeR * 2.0,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  void _layer5AtmosphericGlow(Canvas canvas, Size size) {
    final globeR = size.width * 1.05;
    final globeCenter = Offset(
      size.width / 2,
      size.height * 0.62 + globeR * 0.72,
    );
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          _cyan.withValues(alpha: 0.04),
          _cyan.withValues(alpha: 0.10),
          _cyan.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.72, 0.82, 0.92, 1.0],
      ).createShader(Rect.fromCircle(center: globeCenter, radius: globeR + 60));
    canvas.drawCircle(globeCenter, globeR + 60, haloPaint);
    final bluePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.9),
        radius: 0.6,
        colors: [_blue.withValues(alpha: 0.10), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bluePaint);
  }

  void _layer6Particles(Canvas canvas, Size size) {
    final rng = math.Random(42);
    for (int i = 0; i < 28; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height * 0.85;
      final radius = rng.nextDouble() * 1.5 + 0.5;
      final opacity = rng.nextDouble() * 0.45 + 0.10;
      final isCyan = rng.nextBool();
      final phase = rng.nextDouble() * math.pi * 2;
      final floatY = math.sin(animValue * math.pi * 2 + phase) * 3.0;
      canvas.drawCircle(
        Offset(baseX, baseY + floatY),
        radius,
        Paint()
          ..color = (isCyan ? _cyan : Colors.white).withValues(alpha: opacity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _layer7EnergyBeams(Canvas canvas, Size size) {
    final beamPositions = [0.15, 0.32, 0.50, 0.68, 0.85];
    for (final xFrac in beamPositions) {
      final x = size.width * xFrac;
      final beamPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            _cyan.withValues(alpha: 0.04),
            _cyan.withValues(alpha: 0.08),
            _cyan.withValues(alpha: 0.03),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
        ).createShader(Rect.fromLTWH(x - 6, 0, 12, size.height))
        // Avoid MaskFilter here: the narrow gradient is already soft, and
        // blurred shader rectangles are unreliable on some Android 11 GPUs.
        ..isAntiAlias = true;
      canvas.drawRect(
        Rect.fromLTWH(x - 6, size.height * 0.3, 12, size.height * 0.7),
        beamPaint,
      );
    }
  }

  void _lightBackground(Canvas canvas, Size size) {
    final globeColor = const Color(0xFFACC2EF);
    final connectionsColor = const Color(0xFF8AA3E8);
    final nodesColor = const Color(0xFF4A55FE);
    final highlightsColor = const Color(0xFF8860FF);
    final atmosphereColor = const Color(0xFFFFFFFF);
    final globeR = size.width * 1.05;
    final globeCenter = Offset(
      size.width / 2,
      size.height * 0.62 + globeR * 0.72,
    );
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          atmosphereColor,
          const Color(0xFFD6E2FF).withValues(alpha: 0.8),
          const Color(0xFFE8E5FF).withValues(alpha: 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.75, 0.88, 1.0],
      ).createShader(Rect.fromCircle(center: globeCenter, radius: globeR + 90));
    canvas.drawCircle(globeCenter, globeR + 90, haloPaint);
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.6),
        radius: 1.0,
        colors: [
          globeColor.withValues(alpha: 0.9),
          globeColor.withValues(alpha: 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: globeCenter, radius: globeR));
    canvas.drawCircle(globeCenter, globeR, bodyPaint);
    canvas.drawCircle(
      globeCenter,
      globeR,
      Paint()
        ..color = globeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    final continents = [
      _Continent(
        globeCenter.dx - globeR * 0.30,
        globeCenter.dy - globeR * 0.32,
        globeR * 0.24,
        globeR * 0.17,
        const Color(0xFF87A7ED),
        0.65,
      ),
      _Continent(
        globeCenter.dx + globeR * 0.18,
        globeCenter.dy - globeR * 0.25,
        globeR * 0.30,
        globeR * 0.16,
        const Color(0xFF87A7ED),
        0.60,
      ),
      _Continent(
        globeCenter.dx + globeR * 0.08,
        globeCenter.dy + globeR * 0.06,
        globeR * 0.16,
        globeR * 0.22,
        const Color(0xFF87A7ED),
        0.55,
      ),
    ];
    for (final c in continents) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.x, c.y),
          width: c.w * 2,
          height: c.h * 2,
        ),
        Paint()
          ..color = c.color.withValues(alpha: c.opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
    final latPaint = Paint()
      ..color = globeColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int i = 1; i <= 6; i++) {
      final latFraction = i / 7.0;
      final yOffset = globeCenter.dy - globeR * (1.0 - latFraction * 1.6);
      if (yOffset > size.height || yOffset < 0) continue;
      final halfW = math.sqrt(
        math.max(0, globeR * globeR - math.pow(globeCenter.dy - yOffset, 2)),
      );
      if (halfW < 1) continue;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(globeCenter.dx, yOffset),
          width: halfW * 2,
          height: halfW * 0.28,
        ),
        latPaint,
      );
    }
    final longPaint = Paint()
      ..color = globeColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8.0) * math.pi;
      canvas.save();
      canvas.translate(globeCenter.dx, globeCenter.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: globeR * 0.35,
          height: globeR * 2.0,
        ),
        longPaint,
      );
      canvas.restore();
    }
    final rng = math.Random(100);
    final List<Offset> nodes = [];
    for (int i = 0; i < 16; i++) {
      final angle = (rng.nextDouble() - 0.5) * math.pi * 0.7;
      final distance = globeR * (0.85 + rng.nextDouble() * 0.14);
      final dx = globeCenter.dx + distance * math.sin(angle);
      final dy = globeCenter.dy - distance * math.cos(angle);
      final floatY = math.sin(animValue * math.pi * 2 + i) * 2.0;
      nodes.add(Offset(dx, dy + floatY));
    }
    final connPaint = Paint()
      ..color = connectionsColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final d = (nodes[i] - nodes[j]).distance;
        if (d < size.width * 0.45) {
          final shimmer = math.sin(animValue * math.pi * 4 + i + j) * 0.3 + 0.5;
          connPaint.color = connectionsColor.withValues(alpha: shimmer);
          final path = Path();
          path.moveTo(nodes[i].dx, nodes[i].dy);
          final midX = (nodes[i].dx + nodes[j].dx) / 2;
          final midY = (nodes[i].dy + nodes[j].dy) / 2;
          final vecX = globeCenter.dx - midX;
          final vecY = globeCenter.dy - midY;
          final len = math.sqrt(vecX * vecX + vecY * vecY);
          final ctrlX = midX + (vecX / len) * d * 0.15;
          final ctrlY = midY + (vecY / len) * d * 0.15;
          path.quadraticBezierTo(ctrlX, ctrlY, nodes[j].dx, nodes[j].dy);
          canvas.drawPath(path, connPaint);
        }
      }
    }
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final pulse = math.sin(animValue * math.pi * 2 + i * 0.5) * 0.5 + 0.5;
      canvas.drawCircle(
        node,
        6.0 + pulse * 2.5,
        Paint()
          ..color = highlightsColor.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(node, 3.0, Paint()..color = nodesColor);
      if (i % 3 == 0) {
        final beamPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              highlightsColor.withValues(alpha: 0.35 + pulse * 0.15),
              highlightsColor.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(node.dx - 1.5, node.dy - 120, 3, 120));
        canvas.drawRect(
          Rect.fromLTWH(node.dx - 1.5, node.dy - 120, 3, 120),
          beamPaint,
        );
      }
    }
    final particleRng = math.Random(88);
    for (int i = 0; i < 30; i++) {
      final baseX = particleRng.nextDouble() * size.width;
      final baseY = particleRng.nextDouble() * size.height * 0.7;
      final radius = particleRng.nextDouble() * 1.8 + 0.6;
      final isHighlight = particleRng.nextBool();
      final phase = particleRng.nextDouble() * math.pi * 2;
      final floatY = math.sin(animValue * math.pi * 2 + phase) * 10.0;
      final floatX = math.cos(animValue * math.pi * 2 + phase) * 5.0;
      final opacity = particleRng.nextDouble() * 0.4 + 0.2;
      canvas.drawCircle(
        Offset(baseX + floatX, baseY + floatY),
        radius,
        Paint()
          ..color = (isHighlight ? highlightsColor : nodesColor).withValues(
            alpha: opacity,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlobePainter oldDelegate) =>
      oldDelegate.animValue != animValue || oldDelegate.isDark != isDark;
}

class _Continent {
  final double x, y, w, h, opacity;
  final Color color;
  _Continent(this.x, this.y, this.w, this.h, this.color, this.opacity);
}
