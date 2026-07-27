import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/design_constants.dart';
import '../../../config/theme/theme_controller.dart';
import '../../../domain/model/region.dart';

class RegionListTile extends StatelessWidget {
  const RegionListTile({
    required this.region,
    required this.onTap,
    super.key,
  });

  final Region region;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    
    // Default blue color for regions
    const iconColor = Color(0xFF00C8FF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? DesignConstants.cardSurface(context) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? DesignConstants.border(context)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? .15 : .03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? DesignConstants.elevatedSurface(context)
                    : iconColor.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  FluentIcons.globe_24_filled, 
                  color: iconColor, 
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region.displayName ?? region.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? DesignConstants.primaryText(context)
                          : const Color(0xFF0D1F4A),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Region',
                    style: TextStyle(
                      color: isDark
                          ? DesignConstants.secondaryText(context)
                          : const Color(0xFF6B80A0),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              FluentIcons.compass_northwest_24_regular,
              color: isDark
                  ? DesignConstants.mutedText(context)
                  : const Color(0xFF0066FF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
