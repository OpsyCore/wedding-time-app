import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_effect.dart';
import 'app_theme.dart';
import 'app_theme_controller.dart';

/// جلوه‌های بصری سراسری اپ (خانه + دعوت + تنظیمات موسیقی)
class AppEffectStyle {
  const AppEffectStyle({
    required this.id,
    required this.nameKey,
    required this.subtitleKey,
    required this.primary,
    required this.secondary,
    required this.icon,
  });

  final String id;
  final String nameKey;
  final String subtitleKey;
  final Color primary;
  final Color secondary;
  final IconData icon;

  static const noneId = 'none';
  static const goldId = 'gold';
  static const lavenderId = 'lavender';
  static const roseId = 'rose';
  static const champagneId = 'champagne';
  static const midnightId = 'midnight';
  static const mistyRoseId = 'misty_rose';
  static const oliveGroveId = 'olive_grove';
  static const candlelightId = 'candlelight';
  static const midnightOrchidId = 'midnight_orchid';
  static const pearlSandId = 'pearl_sand';

  static bool get _isDark =>
      AppThemeController.I.themeMode == ThemeMode.dark;

  /// ۱۰ جلوه با پالت و هویت کاملاً مجزا + بدون جلوه
  static List<AppEffectStyle> get all => <AppEffectStyle>[
        AppEffectStyle(
          id: noneId,
          nameKey: 'fx_none',
          subtitleKey: 'fx_none_sub',
          primary:
              _isDark ? AppDarkPalette.textSoft : AppPalette.textSoft,
          secondary:
              _isDark ? AppDarkPalette.cardSoft : AppPalette.cardSoft,
          icon: Icons.block_flipped,
        ),
        // ۱. ذرات رزگلد → رزگلد واقعی #DCA3A3 / #E8B4B8 + ذره ریز پخش
        const AppEffectStyle(
          id: goldId,
          nameKey: 'fx_gold',
          subtitleKey: 'fx_gold_sub',
          primary: Color(0xFFDCA3A3),
          secondary: Color(0xFFE8B4B8),
          icon: Icons.grain_rounded,
        ),
        // ۲. قلب لوندر شیشه‌ای → بنفش شیشه‌ای #C9B6E4 / #E8DDF5 + قلب blur
        const AppEffectStyle(
          id: lavenderId,
          nameKey: 'fx_lavender',
          subtitleKey: 'fx_lavender_sub',
          primary: Color(0xFFC9B6E4),
          secondary: Color(0xFFE8DDF5),
          icon: Icons.blur_on_rounded,
        ),
        // ۳. باران رز → صورتی باران #F8B8C0 / #FFD6DE + قلب ریزان
        const AppEffectStyle(
          id: roseId,
          nameKey: 'fx_rose',
          subtitleKey: 'fx_rose_sub',
          primary: Color(0xFFF8B8C0),
          secondary: Color(0xFFFFD6DE),
          icon: Icons.favorite_rounded,
        ),
        // ۴. شامپاینی و درخشش → طلایی شامپاین #D4AF37 / #F7E7CE + جرقه‌ها
        const AppEffectStyle(
          id: champagneId,
          nameKey: 'fx_champagne',
          subtitleKey: 'fx_champagne_sub',
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFFF7E7CE),
          icon: Icons.auto_awesome_rounded,
        ),
        // ۵. شب آبی ستاره‌ای → سرمه‌ای #1A2A4A / #4A7C9B + ستاره سفید
        const AppEffectStyle(
          id: midnightId,
          nameKey: 'fx_midnight',
          subtitleKey: 'fx_midnight_sub',
          primary: Color(0xFF4A7C9B),
          secondary: Color(0xFF1A2A4A),
          icon: Icons.nights_stay_rounded,
        ),
        // ۶. رز مه‌آلود → صورتی غبار #E8C4C4 / #F5E0E0 مه‌آلود
        const AppEffectStyle(
          id: mistyRoseId,
          nameKey: 'fx_misty_rose',
          subtitleKey: 'fx_misty_rose_sub',
          primary: Color(0xFFE8C4C4),
          secondary: Color(0xFFF5E0E0),
          icon: Icons.cloud_queue_rounded,
        ),
        // ۷. بیشه زیتون → سبز زیتونی #6B8E5A / #8FA68E + برگ
        const AppEffectStyle(
          id: oliveGroveId,
          nameKey: 'fx_olive_grove',
          subtitleKey: 'fx_olive_grove_sub',
          primary: Color(0xFF6B8E5A),
          secondary: Color(0xFF8FA68E),
          icon: Icons.eco_rounded,
        ),
        // ۸. نور شمع → نارنجی گرم #FF9A3C / #FFC857 + فلیکر شعله
        const AppEffectStyle(
          id: candlelightId,
          nameKey: 'fx_candlelight',
          subtitleKey: 'fx_candlelight_sub',
          primary: Color(0xFFFF9A3C),
          secondary: Color(0xFFFFC857),
          icon: Icons.local_fire_department_rounded,
        ),
        // ۹. ارکیده نیمه‌شب → بنفش تیره #2D1B4E / #8E7CC3
        const AppEffectStyle(
          id: midnightOrchidId,
          nameKey: 'fx_midnight_orchid',
          subtitleKey: 'fx_midnight_orchid_sub',
          primary: Color(0xFF8E7CC3),
          secondary: Color(0xFF2D1B4E),
          icon: Icons.local_florist_rounded,
        ),
        // ۱۰. شب مرواریدی → سفید مرواریدی #F5F5F0 / #D4CFC4
        const AppEffectStyle(
          id: pearlSandId,
          nameKey: 'fx_pearl_sand',
          subtitleKey: 'fx_pearl_sand_sub',
          primary: Color(0xFFD4CFC4),
          secondary: Color(0xFFF5F5F0),
          icon: Icons.lens_blur_rounded,
        ),
      ];

  static AppEffectStyle byId(String? id) {
    final norm = AppEffect.normalizeId(id);
    return all.firstWhere(
      (e) => e.id == norm,
      orElse: () => all.first,
    );
  }

  bool get isOff => id == noneId;
}

/// لایه افکت روی خانه / دعوت / پیش‌نمایش زنده
class AppEffectOverlay extends StatefulWidget {
  const AppEffectOverlay({
    super.key,
    required this.effectId,
    this.intensity = 1.0,
  });

  final String effectId;
  final double intensity;

  @override
  State<AppEffectOverlay> createState() => _AppEffectOverlayState();
}

class _AppEffectOverlayState extends State<AppEffectOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant AppEffectOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.effectId != widget.effectId) {
      _ctrl
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = AppEffectStyle.byId(widget.effectId);
    if (style.isOff) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return CustomPaint(
            painter: _EffectPainter(
              progress: _ctrl.value,
              style: style,
              intensity: widget.intensity.clamp(0.6, 2.0),
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _EffectPainter extends CustomPainter {
  _EffectPainter({
    required this.progress,
    required this.style,
    required this.intensity,
  });

  final double progress;
  final AppEffectStyle style;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rnd = math.Random(style.id.hashCode);

    _paintWash(canvas, size);

    switch (style.id) {
      case AppEffectStyle.goldId:
        // ذرات رزگلد: ذره‌های ریز پخشِ رزگلد (#DCA3A3 / #E8B4B8)
        _paintRoseGoldDust(canvas, size, rnd);
        break;
      case AppEffectStyle.lavenderId:
        // قلب لوندر شیشه‌ای: قلب‌های بلور بنفش شیشه‌ای (#C9B6E4 / #E8DDF5)
        _paintParticles(canvas, size, rnd, hearts: true, glass: true, count: 28);
        break;
      case AppEffectStyle.roseId:
        // باران رز: قلب‌های صورتی ریزان (#F8B8C0 / #FFD6DE)
        _paintParticles(canvas, size, rnd, hearts: true, glass: false, count: 34);
        break;
      case AppEffectStyle.champagneId:
        // شامپاینی و درخشش: جرقه‌های چهارپر طلایی شامپاین (#D4AF37 / #F7E7CE)
        _paintChampagneSparkles(canvas, size, rnd);
        break;
      case AppEffectStyle.midnightId:
        // شب آبی ستاره‌ای: آسمان سرمه‌ای (#1A2A4A / #4A7C9B) + ستاره‌های سفید
        _paintStars(canvas, size, rnd);
        break;
      case AppEffectStyle.mistyRoseId:
        // رز مه‌آلود: مه غلیظ صورتی غبار (#E8C4C4 / #F5E0E0) + گلبرگ‌های محو
        _paintMistyRoseFog(canvas, size, rnd);
        break;
      case AppEffectStyle.oliveGroveId:
        // بیشه زیتون: برگ‌های زیتونی رگه‌دار (#6B8E5A / #8FA68E)
        _paintOliveLeaves(canvas, size, rnd);
        break;
      case AppEffectStyle.candlelightId:
        // نور شمع: فلیکر شعله‌های گرم نارنجی/کهربایی (#FF9A3C / #FFC857)
        _paintCandleFlames(canvas, size, rnd);
        break;
      case AppEffectStyle.midnightOrchidId:
        // ارکیده نیمه‌شب: سحابی بنفش تیره (#2D1B4E / #8E7CC3) + گل‌های ارکیده
        _paintMidnightOrchid(canvas, size, rnd);
        break;
      case AppEffectStyle.pearlSandId:
        // شب مرواریدی: گوی‌های صدفی و مرواریدی (#F5F5F0 / #D4CFC4)
        _paintPearlOrbs(canvas, size, rnd);
        break;
      default:
        _paintRoseGoldDust(canvas, size, rnd);
        break;
    }
  }

  void _paintWash(Canvas canvas, Size size) {
    final t = progress * math.pi * 2;
    final blobs = <Offset>[
      Offset(size.width * (0.2 + 0.05 * math.sin(t)), size.height * 0.25),
      Offset(
        size.width * (0.75 + 0.04 * math.cos(t * 0.8)),
        size.height * 0.55,
      ),
      Offset(
        size.width * 0.5,
        size.height * (0.85 + 0.03 * math.sin(t * 1.2)),
      ),
    ];
    for (var i = 0; i < blobs.length; i++) {
      final r = (70.0 + i * 28) * (0.70 + 0.10 * intensity);
      canvas.drawCircle(
        blobs[i],
        r,
        Paint()
          ..color = Color.lerp(style.primary, style.secondary, i / 3)!
              .withValues(alpha: (0.035 * intensity).clamp(0.015, 0.08))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36),
      );
    }
  }

  /// ۱. ذرات رزگلد واقعی (#DCA3A3 / #E8B4B8) — ذره‌های ریز متالیک پخش در کل صفحه
  void _paintRoseGoldDust(Canvas canvas, Size size, math.Random rnd) {
    const roseGold = Color(0xFFDCA3A3);
    const roseGoldLight = Color(0xFFE8B4B8);
    const roseCopper = Color(0xFFC98B8B);

    for (var i = 0; i < 64; i++) {
      final baseX = rnd.nextDouble() * size.width;
      final baseY = rnd.nextDouble() * size.height;
      final speed = 0.12 + rnd.nextDouble() * 0.28;
      final phase = rnd.nextDouble();
      final angle = (progress * speed + phase) * math.pi * 2;
      final x = (baseX + math.cos(angle + i) * 18) % size.width;
      final y = (baseY + math.sin(angle * 0.8 + i) * 14) % size.height;
      final shimmer = 0.35 + 0.65 * ((math.sin(progress * math.pi * 4 + i * 0.7) + 1) / 2);
      final alpha = (0.22 + shimmer * 0.52) * intensity;
      final radius = (0.9 + rnd.nextDouble() * 2.1) * (0.8 + 0.3 * intensity);

      final color = i % 3 == 0
          ? roseGoldLight
          : (i % 3 == 1 ? roseGold : roseCopper);

      // هاله نرم دور ذره رزگلد
      canvas.drawCircle(
        Offset(x, y),
        radius * 2.4,
        Paint()
          ..color = roseGoldLight.withValues(alpha: (alpha * 0.28).clamp(0.05, 0.35))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // هسته ذره رزگلد
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = color.withValues(alpha: alpha.clamp(0.2, 0.88)),
      );
    }
  }

  /// ۲ و ۳. قلب لوندر شیشه‌ای (#C9B6E4) و باران رز (#F8B8C0)
  void _paintParticles(
    Canvas canvas,
    Size size,
    math.Random rnd, {
    required bool hearts,
    required bool glass,
    int? count,
  }) {
    final n = count ?? (hearts ? 34 : 40);
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < n; i++) {
      final baseX = rnd.nextDouble() * size.width;
      final speed = 0.18 + rnd.nextDouble() * 0.45;
      final phase = rnd.nextDouble();
      final sway = glass ? 22.0 : 16.0;
      final t = (progress * speed + phase) % 1.0;
      // برای باران رز از بالا به پایین ببارد، برای لوندر شیشه‌ای معلق باشد
      final y = glass
          ? size.height * (1.10 - t)
          : size.height * (-0.08 + t * 1.16);
      final x = baseX + math.sin((progress * 2 + phase) * math.pi * 2) * sway;
      final fade = (math.sin(t * math.pi)).clamp(0.2, 1.0);
      final opacity =
          (glass ? 0.46 : 0.38) * intensity * fade + rnd.nextDouble() * 0.1;
      final s = (glass ? 16.0 : 13.0) + rnd.nextDouble() * (glass ? 15 : 11);

      if (hearts) {
        if (glass) {
          final glow = Paint()
            ..color = style.secondary
                .withValues(alpha: (opacity * 0.55).clamp(0, 0.65))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
          canvas.drawCircle(
            Offset(x, y),
            s * 0.78,
            glow,
          );
        }
        tp.text = TextSpan(
          text: i.isEven ? '♥' : '♡',
          style: TextStyle(
            color: Color.lerp(style.primary, style.secondary, rnd.nextDouble())!
                .withValues(alpha: opacity.clamp(0.28, 0.88)),
            fontSize: s,
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: glass ? 0.55 : 0.22),
                blurRadius: glass ? 16 : 6,
              ),
              Shadow(
                color: style.primary.withValues(alpha: 0.60),
                blurRadius: 16,
              ),
            ],
          ),
        );
        tp.layout();
        final angle = math.sin((progress + phase) * math.pi * 2) * 0.35;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(angle);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }
  }

  /// ۴. شامپاینی و درخشش (#D4AF37 / #F7E7CE) — جرقه‌های طلایی درخشان + حباب‌های شامپاین
  void _paintChampagneSparkles(
    Canvas canvas,
    Size size,
    math.Random rnd,
  ) {
    const gold = Color(0xFFD4AF37);
    const champagne = Color(0xFFF7E7CE);

    // حباب‌های ظریف طلایی رو به بالا
    for (var i = 0; i < 18; i++) {
      final baseX = rnd.nextDouble() * size.width;
      final speed = 0.16 + rnd.nextDouble() * 0.30;
      final phase = rnd.nextDouble();
      final t = (progress * speed + phase) % 1.0;
      final y = size.height * (1.05 - t);
      final x = baseX + math.sin((t * 3 + phase) * math.pi * 2) * 8;
      final r = 2.0 + rnd.nextDouble() * 3.5;
      final alpha = (0.18 + 0.25 * math.sin(t * math.pi)) * intensity;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = champagne.withValues(alpha: alpha.clamp(0.08, 0.45))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    }

    // جرقه‌های ستاره‌ای طلایی شامپاین (بدون هیچ رنگ صورتی)
    for (var i = 0; i < 28; i++) {
      final x = rnd.nextDouble() * size.width;
      final yBase = rnd.nextDouble() * size.height;
      final drift = math.sin(progress * math.pi * 2 + i) * 14;
      final y = (yBase + drift) % size.height;
      final tw =
          0.40 + 0.60 * ((math.sin((progress * math.pi * 4) + i * 0.9) + 1) / 2);
      final o = (0.28 + tw * 0.55) * intensity;
      final arm = (5.5 + tw * 6.5) * (0.85 + 0.15 * intensity);
      final c = Color.lerp(gold, champagne, tw * 0.65)!
          .withValues(alpha: o.clamp(0.22, 0.92));

      canvas.drawCircle(
        Offset(x, y),
        arm * 0.55,
        Paint()
          ..color = gold.withValues(alpha: (o * 0.25).clamp(0.05, 0.30))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      final sp = Paint()
        ..color = c
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x - arm, y), Offset(x + arm, y), sp);
      canvas.drawLine(Offset(x, y - arm), Offset(x, y + arm), sp);
      if (i % 2 == 0) {
        final dArm = arm * 0.52;
        canvas.drawLine(
          Offset(x - dArm, y - dArm),
          Offset(x + dArm, y + dArm),
          sp..strokeWidth = 1.0,
        );
        canvas.drawLine(
          Offset(x - dArm, y + dArm),
          Offset(x + dArm, y - dArm),
          sp,
        );
      }
      canvas.drawCircle(
        Offset(x, y),
        1.8,
        Paint()..color = Colors.white.withValues(alpha: (o * 0.85).clamp(0.2, 0.95)),
      );
    }
  }

  /// ۵. شب آبی ستاره‌ای (#1A2A4A / #4A7C9B) — آسمان سرمه‌ای + ستاره‌های سفید چشمک‌زن
  void _paintStars(Canvas canvas, Size size, math.Random rnd) {
    const navy = Color(0xFF1A2A4A);
    const steelBlue = Color(0xFF4A7C9B);

    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.15 + i * 0.22);
      final y = size.height *
          (0.2 + 0.25 * math.sin(progress * math.pi * 2 + i));
      canvas.drawCircle(
        Offset(x, y),
        64 + i * 16,
        Paint()
          ..color = Color.lerp(navy, steelBlue, i / 3)!
              .withValues(alpha: (0.12 * intensity).clamp(0.04, 0.22))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 38),
      );
    }

    for (var i = 0; i < 46; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final tw = 0.35 +
          0.65 *
              ((math.sin(progress * math.pi * 2 * (1.2 + i % 3 * 0.2) + i) +
                      1) /
                  2);
      final o = (0.30 + tw * 0.58) * intensity;
      final starColor = Color.lerp(const Color(0xFFD6ECFF), Colors.white, tw)!
          .withValues(alpha: o.clamp(0.25, 0.98));
      canvas.drawCircle(Offset(x, y), 1.3 + tw * 2.2, Paint()..color = starColor);
      if (i % 4 == 0) {
        final sp = Paint()
          ..color = starColor
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;
        final a = 4.0 + tw * 4.0;
        canvas.drawLine(Offset(x - a, y), Offset(x + a, y), sp);
        canvas.drawLine(Offset(x, y - a), Offset(x, y + a), sp);
      }
    }
  }

  /// ۶. رز مه‌آلود (#E8C4C4 / #F5E0E0) — لایه‌های مه غبارآلود صورتی و گلبرگ‌های بیضی محو
  void _paintMistyRoseFog(Canvas canvas, Size size, math.Random rnd) {
    const dustyRose = Color(0xFFE8C4C4);
    const softMist = Color(0xFFF5E0E0);

    // لایه‌های مه افقی شناور
    for (var i = 0; i < 6; i++) {
      final phase = i / 6.0;
      final drift = math.sin((progress + phase) * math.pi * 2) * 32;
      final cx = size.width * (0.2 + (i % 3) * 0.3) + drift;
      final cy = size.height * (0.16 + i * 0.14);
      final rect = Rect.fromCenter(
        center: Offset(cx, cy),
        width: size.width * 0.55,
        height: 46 + (i % 2) * 18,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..color = (i.isEven ? dustyRose : softMist)
              .withValues(alpha: (0.12 * intensity).clamp(0.05, 0.22))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
      );
    }

    // گلبرگ‌های نرم غبارآلود (بدون کاراکتر قلب)
    for (var i = 0; i < 20; i++) {
      final baseX = rnd.nextDouble() * size.width;
      final speed = 0.14 + rnd.nextDouble() * 0.22;
      final phase = rnd.nextDouble();
      final t = (progress * speed + phase) % 1.0;
      final y = size.height * (t * 1.1 - 0.05);
      final x = baseX + math.sin((progress + phase) * math.pi * 2) * 20;
      final angle = (progress + phase) * math.pi * 2;
      final rx = 5.5 + rnd.nextDouble() * 4.5;
      final ry = rx * 0.58;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        Paint()
          ..color = Color.lerp(dustyRose, softMist, rnd.nextDouble())!
              .withValues(alpha: (0.36 * intensity).clamp(0.18, 0.65))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.restore();
    }
  }

  /// ۷. بیشه زیتون (#6B8E5A / #8FA68E) — برگ‌های زیتونی واقعی با رگه وسط
  void _paintOliveLeaves(Canvas canvas, Size size, math.Random rnd) {
    const olive = Color(0xFF6B8E5A);
    const sage = Color(0xFF8FA68E);

    for (var i = 0; i < 24; i++) {
      final baseX = rnd.nextDouble() * size.width;
      final speed = 0.14 + rnd.nextDouble() * 0.26;
      final phase = rnd.nextDouble();
      final t = (progress * speed + phase) % 1.0;
      final y = size.height * (t * 1.12 - 0.06);
      final x = baseX + math.sin((progress * 1.5 + phase) * math.pi * 2) * 22;
      final rot = math.sin((progress + phase) * math.pi * 2) * 0.8 + (i.isEven ? 0.4 : -0.4);
      final len = (10.0 + rnd.nextDouble() * 7.0) * (0.85 + 0.15 * intensity);
      final wid = len * 0.42;
      final fade = (math.sin(t * math.pi)).clamp(0.25, 1.0);
      final leafColor = Color.lerp(olive, sage, rnd.nextDouble())!
          .withValues(alpha: (0.45 * fade * intensity).clamp(0.20, 0.78));

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);

      final path = Path()
        ..moveTo(-len, 0)
        ..quadraticBezierTo(0, -wid * 1.4, len, 0)
        ..quadraticBezierTo(0, wid * 1.4, -len, 0)
        ..close();
      canvas.drawPath(path, Paint()..color = leafColor);

      // رگه وسط برگ زیتون
      canvas.drawLine(
        Offset(-len * 0.85, 0),
        Offset(len * 0.85, 0),
        Paint()
          ..color = Colors.white.withValues(alpha: (0.28 * fade).clamp(0.08, 0.45))
          ..strokeWidth = 0.9
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }
  }

  /// ۸. نور شمع (#FF9A3C / #FFC857) — فلیکر شعله گرم و هاله‌های کهربایی (نه ذره!)
  void _paintCandleFlames(Canvas canvas, Size size, math.Random rnd) {
    const warmOrange = Color(0xFFFF9A3C);
    const candleGold = Color(0xFFFFC857);
    const coreWhite = Color(0xFFFFF8E7);

    for (var i = 0; i < 16; i++) {
      final baseX = size.width * (0.08 + (i / 15.0) * 0.84);
      final baseY = size.height * (0.22 + (i % 4) * 0.19 + rnd.nextDouble() * 0.08);
      final flicker = math.sin(progress * math.pi * 8 + i * 1.3) * 0.18 +
          math.cos(progress * math.pi * 6 + i * 2.1) * 0.12;
      final sway = math.sin(progress * math.pi * 4 + i) * 3.5;
      final scale = (0.85 + flicker) * (0.85 + 0.15 * intensity);
      final h = (16.0 + (i % 3) * 4.5) * scale;
      final w = h * 0.38;

      // هاله گرم لرزان دور شعله
      canvas.drawCircle(
        Offset(baseX + sway * 0.4, baseY - h * 0.35),
        h * 1.65,
        Paint()
          ..color = warmOrange.withValues(alpha: (0.14 * scale * intensity).clamp(0.05, 0.28))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );

      // بدنه بیرونی شعله شمع (اشکی شکل)
      final flameOuter = Path()
        ..moveTo(baseX, baseY)
        ..quadraticBezierTo(baseX - w * 1.3, baseY - h * 0.35, baseX + sway, baseY - h)
        ..quadraticBezierTo(baseX + w * 1.3, baseY - h * 0.35, baseX, baseY)
        ..close();
      canvas.drawPath(
        flameOuter,
        Paint()
          ..color = warmOrange.withValues(alpha: (0.52 * intensity).clamp(0.25, 0.82))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );

      // هسته طلایی روشن شعله
      final flameInner = Path()
        ..moveTo(baseX, baseY - h * 0.08)
        ..quadraticBezierTo(
          baseX - w * 0.65,
          baseY - h * 0.35,
          baseX + sway * 0.6,
          baseY - h * 0.72,
        )
        ..quadraticBezierTo(
          baseX + w * 0.65,
          baseY - h * 0.35,
          baseX,
          baseY - h * 0.08,
        )
        ..close();
      canvas.drawPath(
        flameInner,
        Paint()..color = Color.lerp(candleGold, coreWhite, 0.45)!.withValues(alpha: 0.78),
      );
    }
  }

  /// ۹. ارکیده نیمه‌شب (#2D1B4E / #8E7CC3) — سحابی بنفش تیره و گل‌های ۵پر ارکیده
  void _paintMidnightOrchid(Canvas canvas, Size size, math.Random rnd) {
    const deepViolet = Color(0xFF2D1B4E);
    const orchidPurple = Color(0xFF8E7CC3);
    const orchidSoft = Color(0xFFD5C8F5);

    for (var i = 0; i < 4; i++) {
      final cx = size.width * (0.2 + i * 0.22);
      final cy = size.height * (0.25 + 0.2 * math.sin(progress * math.pi * 2 + i));
      canvas.drawCircle(
        Offset(cx, cy),
        68.0 + i * 14,
        Paint()
          ..color = Color.lerp(deepViolet, orchidPurple, 0.45)!
              .withValues(alpha: (0.14 * intensity).clamp(0.05, 0.24))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34),
      );
    }

    for (var i = 0; i < 18; i++) {
      final baseX = rnd.nextDouble() * size.width;
      final speed = 0.12 + rnd.nextDouble() * 0.22;
      final phase = rnd.nextDouble();
      final t = (progress * speed + phase) % 1.0;
      final y = size.height * (1.06 - t * 1.12);
      final x = baseX + math.sin((progress + phase) * math.pi * 2) * 16;
      final rot = (progress + phase) * math.pi * 2 * 0.5;
      final r = (6.5 + rnd.nextDouble() * 5.0) * (0.85 + 0.15 * intensity);
      final alpha = (0.32 * math.sin(t * math.pi) * intensity).clamp(0.14, 0.62);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      final petalPaint = Paint()
        ..color = Color.lerp(orchidPurple, orchidSoft, (i % 3) / 2)!
            .withValues(alpha: alpha);
      for (var p = 0; p < 5; p++) {
        canvas.save();
        canvas.rotate(p * (math.pi * 2 / 5));
        canvas.drawOval(
          Rect.fromCenter(center: Offset(0, -r * 0.55), width: r * 0.62, height: r * 0.95),
          petalPaint,
        );
        canvas.restore();
      }
      canvas.drawCircle(
        Offset.zero,
        r * 0.18,
        Paint()..color = Colors.white.withValues(alpha: (alpha * 1.1).clamp(0.2, 0.8)),
      );
      canvas.restore();
    }
  }

  /// ۱۰. شب مرواریدی (#F5F5F0 / #D4CFC4) — گوی‌های مرواریدی صدفی با هایلایت براق
  void _paintPearlOrbs(Canvas canvas, Size size, math.Random rnd) {
    const pearlWhite = Color(0xFFF5F5F0);
    const pearlWarm = Color(0xFFD4CFC4);

    for (var i = 0; i < 24; i++) {
      final baseX = rnd.nextDouble() * size.width;
      final baseY = rnd.nextDouble() * size.height;
      final driftX = math.sin(progress * math.pi * 2 + i * 0.8) * 14;
      final driftY = math.cos(progress * math.pi * 2 + i * 0.6) * 12;
      final x = (baseX + driftX) % size.width;
      final y = (baseY + driftY) % size.height;
      final pulse = 0.75 + 0.25 * math.sin(progress * math.pi * 2 + i);
      final r = (4.5 + (i % 5) * 2.2) * pulse * (0.85 + 0.15 * intensity);
      final alpha = (0.28 + 0.22 * pulse) * intensity;

      // هاله مرواریدی
      canvas.drawCircle(
        Offset(x, y),
        r * 1.7,
        Paint()
          ..color = pearlWarm.withValues(alpha: (alpha * 0.32).clamp(0.06, 0.28))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      // بدنه گوی مروارید
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = Color.lerp(pearlWarm, pearlWhite, 0.65)!
              .withValues(alpha: alpha.clamp(0.18, 0.68)),
      );
      // نقطه برق روی مروارید
      canvas.drawCircle(
        Offset(x - r * 0.28, y - r * 0.28),
        r * 0.28,
        Paint()..color = Colors.white.withValues(alpha: (alpha * 1.15).clamp(0.25, 0.90)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EffectPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.style.id != style.id ||
      oldDelegate.intensity != intensity;
}

/// SnackBar با کنتراست بالا
void showAppSnack(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  final dark = AppTok.isDark(context);
  final onAccent =
      dark ? AppDarkPalette.background : Colors.white;

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: error ? Colors.white : onAccent,
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
      ),
      backgroundColor:
          error ? AppTok.danger(context) : AppTok.accent(context),
      behavior: SnackBarBehavior.floating,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
  );
}
