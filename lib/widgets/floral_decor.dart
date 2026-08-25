import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';

/// گل‌های آب‌رنگی تزئینی برای پس‌زمینه صفحات روشن
/// (در Dark mode هم با رنگ‌های برندِ Dark به‌صورت ملایم‌تر رندر می‌شود)
class FloralDecor extends StatelessWidget {
  const FloralDecor({
    super.key,
    this.intensity = 1.0,
    this.frameMode = false,
  });

  final double intensity;

  /// اگر true باشد گل‌ها بیشتر روی چهار گوشه می‌نشینند (کارت دعوت)
  final bool frameMode;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppThemeController.I,
      builder: (context, _) {
        final dark = AppTok.isDark(context);

        final blush = dark ? AppDarkPalette.brandBlush : AppPalette.brandBlush;
        final blushSoft =
            dark ? AppDarkPalette.brandBlushSoft : AppPalette.brandBlushSoft;
        final green = dark ? AppDarkPalette.brandGreen : AppPalette.brandGreen;

        // در دارک کمی ملایم‌تر تا روی پس‌زمینه تیره توی ذوق نزند.
        final aBase = intensity.clamp(0.3, 1.6);
        final a = dark ? (aBase * 0.6) : aBase;

        if (frameMode) {
          return IgnorePointer(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // بالا چپ
                Positioned(
                  top: -22,
                  left: -26,
                  child: Opacity(
                    opacity: 0.72 * a,
                    child: Transform.rotate(
                      angle: -0.25,
                      child: CustomPaint(
                        size: const Size(128, 128),
                        painter: _PeonyPainter(
                          petal: blush.withValues(alpha: 0.62),
                          center: blushSoft,
                          inner: blush.withValues(alpha: 0.55),
                          leaf: green.withValues(alpha: 0.34),
                        ),
                      ),
                    ),
                  ),
                ),
                // بالا راست
                Positioned(
                  top: -26,
                  right: -28,
                  child: Opacity(
                    opacity: 0.75 * a,
                    child: Transform.rotate(
                      angle: 0.35,
                      child: CustomPaint(
                        size: const Size(140, 140),
                        painter: _PeonyPainter(
                          petal: blush.withValues(alpha: 0.58),
                          center: blushSoft.withValues(alpha: 0.95),
                          inner: blush.withValues(alpha: 0.55),
                          leaf: green.withValues(alpha: 0.32),
                        ),
                      ),
                    ),
                  ),
                ),
                // برگ‌های کناری بالا
                Positioned(
                  top: 36,
                  left: -18,
                  child: Opacity(
                    opacity: 0.5 * a,
                    child: Transform.rotate(
                      angle: -0.6,
                      child: CustomPaint(
                        size: const Size(90, 90),
                        painter: _LeafClusterPainter(
                          color: green.withValues(alpha: 0.36),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: -14,
                  child: Opacity(
                    opacity: 0.48 * a,
                    child: Transform.rotate(
                      angle: 0.7,
                      child: CustomPaint(
                        size: const Size(86, 86),
                        painter: _LeafClusterPainter(
                          color: green.withValues(alpha: 0.34),
                        ),
                      ),
                    ),
                  ),
                ),
                // پایین چپ — گل بزرگ
                Positioned(
                  bottom: -34,
                  left: -38,
                  child: Opacity(
                    opacity: 0.78 * a,
                    child: Transform.rotate(
                      angle: -0.15,
                      child: CustomPaint(
                        size: const Size(168, 168),
                        painter: _PeonyPainter(
                          petal: blush.withValues(alpha: 0.55),
                          center: blushSoft.withValues(alpha: 0.95),
                          inner: blush.withValues(alpha: 0.55),
                          leaf: green.withValues(alpha: 0.30),
                        ),
                      ),
                    ),
                  ),
                ),
                // پایین راست
                Positioned(
                  bottom: -30,
                  right: -32,
                  child: Opacity(
                    opacity: 0.7 * a,
                    child: Transform.rotate(
                      angle: 0.4,
                      child: CustomPaint(
                        size: const Size(150, 150),
                        painter: _PeonyPainter(
                          petal: blush.withValues(alpha: 0.5),
                          center: blushSoft,
                          inner: blush.withValues(alpha: 0.55),
                          leaf: green.withValues(alpha: 0.28),
                        ),
                      ),
                    ),
                  ),
                ),
                // برگ پایین وسط-چپ/راست
                Positioned(
                  bottom: 48,
                  left: -10,
                  child: Opacity(
                    opacity: 0.42 * a,
                    child: Transform.rotate(
                      angle: 0.3,
                      child: CustomPaint(
                        size: const Size(78, 78),
                        painter: _LeafClusterPainter(
                          color: green.withValues(alpha: 0.32),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 56,
                  right: -8,
                  child: Opacity(
                    opacity: 0.4 * a,
                    child: Transform.rotate(
                      angle: -0.35,
                      child: CustomPaint(
                        size: const Size(74, 74),
                        painter: _LeafClusterPainter(
                          color: green.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: -18,
                right: -24,
                child: Opacity(
                  opacity: 0.55 * a,
                  child: CustomPaint(
                    size: const Size(150, 150),
                    painter: _PeonyPainter(
                      petal: blush.withValues(alpha: 0.55),
                      center: blushSoft,
                      inner: blush.withValues(alpha: 0.55),
                      leaf: green.withValues(alpha: 0.28),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: -30,
                child: Opacity(
                  opacity: 0.4 * a,
                  child: Transform.rotate(
                    angle: -0.4,
                    child: CustomPaint(
                      size: const Size(120, 120),
                      painter: _LeafClusterPainter(
                        color: green.withValues(alpha: 0.30),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -28,
                left: -36,
                child: Opacity(
                  opacity: 0.5 * a,
                  child: CustomPaint(
                    size: const Size(170, 170),
                    painter: _PeonyPainter(
                      petal: blush.withValues(alpha: 0.42),
                      center: blushSoft.withValues(alpha: 0.9),
                      inner: blush.withValues(alpha: 0.55),
                      leaf: green.withValues(alpha: 0.22),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: -20,
                child: Opacity(
                  opacity: 0.35 * a,
                  child: Transform.rotate(
                    angle: 0.5,
                    child: CustomPaint(
                      size: const Size(110, 110),
                      painter: _LeafClusterPainter(
                        color: green.withValues(alpha: 0.26),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PeonyPainter extends CustomPainter {
  _PeonyPainter({
    required this.petal,
    required this.center,
    required this.inner,
    required this.leaf,
  });

  final Color petal;
  final Color center;
  final Color inner;
  final Color leaf;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.52, size.height * 0.48);
    final r = size.shortestSide * 0.28;

    final leafPaint = Paint()..color = leaf;
    for (int i = 0; i < 5; i++) {
      final ang = -1.0 + i * 0.5;
      final path = Path();
      final tip = Offset(
        c.dx + math.cos(ang) * r * 1.85,
        c.dy + math.sin(ang) * r * 1.85,
      );
      final ctrl1 = Offset(
        c.dx + math.cos(ang - 0.55) * r * 1.15,
        c.dy + math.sin(ang - 0.55) * r * 1.15,
      );
      final ctrl2 = Offset(
        c.dx + math.cos(ang + 0.55) * r * 1.15,
        c.dy + math.sin(ang + 0.55) * r * 1.15,
      );
      path.moveTo(c.dx, c.dy);
      path.quadraticBezierTo(ctrl1.dx, ctrl1.dy, tip.dx, tip.dy);
      path.quadraticBezierTo(ctrl2.dx, ctrl2.dy, c.dx, c.dy);
      canvas.drawPath(path, leafPaint);
    }

    final petalPaint = Paint()..color = petal;
    for (int i = 0; i < 9; i++) {
      final ang = i * math.pi / 4.5;
      final oval = Rect.fromCenter(
        center: Offset(
          c.dx + math.cos(ang) * r * 0.55,
          c.dy + math.sin(ang) * r * 0.55,
        ),
        width: r * 1.2,
        height: r * 0.88,
      );
      canvas.save();
      canvas.translate(oval.center.dx, oval.center.dy);
      canvas.rotate(ang);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: oval.width,
          height: oval.height,
        ),
        petalPaint,
      );
      canvas.restore();
    }

    canvas.drawCircle(c, r * 0.36, Paint()..color = center);
    canvas.drawCircle(c, r * 0.16, Paint()..color = inner);
  }

  @override
  bool shouldRepaint(covariant _PeonyPainter oldDelegate) =>
      oldDelegate.petal != petal ||
      oldDelegate.center != center ||
      oldDelegate.inner != inner ||
      oldDelegate.leaf != leaf;
}

class _LeafClusterPainter extends CustomPainter {
  _LeafClusterPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final c = Offset(size.width * 0.5, size.height * 0.55);
    for (int i = 0; i < 6; i++) {
      final ang = -1.2 + i * 0.45;
      final len = size.shortestSide * (0.36 + i * 0.035);
      final path = Path();
      final tip =
          Offset(c.dx + math.cos(ang) * len, c.dy + math.sin(ang) * len);
      path.moveTo(c.dx, c.dy);
      path.quadraticBezierTo(
        c.dx + math.cos(ang - 0.42) * len * 0.62,
        c.dy + math.sin(ang - 0.42) * len * 0.62,
        tip.dx,
        tip.dy,
      );
      path.quadraticBezierTo(
        c.dx + math.cos(ang + 0.42) * len * 0.62,
        c.dy + math.sin(ang + 0.42) * len * 0.62,
        c.dx,
        c.dy,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LeafClusterPainter oldDelegate) =>
      oldDelegate.color != color;
}