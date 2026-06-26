import 'dart:ui';
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
        color: isDark ? Colors.white : const Color(0xFF0A1931),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTheme.bodyLarge.copyWith(
          color: isDark ? const Color(0xFF4A5568) : const Color(0xFFB3CFE5),
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
              color: isDark ? const Color(0xFF8A9BAE) : const Color(0xFF4A7FA7),
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
                        ? const Color(0xFF8A9BAE)
                        : const Color(0xFF4A7FA7),
                    size: 20,
                  ),
                  onPressed: onClearTap,
                ),
              IconButton(
                icon: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: isListening
                      ? (isDark
                            ? const Color(0xFF00C8FF)
                            : const Color(0xFF4A7FA7))
                      : (isDark
                            ? const Color(0xFF8A9BAE)
                            : const Color(0xFF4A7FA7)),
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

    Widget searchContent = isDark
        ? Container(
            decoration: BoxDecoration(
              color: const Color(0xFF131920),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: const Color(0xFF0066FF).withValues(alpha: 0.30),
                width: 1.0,
              ),
            ),
            child: innerTextField,
          )
        : Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF6FAFD).withValues(alpha: 0.95),
                  const Color(0xFFB3CFE5).withValues(alpha: 0.75),
                  const Color(0xFF4A7FA7).withValues(alpha: 0.45),
                ],
                stops: const [0.0, 0.55, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFFF6FAFD).withValues(alpha: 0.90),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A1931).withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: const Color(0xFF4A7FA7).withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFFF6FAFD).withValues(alpha: 0.80),
                  blurRadius: 0,
                  offset: const Offset(0, -1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF6FAFD).withValues(alpha: 0.55),
                        const Color(0xFFB3CFE5).withValues(alpha: 0.30),
                        const Color(0xFF4A7FA7).withValues(alpha: 0.15),
                      ],
                      stops: const [0.0, 0.50, 1.0],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onPrefixIconTap,
                        behavior: HitTestBehavior.opaque,
                        child: Icon(
                          prefixIcon ?? Icons.search_rounded,
                          color: const Color(0xFF1A3D63),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          onChanged: onChanged,
                          autofocus: !readOnly,
                          readOnly: readOnly,
                          onTap: onTap,
                          style: const TextStyle(
                            color: Color(0xFF0A1931),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: hintText,
                            hintStyle: TextStyle(
                              color: const Color(
                                0xFF4A7FA7,
                              ).withValues(alpha: 0.65),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!readOnly &&
                          controller != null &&
                          controller!.text.isNotEmpty)
                        GestureDetector(
                          onTap: onClearTap,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.close,
                              color: Color(0xFF1A3D63),
                              size: 20,
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: onMicTap,
                        child: Icon(
                          isListening ? Icons.mic : Icons.mic_none,
                          color: isListening
                              ? const Color(0xFF4A7FA7)
                              : const Color(0xFF1A3D63),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
