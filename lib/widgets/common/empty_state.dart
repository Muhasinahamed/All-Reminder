import 'package:flutter/material.dart';
import 'glass_container.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? themeColor;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const EmptyState({
    super.key,
    required this.message,
    this.icon,
    this.themeColor,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseAccent = themeColor ?? (isDark ? const Color(0xFF00F0FF) : const Color(0xFF0070F3));
    final textColor = theme.colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(28),
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          borderColor: baseAccent.withValues(alpha: isDark ? 0.35 : 0.45),
          opacity: isDark ? 0.07 : 0.65,
          blur: 38,
          enableGlow: true,
          glowColor: baseAccent.withValues(alpha: isDark ? 0.4 : 0.25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: baseAccent.withValues(alpha: isDark ? 0.16 : 0.14),
                    border: Border.all(
                      color: baseAccent.withValues(alpha: isDark ? 0.5 : 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: baseAccent.withValues(alpha: isDark ? 0.35 : 0.2),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 48, color: baseAccent),
                ),
              const SizedBox(height: 20),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onActionPressed != null) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: baseAccent,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 4,
                  ),
                  onPressed: onActionPressed,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
