import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatefulWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final Color? color;
  final Color? borderColor;
  final Gradient? borderGradient;
  final Gradient? backgroundGradient;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;
  final bool enableGlow;
  final Color glowColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.07,
    this.borderRadius,
    this.color,
    this.borderColor,
    this.borderGradient,
    this.backgroundGradient,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.width,
    this.height,
    this.onTap,
    this.shadows,
    this.enableGlow = false,
    this.glowColor = const Color(0xFF00F0FF),
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(32);

    final glassFill = widget.color ??
        (isDark
            ? Colors.white.withValues(alpha: widget.opacity)
            : Colors.white.withValues(alpha: 0.68));

    final glassBorderColor = widget.borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.85));

    final defaultShadowColor = isDark ? Colors.black : const Color(0x1A0F172A);
    final shadowList = widget.shadows ?? [
      BoxShadow(
        color: defaultShadowColor.withValues(alpha: isDark ? 0.30 : 0.08),
        blurRadius: 28,
        spreadRadius: -4,
        offset: const Offset(0, 10),
      ),
      if (widget.enableGlow)
        BoxShadow(
          color: widget.glowColor.withValues(alpha: isDark ? 0.25 : 0.35),
          blurRadius: 20,
          spreadRadius: 1,
        ),
    ];

    Widget content = Container(
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundGradient == null ? glassFill : null,
        gradient: widget.backgroundGradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark
                    ? Colors.white.withValues(alpha: widget.opacity + 0.04)
                    : Colors.white.withValues(alpha: 0.78),
                isDark
                    ? Colors.white.withValues(alpha: widget.opacity)
                    : Colors.white.withValues(alpha: 0.58),
              ],
            ),
        borderRadius: effectiveRadius,
        border: widget.borderGradient == null
            ? Border.all(
                color: glassBorderColor,
                width: 1.2,
              )
            : null,
      ),
      child: widget.child,
    );

    if (widget.borderGradient != null) {
      content = Container(
        decoration: BoxDecoration(
          borderRadius: effectiveRadius,
          gradient: widget.borderGradient,
        ),
        padding: const EdgeInsets.all(1.2),
        child: Container(
          decoration: BoxDecoration(
            color: glassFill,
            borderRadius: effectiveRadius,
          ),
          padding: widget.padding,
          child: widget.child,
        ),
      );
    }

    Widget body = AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: effectiveRadius,
          boxShadow: shadowList,
        ),
        child: ClipRRect(
          borderRadius: effectiveRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: widget.blur < 35.0 ? 35.0 : widget.blur,
              sigmaY: widget.blur < 35.0 ? 35.0 : widget.blur,
            ),
            child: content,
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: body,
      );
    }

    return body;
  }
}
