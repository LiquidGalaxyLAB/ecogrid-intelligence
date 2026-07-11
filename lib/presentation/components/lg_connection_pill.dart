import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_theme.dart';
import '../../config/routes/app_routes.dart';
import '../../core/enums/connection_status.dart';
import '../lg_connection/bloc/lg_connection_bloc.dart';
import '../../di/di.dart';

class LgConnectionPill extends StatelessWidget {
  const LgConnectionPill({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<LGConnectionBloc>(),
      child: BlocBuilder<LGConnectionBloc, LGConnectionState>(
        builder: (context, state) {
          final status = state.status;
          final isConnected = status == ConnectionStatus.connected;
          final isConnecting = status == ConnectionStatus.connecting;
          Color statusColor;
          if (isConnected) {
            statusColor = const Color(0xFF00C853);
          } else if (isConnecting) {
            statusColor = const Color(0xFFFFC107);
          } else {
            statusColor = const Color(0xFFFF1744);
          }
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.lgSettings),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardBackground : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(
                  color: isDark
                      ? statusColor.withValues(alpha: 0.4)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Liquid Galaxy',
                        style: AppTheme.caption.copyWith(
                          color: isDark
                              ? AppTheme.textPrimary
                              : const Color(0xFF1A2114),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        status.label,
                        style: AppTheme.labelSmall.copyWith(
                          color: isDark ? AppTheme.textSecondary : statusColor,
                          fontSize: 11,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.settings,
                    size: 20,
                    color: isDark
                        ? AppTheme.textSecondary
                        : const Color(0xFF4A5568),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
