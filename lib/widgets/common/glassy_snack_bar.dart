import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassySnackBar {
  static OverlayEntry? _currentOverlay;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    // Dismiss existing
    dismiss();

    final overlay = Overlay.of(context);
    
    // Animation controller and state
    late final OverlayEntry entry;
    
    entry = OverlayEntry(
      builder: (context) {
        return _GlassyToastWidget(
          message: message,
          actionLabel: actionLabel,
          onActionPressed: onActionPressed,
          duration: duration,
          onDismiss: () {
            entry.remove();
            if (_currentOverlay == entry) {
              _currentOverlay = null;
            }
          },
        );
      },
    );

    _currentOverlay = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    _timer?.cancel();
    if (_currentOverlay != null) {
      try {
        _currentOverlay!.remove();
      } catch (_) {}
      _currentOverlay = null;
    }
  }
}

class _GlassyToastWidget extends StatefulWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Duration duration;
  final VoidCallback onDismiss;

  const _GlassyToastWidget({
    required this.message,
    this.actionLabel,
    this.onActionPressed,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_GlassyToastWidget> createState() => _GlassyToastWidgetState();
}

class _GlassyToastWidgetState extends State<_GlassyToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    _dismissTimer = Timer(widget.duration, () {
      _hide();
    });
  }

  void _hide() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final accentColor = isDark ? const Color(0xFF00F0FF) : const Color(0xFF0094FF);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF12131C).withValues(alpha: 0.88)
                            : const Color(0xFFFFFFFF).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: accentColor.withValues(alpha: isDark ? 0.4 : 0.6),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: isDark ? 0.25 : 0.20),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: accentColor,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              widget.message,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (widget.actionLabel != null &&
                              widget.onActionPressed != null) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: accentColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                _dismissTimer?.cancel();
                                widget.onActionPressed!();
                                _hide();
                              },
                              child: Text(
                                widget.actionLabel!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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
