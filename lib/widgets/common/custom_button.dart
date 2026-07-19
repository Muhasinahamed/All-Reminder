import 'package:flutter/material.dart';
import 'glass_container.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.label,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // High contrast color adaptation for Light Mode
    final activeColor = isDark
        ? color
        : (color == const Color(0xFF00FF87)
            ? const Color(0xFF047857)
            : (color == const Color(0xFFFFB800)
                ? const Color(0xFFD97706)
                : color));

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 14),
      borderRadius: BorderRadius.circular(32),
      blur: 38,
      opacity: isDark ? 0.07 : 0.68,
      borderColor: isDark
          ? activeColor.withValues(alpha: 0.38)
          : activeColor.withValues(alpha: 0.60),
      enableGlow: false,
      onTap: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activeColor.withValues(alpha: isDark ? 0.16 : 0.14),
              border: Border.all(
                color: activeColor.withValues(alpha: isDark ? 0.65 : 0.75),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: isDark ? 0.25 : 0.18),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, size: 28, color: activeColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activeColor.withValues(alpha: isDark ? 0.12 : 0.14),
              border: Border.all(
                color: activeColor.withValues(alpha: isDark ? 0.3 : 0.45),
              ),
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: activeColor,
            ),
          ),
        ],
      ),
    );
  }
}
