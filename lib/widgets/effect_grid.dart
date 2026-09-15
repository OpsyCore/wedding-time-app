import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/app_effect.dart';
import '../core/app_effect_controller.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';

/// نقاش پیش‌نمایش غنی و اختصاصی برای هر یک از ۱۰ افکت + بدون افکت
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

    // ── پس‌زمینه گرادیانتی پرنور و متناسب با افکت ──
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.3, -0.4),
        radius: 1.2,
        colors: [
          primary.withValues(alpha: isDark ? 0.35 : 0.28),
          secondary.withValues(alpha: isDark ? 0.18 : 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    switch (norm) {
      case AppEffect.blushRose:
        _paintBlushRose(canvas, size);
        break;
      case AppEffect.sageGarden:
        _paintSageGarden(canvas, size);
        break;
      case AppEffect.champagneGold:
        _paintChampagneGold(canvas, size);
        break;
      case AppEffect.lavenderDusk:
        _paintLavenderDusk(canvas, size);
        break;
      case AppEffect.oceanMist:
        _paintOceanMist(canvas, size);
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
        _paintGeneric(canvas, size);
        break;
    }
  }

  // ── ۱. بدون جلوه (None) ──
  void _paintNone(Canvas canvas, Size size) {
    final borderP = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.08 : 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    // خطوط مورب ظریف
    for (double i = -size.height; i < size.width + size.height; i += 24) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        borderP,
      );
    }
  }

  // ── ۲. رز بلاش (Blush Rose): قلب‌های رمانتیک و گلبرگ‌های صورتی ──
  void _paintBlushRose(Canvas canvas, Size size) {
    final pFill = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.65 : 0.55)
      ..style = PaintingStyle.fill;
    final pStroke = Paint()
      ..color = secondary.withValues(alpha: isDark ? 0.85 : 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // قلب بزرگ ملایم
    _drawHeart(canvas, Offset(size.width * 0.72, size.height * 0.35), 18, pFill);
    _drawHeart(canvas, Offset(size.width * 0.32, size.height * 0.28), 11, pStroke);
    _drawHeart(canvas, Offset(size.width * 0.82, size.height * 0.75), 9, pFill);

    // ذرات درخشان صورتی
    canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.45), 3.5, pFill);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.65), 2.5, pStroke);
  }

  // ── ۳. باغ سیج (Sage Garden): برگ‌های زیتونی-سبز و پیچک گیاهی ──
  void _paintSageGarden(Canvas canvas, Size size) {
    final pLeaf = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.75 : 0.65)
      ..style = PaintingStyle.fill;
    final pSec = Paint()
      ..color = secondary.withValues(alpha: isDark ? 0.85 : 0.75)
      ..style = PaintingStyle.fill;

    // برگ‌های اکالیپتوس در زاویه‌های مختلف
    _drawLeaf(canvas, Offset(size.width * 0.72, size.height * 0.32), 16, 8, math.pi / 4, pLeaf);
    _drawLeaf(canvas, Offset(size.width * 0.82, size.height * 0.45), 12, 6, -math.pi / 6, pSec);
    _drawLeaf(canvas, Offset(size.width * 0.35, size.height * 0.25), 14, 7, math.pi / 3, pSec);
    _drawLeaf(canvas, Offset(size.width * 0.25, size.height * 0.60), 11, 5, -math.pi / 4, pLeaf);

    // ساقه نازک
    final stemP = Paint()
      ..color = primary.withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.60, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.72, size.height * 0.38, size.width * 0.82, size.height * 0.25);
    canvas.drawPath(path, stemP);
  }

  // ── ۴. شامپاین طلایی (Champagne Gold): ستاره‌های چهارپر درخشان و پولک‌های طلایی ──
  void _paintChampagneGold(Canvas canvas, Size size) {
    final pGold = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.90 : 0.80)
      ..style = PaintingStyle.fill;
    final pGlow = Paint()
      ..color = secondary.withValues(alpha: isDark ? 0.80 : 0.70)
      ..style = PaintingStyle.fill;

    // ستاره‌های ۴ پر درخشان
    _drawStar4(canvas, Offset(size.width * 0.75, size.height * 0.32), 15, 4, pGold);
    _drawStar4(canvas, Offset(size.width * 0.32, size.height * 0.30), 10, 3, pGlow);
    _drawStar4(canvas, Offset(size.width * 0.55, size.height * 0.65), 8, 2.5, pGold);

    // حباب‌های شامپاین
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.60), 4.0, pGlow);
    canvas.drawCircle(Offset(size.width * 0.20, size.height * 0.55), 3.0, pGold);
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.18), 2.2, pGlow);
  }

  // ── ۵. غروب لوندر (Lavender Dusk): بوکه نورانی بنفش و گرد غبار شبانه ──
  void _paintLavenderDusk(Canvas canvas, Size size) {
    // بوکه‌های بزرگ محو
    final bokeh1 = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.45 : 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final bokeh2 = Paint()
      ..color = secondary.withValues(alpha: isDark ? 0.60 : 0.50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(Offset(size.width * 0.70, size.height * 0.35), 22, bokeh1);
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.45), 15, bokeh2);

    // ذرات روشن داخل بوکه
    final dotP = Paint()..color = secondary.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(size.width * 0.70, size.height * 0.35), 3.5, dotP);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.22), 2.2, dotP);
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.30), 2.5, dotP);
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.70), 3.0, dotP);
  }

  // ── ۶. مه اقیانوس (Ocean Mist): امواج آب، قطرات شبنم و حلقه‌های رپیل ──
  void _paintOceanMist(Canvas canvas, Size size) {
    final ringP = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.65 : 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final dropP = Paint()
      ..color = secondary.withValues(alpha: isDark ? 0.85 : 0.75)
      ..style = PaintingStyle.fill;

    // حلقه‌های موج آب
    canvas.drawCircle(Offset(size.width * 0.70, size.height * 0.35), 18, ringP);
    canvas.drawCircle(Offset(size.width * 0.70, size.height * 0.35), 9, ringP);
    canvas.drawCircle(Offset(size.width * 0.70, size.height * 0.35), 3.5, dropP);

    // قطرات آب در اطراف
    _drawDrop(canvas, Offset(size.width * 0.30, size.height * 0.30), 8, dropP);
    _drawDrop(canvas, Offset(size.width * 0.48, size.height * 0.60), 6, dropP);
  }

  // ── ۷. رز مه‌آلود (Misty Rose): گل رز و غبار صورتی ملایم ──
  void _paintMistyRose(Canvas canvas, Size size) {
    final pPetal = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.75 : 0.65)
      ..style = PaintingStyle.fill;
    final pCenter = Paint()
      ..color = secondary.withValues(alpha: isDark ? 0.90 : 0.80)
      ..style = PaintingStyle.fill;

    // گل ۵ پر کوچک در بالا راست
    _drawFlower5(canvas, Offset(size.width * 0.74, size.height * 0.34), 14, pPetal, pCenter);

    // گلبرگ‌های معلق
    _drawLeaf(canvas, Offset(size.width * 0.30, size.height * 0.28), 10, 5, math.pi / 4, pPetal);
    _drawLeaf(canvas, Offset(size.width * 0.52, size.height * 0.65), 8, 4, -math.pi / 3, pPetal);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.65), 3.0, pCenter);
  }

  // ── ۸. بیشهٔ زیتون (Olive Grove): شاخه زیتون با جفت‌برگ‌های گرم ──
  void _paintOliveGrove(Canvas canvas, Size size) {
    final pOlive = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.80 : 0.70)
      ..style = PaintingStyle.fill;
    final pLight = Paint()
      ..color = secondary.withValues(alpha: isDark ? 0.85 : 0.75)
      ..style = PaintingStyle.fill;

    // شاخه زیتون
    _drawLeaf(canvas, Offset(size.width * 0.68, size.height * 0.30), 14, 6, math.pi / 5, pOlive);
    _drawLeaf(canvas, Offset(size.width * 0.78, size.height * 0.38), 14, 6, -math.pi / 5, pOlive);
    _drawLeaf(canvas, Offset(size.width * 0.75, size.height * 0.20), 12, 5, 0, pLight);

    // زیتون‌های گرد
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.42), 4.2, pLight);
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.35), 3.5, pOlive);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.60), 3.0, pLight);
  }

  // ── ۹. نور شمع (Candlelight): شعله‌های گرم شمع و پرتوهای نورانی کهربایی ──
  void _paintCandlelight(Canvas canvas, Size size) {
    final pFlame = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.85 : 0.75)
      ..style = PaintingStyle.fill;
    final pGlow = Paint()
      ..color = secondary.withValues(alpha: isDark ? 0.95 : 0.85)
      ..style = PaintingStyle.fill;

    // شعله شمع قطره‌ای
    _drawFlame(canvas, Offset(size.width * 0.72, size.height * 0.35), 18, pFlame, pGlow);

    // جرقه‌های بالارونده
    _drawStar4(canvas, Offset(size.width * 0.35, size.height * 0.30), 9, 3, pGlow);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.18), 3.0, pGlow);
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.60), 2.5, pFlame);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.55), 2.0, pGlow);
  }

  // ── ۱۰. ارکیده نیمه‌شب (Midnight Orchid): آسمان پرستاره شب و صورت فلکی ارکیده ──
  void _paintMidnightOrchid(Canvas canvas, Size size) {
    final pStar = Paint()
      ..color = secondary.withValues(alpha: isDark ? 0.90 : 0.80)
      ..style = PaintingStyle.fill;
    final pOrchid = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.75 : 0.65)
      ..style = PaintingStyle.fill;

    // ستاره‌های شب
    _drawStar4(canvas, Offset(size.width * 0.75, size.height * 0.28), 14, 4, pStar);
    _drawStar4(canvas, Offset(size.width * 0.45, size.height * 0.45), 9, 2.5, pStar);
    _drawStar4(canvas, Offset(size.width * 0.28, size.height * 0.25), 11, 3, pOrchid);

    // هلال ماه ظریف
    final moonP = Paint()
      ..color = secondary.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width * 0.82, size.height * 0.55), radius: 8),
      -math.pi / 2,
      math.pi * 1.2,
      false,
      moonP,
    );

    canvas.drawCircle(Offset(size.width * 0.60, size.height * 0.22), 2.0, pStar);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.20), 1.8, pStar);
  }

  // ── ۱۱. ماسه مرواریدی (Pearl Sand): حلقه‌های مرواریدی و درخشش شن‌های طلایی ──
  void _paintPearlSand(Canvas canvas, Size size) {
    final pPearl = Paint()
      ..color = secondary.withValues(alpha: isDark ? 0.90 : 0.80)
      ..style = PaintingStyle.fill;
    final pRing = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.65 : 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    // مروارید درخشان با هاله
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.35), 14, pRing);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.35), 7, pPearl);

    // دانه‌های شن درخشان
    _drawStar4(canvas, Offset(size.width * 0.35, size.height * 0.30), 8, 2.5, pPearl);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.65), 3.2, pPearl);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.60), 2.5, pRing);
    canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.65), 2.0, pPearl);
  }

  void _paintGeneric(Canvas canvas, Size size) {
    final p = Paint()..color = primary.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.35), 12, p);
  }

  // ── Helper: رسم قلب ──
  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
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

  // ── Helper: رسم برگ ──
  void _drawLeaf(Canvas canvas, Offset center, double length, double width, double angle, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final rect = Rect.fromCenter(center: Offset.zero, width: length, height: width);
    canvas.drawOval(rect, paint);
    canvas.restore();
  }

  // ── Helper: رسم ستاره ۴ پر (✦) ──
  void _drawStar4(Canvas canvas, Offset center, double outerR, double innerR, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final r = i.isEven ? outerR : innerR;
      final a = i * math.pi / 4;
      final px = center.dx + r * math.cos(a);
      final py = center.dy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // ── Helper: رسم قطره آب ──
  void _drawDrop(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - radius * 1.3);
    path.quadraticBezierTo(center.dx + radius, center.dy, center.dx + radius, center.dy + radius * 0.6);
    path.arcToPoint(
      Offset(center.dx - radius, center.dy + radius * 0.6),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.quadraticBezierTo(center.dx - radius, center.dy, center.dx, center.dy - radius * 1.3);
    path.close();
    canvas.drawPath(path, paint);
  }

  // ── Helper: رسم گل ۵ پر ──
  void _drawFlower5(Canvas canvas, Offset center, double radius, Paint petalPaint, Paint centerPaint) {
    for (int i = 0; i < 5; i++) {
      final a = i * 2 * math.pi / 5;
      final px = center.dx + radius * 0.55 * math.cos(a);
      final py = center.dy + radius * 0.55 * math.sin(a);
      canvas.drawCircle(Offset(px, py), radius * 0.45, petalPaint);
    }
    canvas.drawCircle(center, radius * 0.35, centerPaint);
  }

  // ── Helper: رسم شعله شمع ──
  void _drawFlame(Canvas canvas, Offset center, double height, Paint outerPaint, Paint innerPaint) {
    final pathOuter = Path();
    pathOuter.moveTo(center.dx, center.dy - height * 0.6);
    pathOuter.quadraticBezierTo(center.dx + height * 0.45, center.dy, center.dx, center.dy + height * 0.5);
    pathOuter.quadraticBezierTo(center.dx - height * 0.45, center.dy, center.dx, center.dy - height * 0.6);
    pathOuter.close();
    canvas.drawPath(pathOuter, outerPaint);

    final pathInner = Path();
    final hInner = height * 0.55;
    pathInner.moveTo(center.dx, center.dy - hInner * 0.3);
    pathInner.quadraticBezierTo(center.dx + hInner * 0.35, center.dy + hInner * 0.1, center.dx, center.dy + hInner * 0.4);
    pathInner.quadraticBezierTo(center.dx - hInner * 0.35, center.dy + hInner * 0.1, center.dx, center.dy - hInner * 0.3);
    pathInner.close();
    canvas.drawPath(pathInner, innerPaint);
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
          color: effect.isNone
              ? AppTok.cardSoft(context)
              : effect.primary.withValues(alpha: isDark ? 0.28 : 0.20),
          border: Border.all(
            color: effect.isNone
                ? AppTok.border(context)
                : effect.primary.withValues(alpha: 0.45),
            width: 1.2,
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
                    : (isDark ? Colors.white : effect.primary),
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
                ? effect.primary.withValues(alpha: isDark ? 0.22 : 0.16)
                : AppTok.card(context).withValues(alpha: isDark ? 0.92 : 0.96),
            border: Border.all(
              color: isSelected
                  ? effect.primary
                  : AppTok.border(context).withValues(alpha: 0.6),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? effect.primary.withValues(alpha: isDark ? 0.28 : 0.18)
                    : Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                blurRadius: isSelected ? 16 : 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── لایه طراحی بصری پس‌زمینه کارت (نمایش نمونه جلوه) ──
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

                // ── لایه گرادیانت پایینی برای خوانایی ۱۰۰٪ متن‌ها ──
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 65,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          (isDark ? const Color(0xFF13121C) : Colors.white)
                              .withValues(alpha: 0.88),
                          (isDark ? const Color(0xFF13121C) : Colors.white)
                              .withValues(alpha: 0.98),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── محتوای کارت (آیکون، نام و توضیح) ──
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          EffectPatternIcon(
                            effect: effect,
                            size: 38,
                            iconSize: 20,
                            borderRadius: 12,
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
                                size: 14,
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
