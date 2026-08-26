import 'dart:math' as math;

import 'package:flutter/material.dart';

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
  // new 5 (mapped to new system)
  static const mistyRoseId = 'misty_rose';
  static const oliveGroveId = 'olive_grove';
  static const candlelightId = 'candlelight';
  static const midnightOrchidId = 'midnight_orchid';
  static const pearlSandId = 'pearl_sand';

  static bool get _isDark =>
      AppThemeController.I.themeMode == ThemeMode.dark;

  /// none از پالت فعال تم می‌خواند (light/dark)
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
        const AppEffectStyle(
          id: goldId,
          nameKey: 'fx_gold',
          subtitleKey: 'fx_gold_sub',
          primary: Color(0xFFE8C49A),
          secondary: Color(0xFFFFE0B8),
          icon: Icons.auto_awesome,
        ),
        const AppEffectStyle(
          id: lavenderId,
          nameKey: 'fx_lavender',
          subtitleKey: 'fx_lavender_sub',
          primary: Color(0xFFC4B0FF),
          secondary: Color(0xFFE8DCFF),
          icon: Icons.blur_on_rounded,
        ),
        const AppEffectStyle(
          id: roseId,
          nameKey: 'fx_rose',
          subtitleKey: 'fx_rose_sub',
          primary: Color(0xFFFF8FB8),
          secondary: Color(0xFFFFC1D9),
          icon: Icons.favorite_rounded,
        ),
        const AppEffectStyle(
          id: champagneId,
          nameKey: 'fx_champagne',
          subtitleKey: 'fx_champagne_sub',
          primary: Color(0xFFFFE08A),
          secondary: Color(0xFFFFF3C4),
          icon: Icons.nightlife_rounded,
        ),
        const AppEffectStyle(
          id: midnightId,
          nameKey: 'fx_midnight',
          subtitleKey: 'fx_midnight_sub',
          primary: Color(0xFF8EC5FF),
          secondary: Color(0xFFD0E8FF),
          icon: Icons.nights_stay_rounded,
        ),
        // new 5
        const AppEffectStyle(
          id: mistyRoseId,
          nameKey: 'fx_misty_rose',
          subtitleKey: 'fx_misty_rose_sub',
          primary: Color(0xFFC98A83),
          secondary: Color(0xFFF2D6D0),
          icon: Icons.spa_rounded,
        ),
        const AppEffectStyle(
          id: oliveGroveId,
          nameKey: 'fx_olive_grove',
          subtitleKey: 'fx_olive_grove_sub',
          primary: Color(0xFF6B7A4F),
          secondary: Color(0xFFDDE3D0),
          icon: Icons.park_rounded,
        ),
        const AppEffectStyle(
          id: candlelightId,
          nameKey: 'fx_candlelight',
          subtitleKey: 'fx_candlelight_sub',
          primary: Color(0xFFC9A86A),
          secondary: Color(0xFFF5E6C8),
          icon: Icons.local_fire_department_rounded,
        ),
        const AppEffectStyle(
          id: midnightOrchidId,
          nameKey: 'fx_midnight_orchid',
          subtitleKey: 'fx_midnight_orchid_sub',
          primary: Color(0xFF8E7A8E),
          secondary: Color(0xFFE9DDE6),
          icon: Icons.nights_stay_rounded,
        ),
        const AppEffectStyle(
          id: pearlSandId,
          nameKey: 'fx_pearl_sand',
          subtitleKey: 'fx_pearl_sand_sub',
          primary: Color(0xFFD8CFC2),
          secondary: Color(0xFFF2EEE6),
          icon: Icons.beach_access_rounded,
        ),
      ];

  static AppEffectStyle byId(String? id) {
    final v = (id ?? noneId).trim();
    return all.firstWhere(
      (e) => e.id == v,
      orElse: () => all.first,
    );
  }

  bool get isOff => id == noneId;
}

/// لایه افکت روی خانه / دعوت
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
        _paintParticles(canvas, size, rnd, hearts: false, glass: false);
        _paintSparkles(canvas, size, rnd, count: 12);
        break;
      case AppEffectStyle.lavenderId:
        _paintParticles(canvas, size, rnd, hearts: true, glass: true);
        break;
      case AppEffectStyle.roseId:
        _paintParticles(canvas, size, rnd, hearts: true, glass: false);
        break;
      case AppEffectStyle.champagneId:
        _paintSparkles(canvas, size, rnd, count: 28);
        _paintParticles(
          canvas,
          size,
          rnd,
          hearts: false,
          glass: false,
          count: 10,
        );
        break;
      case AppEffectStyle.midnightId:
        _paintStars(canvas, size, rnd);
        break;
      case AppEffectStyle.mistyRoseId:
        _paintParticles(canvas, size, rnd, hearts: true, glass: false, count: 24);
        _paintWash(canvas, size);
        break;
      case AppEffectStyle.oliveGroveId:
        _paintParticles(canvas, size, rnd, hearts: false, glass: false, count: 30);
        break;
      case AppEffectStyle.candlelightId:
        _paintSparkles(canvas, size, rnd, count: 20);
        _paintParticles(canvas, size, rnd, hearts: false, glass: false, count: 12);
        break;
      case AppEffectStyle.midnightOrchidId:
        _paintStars(canvas, size, rnd);
        _paintParticles(canvas, size, rnd, hearts: true, glass: true, count: 18);
        break;
      case AppEffectStyle.pearlSandId:
        _paintParticles(canvas, size, rnd, hearts: false, glass: false, count: 22);
        _paintSparkles(canvas, size, rnd, count: 10);
        break;
      default:
        // for new AppEffect ids that map via legacy compat
        _paintParticles(canvas, size, rnd, hearts: false, glass: false, count: 16);
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
      final r = (90.0 + i * 35) * (0.85 + 0.15 * intensity);
      canvas.drawCircle(
        blobs[i],
        r,
        Paint()
          ..color = Color.lerp(style.primary, style.secondary, i / 3)!
              .withValues(alpha: (0.07 * intensity).clamp(0.04, 0.16))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 42),
      );
    }
  }

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
      final y = size.height * (1.12 - t);
      final x = baseX + math.sin((progress * 2 + phase) * math.pi * 2) * sway;
      final fade = (math.sin(t * math.pi)).clamp(0.2, 1.0);
      final opacity =
          (glass ? 0.42 : 0.32) * intensity * fade + rnd.nextDouble() * 0.1;
      final s = (glass ? 16.0 : 12.0) + rnd.nextDouble() * (glass ? 16 : 12);

      if (hearts) {
        if (glass) {
          final glow = Paint()
            ..color = style.secondary
                .withValues(alpha: (opacity * 0.45).clamp(0, 0.55))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
          canvas.drawCircle(
            Offset(x + s * 0.35, y + s * 0.35),
            s * 0.7,
            glow,
          );
        }
        tp.text = TextSpan(
          text: i.isEven ? '♥' : '♡',
          style: TextStyle(
            color: Color.lerp(style.primary, style.secondary, rnd.nextDouble())!
                .withValues(alpha: opacity.clamp(0.25, 0.85)),
            fontSize: s,
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: glass ? 0.45 : 0.2),
                blurRadius: glass ? 14 : 6,
              ),
              Shadow(
                color: style.primary.withValues(alpha: 0.55),
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
      } else {
        final p = Paint()
          ..color = style.primary.withValues(alpha: opacity.clamp(0.2, 0.75))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        final rr = 1.8 + rnd.nextDouble() * 3.2 * intensity;
        canvas.drawCircle(Offset(x, y), rr, p);
        canvas.drawCircle(
          Offset(x, y),
          rr * 2.2,
          Paint()
            ..color = style.secondary.withValues(alpha: opacity * 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }
  }

  void _paintSparkles(
    Canvas canvas,
    Size size,
    math.Random rnd, {
    int count = 22,
  }) {
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final yBase = rnd.nextDouble() * size.height;
      final drift = math.sin(progress * math.pi * 2 + i) * 18;
      final y = (yBase + drift) % size.height;
      final tw =
          0.45 + 0.55 * math.sin((progress * math.pi * 4) + i * 0.9);
      final o = (0.22 + tw * 0.45) * intensity;
      final r = 1.6 + rnd.nextDouble() * 2.8 * tw * intensity;
      final c = Color.lerp(style.primary, style.secondary, rnd.nextDouble())!
          .withValues(alpha: o.clamp(0.2, 0.9));
      final p = Paint()..color = c;
      canvas.drawCircle(Offset(x, y), r, p);

      final sp = Paint()
        ..color = c
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      final arm = 5.0 + tw * 5;
      canvas.drawLine(Offset(x - arm, y), Offset(x + arm, y), sp);
      canvas.drawLine(Offset(x, y - arm), Offset(x, y + arm), sp);
      if (i % 2 == 0) {
        canvas.drawLine(
          Offset(x - arm * 0.6, y - arm * 0.6),
          Offset(x + arm * 0.6, y + arm * 0.6),
          sp..strokeWidth = 1,
        );
      }
    }
  }

  void _paintStars(Canvas canvas, Size size, math.Random rnd) {
    for (var i = 0; i < 42; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final tw = 0.35 +
          0.65 *
              ((math.sin(progress * math.pi * 2 * (1.2 + i % 3 * 0.2) + i) +
                      1) /
                  2);
      final o = (0.25 + tw * 0.5) * intensity;
      final p = Paint()
        ..color = Color.lerp(style.primary, Colors.white, tw * 0.55)!
            .withValues(alpha: o.clamp(0.2, 0.95));
      canvas.drawCircle(Offset(x, y), 1.2 + tw * 2.4, p);
      if (i % 4 == 0) {
        final sp = Paint()
          ..color = p.color
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round;
        final a = 3.5 + tw * 3;
        canvas.drawLine(Offset(x - a, y), Offset(x + a, y), sp);
        canvas.drawLine(Offset(x, y - a), Offset(x, y + a), sp);
      }
    }
    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.15 + i * 0.22);
      final y = size.height *
          (0.2 + 0.25 * math.sin(progress * math.pi * 2 + i));
      canvas.drawCircle(
        Offset(x, y),
        55 + i * 14,
        Paint()
          ..color = style.primary.withValues(alpha: 0.08 * intensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36),
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