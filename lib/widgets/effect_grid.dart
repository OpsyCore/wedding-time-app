import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/app_effect.dart';
import '../core/app_effect_controller.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';

/// نقاش جدید: خیلی لطیف — فقط گرادینت کم‌رنگ + مه نرم، بدون بلور سنگین
/// روی وب سبک می‌ماند، شکلی مصنوعی حذف شد، هر جلوه با المان طبیعی مرتبط
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

    // پس‌زمینه: گرادینت شعاعی خیلی کم‌رنگ (فقط 0.14/0.06)
    final bg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.35, -0.3),
        radius: 1.1,
        colors: [
          primary.withValues(alpha: isDark ? 0.16 : 0.12),
          secondary.withValues(alpha: isDark ? 0.08 : 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    // مه نرم مشترک — دو لکه آبرنگی بزرگ خیلی محو
    final mist1 = Paint()..color = primary.withValues(alpha: isDark ? 0.08 : 0.05);
    final mist2 = Paint()..color = secondary.withValues(alpha: isDark ? 0.06 : 0.04);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.32), size.width * 0.28, mist1);
    canvas.drawCircle(Offset(size.width * 0.32, size.height * 0.68), size.width * 0.22, mist2);

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

  // رز بلاش — گلبرگ‌های آبرنگی صورتی، قلب خیلی محو
  void _paintBlushRose(Canvas canvas, Size size) {
    final petal = Paint()..color = primary.withValues(alpha: isDark ? 0.22 : 0.16);
    // دو لکه آبرنگی بیضی چرخیده — شکل گلبرگ طبیعی
    _watercolorBlob(canvas, Offset(size.width * 0.62, size.height * 0.30), 22, 14, -0.35, petal);
    _watercolorBlob(canvas, Offset(size.width * 0.74, size.height * 0.42), 16, 10, 0.6, petal);
    // قلب بسیار محو داخل مه
    final heart = Paint()..color = primary.withValues(alpha: 0.10);
    _drawHeartSoft(canvas, Offset(size.width * 0.68, size.height * 0.36), 13, heart);
  }

  // باغ سیج — برگ‌های نرم با رگه دستی
  void _paintSageGarden(Canvas canvas, Size size) {
    final leaf = Paint()..color = primary.withValues(alpha: isDark ? 0.18 : 0.13);
    final vein = Paint()
      ..color = primary.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (final d in [
      [0.70, 0.32, 15.0, 7.0, 0.55],
      [0.38, 0.28, 11.0, 5.5, -0.45],
      [0.78, 0.62, 9.0, 4.5, 0.2],
    ]) {
      final c = Offset(size.width * d[0], size.height * d[1]);
      _watercolorBlob(canvas, c, d[2], d[3], d[4], leaf);
      // رگه نرم وسط برگ
      final p = Path()
        ..moveTo(c.dx - d[2] * 0.45 * math.cos(d[4]), c.dy - d[2] * 0.45 * math.sin(d[4]))
        ..quadraticBezierTo(c.dx, c.dy, c.dx + d[2] * 0.45 * math.cos(d[4]), c.dy + d[2] * 0.45 * math.sin(d[4]));
      canvas.drawPath(p, vein);
    }
  }

  // شامپاین طلایی — بوکه طلایی گرم، بدون ستاره تیز
  void _paintChampagneGold(Canvas canvas, Size size) {
    final gold = Paint()..color = primary.withValues(alpha: isDark ? 0.14 : 0.10);
    final glow = Paint()..color = const Color(0xFFFFF6D5).withValues(alpha: isDark ? 0.18 : 0.13);
    // سه حباب بوکه نرم
    canvas.drawCircle(Offset(size.width * 0.70, size.height * 0.34), 16, gold);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.22), 8, glow);
    canvas.drawCircle(Offset(size.width * 0.34, size.height * 0.58), 10, gold);
    // نقطه درخشان خیلی کوچک مرکز بوکه
    canvas.drawCircle(Offset(size.width * 0.70, size.height * 0.34), 1.8, Paint()..color = Colors.white.withValues(alpha: 0.55));
  }

  // غروب لوندر — مه بنفش با بوکه خیلی محو
  void _paintLavenderDusk(Canvas canvas, Size size) {
    final b1 = Paint()..color = primary.withValues(alpha: isDark ? 0.13 : 0.09);
    final b2 = Paint()..color = secondary.withValues(alpha: isDark ? 0.11 : 0.07);
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.38), 20, b1);
    canvas.drawCircle(Offset(size.width * 0.40, size.height * 0.62), 14, b2);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.60), 6, b2);
  }

  // مه اقیانوس — موج منحنی دستی، نه حلقه هندسی
  void _paintOceanMist(Canvas canvas, Size size) {
    final wave = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.16 : 0.11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final drop = Paint()..color = secondary.withValues(alpha: 0.18);
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.45)
      ..cubicTo(size.width * 0.32, size.height * 0.38, size.width * 0.48, size.height * 0.52, size.width * 0.82, size.height * 0.36);
    canvas.drawPath(path, wave);
    final path2 = Path()
      ..moveTo(size.width * 0.22, size.height * 0.58)
      ..cubicTo(size.width * 0.38, size.height * 0.50, size.width * 0.52, size.height * 0.62, size.width * 0.76, size.height * 0.48);
    canvas.drawPath(path2, wave..color = wave.color.withValues(alpha: 0.09));
    // یک قطره آبرنگی
    _watercolorBlob(canvas, Offset(size.width * 0.58, size.height * 0.35), 7, 5, 0.4, drop);
  }

  // مه رز — گلبرگ پراکنده با مه صورتی
  void _paintMistyRose(Canvas canvas, Size size) {
    final petal = Paint()..color = primary.withValues(alpha: isDark ? 0.13 : 0.09);
    _watercolorBlob(canvas, Offset(size.width * 0.66, size.height * 0.32), 12, 7, 0.3, petal);
    _watercolorBlob(canvas, Offset(size.width * 0.74, size.height * 0.48), 9, 5, -0.5, petal);
    _watercolorBlob(canvas, Offset(size.width * 0.34, size.height * 0.56), 8, 4.5, 0.8, petal);
  }

  // بیشه زیتون — شاخه با زیتون‌های گرد محو
  void _paintOliveGrove(Canvas canvas, Size size) {
    final leaf = Paint()..color = primary.withValues(alpha: 0.14);
    final fruit = Paint()..color = secondary.withValues(alpha: 0.16);
    // شاخه منحنی نرم
    final stem = Paint()
      ..color = primary.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final p = Path()
      ..moveTo(size.width * 0.22, size.height * 0.68)
      ..cubicTo(size.width * 0.42, size.height * 0.42, size.width * 0.62, size.height * 0.38, size.width * 0.82, size.height * 0.28);
    canvas.drawPath(p, stem);
    _watercolorBlob(canvas, Offset(size.width * 0.45, size.height * 0.44), 10, 5, 0.6, leaf);
    _watercolorBlob(canvas, Offset(size.width * 0.62, size.height * 0.36), 10, 5, -0.4, leaf);
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.48), 3.2, fruit);
    canvas.drawCircle(Offset(size.width * 0.36, size.height * 0.62), 2.4, fruit);
  }

  // نور شمع — هاله کهربایی گرم بدون شعله تیز
  void _paintCandlelight(Canvas canvas, Size size) {
    final glow = Paint()..color = primary.withValues(alpha: isDark ? 0.16 : 0.11);
    final warm = Paint()..color = const Color(0xFFFFE8B0).withValues(alpha: 0.12);
    // هاله بیضی شمع
    _watercolorBlob(canvas, Offset(size.width * 0.68, size.height * 0.38), 18, 22, 0.15, glow);
    _watercolorBlob(canvas, Offset(size.width * 0.68, size.height * 0.30), 5, 8, 0.15, warm);
  }

  // ارکیده نیمه‌شب — آسمان با نقطه‌های خیلی محو، بدون هلال تیز
  void _paintMidnightOrchid(Canvas canvas, Size size) {
    final star = Paint()..color = secondary.withValues(alpha: 0.14);
    canvas.drawCircle(Offset(size.width * 0.70, size.height * 0.32), 9, star);
    canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.28), 5, star);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.58), 4, star);
    // سحابی نرم
    final nebula = Paint()..color = primary.withValues(alpha: 0.07);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.42), 26, nebula);
  }

  // ماسه مرواریدی — بافت شن با نقطه‌های ریز، بدون حلقه فلزی
  void _paintPearlSand(Canvas canvas, Size size) {
    final sand = Paint()..color = primary.withValues(alpha: 0.10);
    final pearl = Paint()..color = Colors.white.withValues(alpha: isDark ? 0.16 : 0.12);
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.36), 11, pearl);
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.36), 4.5, sand);
    canvas.drawCircle(Offset(size.width * 0.32, size.height * 0.40), 2.2, sand);
    canvas.drawCircle(Offset(size.width * 0.44, size.height * 0.64), 1.6, sand);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.62), 1.4, sand);
  }

  void _watercolorBlob(Canvas canvas, Offset c, double rx, double ry, double angle, Paint paint) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    // بیضی با لبه کمی موج‌دار برای حس آبرنگ
    final r = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);
    canvas.drawOval(r, paint);
    // لایه دوم کوچک‌تر برای عمق آبرنگ
    canvas.drawOval(
      r.deflate(rx * 0.35),
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
      oldDelegate.effectId != effectId || oldDelegate.primary != primary || oldDelegate.secondary != secondary || oldDelegate.isDark != isDark;
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
          color: effect.isNone ? AppTok.cardSoft(context) : effect.primary.withValues(alpha: isDark ? 0.14 : 0.10),
          border: Border.all(color: effect.isNone ? AppTok.border(context) : effect.primary.withValues(alpha: 0.18), width: 1),
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
                color: effect.isNone ? AppTok.textSoft(context) : (isDark ? Colors.white.withValues(alpha: 0.92) : effect.primary),
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
            color: isSelected ? effect.primary.withValues(alpha: isDark ? 0.13 : 0.08) : AppTok.card(context).withValues(alpha: isDark ? 0.96 : 0.98),
            border: Border.all(color: isSelected ? effect.primary.withValues(alpha: 0.55) : AppTok.border(context).withValues(alpha: 0.5), width: isSelected ? 1.6 : 1.0),
            boxShadow: [
              BoxShadow(
                color: isSelected ? effect.primary.withValues(alpha: 0.12) : Colors.black.withValues(alpha: isDark ? 0.10 : 0.04),
                blurRadius: isSelected ? 12 : 8,
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
                // گرادیانت پایین برای خوانایی
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
                          (isDark ? const Color(0xFF13121C) : Colors.white).withValues(alpha: 0.82),
                          (isDark ? const Color(0xFF13121C) : Colors.white).withValues(alpha: 0.96),
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
                          EffectPatternIcon(effect: effect, size: 36, iconSize: 18, borderRadius: 11),
                          const Spacer(),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(shape: BoxShape.circle, color: effect.primary),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        AppLang.tr(effect.nameKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppTok.text(context), fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLang.tr(effect.subtitleKey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppTok.textSoft(context), fontSize: 10.5, height: 1.3),
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
