import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/app_effect.dart';
import '../core/app_effect_controller.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';

/// نقاش اختصاصی هر کارت جلوه — هر یک از ۱۰ جلوه رنگ و پترن کاملاً متفاوت دارد
class EffectCardVisualPainter extends CustomPainter {
  const EffectCardVisualPainter({
    required this.effectId,
    required this.primary,
    required this.secondary,
    this.isDark = true,
  });

  final String effectId;
  final Color primary;
  final Color secondary;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final norm = AppEffect.normalizeId(effectId);
    final rect = Offset.zero & size;

    if (norm == AppEffect.none) {
      _paintNone(canvas, size);
      return;
    }

    // پس‌زمینه گرادینت شعاعی با رنگ اختصاصی هر افکت
    final bg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.35, -0.3),
        radius: 1.15,
        colors: [
          primary.withValues(alpha: isDark ? 0.24 : 0.18),
          secondary.withValues(alpha: isDark ? 0.14 : 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.62, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    switch (norm) {
      case AppEffect.gold:
        _paintRoseGoldDust(canvas, size);
        break;
      case AppEffect.lavender:
        _paintLavenderGlassHearts(canvas, size);
        break;
      case AppEffect.rose:
        _paintRoseRain(canvas, size);
        break;
      case AppEffect.champagne:
        _paintChampagneSparkles(canvas, size);
        break;
      case AppEffect.midnight:
        _paintMidnightStars(canvas, size);
        break;
      case AppEffect.mistyRose:
        _paintMistyRose(canvas, size);
        break;
      case AppEffect.oliveGrove:
        _paintOliveGrove(canvas, size);
        break;
      case AppEffect.candlelight:
        _paintCandlelight(canvas, size);
        break;
      case AppEffect.midnightOrchid:
        _paintMidnightOrchid(canvas, size);
        break;
      case AppEffect.pearlSand:
        _paintPearlSand(canvas, size);
        break;
      default:
        break;
    }
  }

  void _paintNone(Canvas canvas, Size size) {
    final p = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (double i = -size.height; i < size.width + size.height; i += 28) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), p);
    }
  }

  // ۱. ذرات رزگلد (#DCA3A3 / #E8B4B8) — ذره‌های ریز پخش رزگلد
  void _paintRoseGoldDust(Canvas canvas, Size size) {
    final rnd = math.Random(101);
    for (var i = 0; i < 26; i++) {
      final x = size.width * (0.12 + rnd.nextDouble() * 0.80);
      final y = size.height * (0.12 + rnd.nextDouble() * 0.76);
      final r = 1.2 + rnd.nextDouble() * 2.4;
      final c = i.isEven ? const Color(0xFFDCA3A3) : const Color(0xFFE8B4B8);
      canvas.drawCircle(
        Offset(x, y),
        r * 2.0,
        Paint()..color = c.withValues(alpha: 0.16),
      );
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = c.withValues(alpha: 0.58),
      );
    }
  }

  // ۲. قلب لوندر شیشه‌ای (#C9B6E4 / #E8DDF5) — قلب‌های بلور بنفش شیشه‌ای
  void _paintLavenderGlassHearts(Canvas canvas, Size size) {
    final halo = Paint()
      ..color = const Color(0xFFE8DDF5).withValues(alpha: isDark ? 0.22 : 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.36), 16, halo);
    canvas.drawCircle(Offset(size.width * 0.34, size.height * 0.52), 11, halo);

    _drawHeartSoft(
      canvas,
      Offset(size.width * 0.68, size.height * 0.36),
      15,
      Paint()..color = const Color(0xFFC9B6E4).withValues(alpha: 0.55),
    );
    _drawHeartSoft(
      canvas,
      Offset(size.width * 0.34, size.height * 0.52),
      10,
      Paint()..color = const Color(0xFFE8DDF5).withValues(alpha: 0.48),
    );
  }

  // ۳. باران رز (#F8B8C0 / #FFD6DE) — قلب‌های صورتی ریزان
  void _paintRoseRain(Canvas canvas, Size size) {
    final p1 = Paint()..color = const Color(0xFFF8B8C0).withValues(alpha: 0.52);
    final p2 = Paint()..color = const Color(0xFFFFD6DE).withValues(alpha: 0.45);
    _drawHeartSoft(canvas, Offset(size.width * 0.72, size.height * 0.28), 13, p1);
    _drawHeartSoft(canvas, Offset(size.width * 0.52, size.height * 0.48), 10, p2);
    _drawHeartSoft(canvas, Offset(size.width * 0.28, size.height * 0.34), 9, p1);
    _drawHeartSoft(canvas, Offset(size.width * 0.78, size.height * 0.62), 8, p2);
  }

  // ۴. شامپاینی و درخشش (#D4AF37 / #F7E7CE) — جرقه‌های چهارپر طلایی شامپاین
  void _paintChampagneSparkles(Canvas canvas, Size size) {
    const gold = Color(0xFFD4AF37);
    const champagne = Color(0xFFF7E7CE);
    final pts = <List<double>>[
      [0.70, 0.30, 8.0],
      [0.45, 0.46, 6.0],
      [0.80, 0.58, 5.0],
      [0.26, 0.32, 5.5],
    ];
    for (final pt in pts) {
      final cx = size.width * pt[0];
      final cy = size.height * pt[1];
      final arm = pt[2];
      final sp = Paint()
        ..color = gold.withValues(alpha: 0.70)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx - arm, cy), Offset(cx + arm, cy), sp);
      canvas.drawLine(Offset(cx, cy - arm), Offset(cx, cy + arm), sp);
      canvas.drawCircle(
        Offset(cx, cy),
        2.0,
        Paint()..color = champagne.withValues(alpha: 0.90),
      );
    }
  }

  // ۵. شب آبی ستاره‌ای (#1A2A4A / #4A7C9B) — آسمان سرمه‌ای با ستاره‌های سفید
  void _paintMidnightStars(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.38),
      26,
      Paint()
        ..color = const Color(0xFF1A2A4A).withValues(alpha: isDark ? 0.55 : 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    final star = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (final pt in const [
      [0.72, 0.26, 2.2],
      [0.54, 0.38, 1.8],
      [0.80, 0.50, 1.5],
      [0.32, 0.30, 1.7],
      [0.40, 0.58, 1.4],
    ]) {
      final cx = size.width * pt[0];
      final cy = size.height * pt[1];
      canvas.drawCircle(Offset(cx, cy), pt[2], star);
    }
  }

  // ۶. رز مه‌آلود (#E8C4C4 / #F5E0E0) — ابرهای مه‌آلود صورتی غبار
  void _paintMistyRose(Canvas canvas, Size size) {
    final mist = Paint()
      ..color = const Color(0xFFE8C4C4).withValues(alpha: isDark ? 0.28 : 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.64, size.height * 0.34),
        width: 48,
        height: 20,
      ),
      mist,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.40, size.height * 0.54),
        width: 42,
        height: 18,
      ),
      mist,
    );
  }

  // ۷. بیشه زیتون (#6B8E5A / #8FA68E) — شاخه و برگ‌های زیتونی
  void _paintOliveGrove(Canvas canvas, Size size) {
    final leaf = Paint()..color = const Color(0xFF6B8E5A).withValues(alpha: 0.45);
    final stem = Paint()
      ..color = const Color(0xFF6B8E5A).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final p = Path()
      ..moveTo(size.width * 0.22, size.height * 0.66)
      ..cubicTo(
        size.width * 0.42,
        size.height * 0.42,
        size.width * 0.62,
        size.height * 0.38,
        size.width * 0.82,
        size.height * 0.26,
      );
    canvas.drawPath(p, stem);
    _watercolorBlob(canvas, Offset(size.width * 0.46, size.height * 0.44), 10, 4.5, 0.55, leaf);
    _watercolorBlob(canvas, Offset(size.width * 0.64, size.height * 0.35), 10, 4.5, -0.45, leaf);
    _watercolorBlob(canvas, Offset(size.width * 0.74, size.height * 0.44), 8, 3.8, 0.35, leaf);
  }

  // ۸. نور شمع (#FF9A3C / #FFC857) — شعله گرم شمع و هاله کهربایی
  void _paintCandlelight(Canvas canvas, Size size) {
    final cx = size.width * 0.68;
    final cy = size.height * 0.48;
    canvas.drawCircle(
      Offset(cx, cy - 8),
      20,
      Paint()
        ..color = const Color(0xFFFF9A3C).withValues(alpha: 0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    final flame = Path()
      ..moveTo(cx, cy)
      ..quadraticBezierTo(cx - 7, cy - 8, cx, cy - 20)
      ..quadraticBezierTo(cx + 7, cy - 8, cx, cy)
      ..close();
    canvas.drawPath(
      flame,
      Paint()..color = const Color(0xFFFF9A3C).withValues(alpha: 0.72),
    );
    final core = Path()
      ..moveTo(cx, cy - 2)
      ..quadraticBezierTo(cx - 3.5, cy - 7, cx, cy - 14)
      ..quadraticBezierTo(cx + 3.5, cy - 7, cx, cy - 2)
      ..close();
    canvas.drawPath(
      core,
      Paint()..color = const Color(0xFFFFC857).withValues(alpha: 0.90),
    );
  }

  // ۹. ارکیده نیمه‌شب (#2D1B4E / #8E7CC3) — گل ۵پر ارکیده روی هاله بنفش تیره
  void _paintMidnightOrchid(Canvas canvas, Size size) {
    final cx = size.width * 0.68;
    final cy = size.height * 0.38;
    canvas.drawCircle(
      Offset(cx, cy),
      22,
      Paint()
        ..color = const Color(0xFF2D1B4E).withValues(alpha: isDark ? 0.55 : 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    final petal = Paint()..color = const Color(0xFF8E7CC3).withValues(alpha: 0.52);
    canvas.save();
    canvas.translate(cx, cy);
    for (var i = 0; i < 5; i++) {
      canvas.save();
      canvas.rotate(i * (math.pi * 2 / 5));
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -6), width: 6.5, height: 10),
        petal,
      );
      canvas.restore();
    }
    canvas.drawCircle(
      Offset.zero,
      2.2,
      Paint()..color = Colors.white.withValues(alpha: 0.80),
    );
    canvas.restore();
  }

  // ۱۰. شب مرواریدی (#F5F5F0 / #D4CFC4) — گوی‌های مرواریدی صدفی
  void _paintPearlSand(Canvas canvas, Size size) {
    for (final o in const [
      [0.68, 0.36, 9.0],
      [0.44, 0.52, 6.0],
      [0.78, 0.58, 4.5],
    ]) {
      final cx = size.width * o[0];
      final cy = size.height * o[1];
      final r = o[2];
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = const Color(0xFFF5F5F0).withValues(alpha: isDark ? 0.38 : 0.65),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = const Color(0xFFD4CFC4).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      canvas.drawCircle(
        Offset(cx - r * 0.3, cy - r * 0.3),
        r * 0.26,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }
  }

  void _watercolorBlob(
    Canvas canvas,
    Offset c,
    double rx,
    double ry,
    double angle,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final r = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);
    canvas.drawOval(r, paint);
    canvas.drawOval(
      r.deflate(rx * 0.35),
      // ignore: deprecated_member_use
      paint..color = paint.color.withValues(alpha: paint.color.opacity * 0.6),
    );
    canvas.restore();
  }

  void _drawHeartSoft(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final w = size;
    final h = size;
    final x = center.dx;
    final y = center.dy - h * 0.3;
    path.moveTo(x, y + h * 0.35);
    path.cubicTo(x - w * 0.55, y - h * 0.3, x - w * 0.55, y + h * 0.3, x, y + h * 0.75);
    path.cubicTo(x + w * 0.55, y + h * 0.3, x + w * 0.55, y - h * 0.3, x, y + h * 0.35);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant EffectCardVisualPainter oldDelegate) =>
      oldDelegate.effectId != effectId ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.isDark != isDark;
}

/// آیکون افکت به همراه الگوی بصری مینیاتوری در پس‌زمینه
class EffectPatternIcon extends StatelessWidget {
  const EffectPatternIcon({
    super.key,
    required this.effect,
    this.size = 42,
    this.iconSize = 20,
    this.borderRadius = 13,
  });

  final AppEffect effect;
  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTok.isDark(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: effect.isNone
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    effect.primary.withValues(alpha: isDark ? 0.32 : 0.24),
                    effect.secondary.withValues(alpha: isDark ? 0.22 : 0.16),
                  ],
                ),
          color: effect.isNone ? AppTok.cardSoft(context) : null,
          border: Border.all(
            color: effect.isNone
                ? AppTok.border(context)
                : effect.primary.withValues(alpha: 0.42),
            width: 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!effect.isNone)
              CustomPaint(
                painter: EffectCardVisualPainter(
                  effectId: effect.id,
                  primary: effect.primary,
                  secondary: effect.secondary,
                  isDark: isDark,
                ),
              ),
            Center(
              child: Icon(
                effect.icon,
                color: effect.isNone
                    ? AppTok.textSoft(context)
                    : (isDark ? Colors.white.withValues(alpha: 0.94) : effect.primary),
                size: iconSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// کارت تک‌افکت با نمایش بصری زنده، پس‌زمینه غنی و متن خوانا
class EffectCard extends StatelessWidget {
  const EffectCard({
    super.key,
    required this.effect,
    required this.isSelected,
    required this.onTap,
  });

  final AppEffect effect;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTok.isDark(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isSelected
                ? effect.primary.withValues(alpha: isDark ? 0.18 : 0.12)
                : AppTok.card(context).withValues(alpha: isDark ? 0.96 : 0.98),
            border: Border.all(
              color: isSelected
                  ? effect.primary.withValues(alpha: 0.70)
                  : effect.primary.withValues(alpha: isDark ? 0.26 : 0.22),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? effect.primary.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: isDark ? 0.10 : 0.04),
                blurRadius: isSelected ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: EffectCardVisualPainter(
                      effectId: effect.id,
                      primary: effect.primary,
                      secondary: effect.secondary,
                      isDark: isDark,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 62,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          (isDark ? const Color(0xFF13121C) : Colors.white)
                              .withValues(alpha: 0.80),
                          (isDark ? const Color(0xFF13121C) : Colors.white)
                              .withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          EffectPatternIcon(
                            effect: effect,
                            size: 36,
                            iconSize: 18,
                            borderRadius: 11,
                          ),
                          const Spacer(),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: effect.primary,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        AppLang.tr(effect.nameKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTok.text(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLang.tr(effect.subtitleKey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTok.textSoft(context),
                          fontSize: 10.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// شبکه نمایشی ۱۰ جلوه بصری + بدون جلوه (مجموعاً ۱۱ مورد)
class EffectGrid extends StatelessWidget {
  const EffectGrid({
    super.key,
    this.selectedEffectId,
    this.onSelect,
    this.physics = const NeverScrollableScrollPhysics(),
    this.shrinkWrap = true,
  });

  final String? selectedEffectId;
  final ValueChanged<AppEffect>? onSelect;
  final ScrollPhysics physics;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    const all = AppEffect.all;
    final currentId = selectedEffectId ?? AppEffectController.I.effectId;
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: all.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, i) {
        final eff = all[i];
        final isSelected = currentId == eff.id;
        return EffectCard(
          effect: eff,
          isSelected: isSelected,
          onTap: () {
            if (onSelect != null) {
              onSelect!(eff);
            } else {
              AppEffectController.I.setEffect(eff.id);
            }
          },
        );
      },
    );
  }
}
