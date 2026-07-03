import 'package:flutter/material.dart';
import '../../config/theme/app_theme.dart';
import '../../config/theme/theme_controller.dart';

class AppSearchBar extends StatelessWidget {
  final String hintText;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final bool isListening;
  final VoidCallback? onMicTap;
  final VoidCallback? onClearTap;
  final VoidCallback? onPrefixIconTap;
  final IconData? prefixIcon;
  const AppSearchBar({
    super.key,
    required this.hintText,
    this.onTap,
    this.readOnly = false,
    this.controller,
    this.onChanged,
    this.isListening = false,
    this.onMicTap,
    this.onClearTap,
    this.onPrefixIconTap,
    this.prefixIcon,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    Widget innerTextField = TextField(
      controller: controller,
      autofocus: !readOnly,
      readOnly: readOnly,
      onTap: onTap,
      style: AppTheme.bodyLarge.copyWith(
        color: isDark ? AppTheme.textPrimary : const Color(0xFF0D1F4A),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTheme.bodyLarge.copyWith(
          color: isDark ? AppTheme.textSecondary : const Color(0xFF6B80A0),
        ),
        border: InputBorder.none,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        prefixIcon: GestureDetector(
          onTap: onPrefixIconTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(
              prefixIcon ?? Icons.search,
              color: isDark ? AppTheme.textSecondary : const Color(0xFF0066FF),
              size: prefixIcon != null ? 20 : 24,
            ),
          ),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!readOnly &&
                  controller != null &&
                  controller!.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark
                        ? AppTheme.textSecondary
                        : const Color(0xFF6B80A0),
                    size: 20,
                  ),
                  onPressed: onClearTap,
                ),
              IconButton(
                icon: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: isListening
                      ? (isDark ? AppTheme.primary : const Color(0xFF0066FF))
                      : (isDark
                            ? AppTheme.textSecondary
                            : const Color(0xFF0066FF)),
                  size: 22,
                ),
                onPressed: onMicTap,
              ),
            ],
          ),
        ),
      ),
      onChanged: onChanged,
    );
    Widget searchContent = Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardBackground : Colors.white,
        borderRadius: BorderRadius.circular(100),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
        border: Border.all(
          color: isDark
              ? AppTheme.primary.withValues(alpha: 0.30)
              : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: innerTextField,
    );
    if (readOnly) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: searchContent,
      );
    }
    return searchContent;
  }
}
