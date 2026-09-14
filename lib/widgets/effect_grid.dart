import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/app_effect.dart';
import '../core/app_effect_controller.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';

/// الگوی بصری مینیاتوری برای هر افکت در آیکون یا پیش‌نمایش
class EffectPatternPainter extends CustomPainter {
  const EffectPatternPainter({
    required this.effectId,
    required this.primary,
    required this.secondary,
    this.isDark = false,
  });

  final String effectId;
  final Color primary;
  final Color secondary;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final norm = AppEffect.normalizeId(effectId);
    if (norm == AppEffect.none) return;

    final rect = Offset.zero & size;
    final r = math.min(size.width, size.height);

    // Subtle background radial glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primary.withValues(alpha: isDark ? 0.35 : 0.22),
          secondary.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaint);

    final p1 = Paint()..color = primary.withValues(alpha: 0.55);
    final p2 = Paint()..color = secondary.withValues(alpha: 0.45);

    switch (norm) {
      case AppEffect.blushRose:
      case AppEffect.mistyRose:
        // Petal / Heart dots
        canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.3), r * 0.12, p1);
        canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.35), r * 0.09, p2);
        canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.75), r * 0.14, p1);
        canvas.drawCircle(Offset(size.width * 0.30, size.height * 0.70), r * 0.08, p2);
        break;

      case AppEffect.sageGarden:
      case AppEffect.oliveGrove:
        // Botanical leaves / dots
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.3, size.height * 0.35),
            width: r * 0.24,
            height: r * 0.12,
          ),
          p1,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.7, size.height * 0.65),
            width: r * 0.22,
            height: r * 0.10,
          ),
          p2,
        );
        canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.28), r * 0.08, p1);
        canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.72), r * 0.09, p2);
        break;

      case AppEffect.champagneGold:
      case AppEffect.candlelight:
        // Sparkle crosses and shimmer points
        _drawSparkle(canvas, Offset(size.width * 0.28, size.height * 0.32), r * 0.16, p1);
        _drawSparkle(canvas, Offset(size.width * 0.72, size.height * 0.68), r * 0.14, p2);
        canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.28), r * 0.07, p1);
        canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.72), r * 0.08, p2);
        break;

      case AppEffect.lavenderDusk:
      case AppEffect.midnightOrchid:
        // Glowing bokeh & star dust
        canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.30), r * 0.16, p1);
        canvas.drawCircle(Offset(size.width * 0.70, size.height * 0.40), r * 0.20, p2);
        canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.75), r * 0.12, p1);
        _drawSparkle(canvas, Offset(size.width * 0.25, size.height * 0.70), r * 0.12, p2);
        break;

      case AppEffect.oceanMist:
      case AppEffect.pearlSand:
      default:
        // Water ripples / pearl shimmer
        canvas.drawCircle(Offset(size.width * 0.30, size.height * 0.32), r * 0.15, p1);
        canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.36), r * 0.11, p2);
        canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.72), r * 0.18, p1);
        canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.70), r * 0.09, p2);
        break;
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Paint paint) {
    final sp = Paint()
      ..color = paint.color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      sp,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      sp,
    );
    canvas.drawCircle(center, radius * 0.3, paint);
  }

  @override
  bool shouldRepaint(covariant EffectPatternPainter oldDelegate) =>
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
    this.size = 40,
    this.iconSize = 20,
    this.borderRadius = 12,
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
              : effect.primary.withValues(alpha: isDark ? 0.20 : 0.14),
          border: Border.all(
            color: effect.isNone
                ? AppTok.border(context)
                : effect.primary.withValues(alpha: 0.30),
          ),
          gradient: effect.isNone
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    effect.primary.withValues(alpha: isDark ? 0.25 : 0.20),
                    effect.secondary.withValues(alpha: isDark ? 0.15 : 0.10),
                  ],
                ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!effect.isNone)
              CustomPaint(
                painter: EffectPatternPainter(
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
                    : effect.primary,
                size: iconSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// کارت تک‌افکت با پیش‌نمایش الگو، عنوان و زیرعنوان
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
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: isSelected
                ? effect.primary.withValues(alpha: isDark ? 0.18 : 0.14)
                : AppTok.card(context).withValues(alpha: 0.88),
            border: Border.all(
              color: isSelected
                  ? effect.primary
                  : AppTok.border(context).withValues(alpha: 0.8),
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  EffectPatternIcon(
                    effect: effect,
                    size: 38,
                    iconSize: 20,
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: effect.primary,
                      size: 20,
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
                  fontSize: 13,
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
        childAspectRatio: 1.35,
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
