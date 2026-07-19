import 'dart:math' as math;
import 'package:flutter/material.dart';

class GlassBackground extends StatefulWidget {
  final Widget child;
  final bool animate;

  const GlassBackground({
    super.key,
    required this.child,
    this.animate = true,
  });

  @override
  State<GlassBackground> createState() => _GlassBackgroundState();
}

class _GlassBackgroundState extends State<GlassBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF09090B) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: baseColor,
      body: Stack(
        children: [
          // Base background canvas
          Positioned.fill(
            child: Container(
              color: baseColor,
            ),
          ),

          // Animated Light Orb 1 (Electric Blue / Cyan top left)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final val = _controller.value;
              final offsetX = math.sin(val * math.pi) * 45;
              final offsetY = math.cos(val * math.pi) * 35;

              final orbColors = isDark
                  ? [
                      const Color(0xFF00F0FF).withValues(alpha: 0.28),
                      const Color(0xFF00FFE0).withValues(alpha: 0.12),
                      Colors.transparent,
                    ]
                  : [
                      const Color(0xFF0094FF).withValues(alpha: 0.40),
                      const Color(0xFF00F0FF).withValues(alpha: 0.20),
                      Colors.transparent,
                    ];

              return Positioned(
                top: -80 + offsetY,
                left: -80 + offsetX,
                child: Container(
                  width: size.width * 0.90,
                  height: size.width * 0.90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: orbColors,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // Animated Light Orb 2 (Cyber Purple / Magenta bottom right)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final val = _controller.value;
              final offsetX = math.cos(val * math.pi) * 55;
              final offsetY = math.sin(val * math.pi) * 45;

              final orbColors = isDark
                  ? [
                      const Color(0xFF9D00FF).withValues(alpha: 0.25),
                      const Color(0xFF7000FF).withValues(alpha: 0.10),
                      Colors.transparent,
                    ]
                  : [
                      const Color(0xFFD946EF).withValues(alpha: 0.35),
                      const Color(0xFFA855F7).withValues(alpha: 0.18),
                      Colors.transparent,
                    ];

              return Positioned(
                bottom: -100 + offsetY,
                right: -80 + offsetX,
                child: Container(
                  width: size.width * 0.95,
                  height: size.width * 0.95,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: orbColors,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // Animated Light Orb 3 (Emerald / Mint center glow)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final val = _controller.value;
              final scale = 0.8 + (math.sin(val * math.pi * 2) * 0.2);

              final orbColors = isDark
                  ? [
                      const Color(0xFF00FF87).withValues(alpha: 0.14),
                      Colors.transparent,
                    ]
                  : [
                      const Color(0xFF10B981).withValues(alpha: 0.28),
                      Colors.transparent,
                    ];

              return Positioned(
                top: size.height * 0.32,
                left: size.width * 0.05,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: size.width * 0.85,
                    height: size.width * 0.85,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: orbColors,
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Animated Light Orb 4 (Gold / Amber / Rose Gold mid-right glow)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final val = _controller.value;
              final offsetX = math.sin(val * math.pi * 1.5) * 40;
              final offsetY = math.cos(val * math.pi * 1.5) * 30;

              final orbColors = isDark
                  ? [
                      const Color(0xFFFFB800).withValues(alpha: 0.16),
                      Colors.transparent,
                    ]
                  : [
                      const Color(0xFFF43F5E).withValues(alpha: 0.22),
                      Colors.transparent,
                    ];

              return Positioned(
                top: size.height * 0.18 + offsetY,
                right: -60 + offsetX,
                child: Container(
                  width: size.width * 0.75,
                  height: size.width * 0.75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: orbColors,
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // Child content on top
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}
