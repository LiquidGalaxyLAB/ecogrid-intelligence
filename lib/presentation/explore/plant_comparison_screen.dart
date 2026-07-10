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
  bool _isCarouselMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Comparing ${widget.plants.length} Plants'),
        actions: [
          IconButton(
            onPressed: () =>
                setState(() => _isCarouselMode = !_isCarouselMode),
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
              )
            : _ComparisonGridView(
                key: const ValueKey('grid'),
                plants: widget.plants,
                cvsRepository: widget.cvsRepository,
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
  const _CarouselView({
    super.key,
    required this.plants,
    required this.cvsRepository,
  });

  @override
  State<_CarouselView> createState() => _CarouselViewState();
}

class _CarouselViewState extends State<_CarouselView> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88, initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Dot indicators ─────────────────────────────────────────────────
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.plants.length,
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
        const SizedBox(height: 16),

        // ── Cards ──────────────────────────────────────────────────────────
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.plants.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) => AnimatedScale(
              scale: _currentPage == index ? 1.0 : 0.92,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: _PlantCard(
                plant: widget.plants[index],
                cvsRepository: widget.cvsRepository,
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 18, top: 10),
          child: Text(
            'Swipe to compare plants',
            style: AppTheme.caption.copyWith(color: AppTheme.textMuted),
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
  const _PlantCard({required this.plant, required this.cvsRepository});

  @override
  State<_PlantCard> createState() => _PlantCardState();
}

class _PlantCardState extends State<_PlantCard> {
  String? _aiInsight;
  bool _isLoadingInsight = false;
  bool _insightError = false;

  @override
  void initState() {
    super.initState();
    _loadInsight();
  }

  Future<void> _loadInsight() async {
    final CVSResult? cvs =
        widget.cvsRepository.getCachedCvs(widget.plant);
    if (cvs == null) return; // CVS not ready yet — skip AI for now
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
        params: {'context': payload, 'isUserInitiated': false},
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
    final CVSResult? cvs = widget.cvsRepository.getCachedCvs(widget.plant);
    final risk = cvs?.riskLevel ?? RiskLevel.low;
    final score = cvs?.score ?? 0.0;
    final riskColor = _riskColor(risk);
    final hasCvs = cvs != null;

    final riskLabel = switch (risk) {
      RiskLevel.high => 'HIGH RISK',
      RiskLevel.medium => 'MEDIUM RISK',
      RiskLevel.low => 'LOW RISK',
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            riskColor.withValues(alpha: hasCvs ? 0.15 : 0.05),
            AppTheme.surface,
            const Color(0xFF0F172A),
          ],
          stops: const [0.0, 0.35, 1.0],
        ),
        border: Border.all(
          color: riskColor.withValues(alpha: hasCvs ? 0.45 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: riskColor.withValues(alpha: 0.2),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Fuel chip ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: riskColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  widget.plant.primaryFuel.displayName.toUpperCase(),
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Plant name ────────────────────────────────────────────
              Text(
                widget.plant.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // ── Location · capacity · year ────────────────────────────
              Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      size: 12, color: AppTheme.textMuted),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      widget.plant.countryLong ?? widget.plant.country,
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.plant.capacityMw != null) ...[
                    Text('  ·  ',
                        style: TextStyle(color: AppTheme.textMuted)),
                    Text(
                      '${widget.plant.capacityMw!.toStringAsFixed(0)} MW',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (widget.plant.commissioningYear != null) ...[
                    Text('  ·  ',
                        style: TextStyle(color: AppTheme.textMuted)),
                    Text(
                      'Est. ${widget.plant.commissioningYear}',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),
              _CardDivider(),

              // ── CVS Score section ─────────────────────────────────────
              const SizedBox(height: 16),
              if (!hasCvs)
                _PendingScoreBanner()
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      score.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 76,
                        fontWeight: FontWeight.w900,
                        color: riskColor,
                        height: 1.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 6),
                      child: Text(
                        '/100',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: riskColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        riskLabel,
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (score / 100).clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(riskColor),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // ── Stress breakdown ───────────────────────────────────────
              _SectionHeader(
                icon: Icons.thermostat_auto_rounded,
                label: 'CLIMATE STRESS',
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  children: [
                    _StressRow(
                      icon: '🌡',
                      label: 'TEMP',
                      value: cvs?.temperatureStress ?? 0,
                      color: const Color(0xFFEF4444),
                      hasCvs: hasCvs,
                    ),
                    const SizedBox(height: 10),
                    _StressRow(
                      icon: '💧',
                      label: 'WATER',
                      value: cvs?.waterStress ?? 0,
                      color: const Color(0xFF3B82F6),
                      hasCvs: hasCvs,
                    ),
                    const SizedBox(height: 10),
                    _StressRow(
                      icon: '🌬',
                      label: 'WIND',
                      value: cvs?.windStress ?? 0,
                      color: const Color(0xFF10B981),
                      hasCvs: hasCvs,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _CardDivider(),
              const SizedBox(height: 16),

              // ── Coordinates ───────────────────────────────────────────
              _SectionHeader(
                icon: Icons.my_location_rounded,
                label: 'LOCATION',
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.plant.latitude.toStringAsFixed(4)}° N, '
                '${widget.plant.longitude.toStringAsFixed(4)}° E',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),

              const SizedBox(height: 20),
              _CardDivider(),
              const SizedBox(height: 16),

              // ── AI Insight ────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.auto_awesome_rounded,
                        color: AppTheme.secondary, size: 13),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI INSIGHT',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  if (_insightError)
                    GestureDetector(
                      onTap: _loadInsight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded,
                              size: 13, color: AppTheme.secondary),
                          const SizedBox(width: 4),
                          Text('Retry',
                              style: TextStyle(
                                  color: AppTheme.secondary,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _AiInsightBody(
                isLoading: _isLoadingInsight,
                hasError: _insightError,
                insight: _aiInsight,
                hasCvs: hasCvs,
              ),
            ],
          ),
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
          Text(
            'CVS score computing…',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
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

  const _AiInsightBody({
    required this.isLoading,
    required this.hasError,
    required this.insight,
    required this.hasCvs,
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
    if (hasError || insight == null) {
      return _muted('Could not generate insight for this plant.');
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondary.withValues(alpha: 0.08),
            AppTheme.secondary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.secondary.withValues(alpha: 0.2)),
      ),
      child: Text(
        insight!,
        style: const TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 12,
          height: 1.6,
        ),
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
        childAspectRatio: 0.7,
        children: plants.map((plant) {
          final cvs = cvsRepository.getCachedCvs(plant);
          final risk = cvs?.riskLevel ?? RiskLevel.low;
          final score = cvs?.score ?? 0.0;
          final riskColor = _riskColor(risk);

          return Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: riskColor.withValues(alpha: 0.35), width: 1.5),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        plant.primaryFuel.displayName,
                        style: TextStyle(
                            color: riskColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
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
                    const SizedBox(height: 4),
                    Text(
                      plant.countryLong ?? plant.country,
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Center(
                  child: cvs == null
                      ? Text('—',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textMuted,
                          ))
                      : Text(
                          score.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: riskColor,
                          ),
                        ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StressRow(
                      icon: '🌡',
                      label: 'TEMP',
                      value: cvs?.temperatureStress ?? 0,
                      color: const Color(0xFFEF4444),
                      hasCvs: cvs != null,
                    ),
                    const SizedBox(height: 4),
                    _StressRow(
                      icon: '💧',
                      label: 'WATER',
                      value: cvs?.waterStress ?? 0,
                      color: const Color(0xFF3B82F6),
                      hasCvs: cvs != null,
                    ),
                    const SizedBox(height: 4),
                    _StressRow(
                      icon: '🌬',
                      label: 'WIND',
                      value: cvs?.windStress ?? 0,
                      color: const Color(0xFF10B981),
                      hasCvs: cvs != null,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
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
            color: Color(0xFF64748B),
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
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: hasCvs
                ? LinearProgressIndicator(
                    value: (value / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.07),
                    valueColor: AlwaysStoppedAnimation(color),
                  )
                : LinearProgressIndicator(
                    value: null,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.07),
                    valueColor: AlwaysStoppedAnimation(
                        color.withValues(alpha: 0.3)),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: hasCvs
              ? Text(
                  value.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Text(
                  '—',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.4),
                    fontSize: 12,
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
    _anim = Tween<double>(begin: 0.1, end: 0.35).animate(
      CurvedAnimation(parent: _ctrl!, curve: Curves.easeInOut),
    );
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
