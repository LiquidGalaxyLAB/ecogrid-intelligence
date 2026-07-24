import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../config/theme/app_theme.dart';
import '../../core/enums/risk_level.dart';
import '../../core/resources/data_state.dart';
import '../../di/di.dart';
import '../../domain/model/cvs_result.dart';
import '../../domain/model/plant_context_payload.dart';
import '../../domain/model/power_plant.dart';
import '../../domain/repository/cvs_repository.dart';
import '../../domain/usecases/ai/services/generate_plant_insight_usecase.dart';
import '../../service/lg_service.dart';
import '../../core/utils/comparison_tour_builder.dart';
import '../../core/utils/comparison_kml_builder.dart';
import '../../core/utils/comparison_balloon_builder.dart';
import '../../core/utils/kml_utils.dart';
import '../../domain/model/lg_settings.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry-point widget
// ─────────────────────────────────────────────────────────────────────────────

class PlantComparisonScreen extends StatefulWidget {
  final List<PowerPlant> plants;
  final CvsRepository cvsRepository;

  const PlantComparisonScreen({
    super.key,
    required this.plants,
    required this.cvsRepository,
  });

  @override
  State<PlantComparisonScreen> createState() => _PlantComparisonScreenState();
}

class _PlantComparisonScreenState extends State<PlantComparisonScreen> {
  bool _globalIsFront = true;

  void _toggleGlobalFlip() {
    setState(() {
      _globalIsFront = !_globalIsFront;
    });
  }
  bool _isCarouselMode = true;

  @override
  void initState() {
    super.initState();
    _startComparisonTour();
  }

  Future<void> _startComparisonTour() async {
    final lgService = sl<LGService>();
    final kml = ComparisonTourBuilder.build(plants: widget.plants);
    
    // Calculate unified scores for accurate risk colors
    final scores = widget.plants.map((p) => widget.cvsRepository.getUnifiedScore(p)).toList();
    
    final networkKml = ComparisonKmlBuilder.build(
      plants: widget.plants,
      cvsResults: scores,
      tourKml: kml,
    );
    await lgService.sendKmlToMaster(networkKml);

    // Send the comparison balloon to the rightmost screen
    final bbox = ComparisonTourBuilder.boundingBox(widget.plants);
    final balloonKml = ComparisonBalloonBuilder.build(
      plants: widget.plants,
      cvsResults: scores,
      lat: bbox.centerLat,
      lon: bbox.centerLon,
    );
    
    final settingsResult = await lgService.loadSettings();
    int rightmostScreen = LGSettings.empty.rightmostScreen;
    if (settingsResult is DataSuccess) {
      rightmostScreen = settingsResult.data!.rightmostScreen;
    }
    await lgService.showBalloonOnSlave(rightmostScreen, balloonKml);

    // Then start the tour
    await lgService.startComparisonTour(ComparisonTourBuilder.tourName);
  }

  bool _isCleanedUp = false;

  @override
  void dispose() {
    if (!_isCleanedUp) {
      // Best-effort fallback, not the primary cleanup path — see PopScope above.
      final lgService = sl<LGService>();
      lgService.stopOrbit();
      lgService.clearKml();
      // Note: clearKml() already clears all slave screens (which includes rightmostScreen).
      // This separate clearBalloonOnSlave call might be redundant, but is left as-is for safety.
      lgService.loadSettings().then((result) {
        if (result is DataSuccess<LGSettings>) {
          lgService.clearBalloonOnSlave(result.data!.rightmostScreen);
        }
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) return;
        _isCleanedUp = true;
        final lgService = sl<LGService>();
        await lgService.stopOrbit();
        await lgService.clearKml();
        final settingsResult = await lgService.loadSettings();
        if (settingsResult is DataSuccess<LGSettings>) {
          final rightmostScreen = settingsResult.data!.rightmostScreen;
          await lgService.clearBalloonOnSlave(rightmostScreen);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text('Plant Comparison'),
          actions: [
            IconButton(
              onPressed: () => setState(() => _isCarouselMode = !_isCarouselMode),
              icon: Icon(
                _isCarouselMode
                    ? Icons.grid_view_rounded
                    : Icons.view_carousel_rounded,
              ),
              tooltip: _isCarouselMode ? 'Grid View' : 'Carousel View',
            ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: _isCarouselMode
              ? _CarouselView(
                  key: const ValueKey('carousel'),
                  plants: widget.plants,
                  cvsRepository: widget.cvsRepository,
                  isFront: _globalIsFront,
                  onFlip: _toggleGlobalFlip,
                )
              : _ComparisonGridView(
                  key: const ValueKey('grid'),
                  plants: widget.plants,
                  cvsRepository: widget.cvsRepository,
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carousel View
// ─────────────────────────────────────────────────────────────────────────────

class _CarouselView extends StatefulWidget {
  final List<PowerPlant> plants;
  final CvsRepository cvsRepository;
  final bool isFront;
  final VoidCallback onFlip;
  const _CarouselView({
    super.key,
    required this.plants,
    required this.cvsRepository,
    required this.isFront,
    required this.onFlip,
  });

  @override
  State<_CarouselView> createState() => _CarouselViewState();
}

class _CarouselViewState extends State<_CarouselView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentPage = 0;
  double _rotationOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rotate(int direction) {
    if (_controller.isAnimating) return;

    int count = widget.plants.length;
    int next = (_currentPage + direction) % count;
    if (next < 0) next += count;

    final double start = _rotationOffset;
    final double end = start + (direction * (2 * math.pi / count));

    Animation<double> anim = Tween<double>(begin: start, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    anim.addListener(() {
      setState(() {
        _rotationOffset = anim.value;
      });
    });

    _controller.forward(from: 0.0).then((_) {
      setState(() {
        _currentPage = next;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final int count = widget.plants.length;
    final double angleStep = 2 * math.pi / count;

    List<Widget> cardStack = [];
    List<Map<String, dynamic>> cardData = [];

    for (int i = 0; i < count; i++) {
      double currentAngle = (i * angleStep) - _rotationOffset + (math.pi / 2);

      double sinValue = math.sin(currentAngle);
      double cosValue = math.cos(currentAngle);

      double depth = (sinValue + 1) / 2;

      double minScale = count == 4 ? 0.55 : 0.75;
      double minOpacity = count == 4 ? 0.25 : 0.5;

      double scale = minScale + ((1.0 - minScale) * depth);
      double opacity = minOpacity + ((1.0 - minOpacity) * depth);

      double xOffset = cosValue * (MediaQuery.of(context).size.width * 0.4);
      double yOffset = (1 - depth) * -60;

      cardData.add({
        'index': i,
        'widget': widget.plants[i],
        'depth': depth,
        'scale': scale,
        'opacity': opacity,
        'x': xOffset,
        'y': yOffset,
      });
    }

    cardData.sort((a, b) => a['depth'].compareTo(b['depth']));

    for (var data in cardData) {
      cardStack.add(
        Positioned(
          key: ValueKey(data['widget'].name),
          top: 40,
          bottom: 120, // Leave room for arrows and dots
          left: 16,
          right: 16,
          child: Transform.translate(
            offset: Offset(data['x'], data['y']),
            child: Transform.scale(
              scale: data['scale'],
              alignment: Alignment.center,
              child: Opacity(
                opacity: data['opacity'],
                child: IgnorePointer(
                  ignoring: data['depth'] < 0.95,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _PlantCard(
                        key: ValueKey(data['widget'].name),
                        plant: data['widget'],
                        cvsRepository: widget.cvsRepository,
                        isFront: widget.isFront,
                        onFlip: widget.onFlip,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            count,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == i ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == i
                    ? AppTheme.secondary
                    : AppTheme.cardBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),

        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 200) {
                _rotate(1); // swipe right -> show previous card
              } else if (details.primaryVelocity! < -200) {
                _rotate(-1); // swipe left -> show next card
              }
            },
            child: Container(
              color: Colors.transparent,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ...cardStack,

                  // Arrow buttons fallback
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => _rotate(1),
                          icon: const Icon(Icons.arrow_back_ios_rounded),
                          color: AppTheme.textMuted,
                          iconSize: 28,
                        ),
                        Text(
                          'Swipe to compare',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _rotate(-1),
                          icon: const Icon(Icons.arrow_forward_ios_rounded),
                          color: AppTheme.textMuted,
                          iconSize: 28,
                        ),
                      ],
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Single Plant Card — all info in one scrollable card, no flip
// ─────────────────────────────────────────────────────────────────────────────

class _PlantCard extends StatefulWidget {
  final PowerPlant plant;
  final CvsRepository cvsRepository;
  final bool isFront;
  final VoidCallback onFlip;
  const _PlantCard({super.key, required this.plant, required this.cvsRepository, required this.isFront, required this.onFlip});

  @override
  State<_PlantCard> createState() => _PlantCardState();
}

class _PlantCardState extends State<_PlantCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  String? _aiInsight;
  bool _isLoadingInsight = false;
  bool _insightError = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: widget.isFront ? 0.0 : 1.0,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );

    if (!widget.isFront) {
      if (_aiInsight == null && !_isLoadingInsight) {
        _loadInsight();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }


  @override
  void didUpdateWidget(covariant _PlantCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plant.name != widget.plant.name) {
      _aiInsight = null;
      _isLoadingInsight = false;
      _insightError = false;
    }
    if (oldWidget.isFront != widget.isFront) {
      if (widget.isFront) {
        _flipController.reverse();
      } else {
        _flipController.forward();
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (widget.isFront) {
      _flipController.forward();
      if (_aiInsight == null && !_isLoadingInsight) {
        _loadInsight();
      }
    } else {
      _flipController.reverse();
    }
    widget.onFlip();
  }

  Future<void> _loadInsight() async {
    final CVSResult cvs = widget.cvsRepository.getUnifiedScore(widget.plant);
    if (!mounted) return;

    setState(() {
      _isLoadingInsight = true;
      _insightError = false;
    });

    try {
      final payload = PlantContextPayload.fromEntities(
        plant: widget.plant,
        cvs: cvs,
      );
      final result = await sl<GeneratePlantInsightUsecase>()(
        params: {'context': payload, 'isUserInitiated': true},
      ).last.timeout(const Duration(seconds: 14));

      if (mounted) {
        if (result is DataSuccess<String>) {
          setState(() {
            _aiInsight = result.data;
            _isLoadingInsight = false;
          });
        } else {
          setState(() {
            _insightError = true;
            _isLoadingInsight = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _insightError = true;
          _isLoadingInsight = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * 3.1415926535897932;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);

        return GestureDetector(
          onTap: _toggleFlip,
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: angle < 3.1415926535897932 / 2
                ? _buildFront(context)
                : Transform(
                    transform: Matrix4.identity()..rotateY(3.1415926535897932),
                    alignment: Alignment.center,
                    child: _buildBack(context),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildCardBase(BuildContext context, Widget child) {
    final CVSResult cvs = widget.cvsRepository.getUnifiedScore(widget.plant);
    final hasCvs = cvs != null;
    final risk = cvs.riskLevel ?? RiskLevel.low;
    final riskColor = _riskColor(risk);

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 450,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            riskColor.withValues(alpha: hasCvs ? 0.25 : 0.08),
            AppTheme.surface,
            const Color(0xFF0F172A),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        border: Border.all(
          color: riskColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: riskColor.withValues(alpha: 0.25),
            blurRadius: 32,
            spreadRadius: -2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(28), child: child),
    );
  }

  Widget _buildFront(BuildContext context) {
    final CVSResult cvs = widget.cvsRepository.getUnifiedScore(widget.plant);
    final hasCvs = cvs != null;
    final risk = cvs.riskLevel ?? RiskLevel.low;
    final riskColor = _riskColor(risk);
    final score = cvs.score ?? 0;
    final riskLabel = risk.label.toUpperCase();

    return _buildCardBase(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Section: 2 Columns ───────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: CVS Score
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.plant.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.15,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (!hasCvs)
                        _PendingScoreBanner()
                      else ...[
                        Text(
                          score.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 76,
                            fontWeight: FontWeight.w900,
                            color: riskColor,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: riskColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: riskColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            riskLabel,
                            style: TextStyle(
                              color: riskColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right Column: 2x2 Metadata Grid
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: _MetaItem(
                              icon: Icons.location_on_rounded,
                              label: 'Location',
                              value:
                                  widget.plant.countryLong ??
                                  widget.plant.country,
                            ),
                          ),
                          Expanded(
                            child: _MetaItem(
                              icon: Icons.bolt_rounded,
                              label: 'Capacity',
                              value: widget.plant.capacityMw != null
                                  ? '${widget.plant.capacityMw!.toStringAsFixed(0)} MW'
                                  : 'Unknown',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _MetaItem(
                              icon: Icons.factory_rounded,
                              label: 'Fuel',
                              value: widget.plant.primaryFuel.displayName,
                            ),
                          ),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            _CardDivider(),
            const SizedBox(height: 12),

            // ── Stress breakdown ───────────────────────────────────────
            _SectionHeader(
              icon: Icons.thermostat_auto_rounded,
              label: 'CLIMATE STRESS',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  _StressRow(
                    icon: '🌡',
                    label: 'TEMP',
                    value: cvs.temperatureStress ?? 0,
                    color: const Color(0xFFEF4444),
                    hasCvs: hasCvs,
                  ),
                  const SizedBox(height: 12),
                  _StressRow(
                    icon: '💧',
                    label: 'WATER',
                    value: cvs.waterStress ?? 0,
                    color: const Color(0xFF3B82F6),
                    hasCvs: hasCvs,
                  ),
                  const SizedBox(height: 12),
                  _StressRow(
                    icon: '🌬',
                    label: 'WIND',
                    value: cvs.windStress ?? 0,
                    color: const Color(0xFF10B981),
                    hasCvs: hasCvs,
                  ),
                ],
              ),
            ),

            const Spacer(),
            _CardDivider(),
            const SizedBox(height: 10),

            // ── Coordinates ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        icon: Icons.my_location_rounded,
                        label: 'LOCATION',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.plant.latitude.toStringAsFixed(4)}° N, '
                        '${widget.plant.longitude.toStringAsFixed(4)}° E',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.touch_app_rounded,
                  size: 24,
                  color: const Color(0xFF2563EB).withValues(alpha: 0.75),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    final CVSResult cvs = widget.cvsRepository.getUnifiedScore(widget.plant);
    final hasCvs = cvs != null;

    return _buildCardBase(
      context,
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.secondary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AI INSIGHT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                if (_insightError)
                  GestureDetector(
                    onTap: _loadInsight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 14,
                            color: AppTheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Retry',
                            style: TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _AiInsightBody(
              isLoading: _isLoadingInsight,
              hasError: _insightError,
              insight: _aiInsight,
              hasCvs: hasCvs,
              onGenerate: _loadInsight,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Score pending" banner shown when CVS hasn't been computed yet
// ─────────────────────────────────────────────────────────────────────────────

class _PendingScoreBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.secondary,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'CVS score computing…',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Insight body
// ─────────────────────────────────────────────────────────────────────────────

class _AiInsightBody extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final String? insight;
  final bool hasCvs;
  final VoidCallback? onGenerate;

  const _AiInsightBody({
    required this.isLoading,
    required this.hasError,
    required this.insight,
    required this.hasCvs,
    this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasCvs) {
      return _muted('AI insight will appear once the CVS score is ready.');
    }
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerLine(width: double.infinity, height: 9),
          const SizedBox(height: 5),
          _ShimmerLine(width: double.infinity, height: 9),
          const SizedBox(height: 5),
          _ShimmerLine(width: 200, height: 9),
          const SizedBox(height: 5),
          _ShimmerLine(width: double.infinity, height: 9),
          const SizedBox(height: 5),
          _ShimmerLine(width: 140, height: 9),
        ],
      );
    }
    if (hasError) {
      return _muted('Could not generate insight for this plant.');
    }
    if (insight == null) {
      return Center(
        child: TextButton.icon(
          onPressed: onGenerate,
          icon: Icon(Icons.auto_awesome, size: 14, color: AppTheme.secondary),
          label: Text(
            'Generate Insight',
            style: TextStyle(color: AppTheme.secondary, fontSize: 12),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: AppTheme.secondary.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }
    return Text(
      insight!,
      style: const TextStyle(
        color: Color(0xFFCBD5E1),
        fontSize: 13,
        height: 1.6,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _muted(String text) => Text(
    text,
    style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid View — side-by-side compact cards
// ─────────────────────────────────────────────────────────────────────────────

class _ComparisonGridView extends StatelessWidget {
  final List<PowerPlant> plants;
  final CvsRepository cvsRepository;
  const _ComparisonGridView({
    super.key,
    required this.plants,
    required this.cvsRepository,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.55,
        children: plants.map((plant) {
          final cvs = cvsRepository.getUnifiedScore(plant);
          final risk = cvs.riskLevel ?? RiskLevel.low;
          final score = cvs.score ?? 0.0;
          final riskColor = _riskColor(risk);

          return Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: riskColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: riskColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          plant.primaryFuel.displayName,
                          style: TextStyle(
                            color: riskColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 34,
                        child: Text(
                          plant.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 16,
                        child: Text(
                          plant.countryLong ?? plant.country,
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      score.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: riskColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StressRow(
                        icon: '🌡',
                        label: 'TEMP',
                        value: cvs.temperatureStress ?? 0,
                        color: const Color(0xFFEF4444),
                        hasCvs: cvs != null,
                      ),
                      const SizedBox(height: 4),
                      _StressRow(
                        icon: '💧',
                        label: 'WATER',
                        value: cvs.waterStress ?? 0,
                        color: const Color(0xFF3B82F6),
                        hasCvs: cvs != null,
                      ),
                      const SizedBox(height: 4),
                      _StressRow(
                        icon: '🌬',
                        label: 'WIND',
                        value: cvs.windStress ?? 0,
                        color: const Color(0xFF10B981),
                        hasCvs: cvs != null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      risk.label.toUpperCase(),
                      style: TextStyle(
                        color: riskColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _CardDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 0.5,
    color: Colors.white.withValues(alpha: 0.08),
  );
}

class _StressRow extends StatelessWidget {
  final String icon;
  final String label;
  final double value;
  final Color color;
  final bool hasCvs;

  const _StressRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.hasCvs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hasCvs
                ? LinearProgressIndicator(
                    value: (value / 100).clamp(0.0, 1.0),
                    minHeight: 14,
                    backgroundColor: Colors.white.withValues(alpha: 0.07),
                    valueColor: AlwaysStoppedAnimation(color),
                  )
                : LinearProgressIndicator(
                    value: null,
                    minHeight: 14,
                    backgroundColor: Colors.white.withValues(alpha: 0.07),
                    valueColor: AlwaysStoppedAnimation(
                      color.withValues(alpha: 0.3),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 48,
          child: hasCvs
              ? RichText(
                  textAlign: TextAlign.right,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value.toStringAsFixed(0),
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: '/100',
                        style: TextStyle(
                          color: color.withValues(alpha: 0.7),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : RichText(
                  textAlign: TextAlign.right,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '—',
                        style: TextStyle(
                          color: color.withValues(alpha: 0.4),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: '/100',
                        style: TextStyle(
                          color: color.withValues(alpha: 0.4),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
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

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer line
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerLine extends StatefulWidget {
  final double width;
  final double height;
  const _ShimmerLine({required this.width, required this.height});

  @override
  State<_ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<_ShimmerLine>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  Animation<double>? _anim;

  void _ensureInitialized() {
    if (_ctrl != null) return;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.1,
      end: 0.35,
    ).animate(CurvedAnimation(parent: _ctrl!, curve: Curves.easeInOut));
  }

  @override
  void initState() {
    super.initState();
    _ensureInitialized();
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ensureInitialized();
    return AnimatedBuilder(
      animation: _anim!,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _anim!.value),
          borderRadius: BorderRadius.circular(widget.height / 2),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────────────────────

Color _riskColor(RiskLevel risk) => switch (risk) {
  RiskLevel.high => const Color(0xFFEF4444),
  RiskLevel.medium => const Color(0xFFF97316),
  RiskLevel.low => const Color(0xFF22C55E),
};

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.white70),
              const SizedBox(width: 2),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
