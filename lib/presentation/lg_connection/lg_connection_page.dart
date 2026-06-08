import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ecogrid_intelligence/config/theme/app_theme.dart';
import 'package:ecogrid_intelligence/config/theme/theme_controller.dart';
import 'package:ecogrid_intelligence/core/enums/connection_status.dart';
import 'package:ecogrid_intelligence/domain/model/lg_settings.dart';
import 'package:ecogrid_intelligence/di/di.dart';
import 'package:ecogrid_intelligence/presentation/lg_connection/bloc/lg_connection_bloc.dart';
import 'package:ecogrid_intelligence/presentation/components/atmospheric_globe_painter.dart';

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

class _LgSettingsBodyState extends State<_LgSettingsBody> {
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
                    child: FuturisticGlobeBackground(isDark: isDark),
                  ),
                ),
              ),
              SafeArea(
                child: BlocBuilder<LGConnectionBloc, LGConnectionState>(
                  builder: (context, state) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
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
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
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
                          const SizedBox(height: 24),
                          Text(
                            'Settings',
                            style: AppTheme.headingLarge.copyWith(
                              fontSize: 36,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Manage your EcoGrid experience',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 32),

                          _buildLgCard(context, state, isDark),
                          const SizedBox(height: 32),

                          _buildSectionLabel('APPEARANCE'),
                          const SizedBox(height: 12),
                          _buildThemeCard(mode, isDark),
                          const SizedBox(height: 32),

                          _buildSectionLabel('PREFERENCES'),
                          const SizedBox(height: 12),
                          _buildLanguageCard(isDark),
                          const SizedBox(height: 32),

                          _buildSectionLabel('MORE'),
                          const SizedBox(height: 12),
                          _buildAboutCard(isDark),
                          const SizedBox(height: 48),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildLgCard(
    BuildContext context,
    LGConnectionState state,
    bool isDark,
  ) {
    final isConnected = state.status == ConnectionStatus.connected;
    final statusColor = isConnected
        ? const Color(0xFF00C853)
        : const Color(0xFFFF1744);
    final statusText = isConnected ? 'Connected' : 'Disconnected';
    final ipText = state.settings.host.isNotEmpty
        ? state.settings.host
        : 'Not configured';

    return _buildBaseCard(
      isDark: isDark,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.satellite_alt,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liquid Galaxy',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: AppTheme.bodyMedium.copyWith(
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ipText,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.surfaceLight.withValues(alpha: 0.5)
                  : const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF00C853),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Manage your SSH connection\nand controller settings',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<LGConnectionBloc>(),
                          child: const SshCredentialsScreen(),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 8.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Configure',
                          style: AppTheme.bodyMedium.copyWith(
                            color: const Color(0xFF00C853),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF00C853),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(ThemeMode currentMode, bool isDark) {
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
                    'Select your preferred\napp theme',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceLight : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildThemeSegment(
                    'Light',
                    ThemeMode.light,
                    currentMode,
                    isDark,
                  ),
                  _buildThemeSegment(
                    'Dark',
                    ThemeMode.dark,
                    currentMode,
                    isDark,
                  ),
                  _buildThemeSegment(
                    'System',
                    ThemeMode.system,
                    currentMode,
                    isDark,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    'Select your preferred\napplication language',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textMuted,
                      height: 1.3,
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

  Widget _buildAboutCard(bool isDark) {
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
                color: isDark ? AppTheme.surfaceLight : const Color(0xFFF3F4F6),
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
                    'Learn more about EcoGrid',
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
    );
  }
}

class SshCredentialsScreen extends StatefulWidget {
  const SshCredentialsScreen({super.key});

  @override
  State<SshCredentialsScreen> createState() => _SshCredentialsScreenState();
}

class _SshCredentialsScreenState extends State<SshCredentialsScreen> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController(text: 'lg');
  final _passwordController = TextEditingController();
  final _screenCountController = TextEditingController(text: '5');

  @override
  void initState() {
    super.initState();
    final state = context.read<LGConnectionBloc>().state;
    if (state.settings.isConfigured) {
      _hostController.text = state.settings.host;
      _portController.text = state.settings.port.toString();
      _usernameController.text = state.settings.username;
      _passwordController.text = state.settings.password;
      _screenCountController.text = state.settings.screenCount.toString();
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('SSH Credentials', style: AppTheme.headingSmall),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<LGConnectionBloc, LGConnectionState>(
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
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(
                  'Host / IP Address',
                  _hostController,
                  Icons.computer,
                ),
                _buildField(
                  'Port',
                  _portController,
                  Icons.numbers,
                  keyboardType: TextInputType.number,
                ),
                _buildField('Username', _usernameController, Icons.person),
                _buildField(
                  'Password',
                  _passwordController,
                  Icons.lock,
                  obscure: true,
                ),
                _buildField(
                  'Screen Count',
                  _screenCountController,
                  Icons.monitor,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final settings = LGSettings(
                            host: _hostController.text.trim(),
                            port: int.tryParse(_portController.text) ?? 22,
                            username: _usernameController.text.trim(),
                            password: _passwordController.text.trim(),
                            screenCount:
                                int.tryParse(_screenCountController.text) ?? 5,
                          );
                          context.read<LGConnectionBloc>()
                            ..add(LGSettingsSaveRequested(settings))
                            ..add(LGConnectRequested(settings));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: state.status == ConnectionStatus.connecting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.background,
                                  ),
                                )
                              : Text(
                                  'Connect',
                                  style: AppTheme.labelLarge.copyWith(
                                    color: AppTheme.background,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => context.read<LGConnectionBloc>().add(
                        const LGDisconnectRequested(),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 24,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Text(
                          'Disconnect',
                          style: AppTheme.labelLarge.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: AppTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTheme.bodySmall,
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
          filled: true,
          fillColor: AppTheme.surfaceLight.withValues(alpha: 0.5),
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
