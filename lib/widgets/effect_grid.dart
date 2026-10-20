import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/app_effect.dart';
import '../core/app_effect_controller.dart';
import '../core/app_effects.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';

/// نقاش اختصاصی و متحرک هر کارت جلوه — با پارامتر [progress] (۰ تا ۱)
/// تا هر کارت در پنجرهٔ «انتخاب جلوه» به‌صورت زنده و متحرک پیش‌نمایش واقعی خودش را نشان دهد.
class EffectCardVisualPainter extends CustomPainter {
  const EffectCardVisualPainter({
    required this.effectId,
    required this.primary,
    required this.secondary,
    this.isDark = true,
    this.progress = 0.0,
  });

  final String effectId;
  final Color primary;
  final Color secondary;
  final bool isDark;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final norm = AppEffect.normalizeId(effectId);
    final rect = Offset.zero & size;

    if (norm == AppEffect.none) {
      _paintNone(canvas, size);
      return;
    }

    final t = progress * math.pi * 2;
    final cx = 0.35 + 0.12 * math.sin(t);
    final cy = -0.28 + 0.10 * math.cos(t);

    // پس‌زمینه گرادینت شعاعی زنده با رنگ اختصاصی هر افکت
    final bg = Paint()
      ..shader = RadialGradient(
        center: Alignment(cx, cy),
        radius: 1.18,
        colors: [
          primary.withValues(alpha: isDark ? 0.28 : 0.20),
          secondary.withValues(alpha: isDark ? 0.16 : 0.11),
          Colors.transparent,
        ],
        stops: const [0.0, 0.64, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    switch (norm) {
      case AppEffect.gold:
        _paintRoseGoldDust(canvas, size, t);
        break;
      case AppEffect.lavender:
        _paintLavenderGlassHearts(canvas, size, t);
        break;
      case AppEffect.rose:
        _paintRoseRain(canvas, size, t);
        break;
      case AppEffect.champagne:
        _paintChampagneSparkles(canvas, size, t);
        break;
      case AppEffect.midnight:
        _paintMidnightStars(canvas, size, t);
        break;
      case AppEffect.mistyRose:
        _paintMistyRose(canvas, size, t);
        break;
      case AppEffect.oliveGrove:
        _paintOliveGrove(canvas, size, t);
        break;
      case AppEffect.candlelight:
        _paintCandlelight(canvas, size, t);
        break;
      case AppEffect.midnightOrchid:
        _paintMidnightOrchid(canvas, size, t);
        break;
      case AppEffect.pearlSand:
        _paintPearlSand(canvas, size, t);
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

  // ۱. ذرات رزگلد (#DCA3A3 / #E8B4B8) — ذره‌های ریز متالیک شناور و چشمک‌زن
  void _paintRoseGoldDust(Canvas canvas, Size size, double t) {
    final rnd = math.Random(101);
    for (var i = 0; i < 28; i++) {
      final bx = rnd.nextDouble();
      final by = rnd.nextDouble();
      final speed = 0.6 + (i % 3) * 0.4;
      final phase = rnd.nextDouble() * math.pi * 2;
      final x = size.width * ((bx + 0.06 * math.sin(t * speed + phase)) % 1.0);
      final y = size.height *
          ((by - progress * (0.35 + (i % 4) * 0.15)) % 1.0 + 1.0) %
          size.height;
      final tw = 0.45 + 0.55 * ((math.sin(t * 2 + phase) + 1) / 2);
      final r = (1.3 + rnd.nextDouble() * 2.4) * (0.75 + 0.4 * tw);
      final c = i.isEven ? const Color(0xFFDCA3A3) : const Color(0xFFE8B4B8);
      canvas.drawCircle(
        Offset(x, y),
        r * 2.3,
        Paint()..color = c.withValues(alpha: (0.20 * tw).clamp(0.05, 0.30)),
      );
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = c.withValues(alpha: (0.45 + 0.45 * tw).clamp(0.25, 0.92)),
      );
    }
  }

  // ۲. قلب لوندر شیشه‌ای (#C9B6E4 / #E8DDF5) — قلب‌های بلور بنفش شیشه‌ای شناور رو به بالا
  void _paintLavenderGlassHearts(Canvas canvas, Size size, double t) {
    const items = <List<double>>[
      [0.68, 0.72, 16.0, 0.0],
      [0.32, 0.45, 13.0, 1.4],
      [0.52, 0.25, 11.0, 2.8],
      [0.22, 0.78, 10.0, 4.1],
      [0.78, 0.38, 12.0, 5.2],
    ];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final phase = item[3];
      final flow = (item[1] - progress + i * 0.19) % 1.0;
      final normY = flow < 0 ? flow + 1.0 : flow;
      final y = size.height * (0.10 + normY * 0.78);
      final x = size.width * item[0] + math.sin(t + phase) * 8.0;
      final fade = math.sin(normY * math.pi).clamp(0.25, 1.0);
      final hs = item[2];

      final halo = Paint()
        ..color = const Color(0xFFE8DDF5)
            .withValues(alpha: (isDark ? 0.28 : 0.34) * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
      canvas.drawCircle(Offset(x, y), hs * 0.95, halo);

      _drawHeartSoft(
        canvas,
        Offset(x, y),
        hs,
        Paint()
          ..color = (i.isEven
                  ? const Color(0xFFC9B6E4)
                  : const Color(0xFFE8DDF5))
              .withValues(alpha: (0.68 * fade).clamp(0.22, 0.85)),
      );
    }
  }

  // ۳. باران رز (#F8B8C0 / #FFD6DE) — قلب‌های صورتی در حال بارش از بالا به پایین
  void _paintRoseRain(Canvas canvas, Size size, double t) {
    const items = <List<double>>[
      [0.74, 0.15, 14.0, 0.0],
      [0.50, 0.42, 12.0, 1.1],
      [0.26, 0.68, 13.0, 2.3],
      [0.80, 0.55, 10.0, 3.5],
      [0.38, 0.22, 11.0, 4.7],
      [0.62, 0.82, 9.5, 5.6],
    ];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final phase = item[3];
      final fall = (item[1] + progress + i * 0.14) % 1.0;
      final y = size.height * (0.08 + fall * 0.82);
      final x = size.width * item[0] + math.sin(t + phase) * 6.5;
      final fade = math.sin(fall * math.pi).clamp(0.28, 1.0);
      final c = i.isEven ? const Color(0xFFF8B8C0) : const Color(0xFFFFD6DE);
      _drawHeartSoft(
        canvas,
        Offset(x, y),
        item[2],
        Paint()..color = c.withValues(alpha: (0.72 * fade).clamp(0.25, 0.88)),
      );
    }
  }

  // ۴. شامپاینی و درخشش (#D4AF37 / #F7E7CE) — جرقه‌های چهارپر طلایی چشمک‌زن + حباب‌های شامپاین
  void _paintChampagneSparkles(Canvas canvas, Size size, double t) {
    const gold = Color(0xFFD4AF37);
    const champagne = Color(0xFFF7E7CE);

    // حباب‌های طلایی ظریف رو به بالا
    for (var i = 0; i < 6; i++) {
      final flow = (1.0 - ((progress + i * 0.17) % 1.0));
      final bx = size.width * (0.18 + i * 0.13) + math.sin(t + i) * 4;
      final by = size.height * (0.12 + flow * 0.75);
      canvas.drawCircle(
        Offset(bx, by),
        2.2 + (i % 2) * 1.2,
        Paint()
          ..color = champagne.withValues(alpha: 0.34)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    const pts = <List<double>>[
      [0.70, 0.28, 9.5, 0.0],
      [0.44, 0.46, 7.5, 1.6],
      [0.78, 0.56, 6.5, 3.1],
      [0.25, 0.32, 7.0, 4.4],
      [0.58, 0.66, 6.0, 2.2],
    ];
    for (final pt in pts) {
      final pulse = 0.45 + 0.55 * ((math.sin(t * 2 + pt[3]) + 1) / 2);
      final cx = size.width * pt[0];
      final cy = size.height * pt[1] + math.sin(t + pt[3]) * 3.0;
      final arm = pt[2] * (0.65 + 0.50 * pulse);
      final sp = Paint()
        ..color = gold.withValues(alpha: (0.45 + 0.48 * pulse).clamp(0.3, 0.95))
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx - arm, cy), Offset(cx + arm, cy), sp);
      canvas.drawLine(Offset(cx, cy - arm), Offset(cx, cy + arm), sp);
      final dArm = arm * 0.48;
      canvas.drawLine(
        Offset(cx - dArm, cy - dArm),
        Offset(cx + dArm, cy + dArm),
        sp..strokeWidth = 1.0,
      );
      canvas.drawLine(
        Offset(cx - dArm, cy + dArm),
        Offset(cx + dArm, cy - dArm),
        sp,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        2.2 * pulse,
        Paint()..color = champagne.withValues(alpha: 0.95),
      );
    }
  }

  // ۵. شب آبی ستاره‌ای (#1A2A4A / #4A7C9B) — آسمان سرمه‌ای با ستاره‌های سفید چشمک‌زن
  void _paintMidnightStars(Canvas canvas, Size size, double t) {
    canvas.drawCircle(
      Offset(
        size.width * (0.64 + 0.04 * math.sin(t)),
        size.height * (0.38 + 0.04 * math.cos(t)),
      ),
      30,
      Paint()
        ..color = const Color(0xFF1A2A4A).withValues(alpha: isDark ? 0.62 : 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    const stars = <List<double>>[
      [0.72, 0.24, 2.4, 0.0],
      [0.52, 0.36, 2.0, 1.2],
      [0.80, 0.50, 1.8, 2.5],
      [0.30, 0.28, 2.1, 3.7],
      [0.38, 0.56, 1.7, 4.9],
      [0.64, 0.62, 2.2, 0.8],
      [0.20, 0.46, 1.5, 2.9],
    ];
    for (final st in stars) {
      final tw = 0.30 + 0.70 * ((math.sin(t * 2 + st[3]) + 1) / 2);
      final cx = size.width * st[0];
      final cy = size.height * st[1];
      final r = st[2] * (0.75 + 0.45 * tw);
      final starPaint = Paint()
        ..color = Colors.white.withValues(alpha: (0.35 + 0.62 * tw).clamp(0.25, 0.98));
      canvas.drawCircle(Offset(cx, cy), r, starPaint);
      if (tw > 0.62) {
        final arm = r * 2.6;
        final linePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.55 * tw)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx - arm, cy), Offset(cx + arm, cy), linePaint);
        canvas.drawLine(Offset(cx, cy - arm), Offset(cx, cy + arm), linePaint);
      }
    }
  }

  // ۶. رز مه‌آلود (#E8C4C4 / #F5E0E0) — ابرهای مه‌آلود صورتی غبار در حال حرکت + گلبرگ نرم
  void _paintMistyRose(Canvas canvas, Size size, double t) {
    final mist1 = Paint()
      ..color = const Color(0xFFE8C4C4).withValues(alpha: isDark ? 0.32 : 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11);
    final mist2 = Paint()
      ..color = const Color(0xFFF5E0E0).withValues(alpha: isDark ? 0.24 : 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.width * (0.62 + 0.08 * math.sin(t)),
          size.height * 0.34,
        ),
        width: 58,
        height: 24,
      ),
      mist1,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.width * (0.38 - 0.08 * math.sin(t * 0.8)),
          size.height * 0.54,
        ),
        width: 52,
        height: 22,
      ),
      mist2,
    );

    // گلبرگ‌های شناور در مه
    for (var i = 0; i < 4; i++) {
      final flow = (progress + i * 0.25) % 1.0;
      final px = size.width * (0.25 + i * 0.18) + math.sin(t + i) * 6;
      final py = size.height * (0.16 + flow * 0.62);
      _watercolorBlob(
        canvas,
        Offset(px, py),
        6.5,
        3.6,
        t * 0.5 + i,
        Paint()..color = const Color(0xFFE8C4C4).withValues(alpha: 0.45),
      );
    }
  }

  // ۷. بیشه زیتون (#6B8E5A / #8FA68E) — شاخه زیتون در حال تکان خوردن در باد + برگ‌های شناور
  void _paintOliveGrove(Canvas canvas, Size size, double t) {
    final sway = math.sin(t) * 4.5;
    final leaf = Paint()..color = const Color(0xFF6B8E5A).withValues(alpha: 0.58);
    final leafSoft = Paint()..color = const Color(0xFF8FA68E).withValues(alpha: 0.52);
    final stem = Paint()
      ..color = const Color(0xFF6B8E5A).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final p = Path()
      ..moveTo(size.width * 0.20, size.height * 0.66)
      ..cubicTo(
        size.width * 0.42,
        size.height * 0.42 + sway * 0.5,
        size.width * 0.62,
        size.height * 0.38 - sway * 0.5,
        size.width * 0.82,
        size.height * 0.26 + sway,
      );
    canvas.drawPath(p, stem);

    final tilt = math.sin(t) * 0.16;
    _watercolorBlob(
      canvas,
      Offset(size.width * 0.46, size.height * 0.44 + sway * 0.3),
      10.5,
      4.8,
      0.55 + tilt,
      leaf,
    );
    _watercolorBlob(
      canvas,
      Offset(size.width * 0.64, size.height * 0.35 - sway * 0.2),
      10.5,
      4.8,
      -0.45 + tilt,
      leaf,
    );
    _watercolorBlob(
      canvas,
      Offset(size.width * 0.74, size.height * 0.44 + sway * 0.5),
      8.5,
      4.0,
      0.35 - tilt,
      leafSoft,
    );

    // دو برگ زیتون در حال رقص و فرود
    for (var i = 0; i < 2; i++) {
      final fall = (progress + i * 0.5) % 1.0;
      final lx = size.width * (0.30 + i * 0.38) + math.sin(t + i * 2) * 8;
      final ly = size.height * (0.14 + fall * 0.66);
      _watercolorBlob(canvas, Offset(lx, ly), 7.5, 3.4, t + i, leafSoft);
    }
  }

  // ۸. نور شمع (#FF9A3C / #FFC857) — فلیکر زندهٔ شعله‌های شمع و هاله کهربایی گرم
  void _paintCandlelight(Canvas canvas, Size size, double t) {
    const candles = <List<double>>[
      [0.68, 0.54, 1.0, 0.0],
      [0.36, 0.62, 0.76, 1.9],
    ];
    for (final c in candles) {
      final cx = size.width * c[0];
      final cy = size.height * c[1];
      final sc = c[2];
      final phase = c[3];
      final flicker = 0.90 +
          0.16 * math.sin(t * 3 + phase) +
          0.08 * math.cos(t * 5 + phase);
      final tipX = cx + math.sin(t * 2 + phase) * 2.8 * sc;
      final h = 22.0 * sc * flicker;
      final w = 7.5 * sc;

      canvas.drawCircle(
        Offset(cx, cy - h * 0.45),
        22 * sc * flicker,
        Paint()
          ..color = const Color(0xFFFF9A3C).withValues(alpha: 0.26 * flicker)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      final flame = Path()
        ..moveTo(cx, cy)
        ..quadraticBezierTo(cx - w, cy - h * 0.38, tipX, cy - h)
        ..quadraticBezierTo(cx + w, cy - h * 0.38, cx, cy)
        ..close();
      canvas.drawPath(
        flame,
        Paint()..color = const Color(0xFFFF9A3C).withValues(alpha: 0.82),
      );
      final core = Path()
        ..moveTo(cx, cy - 2)
        ..quadraticBezierTo(
          cx - w * 0.5,
          cy - h * 0.35,
          tipX,
          cy - h * 0.70,
        )
        ..quadraticBezierTo(
          cx + w * 0.5,
          cy - h * 0.35,
          cx,
          cy - 2,
        )
        ..close();
      canvas.drawPath(
        core,
        Paint()..color = const Color(0xFFFFC857).withValues(alpha: 0.95),
      );
    }
  }

  // ۹. ارکیده نیمه‌شب (#2D1B4E / #8E7CC3) — گل‌های ۵پر ارکیده چرخان روی هاله بنفش تیره
  void _paintMidnightOrchid(Canvas canvas, Size size, double t) {
    final cx = size.width * 0.66;
    final cy = size.height * 0.38 + math.sin(t) * 3.0;
    canvas.drawCircle(
      Offset(cx, cy),
      26,
      Paint()
        ..color = const Color(0xFF2D1B4E).withValues(alpha: isDark ? 0.62 : 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    void drawOrchid(Offset center, double scale, double rot, double alpha) {
      final petal = Paint()
        ..color = const Color(0xFF8E7CC3).withValues(alpha: alpha);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rot);
      for (var i = 0; i < 5; i++) {
        canvas.save();
        canvas.rotate(i * (math.pi * 2 / 5));
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, -6.5 * scale),
            width: 6.8 * scale,
            height: 10.5 * scale,
          ),
          petal,
        );
        canvas.restore();
      }
      canvas.drawCircle(
        Offset.zero,
        2.3 * scale,
        Paint()..color = Colors.white.withValues(alpha: (alpha + 0.25).clamp(0.3, 0.92)),
      );
      canvas.restore();
    }

    drawOrchid(Offset(cx, cy), 1.05, t * 0.5, 0.62);
    drawOrchid(
      Offset(
        size.width * 0.32 + math.cos(t) * 4,
        size.height * 0.52 + math.sin(t) * 4,
      ),
      0.72,
      -t * 0.4,
      0.46,
    );
  }

  // ۱۰. شب مرواریدی (#F5F5F0 / #D4CFC4) — گوی‌های مرواریدی صدفی شناور و درخشان
  void _paintPearlSand(Canvas canvas, Size size, double t) {
    const orbs = <List<double>>[
      [0.68, 0.36, 9.5, 0.0],
      [0.40, 0.50, 7.0, 1.5],
      [0.78, 0.58, 5.2, 3.0],
      [0.26, 0.32, 5.8, 4.2],
    ];
    for (final o in orbs) {
      final pulse = 0.85 + 0.15 * math.sin(t * 2 + o[3]);
      final cx = size.width * o[0] + math.sin(t + o[3]) * 4.5;
      final cy = size.height * o[1] + math.cos(t + o[3]) * 3.5;
      final r = o[2] * pulse;
      canvas.drawCircle(
        Offset(cx, cy),
        r * 1.5,
        Paint()
          ..color = const Color(0xFFD4CFC4).withValues(alpha: 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = const Color(0xFFF5F5F0).withValues(alpha: isDark ? 0.48 : 0.72),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = const Color(0xFFD4CFC4).withValues(alpha: 0.62)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      canvas.drawCircle(
        Offset(cx - r * 0.3, cy - r * 0.3),
        r * 0.28,
        Paint()..color = Colors.white.withValues(alpha: 0.92),
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
    final r = size * 0.55;
    final x = center.dx;
    final y = center.dy;
    path.moveTo(x, y + r * 0.85);
    path.cubicTo(
      x - r * 1.35,
      y + r * 0.10,
      x - r * 0.95,
      y - r * 0.95,
      x,
      y - r * 0.28,
    );
    path.cubicTo(
      x + r * 0.95,
      y - r * 0.95,
      x + r * 1.35,
      y + r * 0.10,
      x,
      y + r * 0.85,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant EffectCardVisualPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.effectId != effectId ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.isDark != isDark;
}

/// ویجت پس‌زمینهٔ متحرک برای هر کارت جلوه (در پنجرهٔ انتخاب جلوه و صفحهٔ موسیقی و جلوه‌ها)
class AnimatedEffectCardBackground extends StatefulWidget {
  const AnimatedEffectCardBackground({
    super.key,
    required this.effect,
    required this.isDark,
  });

  final AppEffect effect;
  final bool isDark;

  @override
  State<AnimatedEffectCardBackground> createState() =>
      _AnimatedEffectCardBackgroundState();
}

class _AnimatedEffectCardBackgroundState
    extends State<AnimatedEffectCardBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.effect.isNone) {
      return CustomPaint(
        painter: EffectCardVisualPainter(
          effectId: widget.effect.id,
          primary: widget.effect.primary,
          secondary: widget.effect.secondary,
          isDark: widget.isDark,
        ),
      );
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          painter: EffectCardVisualPainter(
            effectId: widget.effect.id,
            primary: widget.effect.primary,
            secondary: widget.effect.secondary,
            isDark: widget.isDark,
            progress: _ctrl.value,
          ),
        );
      },
    );
  }
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

/// کارت تک‌افکت با انیمیشن زنده و پیش‌نمایش متحرک داخل خود کارت
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
                  child: AnimatedEffectCardBackground(
                    effect: effect,
                    isDark: isDark,
                  ),
                ),
                if (!effect.isNone)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AppEffectOverlay(
                        effectId: effect.id,
                        intensity: 1.05,
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
