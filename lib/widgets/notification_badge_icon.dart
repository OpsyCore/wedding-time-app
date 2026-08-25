import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../services/notification_service.dart';

class NotificationBadgeIcon extends StatelessWidget {
  const NotificationBadgeIcon({
    super.key,
    required this.weddingId,
    required this.onPressed,
    this.iconSize = 22,
    this.iconColor, // دیگر default با AppPalette نده
  });

  final String weddingId;
  final VoidCallback onPressed;
  final double iconSize;
  final Color? iconColor;

  static const _fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  String _faDigits(String s) => s.split('').map((c) {
        final i = int.tryParse(c);
        return i != null ? _fa[i] : c;
      }).join();

  String _countLabel(int count) {
    if (count > 99) return AppLang.tr('badge_99_plus');
    final raw = '$count';
    return AppLang.I.isFa ? _faDigits(raw) : raw;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        final color = iconColor ?? AppTok.text(context);

        return Directionality(
          textDirection: AppLang.I.direction,
          child: StreamBuilder<int>(
            stream: NotificationService(weddingId).watchUnreadCount(),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              final label = _countLabel(count);

              return IconButton(
                tooltip: AppLang.tr('notifications'),
                onPressed: onPressed,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      count > 0
                          ? Icons.notifications
                          : Icons.notifications_none,
                      color: color,
                      size: iconSize,
                    ),
                    if (count > 0)
                      Positioned(
                        left: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppTok.danger(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTok.background(context),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}