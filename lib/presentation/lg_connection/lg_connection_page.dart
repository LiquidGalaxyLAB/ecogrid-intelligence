import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_theme.dart';
import '../../config/theme/theme_controller.dart';
import '../../core/enums/connection_status.dart';
import '../../domain/model/lg_settings.dart';
import '../../di/di.dart';
import 'bloc/lg_connection_bloc.dart';
import '../components/atmospheric_globe_painter.dart';
import '../../config/routes/app_routes.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme/map_themes.dart';
import '../../core/enums/historical_data_mode.dart';

class LgSettingsScreen extends StatelessWidget {
  const LgSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = sl<LGConnectionBloc>()..add(const LGSettingsLoadRequested());
    return BlocProvider.value(value: bloc, child: const _LgSettingsBody());
  }
}

class _LgSettingsBody extends StatefulWidget {
  const _LgSettingsBody();

  @override
  State<_LgSettingsBody> createState() => _LgSettingsBodyState();
}

class _LgSettingsBodyState extends State<_LgSettingsBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeModeNotifier,
      builder: (context, mode, _) {
        final isDark = ThemeController.instance.isDarkMode;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Stack(
            children: [
              Positioned(
                top: -100,
                right: -150,
                child: Opacity(
                  opacity: 0.08,
                  child: SizedBox(
                    width: 400,
                    height: 400,
                    child: FuturisticGlobeBackground(
                      isDark: isDark,
                      animate: false, // Prevents 60FPS Opacity redraws
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, isDark),
                    _buildCustomTabBar(isDark),
                    Expanded(
                      child: BlocBuilder<LGConnectionBloc, LGConnectionState>(
                        // Only rebuild tabs when status or settings change.
                        // Error messages are handled by BlocListener in ConnectionTab,
                        // so they don't need to trigger a full tab tree rebuild.
                        buildWhen: (previous, current) =>
                            previous.status != current.status ||
                            previous.settings != current.settings,
                        builder: (context, state) {
                          return TabBarView(
                            controller: _tabController,
                            children: [
                              _GeneralTab(mode: mode, isDark: isDark),
                              _ConnectionTab(state: state, isDark: isDark),
                              _LiquidGalaxyTab(isDark: isDark),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                shape: BoxShape.circle,
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Settings',
            style: AppTheme.headingLarge.copyWith(
              fontSize: 32,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: AppTheme.labelLarge.copyWith(fontSize: 13),
        unselectedLabelStyle: AppTheme.labelLarge.copyWith(fontSize: 13),
        tabs: const [
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.tune, size: 16),
                  SizedBox(width: 6),
                  Text('General'),
                ],
              ),
            ),
          ),
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi, size: 16),
                  SizedBox(width: 6),
                  Text('Connection'),
                ],
              ),
            ),
          ),
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.public, size: 16),
                  SizedBox(width: 6),
                  Text('Liquid Galaxy'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// GENERAL TAB
// ════════════════════════════════════════════════════════════════════════════

class _GeneralTab extends StatefulWidget {
  final ThemeMode mode;
  final bool isDark;

  const _GeneralTab({required this.mode, required this.isDark});

  @override
  State<_GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends State<_GeneralTab> {
  MapType _selectedMapType = MapType.normal;
  String _selectedMapTheme = MapThemes.mapsThemeNone;
  HistoricalDataMode _selectedHistoricalMode = HistoricalDataMode.fast;

  @override
  void initState() {
    super.initState();
    _loadMapPreferences();
  }

  Future<void> _loadMapPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final mapTypeIndex = prefs.getInt('map_style') ?? MapType.normal.index;
    if (mapTypeIndex >= 0 && mapTypeIndex < MapType.values.length) {
      _selectedMapType = MapType.values[mapTypeIndex];
    }
    _selectedMapTheme = prefs.getString('map_theme') ?? MapThemes.mapsThemeNone;
    
    final modeIndex = prefs.getInt('historical_data_mode') ?? HistoricalDataMode.fast.index;
    if (modeIndex >= 0 && modeIndex < HistoricalDataMode.values.length) {
      _selectedHistoricalMode = HistoricalDataMode.values[modeIndex];
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _setMapType(MapType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('map_style', type.index);
    setState(() {
      _selectedMapType = type;
    });
  }

  Future<void> _setMapTheme(String themeJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('map_theme', themeJson);
    setState(() {
      _selectedMapTheme = themeJson;
    });
  }

  Future<void> _setHistoricalMode(HistoricalDataMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('historical_data_mode', mode.index);
    setState(() {
      _selectedHistoricalMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('APPEARANCE'),
          const SizedBox(height: 12),
          _buildThemeCard(widget.mode, widget.isDark),
          const SizedBox(height: 32),
          _buildSectionLabel('MAPS STYLE'),
          const SizedBox(height: 12),
          _buildMapStyleSection(widget.isDark),
          const SizedBox(height: 32),
          _buildSectionLabel('MAPS THEME'),
          const SizedBox(height: 12),
          _buildMapThemeSection(widget.isDark),
          const SizedBox(height: 32),
          _buildSectionLabel('HISTORICAL DATA'),
          const SizedBox(height: 12),
          _buildHistoricalDataSection(widget.isDark),
          const SizedBox(height: 32),
          _buildSectionLabel('PREFERENCES'),
          const SizedBox(height: 12),
          _buildLanguageCard(widget.isDark),
          const SizedBox(height: 32),
          _buildSectionLabel('ABOUT'),
          const SizedBox(height: 12),
          _buildAboutCard(context, widget.isDark),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildMapStyleSection(bool isDark) {
    final styles = [
      {'title': 'Normal', 'type': MapType.normal},
      {'title': 'Terrain', 'type': MapType.terrain},
      {'title': 'Satellite', 'type': MapType.satellite},
      {'title': 'Hybrid', 'type': MapType.hybrid},
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: styles.length,
        itemBuilder: (context, index) {
          final style = styles[index];
          final type = style['type'] as MapType;
          return _MapPreviewCard(
            title: style['title'] as String,
            isSelected: _selectedMapType == type,
            onTap: () => _setMapType(type),
            mapType: type,
            mapTheme: MapThemes.mapsThemeNone,
            isDark: isDark,
            delayMs: index * 150,
          );
        },
      ),
    );
  }

  Widget _buildMapThemeSection(bool isDark) {
    final themes = [
      {'name': 'Default', 'json': MapThemes.mapsThemeNone},
      {'name': 'Red', 'json': MapThemes.mapsThemeRed},
      {'name': 'Yellow', 'json': MapThemes.mapsThemeYellow},
      {'name': 'Green', 'json': MapThemes.mapsThemeGreen},
      {'name': 'Blue', 'json': MapThemes.mapsThemeBlue},
      {'name': 'Indigo', 'json': MapThemes.mapsThemeIndigo},
      {'name': 'Purple', 'json': MapThemes.mapsThemePurple},
      {'name': 'Pink', 'json': MapThemes.mapsThemePink},
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: themes.length,
        itemBuilder: (context, index) {
          final theme = themes[index];
          final String title = theme['name'] as String;
          final String json = theme['json'] as String;

          return _MapPreviewCard(
            title: title,
            isSelected: _selectedMapTheme == json,
            onTap: () => _setMapTheme(json),
            mapType: MapType.normal,
            mapTheme: json,
            isDark: isDark,
            delayMs: index * 150,
          );
        },
      ),
    );
  }

  Widget _buildHistoricalDataSection(bool isDark) {
    return Material(
      color: AppTheme.surfaceLight,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.divider : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppTheme.textPrimary,
          collapsedIconColor: AppTheme.textMuted,
          title: Text(
            'Data Fetch Range',
            style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            _selectedHistoricalMode.displayName,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.primary),
          ),
          children: [
            for (final mode in HistoricalDataMode.values)
              InkWell(
                onTap: () => _setHistoricalMode(mode),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedHistoricalMode == mode 
                        ? AppTheme.primary.withValues(alpha: 0.1) 
                        : Colors.transparent,
                    border: Border(
                      left: BorderSide(
                        color: _selectedHistoricalMode == mode 
                            ? AppTheme.primary 
                            : Colors.transparent,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(mode.icon, color: _selectedHistoricalMode == mode ? AppTheme.primary : AppTheme.textMuted),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mode.displayName, style: AppTheme.bodyLarge.copyWith(
                              fontWeight: _selectedHistoricalMode == mode ? FontWeight.w600 : FontWeight.w400,
                              color: _selectedHistoricalMode == mode ? AppTheme.primary : AppTheme.textPrimary,
                            )),
                            Text(mode.description, style: AppTheme.bodySmall),
                          ],
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _selectedHistoricalMode == mode
                            ? Icon(
                                Icons.check_circle,
                                key: const ValueKey('selected'),
                                color: AppTheme.primary,
                              )
                            : Icon(
                                Icons.radio_button_unchecked,
                                key: const ValueKey('unselected'),
                                color: AppTheme.textMuted,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTheme.labelLarge.copyWith(
        color: AppTheme.textMuted,
        letterSpacing: 1.5,
        fontSize: 11,
      ),
    );
  }

  Widget _buildBaseCard({required Widget child, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _buildThemeCard(ThemeMode currentMode, bool isDark) {
    return _buildBaseCard(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF7B8FD4).withValues(alpha: 0.1)
                        : const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: isDark
                        ? const Color(0xFF7B8FD4)
                        : const Color(0xFF4A90D9),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select app theme',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceLight : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildThemeSegment(
                      'Light',
                      ThemeMode.light,
                      currentMode,
                      isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildThemeSegment(
                      'Dark',
                      ThemeMode.dark,
                      currentMode,
                      isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildThemeSegment(
                      'System',
                      ThemeMode.system,
                      currentMode,
                      isDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSegment(
    String label,
    ThemeMode mode,
    ThemeMode currentMode,
    bool isDark,
  ) {
    final isSelected = mode == currentMode;
    return GestureDetector(
      onTap: () => ThemeController.instance.setThemeMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A90D9) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: (isSelected && !isDark)
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(bool isDark) {
    return _buildBaseCard(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.language,
                color: Color(0xFFFFC107),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Language',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select app language',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  'English',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: AppTheme.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.about),
      child: _buildBaseCard(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.surfaceLight
                      : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About EcoGrid',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Learn more about the application',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }


}

// ════════════════════════════════════════════════════════════════════════════
// CONNECTION TAB
// ════════════════════════════════════════════════════════════════════════════

class _ConnectionTab extends StatefulWidget {
  final LGConnectionState state;
  final bool isDark;

  const _ConnectionTab({required this.state, required this.isDark});

  @override
  State<_ConnectionTab> createState() => _ConnectionTabState();
}

class _ConnectionTabState extends State<_ConnectionTab> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController(text: 'lg');
  final _passwordController = TextEditingController();
  final _screenCountController = TextEditingController(text: '3');
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.state.settings.isConfigured) {
      _hostController.text = widget.state.settings.host;
      _portController.text = widget.state.settings.port.toString();
      _usernameController.text = widget.state.settings.username;
      _passwordController.text = widget.state.settings.password;
      _screenCountController.text = widget.state.settings.screenCount
          .toString();
    }
  }

  @override
  void didUpdateWidget(covariant _ConnectionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.state.settings.isConfigured &&
        widget.state.settings.isConfigured) {
      _hostController.text = widget.state.settings.host;
      _portController.text = widget.state.settings.port.toString();
      _usernameController.text = widget.state.settings.username;
      _passwordController.text = widget.state.settings.password;
      _screenCountController.text = widget.state.settings.screenCount
          .toString();
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _screenCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.state.status == ConnectionStatus.connected;
    final statusColor = isConnected
        ? const Color(0xFF00C853)
        : const Color(0xFFFF1744);
    final statusText = isConnected ? 'Connected' : 'Disconnected';
    final ipText = widget.state.settings.host.isNotEmpty
        ? widget.state.settings.host
        : 'Not configured';

    return BlocListener<LGConnectionBloc, LGConnectionState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AppTheme.riskCritical,
            ),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Indicator
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: widget.isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 15,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.satellite_alt,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: AppTheme.bodyLarge.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ipText,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'CREDENTIALS',
              style: AppTheme.labelLarge.copyWith(
                color: AppTheme.textMuted,
                letterSpacing: 1.5,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),

            _buildField('Username', _usernameController, Icons.person),
            _buildField(
              'Password',
              _passwordController,
              Icons.lock,
              obscure: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            _buildField(
              'IP Address',
              _hostController,
              Icons.computer,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    'Port',
                    _portController,
                    Icons.numbers,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildField(
                    'Total Screens',
                    _screenCountController,
                    Icons.monitor,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Connect / Disconnect Button
            if (!isConnected)
              GestureDetector(
                onTap: () {
                  final settings = LGSettings(
                    host: _hostController.text.trim(),
                    port: int.tryParse(_portController.text) ?? 22,
                    username: _usernameController.text.trim(),
                    password: _passwordController.text.trim(),
                    screenCount:
                        int.tryParse(_screenCountController.text) ?? 3,
                  );
                  context.read<LGConnectionBloc>()
                    ..add(LGSettingsSaveRequested(settings))
                    ..add(LGConnectRequested(settings));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: widget.isDark
                        ? []
                        : [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  alignment: Alignment.center,
                  child: widget.state.status == ConnectionStatus.connecting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.background,
                          ),
                        )
                      : Text(
                          'Connect',
                          style: AppTheme.labelLarge.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
              )
            else
              GestureDetector(
                onTap: () => context.read<LGConnectionBloc>().add(
                  const LGDisconnectRequested(),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.riskCritical.withValues(alpha: 0.5)),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.power_settings_new, color: AppTheme.riskCritical, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Disconnect',
                        style: AppTheme.labelLarge.copyWith(
                          color: AppTheme.riskCritical,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: AppTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: AppTheme.surfaceLight.withValues(alpha: 0.5),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.cardBorder.withValues(alpha: 0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.cardBorder.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppTheme.primary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// LIQUID GALAXY TAB
// ════════════════════════════════════════════════════════════════════════════

class _LiquidGalaxyTab extends StatelessWidget {
  final bool isDark;

  const _LiquidGalaxyTab({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('SYSTEM CONTROLS'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context: context,
                  title: 'Relaunch',
                  icon: Icons.refresh,
                  color: const Color(0xFF4A90D9),
                  onTap: () {
                    context.read<LGConnectionBloc>().add(
                      const LGRelaunchRequested(),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  context: context,
                  title: 'Reboot',
                  icon: Icons.restart_alt,
                  color: const Color(0xFFFF9800),
                  onTap: () {
                    context.read<LGConnectionBloc>().add(
                      const LGRebootRequested(),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context: context,
            title: 'Shut Down',
            icon: Icons.power_settings_new,
            color: AppTheme.riskCritical,
            isDestructive: true,
            isHorizontal: true,
            onTap: () {
              context.read<LGConnectionBloc>().add(const LGPowerOffRequested());
            },
          ),

          const SizedBox(height: 32),
          _buildSectionLabel('DISPLAY CONTROLS'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context: context,
                  title: 'Show Logos',
                  icon: Icons.image_outlined,
                  color: const Color(0xFF9C27B0),
                  onTap: () {
                    context.read<LGConnectionBloc>().add(
                      const LGShowLogosRequested(),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  context: context,
                  title: 'Clear Logos',
                  icon: Icons.hide_image_outlined,
                  color: AppTheme.textSecondary,
                  onTap: () {
                    context.read<LGConnectionBloc>().add(
                      const LGClearLogosRequested(),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context: context,
            title: 'Clear KML',
            icon: Icons.layers_clear,
            color: const Color(0xFF00C853),
            isHorizontal: true,
            onTap: () {
              context.read<LGConnectionBloc>().add(const LGClearKmlRequested());
            },
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTheme.labelLarge.copyWith(
        color: AppTheme.textMuted,
        letterSpacing: 1.5,
        fontSize: 11,
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isHorizontal = false,
  }) {
    return Container(
      width: isHorizontal ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withValues(alpha: 0.2), // Glowing ripple
          highlightColor: color.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isDestructive
                  ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
                  : null,
            ),
            child: isHorizontal
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        title,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDestructive ? color : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDestructive ? color : AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _MapPreviewCard extends StatefulWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final MapType mapType;
  final String mapTheme;
  final bool isDark;
  final int delayMs;

  const _MapPreviewCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.mapType,
    required this.mapTheme,
    required this.isDark,
    required this.delayMs,
  });

  @override
  State<_MapPreviewCard> createState() => _MapPreviewCardState();
}

class _MapPreviewCardState extends State<_MapPreviewCard> {


  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isSelected ? AppTheme.primary : AppTheme.cardBorder,
            width: widget.isSelected ? 2 : 1,
          ),
          boxShadow: widget.isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Container(
                color: _getMockColorForTheme(widget.mapTheme, widget.mapType, widget.isDark),
                child: Center(
                  child: Icon(
                    Icons.map_outlined,
                    size: 32,
                    color: widget.isDark || 
                           widget.mapType == MapType.satellite || 
                           widget.mapType == MapType.hybrid
                           ? Colors.white.withValues(alpha: 0.5)
                           : Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (widget.isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMockColorForTheme(String mapTheme, MapType type, bool isDark) {
    if (type == MapType.satellite || type == MapType.hybrid) {
      return const Color(0xFF2E3D2B); // Dark earthy green for satellite
    }
    if (type == MapType.terrain) {
      return const Color(0xFFC1D0B5); // Light greenish for terrain
    }
    
    if (mapTheme == MapThemes.mapsThemeRed) {
      return const Color(0xFFFFCDD2); // Light Red
    } else if (mapTheme == MapThemes.mapsThemeYellow) {
      return const Color(0xFFFFF9C4); // Light Yellow
    } else if (mapTheme == MapThemes.mapsThemeGreen) {
      return const Color(0xFFC8E6C9); // Light Green
    } else if (mapTheme == MapThemes.mapsThemeBlue) {
      return const Color(0xFFBBDEFB); // Light Blue
    } else if (mapTheme == MapThemes.mapsThemeIndigo) {
      return const Color(0xFFC5CAE9); // Light Indigo
    } else if (mapTheme == MapThemes.mapsThemePurple) {
      return const Color(0xFFE1BEE7); // Light Purple
    } else if (mapTheme == MapThemes.mapsThemePink) {
      return const Color(0xFFF8BBD0); // Light Pink
    }
    
    return isDark ? const Color(0xFF303030) : const Color(0xFFF5F5F5);
  }
}
