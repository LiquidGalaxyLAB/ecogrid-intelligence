import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// About screen for EcoGrid Intelligence.
///
/// Fully theme-aware (light + dark). No hardcoded colours — everything
/// derives from ColorScheme so the screen looks correct in both themes.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _HeroSection(isDark: isDark),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionLabel(label: 'ABOUT THE PROJECT'),
                const SizedBox(height: 12),
                _MissionCard(isDark: isDark),
                const SizedBox(height: 28),

                _SectionLabel(label: 'UNDERSTANDING CVS SCORE'),
                const SizedBox(height: 12),
                _CVSCard(isDark: isDark),
                const SizedBox(height: 28),

                _SectionLabel(label: 'KEY CAPABILITIES'),
                const SizedBox(height: 12),
                _FeaturesGrid(isDark: isDark),
                const SizedBox(height: 28),

                _SectionLabel(label: 'BUILT WITH'),
                const SizedBox(height: 12),
                _TechChips(),
                const SizedBox(height: 28),

                _SectionLabel(label: 'GSOC PROJECT'),
                const SizedBox(height: 12),
                _GSoCCard(isDark: isDark),
                const SizedBox(height: 28),

                _LinksRow(),
                const SizedBox(height: 16),
                _Footer(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Section
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool isDark;
  const _HeroSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0D1B2A),
                  const Color(0xFF1A2E44),
                  const Color(0xFF0F3460),
                ]
              : [
                  const Color(0xFFB8D8F0),
                  const Color(0xFF7EC8E3),
                  const Color(0xFFDEF0FA),
                ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo + name row
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      errorBuilder: (_, _, _) => Icon(
                        Icons.energy_savings_leaf_rounded,
                        color: isDark
                            ? const Color(0xFF4ECDC4)
                            : const Color(0xFF1A6B8A),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EcoGrid Intelligence',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0D2137),
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Liquid Galaxy · GSoC 2026',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.55)
                              : const Color(0xFF1A6B8A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'AI-Driven Climate Resilience\nAnalysis for Global Energy\nInfrastructure',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0D2137),
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mission Card
// ─────────────────────────────────────────────────────────────────────────────

class _MissionCard extends StatelessWidget {
  final bool isDark;
  const _MissionCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(cs, isDark),
      child: Text(
        'Built as part of Google Summer of Code 2026 with Liquid Galaxy LAB, EcoGrid Intelligence is a research tool for understanding climate risk across global energy infrastructure. It turns complex climate and power plant data into something you can actually see, explore, and act on.\n\n'
        'Search any region or power plant in the world, and the app instantly flies Liquid Galaxy\'s panoramic display to that location — rendering every nearby facility color-coded by its Climate Vulnerability Score. Filter by plant type, risk level, or climate stress dimension to find exactly what you\'re looking for.\n\n'
        'Behind every score is real data. EcoGrid pulls live weather conditions from Open-Meteo and weighs them against each plant\'s specific sensitivity to heat, water stress, and wind.',
        style: TextStyle(
          fontSize: 14.5,
          height: 1.7,
          color: cs.onSurface.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CVS Card — the signature element
// ─────────────────────────────────────────────────────────────────────────────

class _CVSCard extends StatelessWidget {
  final bool isDark;
  const _CVSCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(cs, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                  ),
                ),
                child: const Text(
                  'CVS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3B82F6),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Climate Vulnerability Score',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'A 0–100 index that measures how exposed a power plant is to current '
            'weather conditions, weighted by that plant type\'s inherent climate '
            'sensitivity. The score combines temperature stress, water availability, '
            'and wind intensity — each weighted differently depending on the plant '
            'type (Solar, Nuclear, Hydro, Thermal, or Wind).',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.65,
              color: cs.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 20),

          // Risk scale bar — the visual signature
          _CVSScaleBar(),
          const SizedBox(height: 14),

          // Risk level descriptions
          _RiskRow(
            color: const Color(0xFF22C55E),
            label: 'Low Risk',
            range: '0 – 33',
            description: 'Operating within safe climate margins.',
          ),
          const SizedBox(height: 8),
          _RiskRow(
            color: const Color(0xFFF97316),
            label: 'Medium Risk',
            range: '34 – 66',
            description: 'Elevated stress — monitor closely.',
          ),
          const SizedBox(height: 8),
          _RiskRow(
            color: const Color(0xFFEF4444),
            label: 'High Risk',
            range: '67 – 100',
            description: 'Critical climate exposure — action needed.',
          ),
        ],
      ),
    );
  }
}

class _CVSScaleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gradient bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 12,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF22C55E),
                  Color(0xFF84CC16),
                  Color(0xFFEAB308),
                  Color(0xFFF97316),
                  Color(0xFFEF4444),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Scale markers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0', style: _markerStyle()),
            Text('33', style: _markerStyle()),
            Text('66', style: _markerStyle()),
            Text('100', style: _markerStyle()),
          ],
        ),
      ],
    );
  }

  TextStyle _markerStyle() => const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0xFF94A3B8),
  );
}

class _RiskRow extends StatelessWidget {
  final Color color;
  final String label;
  final String range;
  final String description;

  const _RiskRow({
    required this.color,
    required this.label,
    required this.range,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label ($range) — ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: description,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.7),
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
// Features Grid
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturesGrid extends StatelessWidget {
  final bool isDark;
  const _FeaturesGrid({required this.isDark});

  static const _features = [
    _Feature(
      icon: Icons.language_rounded,
      accent: Color(0xFF3B82F6),
      title: 'Liquid Galaxy\nVisualization',
      body:
          'Cast climate data across a multi-screen panoramic rig with live KML rendering.',
    ),
    _Feature(
      icon: Icons.bolt_rounded,
      accent: Color(0xFFF59E0B),
      title: 'Infrastructure\nAnalysis',
      body:
          'Explore vulnerability of 35 000+ power plants across every region and fuel type.',
    ),
    _Feature(
      icon: Icons.cloud_rounded,
      accent: Color(0xFF10B981),
      title: 'Climate\nForecasting',
      body:
          'Real-time weather data from Open-Meteo feeds live CVS scores per plant.',
    ),
    _Feature(
      icon: Icons.psychology_rounded,
      accent: Color(0xFFA855F7),
      title: 'AI Risk\nInsights',
      body:
          'AI-powered analysis explains why a plant is vulnerable in plain language.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.88,
      children: _features
          .map((f) => _FeatureCard(feature: f, isDark: isDark))
          .toList(),
    );
  }
}

class _Feature {
  final IconData icon;
  final Color accent;
  final String title;
  final String body;
  const _Feature({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
  });
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  final bool isDark;
  const _FeatureCard({required this.feature, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(cs, isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: feature.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(feature.icon, color: feature.accent, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            feature.title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              feature.body,
              style: TextStyle(
                fontSize: 12,
                height: 1.55,
                color: cs.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tech Chips
// ─────────────────────────────────────────────────────────────────────────────

class _TechChips extends StatelessWidget {
  static const _items = [
    'Flutter & Dart',
    'BLoC Architecture',
    'DartSSH2',
    'Open-Meteo API',
    'WRI GPPD Dataset',
    'KML Visualization',
    'Clean Architecture',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _items
          .map(
            (t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Text(
                t,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GSoC Card
// ─────────────────────────────────────────────────────────────────────────────

class _GSoCCard extends StatelessWidget {
  final bool isDark;
  const _GSoCCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(cs, isDark),
      child: Column(
        children: [
          _InfoRow(label: 'Program', value: 'Google Summer of Code 2026'),
          const SizedBox(height: 12),
          _InfoRow(label: 'Organization', value: 'Liquid Galaxy LAB'),
          const SizedBox(height: 12),
          _InfoRow(label: 'Mentors', value: 'Yash Raj Bharti\nSiddhart Mudgil'),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'About LG LAB',
            value:
                'Liquid Galaxy LAB is an open-source innovation lab that builds '
                'immersive geospatial experiences across multi-screen panoramic '
                'display systems.',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.45),
              letterSpacing: 0.3,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withValues(alpha: 0.88),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Links Row
// ─────────────────────────────────────────────────────────────────────────────

class _LinksRow extends StatelessWidget {
  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LinkButton(
            icon: Icons.code_rounded,
            label: 'GitHub',
            accent: const Color(0xFF6E40C9),
            onTap: () =>
                _launch('https://github.com/yourusername/ecogrid_intelligence'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LinkButton(
            icon: Icons.language_rounded,
            label: 'Liquid Galaxy',
            accent: const Color(0xFF3B82F6),
            onTap: () => _launch('https://www.liquidgalaxy.eu'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LinkButton(
            icon: Icons.bug_report_rounded,
            label: 'Report Bug',
            accent: const Color(0xFFEF4444),
            onTap: () => _launch(
              'https://github.com/yourusername/ecogrid_intelligence/issues',
            ),
          ),
        ),
      ],
    );
  }
}

class _LinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  const _LinkButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        'Liquid Galaxy LAB · GSoC 2026',
        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.35)),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}

BoxDecoration _cardDecoration(ColorScheme cs, bool isDark) {
  return BoxDecoration(
    color: isDark
        ? cs.surfaceContainerLow
        : cs.surfaceContainerHighest.withValues(alpha: 0.45),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: cs.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.35),
      width: 1,
    ),
  );
}
