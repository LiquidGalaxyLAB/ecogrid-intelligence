import 'package:flutter/material.dart';
import '../../config/theme/app_theme.dart';

/// A small pill widget shown during the FTUE tour that lets the user
/// dismiss / skip the entire tour at any step.
///
/// Used as the [globalFloatingActionWidget] in [ShowcaseView.register].
class TourSkipPill extends StatelessWidget {
  final VoidCallback onTap;
  const TourSkipPill({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Skip tour',
              style: AppTheme.labelSmall.copyWith(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.close, color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }
}
