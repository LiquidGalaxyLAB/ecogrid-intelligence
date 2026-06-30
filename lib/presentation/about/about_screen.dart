import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> _launch(String url) async {
  final uri = Uri.parse(url);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {}
  }
}

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((i) {
      if (mounted) setState(() => _appVersion = i.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero ─────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: _HeroSection(isDark: isDark),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── About / Description ────────────────────────────────
                _label('ABOUT'),
                const SizedBox(height: 12),
                _card(
                  isDark,
                  cs,
                  child: Text(
                    'Built as part of Google Summer of Code 2026 with Liquid Galaxy LAB, '
                    'EcoGrid Intelligence is a research tool for understanding climate risk '
                    'across global energy infrastructure. It turns complex climate and power '
                    'plant data into something you can actually see, explore, and act on.\n\n'
                    'Search any region or power plant in the world, and the app instantly '
                    'flies Liquid Galaxy\'s panoramic display to that location — rendering '
                    'every nearby facility color-coded by its Climate Vulnerability Score. '
                    'Filter by plant type, risk level, or climate stress dimension.\n\n'
                    'Behind every score is real data. EcoGrid pulls live weather conditions '
                    'from Open-Meteo and weighs them against each plant\'s specific '
                    'sensitivity to heat, water stress, and wind.',
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.75,
                      color: cs.onSurface.withValues(alpha: 0.82),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── CVS ───────────────────────────────────────────────
                _CVSCard(isDark: isDark),
                const SizedBox(height: 28),

                // ── Features ──────────────────────────────────────────
                _label('KEY CAPABILITIES'),
                const SizedBox(height: 12),
                _FeaturesGrid(isDark: isDark),
                const SizedBox(height: 28),

                _divider(cs),
                const SizedBox(height: 28),

                // ── Developer ─────────────────────────────────────────
                _label('DEVELOPER'),
                const SizedBox(height: 12),
                _DeveloperCard(isDark: isDark, cs: cs),
                const SizedBox(height: 28),

                _divider(cs),
                const SizedBox(height: 28),

                // ── Organization / Liquid Galaxy ──────────────────────
                _label('ORGANIZATION'),
                const SizedBox(height: 12),
                Center(
                  child: Image.asset(
                    'assets/images/logos.png',
                    height: 180,
                    errorBuilder: (_, _, _) =>
                        Icon(Icons.public, size: 80, color: cs.primary),
                  ),
                ),
                const SizedBox(height: 16),
                _card(
                  isDark,
                  cs,
                  child: Text(
                    'Liquid Galaxy LAB is an open-source innovation lab and Google Summer '
                    'of Code organization that builds immersive, interactive geospatial '
                    'experiences on panoramic multi-screen display systems.\n\n'
                    'The platform clusters 3 to 7 computers, each driving one screen, into '
                    'a seamlessly synchronized panoramic rig. A master node controls '
                    'navigation and broadcasts position data over UDP — every slave screen '
                    'instantly updates its view to match its relative angle to the master, '
                    'creating a breathtaking 270° window into the Earth.\n\n'
                    'Today, Liquid Galaxy empowers researchers and organizations to visualize '
                    'complex datasets across awe-inspiring immersive environments. From climate '
                    'change monitoring to urban planning, the platform transforms standard data '
                    'into interactive, room-scale spatial experiences.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.75,
                      color: cs.onSurface.withValues(alpha: 0.80),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Organization socials
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SocialChip(
                        icon: Icons.camera_alt_rounded,
                        label: 'Instagram',
                        color: const Color(0xFFE1306C),
                        url: 'https://www.instagram.com/_liquidgalaxy',
                      ),
                      _SocialChip(
                        icon: Icons.chat_rounded,
                        label: 'Twitter / X',
                        color: const Color(0xFF1DA1F2),
                        url: 'https://www.x.com/_liquidgalaxy',
                      ),
                      _SocialChip(
                        icon: Icons.code_rounded,
                        label: 'GitHub',
                        color: const Color(0xFF6E40C9),
                        url: 'https://github.com/LiquidGalaxyLAB',
                      ),
                      _SocialChip(
                        icon: Icons.business_rounded,
                        label: 'LinkedIn',
                        color: const Color(0xFF0A66C2),
                        url:
                            'https://www.linkedin.com/company/google-summer-of-code---liquid-galaxy-project',
                      ),
                      _SocialChip(
                        icon: Icons.language_rounded,
                        label: 'Website',
                        color: const Color(0xFF10B981),
                        url: 'https://www.liquidgalaxy.eu',
                      ),
                      _SocialChip(
                        icon: Icons.mail_rounded,
                        label: 'Email',
                        color: const Color(0xFFF59E0B),
                        url: 'mailto:liquidgalaxylab@gmail.com',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                _divider(cs),
                const SizedBox(height: 28),

                // ── Credits ───────────────────────────────────────────
                _label('CREDITS'),
                const SizedBox(height: 12),
                _card(
                  isDark,
                  cs,
                  child: Column(
                    children: [
                      _CreditRow(
                        icon: Icons.person_rounded,
                        name: 'Andreu Ibáñez',
                        role: 'Admin — Liquid Galaxy',
                      ),
                      const SizedBox(height: 12),
                      _CreditRow(
                        icon: Icons.school_rounded,
                        name: 'Yash Raj Bharti',
                        role: 'Mentor — Liquid Galaxy',
                      ),
                      const SizedBox(height: 12),
                      _CreditRow(
                        icon: Icons.school_rounded,
                        name: 'Siddhart Mudgil',
                        role: 'Mentor — Liquid Galaxy',
                      ),
                      const SizedBox(height: 12),
                      _CreditRow(
                        icon: Icons.cloud_rounded,
                        name: 'Open-Meteo',
                        role: 'Free climate & weather API',
                      ),
                      const SizedBox(height: 12),
                      _CreditRow(
                        icon: Icons.flash_on_rounded,
                        name: 'Global Power Plant Database',
                        role: 'WRI — plant data source',
                      ),
                      const SizedBox(height: 12),
                      _CreditRow(
                        icon: Icons.auto_awesome_rounded,
                        name: 'Google Gemini',
                        role: 'AI-powered insights engine',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── App-level links row ───────────────────────────────
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SocialChip(
                        icon: Icons.code_rounded,
                        label: 'App GitHub',
                        color: const Color(0xFF6E40C9),
                        url:
                            'https://github.com/LiquidGalaxyLAB/ecogrid-intelligence',
                      ),
                      _SocialChip(
                        icon: Icons.language_rounded,
                        label: 'Liquid Galaxy',
                        color: const Color(0xFF10B981),
                        url: 'https://www.liquidgalaxy.eu',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Footer ────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Liquid Galaxy LAB · GSoC 2026',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                      if (_appVersion.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'v$_appVersion',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: cs.onSurface.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _divider(ColorScheme cs) => Divider(
        color: cs.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
        indent: MediaQuery.of(context).size.width * 0.2,
        endIndent: MediaQuery.of(context).size.width * 0.2,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero
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
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25)),
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
                          color: isDark ? Colors.white : const Color(0xFF0D2137),
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
// CVS Card (kept as-is — user likes this)
// ─────────────────────────────────────────────────────────────────────────────

class _CVSCard extends StatelessWidget {
  final bool isDark;
  const _CVSCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _card(
      isDark,
      cs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.35)),
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
          // Scale bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(flex: 33, child: Container(color: const Color(0xFF22C55E))),
                  Expanded(flex: 33, child: Container(color: const Color(0xFFF97316))),
                  Expanded(flex: 34, child: Container(color: const Color(0xFFEF4444))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
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
            description: 'High curtailment risk under current conditions.',
          ),
        ],
      ),
    );
  }
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
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(width: 6),
        Text('($range)',
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withValues(alpha: 0.45))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(description,
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.65))),
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
    _Feat(
      icon: Icons.language_rounded,
      accent: Color(0xFF3B82F6),
      title: 'Liquid Galaxy\nVisualization',
      body:
          'Cast climate data across a multi-screen panoramic rig with live KML rendering.',
    ),
    _Feat(
      icon: Icons.bolt_rounded,
      accent: Color(0xFFF59E0B),
      title: 'Infrastructure\nAnalysis',
      body:
          'Explore vulnerability of 35 000+ power plants across every region and fuel type.',
    ),
    _Feat(
      icon: Icons.cloud_rounded,
      accent: Color(0xFF10B981),
      title: 'Climate\nForecasting',
      body:
          'Real-time weather data from Open-Meteo feeds live CVS scores per plant.',
    ),
    _Feat(
      icon: Icons.psychology_rounded,
      accent: Color(0xFFA855F7),
      title: 'AI Risk\nInsights',
      body:
          'AI-powered analysis explains why a plant is vulnerable in plain language.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.88,
      children: _features
          .map((f) => Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(cs, isDark),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: f.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(f.icon, color: f.accent, size: 22),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      f.title,
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
                        f.body,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.55,
                          color: cs.onSurface.withValues(alpha: 0.62),
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _Feat {
  final IconData icon;
  final Color accent;
  final String title;
  final String body;
  const _Feat(
      {required this.icon,
      required this.accent,
      required this.title,
      required this.body});
}

// ─────────────────────────────────────────────────────────────────────────────
// Developer Card — centered
// ─────────────────────────────────────────────────────────────────────────────

class _DeveloperCard extends StatelessWidget {
  final bool isDark;
  final ColorScheme cs;
  const _DeveloperCard({required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    return _card(
      isDark,
      cs,
      child: Column(
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: cs.primary.withValues(alpha: 0.25), width: 2),
            ),
            child: Icon(Icons.person_rounded, color: cs.primary, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            'Bhoomi Shivhare',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'GSoC 2026 Contributor · Liquid Galaxy LAB',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: cs.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Social chips
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _SocialChip(
                icon: Icons.mail_rounded,
                label: 'Email',
                color: const Color(0xFFF59E0B),
                url: 'mailto:shivharebhoomi07@gmail.com',
              ),
              _SocialChip(
                icon: Icons.code_rounded,
                label: 'GitHub',
                color: const Color(0xFF6E40C9),
                url: 'https://github.com/shivharebhoomi07',
              ),
            ],
          ),
        ],
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// Credits Row
// ─────────────────────────────────────────────────────────────────────────────

class _CreditRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final String role;
  const _CreditRow(
      {required this.icon, required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: cs.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
              Text(role,
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Social Chip — pill-style with per-type accent color
// ─────────────────────────────────────────────────────────────────────────────

class _SocialChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final Color? color;
  const _SocialChip(
      {required this.icon, required this.label, required this.url, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = color ?? cs.primary;
    return InkWell(
      onTap: () => _launch(url),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accent, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _card(bool isDark, ColorScheme cs, {required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: _cardDecoration(cs, isDark),
    child: child,
  );
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
