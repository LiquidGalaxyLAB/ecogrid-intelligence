import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../config/theme/app_theme.dart';
import '../../di/di.dart';
import '../../service/tour_service.dart';

class EcoShowcase extends StatelessWidget {
  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;
  final VoidCallback? onTargetClick;
  final bool disposeOnTap;
  final BorderRadius? targetBorderRadius;
  final EdgeInsets targetPadding;
  final VoidCallback? onNextClick;
  final String? nextButtonText;

  const EcoShowcase({
    super.key,
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
    this.onTargetClick,
    this.disposeOnTap = true,
    this.targetBorderRadius,
    this.targetPadding = const EdgeInsets.all(8),
    this.onNextClick,
    this.nextButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: sl<TourService>().isTourActive,
      builder: (context, isActive, childWidget) {
        if (!isActive) return child;
        
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Showcase.withWidget(
          key: showcaseKey,
          targetBorderRadius: targetBorderRadius,
          targetPadding: targetPadding,
          disposeOnTap: disposeOnTap,
          onTargetClick: onTargetClick,
          blurValue: 3,
          overlayColor: isDark ? Colors.black : const Color(0xFF101828),
          overlayOpacity: 0.85,
      container: Container(
        width: 320,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF101828),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF475467),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (disposeOnTap)
                  Text(
                    'Tap target to continue',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary.withValues(alpha: 0.8),
                    ),
                  )
                else
                  const Spacer(),
                if (onNextClick != null)
                  ElevatedButton(
                    onPressed: onNextClick,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      nextButtonText ?? 'Next ➔',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      child: child,
    );
      },
    );
  }
}
