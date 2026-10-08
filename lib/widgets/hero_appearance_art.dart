// hero_appearance_art.dart
// نقاشی بنرهای ادیتوریال و قلب‌های مخملی برای «ظاهر کارت خانه»
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/hero_styles.dart';

// ───────────────────────── ابزارهای مشترک ─────────────────────────

Color _lighten(Color c, double a) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness + a).clamp(0.0, 1.0)).toColor();
}

Color _darken(Color c, double a) => _lighten(c, -a);

Paint _fill(Color c) => Paint()..color = c;

Paint _stroke(Color c, double w) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..color = c;

Path _dashed(Path src, double dash, double gap) {
  final out = Path();
  for (final m in src.computeMetrics()) {
    double d = 0;
    while (d < m.length) {
      out.addPath(m.extractPath(d, math.min(d + dash, m.length)), Offset.zero);
      d += dash + gap;
    }
  }
  return out;
}

void _star(Canvas c, Offset p, double r, int pts, Paint paint,
    {double inner = 0.42}) {
  final path = Path();
  for (int i = 0; i < pts * 2; i++) {
    final rad = i.isEven ? r : r * inner;
    final a = -math.pi / 2 + i * math.pi / pts;
    final pt = Offset(p.dx + rad * math.cos(a), p.dy + rad * math.sin(a));
    i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
  }
  path.close();
  c.drawPath(path, paint);
}

// ───────────────────────── بنر ─────────────────────────

class HeroBannerArtPainter extends CustomPainter {
  final HeroBannerOption o;
  const HeroBannerArtPainter(this.o);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    if (o.id == 'none') {
      _none(canvas, s);
      return;
    }
    final dark = o.gradient.first.computeLuminance() < 0.35;
    final ink = o.archTint;
    final full = Offset.zero & s;

    // پس‌زمینه ابریشمی: گرادیان شعاعی + هاله نور بالا-چپ
    canvas.drawRect(
      full,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.55),
          radius: 1.3,
          colors: o.gradient,
        ).createShader(full),
    );
    canvas.drawRect(
      full,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.6, -0.8),
          radius: 0.9,
          colors: [
            Colors.white.withValues(alpha: dark ? 0.12 : 0.35),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(full),
    );

    // قوس
    final ah = h * 0.62;
    final aw = math.min(w * 0.56, ah * 0.8);
    final a = Rect.fromLTWH((w - aw) / 2, h * 0.2, aw, ah);
    final arch = RRect.fromRectAndCorners(
      a,
      topLeft: Radius.circular(aw / 2),
      topRight: Radius.circular(aw / 2),
      bottomLeft: Radius.circular(aw * 0.1),
      bottomRight: Radius.circular(aw * 0.1),
    );

    // سایه نرم زیر قوس
    canvas.drawRRect(
      arch.shift(Offset(0, h * 0.04)),
      Paint()
        ..color = Colors.black.withValues(alpha: dark ? 0.42 : 0.16)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.06),
    );

    // پرده شیشه‌ای داخل قوس
    canvas.drawRRect(
      arch,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: dark ? 0.10 : 0.38),
            Colors.white.withValues(alpha: dark ? 0.02 : 0.06),
          ],
        ).createShader(a),
    );

    // قاب دوبل (ضخیم‌تر بیرونی + مویی درونی)
    final sw = math.max(0.9, w * 0.016);
    canvas.drawRRect(arch, _stroke(ink.withValues(alpha: 0.95), sw));
    canvas.drawRRect(
      arch.deflate(aw * 0.07),
      _stroke((dark ? Colors.white : ink).withValues(alpha: 0.5), sw * 0.7),
    );

    // نقطه بالای قوس (مروارید برای ابریشم عاجی، طلا برای بقیه)
    final dot = Offset(w / 2, a.top - h * 0.065);
    if (o.id == 'silkIvory') {
      canvas.drawCircle(dot, w * 0.022, _fill(Colors.white));
      canvas.drawCircle(dot, w * 0.022, _stroke(ink, sw * 0.6));
    } else {
      canvas.drawCircle(dot, w * 0.018, _fill(ink));
    }

    canvas.save();
    canvas.clipRRect(arch);
    _motif(canvas, a, ink, dark);
    canvas.restore();
  }

  Path _rhombus(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy - r)
    ..lineTo(c.dx + r * 0.75, c.dy)
    ..lineTo(c.dx, c.dy + r)
    ..lineTo(c.dx - r * 0.75, c.dy)
    ..close();

  void _spiral(Canvas c, Offset o, double size, double dx, double dy, Color col) {
    final p = Path();
    for (double t = 0; t <= 1.0; t += 0.04) {
      final ang = t * 4.6;
      final r = size * t;
      final pt = Offset(o.dx + dx * r * math.cos(ang), o.dy + dy * r * math.sin(ang));
      t == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    c.drawPath(p, _stroke(col, 1.1));
  }

  void _motif(Canvas c, Rect a, Color ink, bool dark) {
    final ctr = Offset(a.center.dx, a.top + a.height * 0.54);
    final u = a.width;
    switch (o.id) {
      case 'silkIvory':
        {
          c.drawCircle(
            ctr,
            u * 0.4,
            Paint()
              ..shader = RadialGradient(colors: [
                Colors.white.withValues(alpha: 0.85),
                Colors.white.withValues(alpha: 0),
              ]).createShader(Rect.fromCircle(center: ctr, radius: u * 0.4)),
          );
          _star(c, ctr, u * 0.13, 4, _fill(ink), inner: 0.3);
          _star(c, ctr.translate(u * 0.2, -u * 0.2), u * 0.05, 4,
              _fill(ink.withValues(alpha: 0.7)), inner: 0.3);
          break;
        }
      case 'midnightGold':
        {
          final r = u * 0.2;
          c.drawPath(_rhombus(ctr, r), _stroke(ink, 1.3));
          c.drawPath(_rhombus(ctr, r * 0.55), _fill(ink.withValues(alpha: 0.3)));
          c.drawPath(_rhombus(ctr, r * 0.55), _stroke(ink, 0.9));
          for (final d in [
            const Offset(0, -1), const Offset(0, 1),
            const Offset(-1, 0), const Offset(1, 0),
          ]) {
            c.drawLine(
              ctr + Offset(d.dx * r * (d.dx == 0 ? 1.25 : 1.05),
                  d.dy * r * 1.25),
              ctr + Offset(d.dx * r * (d.dx == 0 ? 1.55 : 1.35),
                  d.dy * r * 1.55),
              _stroke(ink.withValues(alpha: 0.8), 1),
            );
          }
          break;
        }
      case 'blushBloom':
        {
          c.drawOval(
            Rect.fromCenter(center: ctr, width: u * 0.62, height: u * 0.8),
            _fill(Colors.white.withValues(alpha: 0.25)),
          );
          for (int i = 0; i < 5; i++) {
            c.save();
            c.translate(ctr.dx, ctr.dy);
            c.rotate(i * 2 * math.pi / 5);
            final pr = Rect.fromCenter(
                center: Offset(0, -u * 0.12), width: u * 0.14, height: u * 0.24);
            c.drawOval(pr, _fill(Colors.white.withValues(alpha: 0.75)));
            c.drawOval(pr, _stroke(ink.withValues(alpha: 0.8), 0.9));
            c.restore();
          }
          c.drawCircle(ctr, u * 0.04, _fill(ink));
          break;
        }
      case 'sageWhisper':
        {
          final rr = u * 0.22;
          c.drawCircle(ctr, rr, _stroke(ink.withValues(alpha: 0.45), 0.9));
          for (int i = 0; i < 12; i++) {
            final ang = i * 2 * math.pi / 12;
            final p = ctr + Offset(math.cos(ang), math.sin(ang)) * rr;
            c.save();
            c.translate(p.dx, p.dy);
            c.rotate(ang + math.pi / 2);
            c.drawOval(
              Rect.fromCenter(center: Offset.zero, width: u * 0.13, height: u * 0.05),
              _fill(ink.withValues(alpha: i.isEven ? 0.85 : 0.55)),
            );
            c.restore();
          }
          break;
        }
      case 'terracottaDune':
        {
          for (double y = a.top + a.height * 0.12; y < a.bottom; y += a.height * 0.06) {
            c.drawLine(Offset(a.left, y), Offset(a.right, y),
                _stroke(ink.withValues(alpha: 0.22), 0.8));
          }
          for (final k in [-1.0, 0.0, 1.0]) {
            final base = Offset(ctr.dx + k * u * 0.06, a.bottom - a.height * 0.14);
            final tip = Offset(ctr.dx + k * u * 0.24, ctr.dy - a.height * 0.1);
            final p = Path()
              ..moveTo(base.dx, base.dy)
              ..quadraticBezierTo(ctr.dx + k * u * 0.04, ctr.dy, tip.dx, tip.dy);
            c.drawPath(p, _stroke(ink.withValues(alpha: 0.9), 1.1));
            c.drawCircle(tip, u * 0.028, _fill(ink.withValues(alpha: 0.55)));
          }
          break;
        }
      case 'oliveLinen':
        {
          for (double x = a.left; x < a.right; x += u * 0.08) {
            c.drawLine(Offset(x, a.top), Offset(x, a.bottom),
                _stroke(ink.withValues(alpha: 0.18), 0.8));
          }
          final stem = Path()
            ..moveTo(ctr.dx - u * 0.12, a.bottom - a.height * 0.14)
            ..quadraticBezierTo(
                ctr.dx - u * 0.02, ctr.dy, ctr.dx + u * 0.1, a.top + a.height * 0.28);
          c.drawPath(stem, _stroke(ink, 1.2));
          final m = stem.computeMetrics().first;
          for (int i = 1; i <= 6; i++) {
            final t = m.getTangentForOffset(m.length * i / 7);
            if (t == null) continue;
            final side = i.isEven ? 1.0 : -1.0;
            c.save();
            c.translate(t.position.dx, t.position.dy);
            c.rotate(t.angle + side * 0.9);
            c.drawOval(Rect.fromLTWH(0, -u * 0.03, u * 0.14, u * 0.06),
                _fill(ink.withValues(alpha: 0.85)));
            c.restore();
          }
          break;
        }
      case 'persianCrimson':
        {
          final col = ink.withValues(alpha: 0.9);
          final topY = a.top + a.height * 0.34;
          final botY = a.bottom - a.height * 0.12;
          _spiral(c, Offset(a.left + u * 0.2, topY), u * 0.12, 1, 1, col);
          _spiral(c, Offset(a.right - u * 0.2, topY), u * 0.12, -1, 1, col);
          _spiral(c, Offset(a.left + u * 0.2, botY), u * 0.12, 1, -1, col);
          _spiral(c, Offset(a.right - u * 0.2, botY), u * 0.12, -1, -1, col);
          _star(c, ctr, u * 0.11, 8, _fill(col), inner: 0.55);
          break;
        }
      case 'turquoiseCourt':
        {
          final iv = ink;
          final p = Path()
            ..moveTo(ctr.dx - u * 0.2, a.bottom - a.height * 0.12)
            ..lineTo(ctr.dx - u * 0.2, ctr.dy)
            ..quadraticBezierTo(ctr.dx - u * 0.18, a.top + a.height * 0.3,
                ctr.dx, a.top + a.height * 0.2)
            ..quadraticBezierTo(ctr.dx + u * 0.18, a.top + a.height * 0.3,
                ctr.dx + u * 0.2, ctr.dy)
            ..lineTo(ctr.dx + u * 0.2, a.bottom - a.height * 0.12)
            ..close();
          c.drawPath(p, _fill(iv.withValues(alpha: 0.14)));
          c.drawPath(p, _stroke(iv.withValues(alpha: 0.95), 1.4));
          c.drawCircle(Offset(ctr.dx, a.top + a.height * 0.2 + u * 0.06),
              u * 0.025, _fill(iv));
          break;
        }
    }
  }

  void _none(Canvas c, Size s) {
    final full = Offset.zero & s;
    c.drawRect(full, _fill(const Color(0xFF2B2C31)));
    final ctr = s.center(Offset.zero);
    final r = s.width * 0.2;
    final col = const Color(0xFFB8B3AA).withValues(alpha: 0.8);
    c.drawCircle(ctr, r, _stroke(col, 1.8));
    final d = r * math.sqrt1_2;
    c.drawLine(ctr + Offset(-d, -d), ctr + Offset(d, d), _stroke(col, 1.8));
  }

  @override
  bool shouldRepaint(covariant HeroBannerArtPainter old) => old.o.id != o.id;
}

// ───────────────────────── قلب ─────────────────────────

Path _heart(Rect r) {
  final w = r.width, h = r.height, x = r.left, y = r.top;
  return Path()
    ..moveTo(x + w * 0.5, y + h * 0.95)
    ..cubicTo(x + w * 0.05, y + h * 0.62, x - w * 0.02, y + h * 0.22,
        x + w * 0.25, y + h * 0.12)
    ..cubicTo(x + w * 0.40, y + h * 0.07, x + w * 0.5, y + h * 0.18,
        x + w * 0.5, y + h * 0.28)
    ..cubicTo(x + w * 0.5, y + h * 0.18, x + w * 0.60, y + h * 0.07,
        x + w * 0.75, y + h * 0.12)
    ..cubicTo(x + w * 1.02, y + h * 0.22, x + w * 0.95, y + h * 0.62,
        x + w * 0.5, y + h * 0.95)
    ..close();
}

void _bow(Canvas c, Offset p, double size, Color fill, Color edge) {
  for (final side in [-1.0, 1.0]) {
    final wing = Path()
      ..moveTo(p.dx, p.dy)
      ..cubicTo(p.dx + side * size * 0.95, p.dy - size * 0.75,
          p.dx + side * size * 1.05, p.dy + size * 0.75, p.dx, p.dy);
    c.drawPath(wing, _fill(fill));
    c.drawPath(wing, _stroke(edge, 0.9));
  }
  c.drawCircle(p, size * 0.2, _fill(fill));
  c.drawCircle(p, size * 0.2, _stroke(edge, 0.9));
}

class HeroHeartArtPainter extends CustomPainter {
  final HeroHeartOption o;
  const HeroHeartArtPainter(this.o);

  @override
  void paint(Canvas canvas, Size s) {
    final r = Rect.fromLTWH(s.width * 0.1, s.height * 0.14, s.width * 0.8, s.height * 0.72);
    final path = _heart(r);
    final base = o.base, acc = o.accent;

    // هاله سفید پشت قلب آبرنگی
    if (o.style == HeartStyle.skyWatercolor) {
      canvas.drawCircle(
        r.center,
        r.width * 0.62,
        Paint()
          ..shader = RadialGradient(colors: [
            Colors.white.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: r.center, radius: r.width * 0.62)),
      );
    }

    // سایه نرم
    canvas.drawPath(
      path.shift(Offset(0, r.height * 0.1)),
      Paint()
        ..color = _darken(base, 0.25).withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r.width * 0.12),
    );

    // بدنه مخملی: گرادیان عمودی
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_lighten(base, 0.1), base, _darken(base, 0.16)],
        ).createShader(r),
    );

    canvas.save();
    canvas.clipPath(path);
    // هایلایت ابریشمی بالا-چپ
    canvas.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.5, -0.65),
          radius: 0.9,
          colors: [
            Colors.white.withValues(alpha: 0.38),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(r),
    );
    _texture(canvas, r);
    canvas.restore();

    // لبه
    canvas.drawPath(path, _stroke(_darken(base, 0.2).withValues(alpha: 0.5), 0.8));

    // دوخت دَش
    final inset = _heart(r.deflate(r.width * 0.07));
    final thick = o.style == HeartStyle.crimsonGold;
    canvas.drawPath(
      _dashed(inset, r.width * 0.05, r.width * 0.035),
      _stroke(acc.withValues(alpha: 0.9), thick ? 1.8 : 1.0),
    );

    _extras(canvas, r, inset);
  }

  void _texture(Canvas c, Rect r) {
    switch (o.style) {
      case HeartStyle.blushSuede:
        final rnd = math.Random(7);
        for (int i = 0; i < 90; i++) {
          final p = Offset(r.left + rnd.nextDouble() * r.width,
              r.top + rnd.nextDouble() * r.height);
          c.drawCircle(p, 0.6,
              _fill((i.isEven ? Colors.white : Colors.black).withValues(alpha: 0.1)));
        }
        break;
      case HeartStyle.sageLinen:
        final step = r.width * 0.05;
        for (double x = r.left; x < r.right; x += step) {
          c.drawLine(Offset(x, r.top), Offset(x, r.bottom),
              _stroke(Colors.white.withValues(alpha: 0.12), 0.6));
        }
        for (double y = r.top; y < r.bottom; y += step) {
          c.drawLine(Offset(r.left, y), Offset(r.right, y),
              _stroke(Colors.white.withValues(alpha: 0.12), 0.6));
        }
        break;
      case HeartStyle.skyWatercolor:
        c.drawCircle(r.center.translate(-r.width * 0.15, -r.height * 0.05),
            r.width * 0.28, _fill(Colors.white.withValues(alpha: 0.22)));
        c.drawCircle(r.center.translate(r.width * 0.2, r.height * 0.12),
            r.width * 0.22, _fill(o.accent.withValues(alpha: 0.28)));
        break;
      default:
        break;
    }
  }

  void _scallops(Canvas c, Path inset, Rect r, Color col) {
    for (final m in inset.computeMetrics()) {
      final n = 22;
      for (int i = 0; i < n; i++) {
        final t = m.getTangentForOffset(m.length * i / n);
        if (t == null) continue;
        c.drawCircle(t.position, r.width * 0.028,
            _stroke(col.withValues(alpha: 0.55), 0.9));
      }
    }
  }

  void _extras(Canvas c, Rect r, Path inset) {
    final bowPos = Offset(r.center.dx, r.top + r.height * 0.3);
    switch (o.style) {
      case HeartStyle.pearlSatin:
        _bow(c, bowPos, r.width * 0.13, const Color(0xFFF3E9DA), o.accent.withValues(alpha: 0.85));
        break;
      case HeartStyle.noirVelvet:
        _star(c, r.center.translate(0, -r.height * 0.02), r.width * 0.11, 5,
            _fill(o.accent), inner: 0.45);
        break;
      case HeartStyle.terracottaRuffle:
        _scallops(c, inset, r, const Color(0xFFFFF1DC));
        _bow(c, bowPos, r.width * 0.12, const Color(0xFFF7E6CC), o.accent);
        break;
      case HeartStyle.sageLinen:
        _scallops(c, inset, r, const Color(0xFFE7F0E4));
        break;
      case HeartStyle.persianTurquoise:
        for (final p in const [
          Offset(0.26, 0.30), Offset(0.74, 0.30),
          Offset(0.38, 0.62), Offset(0.62, 0.62),
        ]) {
          _star(c, Offset(r.left + r.width * p.dx, r.top + r.height * p.dy),
              r.width * 0.065, 4, _fill(o.accent), inner: 0.35);
        }
        break;
      case HeartStyle.crimsonGold:
        _bow(c, bowPos, r.width * 0.13, const Color(0xFFF2DFC4), o.accent);
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant HeroHeartArtPainter old) => old.o.id != o.id;
}

// ───────────────────────── ویجت‌های آماده Picker ─────────────────────────

const _kSelected = Color(0xFFE0C097);

class HeroBannerThumb extends StatelessWidget {
  final HeroBannerOption option;
  final bool selected;
  final VoidCallback? onTap;
  final double width, height;
  const HeroBannerThumb({
    super.key,
    required this.option,
    this.selected = false,
    this.onTap,
    this.width = 64,
    this.height = 74,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.04 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? _kSelected : Colors.transparent, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: CustomPaint(
              size: Size.infinite,
              painter: HeroBannerArtPainter(option),
            ),
          ),
        ),
      ),
    );
  }
}

class HeroHeartThumb extends StatelessWidget {
  final HeroHeartOption option;
  final bool selected;
  final VoidCallback? onTap;
  final double width, height;
  const HeroHeartThumb({
    super.key,
    required this.option,
    this.selected = false,
    this.onTap,
    this.width = 64,
    this.height = 64,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.04 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF222328),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? _kSelected : const Color(0xFF34353B),
                width: selected ? 2 : 1),
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: HeroHeartArtPainter(option),
          ),
        ),
      ),
    );
  }
}
