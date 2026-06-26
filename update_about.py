import re

with open('c:/Users/shivh/Projects/ecogrid_intelligence/lib/presentation/about/about_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace imports to include package_info_plus
content = content.replace("import 'package:url_launcher/url_launcher.dart';", "import 'package:url_launcher/url_launcher.dart';\nimport 'package:package_info_plus/package_info_plus.dart';")

# Change AboutScreen to StatefulWidget
class_about_screen = '''class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = "";

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  void _getAppVersion() async {
    final appVersion = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = appVersion.version;
    });
  }

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
                _MissionCard(isDark: isDark),
                const SizedBox(height: 28),

                _SectionLabel(label: 'KEY CAPABILITIES'),
                const SizedBox(height: 12),
                _FeaturesGrid(isDark: isDark),
                const SizedBox(height: 28),

                Divider(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  thickness: 1,
                  indent: MediaQuery.of(context).size.width * 0.2,
                  endIndent: MediaQuery.of(context).size.width * 0.2,
                ),
                const SizedBox(height: 28),

                _SectionLabel(label: 'DEVELOPER'),
                const SizedBox(height: 12),
                Text(
                  'Sidharth Mudgil',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _DeveloperSocials(),
                const SizedBox(height: 28),

                Center(
                  child: Image.asset(
                    'assets/images/logos.png',
                    height: 120,
                    errorBuilder: (_, __, ___) => Icon(Icons.public, size: 80, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 28),
                _LGDescriptionCard(isDark: isDark),
                const SizedBox(height: 28),

                Divider(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  thickness: 1,
                  indent: MediaQuery.of(context).size.width * 0.2,
                  endIndent: MediaQuery.of(context).size.width * 0.2,
                ),
                const SizedBox(height: 28),

                _SectionLabel(label: 'ORGANIZATION'),
                const SizedBox(height: 12),
                Text(
                  'Liquid Galaxy LAB',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _OrganizationSocials(),
                const SizedBox(height: 28),

                _SectionLabel(label: 'CREDITS'),
                const SizedBox(height: 12),
                Text(
                  'Special thanks to all mentors.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  _appVersion,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}'''

# Remove old AboutScreen
content = re.sub(r'class AboutScreen extends StatelessWidget \{.*?\n\}\n', class_about_screen + '\n', content, flags=re.DOTALL)

# Add new widget classes
new_classes = '''
class _LGDescriptionCard extends StatelessWidget {
  final bool isDark;
  const _LGDescriptionCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(cs, isDark),
      child: Text(
        'Liquid Galaxy is a remarkable panoramic system that is tremendously compelling. It started off as a Google 20% project created by Google engineer Jason Holt to run Google Earth across a cluster of PC\\'s and it has grown from there!\\n\\n'
        'Liquid Galaxy hardware consists of 3 or more computers driving multiple displays, usually one computer for each display. Liquid Galaxy applications have been developed using a master/slave architecture. The view orientation of each slave display is configured in reference to the view of the master display. Navigation on the system is done from the master instance and the location on the master is broadcast to the slaves over UDP. The slave instances, knowing their own locations in reference to the master, then change their views accordingly.',
        style: TextStyle(
          fontSize: 14.5,
          height: 1.7,
          color: cs.onSurface.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

class _DeveloperSocials extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(
          iconData: Icons.mail_rounded,
          url: 'mailto:smudgil101@gmail.com',
        ),
        _SocialButton(
          iconData: Icons.code_rounded,
          url: 'https://www.github.com/sidharthmudgil',
        ),
        _SocialButton(
          iconData: Icons.link_rounded,
          url: 'https://www.linkedin.com/in/sidharthmudgil',
        ),
      ],
    );
  }
}

class _OrganizationSocials extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(
          iconData: Icons.camera_alt_rounded,
          url: 'https://www.instagram.com/_liquidgalaxy',
        ),
        _SocialButton(
          iconData: Icons.chat_rounded,
          url: 'https://www.x.com/_liquidgalaxy',
        ),
        _SocialButton(
          iconData: Icons.code_rounded,
          url: 'https://www.github.com/LiquidGalaxyLAB',
        ),
        _SocialButton(
          iconData: Icons.business_rounded,
          url: 'https://www.linkedin.com/company/google-summer-of-code---liquid-galaxy-project',
        ),
        _SocialButton(
          iconData: Icons.language_rounded,
          url: 'https://www.liquidgalaxy.eu',
        ),
        _SocialButton(
          iconData: Icons.mail_rounded,
          url: 'mailto:liquidgalaxylab@gmail.com',
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData iconData;
  final String url;
  
  const _SocialButton({required this.iconData, required this.url});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(iconData, color: cs.primary, size: 22),
        ),
      ),
    );
  }
}
'''

# Update _SectionLabel to be centered
content = content.replace('''class _SectionLabel extends StatelessWidget {
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
}''', '''class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}''')

content += new_classes

with open('c:/Users/shivh/Projects/ecogrid_intelligence/lib/presentation/about/about_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Done!')
