import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../providers/language_provider.dart';
import 'glass_container.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final Color themeColor;
  final bool enabled;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.themeColor,
    required this.enabled,
    required this.onToggle,
    required this.onTap,
    this.onDelete,
  });

  String _formatTo12Hour(String timeString) {
    try {
      if (timeString.toLowerCase().contains('am') || timeString.toLowerCase().contains('pm')) {
        return timeString;
      }
      final parts = timeString.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final minuteStr = minute.toString().padLeft(2, '0');
      
      return "$hour12:$minuteStr $period";
    } catch (e) {
      return timeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    // High contrast color adaptation for Light Mode
    final activeColor = isDark
        ? themeColor
        : (themeColor == const Color(0xFF00FF87)
            ? const Color(0xFF047857)
            : (themeColor == const Color(0xFFFFB800)
                ? const Color(0xFFD97706)
                : themeColor));

    final card = GlassContainer(
      margin: const EdgeInsets.only(bottom: 14),
      borderRadius: BorderRadius.circular(32),
      blur: 38,
      opacity: enabled ? (isDark ? 0.08 : 0.68) : (isDark ? 0.04 : 0.40),
      borderColor: enabled
          ? activeColor.withValues(alpha: isDark ? 0.45 : 0.60)
          : (isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08)),
      enableGlow: false,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled
                  ? activeColor.withValues(alpha: isDark ? 0.15 : 0.14)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03)),
              border: Border.all(
                color: enabled
                    ? activeColor.withValues(alpha: isDark ? 0.7 : 0.8)
                    : (isDark ? Colors.white24 : Colors.black12),
                width: 1.2,
              ),
            ),
            child: Icon(
              enabled ? Icons.notifications_active : Icons.notifications_off,
              color: enabled
                  ? activeColor
                  : (isDark ? Colors.white38 : Colors.black38),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  notification.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: enabled ? textColor : textColor.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_filled,
                      size: 14,
                      color: activeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTo12Hour(notification.time),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: activeColor,
                      ),
                    ),
                  ],
                ),
                if (notification.message != null && notification.message!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notification.message!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: enabled,
            onChanged: (_) => onToggle(),
            activeThumbColor: activeColor,
            activeTrackColor: activeColor.withValues(alpha: isDark ? 0.3 : 0.25),
            inactiveThumbColor: isDark ? Colors.white38 : Colors.black26,
            inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,
          ),
        ],
      ),
    );

    if (onDelete != null) {
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);

      return Dismissible(
        key: Key('${notification.category}_${notification.name}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: isDark
                    ? const Color(0xFF12131F).withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: Colors.redAccent.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent.withValues(alpha: 0.15),
                      ),
                      child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        langProvider.translate('delete_reminder'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  "${langProvider.translate('confirm_delete')} '${notification.name}'?",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      langProvider.translate('cancel'),
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      langProvider.translate('delete'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            },
          ) ?? false;
        },
        onDismissed: (_) => onDelete!(),
        background: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                langProvider.translate('delete'),
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.delete_outline, color: Colors.redAccent, size: 26),
            ],
          ),
        ),
        child: card,
      );
    }

    return card;
  }
}
