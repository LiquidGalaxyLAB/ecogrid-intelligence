import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ecogrid_intelligence/config/theme.dart';
import 'package:ecogrid_intelligence/core/enums/connection_status.dart';
import 'package:ecogrid_intelligence/domain/entities/lg_settings.dart';
import 'package:ecogrid_intelligence/di/injection_container.dart';
import 'package:ecogrid_intelligence/presentation/blocs/lg_connection/lg_connection_bloc.dart';

class LgSettingsScreen extends StatelessWidget {
  const LgSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<LGConnectionBloc>()..add(const LGSettingsLoadRequested()),
      child: const _LgSettingsBody(),
    );
  }
}

class _LgSettingsBody extends StatefulWidget {
  const _LgSettingsBody();

  @override
  State<_LgSettingsBody> createState() => _LgSettingsBodyState();
}

class _LgSettingsBodyState extends State<_LgSettingsBody> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController(text: 'lg');
  final _passwordController = TextEditingController();
  final _screenCountController = TextEditingController(text: '5');

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
      body: SafeArea(
        child: BlocConsumer<LGConnectionBloc, LGConnectionState>(
          listener: (context, state) {
            if (state.settings.isConfigured) {
              _hostController.text = state.settings.host;
              _portController.text = state.settings.port.toString();
              _usernameController.text = state.settings.username;
              _passwordController.text = state.settings.password;
              _screenCountController.text =
                  state.settings.screenCount.toString();
            }
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
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusSmall),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              size: 18, color: AppTheme.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text('LG Settings', style: AppTheme.headingMedium),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Connection Status ───────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: state.status == ConnectionStatus.connected
                          ? AppTheme.connectedGreen.withValues(alpha: 0.1)
                          : AppTheme.surfaceLight,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(
                        color: state.status == ConnectionStatus.connected
                            ? AppTheme.connectedGreen
                                .withValues(alpha: 0.3)
                            : AppTheme.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                state.status == ConnectionStatus.connected
                                    ? AppTheme.connectedGreen
                                    : state.status ==
                                            ConnectionStatus.connecting
                                        ? AppTheme.riskMedium
                                        : AppTheme.riskCritical,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(state.status.label,
                            style: AppTheme.labelLarge),
                        const Spacer(),
                        Icon(Icons.tv,
                            color: AppTheme.textMuted, size: 24),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── SSH Config Fields ───────────────
                  Text('SSH CONFIGURATION',
                      style: AppTheme.labelSmall
                          .copyWith(letterSpacing: 2)),
                  const SizedBox(height: 16),

                  _buildField('Host / IP Address', _hostController,
                      Icons.computer),
                  _buildField('Port', _portController, Icons.numbers,
                      keyboardType: TextInputType.number),
                  _buildField(
                      'Username', _usernameController, Icons.person),
                  _buildField('Password', _passwordController, Icons.lock,
                      obscure: true),
                  _buildField('Screen Count', _screenCountController,
                      Icons.monitor,
                      keyboardType: TextInputType.number),

                  const SizedBox(height: 24),

                  // ── Connect / Disconnect Buttons ────
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final settings = LGSettings(
                              host: _hostController.text.trim(),
                              port: int.tryParse(_portController.text) ??
                                  22,
                              username:
                                  _usernameController.text.trim(),
                              password:
                                  _passwordController.text.trim(),
                              screenCount: int.tryParse(
                                      _screenCountController.text) ??
                                  5,
                            );
                            context.read<LGConnectionBloc>()
                              ..add(LGSettingsSaveRequested(settings))
                              ..add(LGConnectRequested(settings));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium),
                            ),
                            alignment: Alignment.center,
                            child: state.status ==
                                    ConnectionStatus.connecting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text('Connect',
                                    style: AppTheme.labelLarge.copyWith(
                                        color: AppTheme.background)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => context
                            .read<LGConnectionBloc>()
                            .add(const LGDisconnectRequested()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 24),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium),
                            border:
                                Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Text('Disconnect',
                              style: AppTheme.labelLarge
                                  .copyWith(color: AppTheme.textMuted)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── LG Controls ─────────────────────
                  Text('LG CONTROLS',
                      style: AppTheme.labelSmall
                          .copyWith(letterSpacing: 2)),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ControlButton(
                          icon: Icons.cleaning_services,
                          label: 'Clear KML',
                          onTap: () {}),
                      _ControlButton(
                          icon: Icons.rotate_right,
                          label: 'Orbit',
                          onTap: () {}),
                      _ControlButton(
                          icon: Icons.flight,
                          label: 'FlyTo',
                          onTap: () {}),
                      _ControlButton(
                          icon: Icons.restart_alt,
                          label: 'Reboot',
                          onTap: () {},
                          dangerous: true),
                    ],
                  ),
                ],
              ),
            );
          },
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
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(
                color: AppTheme.cardBorder.withValues(alpha: 0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(
                color: AppTheme.cardBorder.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(
                color: AppTheme.primary.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dangerous;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.dangerous = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: dangerous
              ? AppTheme.riskCritical.withValues(alpha: 0.1)
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: dangerous
                ? AppTheme.riskCritical.withValues(alpha: 0.3)
                : AppTheme.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: dangerous
                    ? AppTheme.riskCritical
                    : AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(label,
                style: AppTheme.bodySmall.copyWith(
                  color: dangerous
                      ? AppTheme.riskCritical
                      : AppTheme.textSecondary,
                )),
          ],
        ),
      ),
    );
  }
}
