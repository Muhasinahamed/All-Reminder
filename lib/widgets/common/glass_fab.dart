import 'dart:ui';
import 'package:flutter/material.dart';

class GlassFab extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;
  final String? tooltip;
  final double size;

  const GlassFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.color = const Color(0xFF00F0FF),
    this.tooltip,
    this.size = 60.0,
  });

  @override
  State<GlassFab> createState() => _GlassFabState();
}

class _GlassFabState extends State<GlassFab> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(24);

    // High-contrast color adaptation
    final activeColor = isDark
        ? widget.color
        : (widget.color == const Color(0xFF00FF87)
            ? const Color(0xFF047857)
            : (widget.color == const Color(0xFFFFB800)
                ? const Color(0xFFD97706)
                : widget.color));

    return Tooltip(
      message: widget.tooltip ?? '',
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onPressed,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 14,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: activeColor.withValues(alpha: isDark ? 0.18 : 0.15),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    color: isDark
                        ? activeColor.withValues(alpha: 0.20)
                        : activeColor.withValues(alpha: 0.18),
                    border: Border.all(
                      color: activeColor.withValues(alpha: isDark ? 0.50 : 0.65),
                      width: 1.4,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Liquid Glass Specular Reflection Highlight
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: borderRadius,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: isDark ? 0.35 : 0.50),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.55],
                          ),
                        ),
                      ),
                      // Icon inside Liquid Glass body
                      Icon(
                        widget.icon,
                        size: widget.size * 0.50,
                        color: isDark ? Colors.white : activeColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
