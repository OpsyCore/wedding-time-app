// hero_appearance_art.dart
// پورت Flutter از Reactِ حرفه‌ایِ انتخاب‌گر بنر/قلب + قلب دوآواتاره (عکس ارسالی)
// React منبع: BANNERS/HEARTS با BannerMotif/HeartVisual + Framer-Motion pickers
// نگاشت 1:1 به Canvas فلکس — گرادیان‌ها/رنگ‌ها از hero_styles.dart همگام با React
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/hero_styles.dart';

// ───────────────────────── ابزار ─────────────────────────
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

void _star(Canvas c, Offset p, double r, int pts, Paint paint, {double inner = 0.42}) {
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

Path _diamondPath(Offset c, double r) => Path()
  ..moveTo(c.dx, c.dy - r)
  ..lineTo(c.dx + r * 0.70, c.dy)
  ..lineTo(c.dx, c.dy + r)
  ..lineTo(c.dx - r * 0.70, c.dy)
  ..close();

// ───────────────────────── بنر — نقاش ادیتوریال (React BannerVisual → Flutter) ─────────────────────────
// React: radial gradient 50% 5%, overlay white 10% 0%, arch double border, clip 78,54,164,186 + BannerMotif
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
    // glow از React — برای هاله آخر (silkIvory -> #fff6e8, midnight -> #4f5e83, ...)
    final glow = _glowFor(o.id);
    final full = Offset.zero & s;

    // 1) پس‌زمینه شعاعی — React: radial-gradient(circle at 50% 5%, gradient[0] → gradient[1] 90%)
    canvas.drawRect(
      full,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.9),
          radius: 1.45,
          colors: o.gradient.length >= 2 ? [o.gradient.first, o.gradient.last] : o.gradient,
          stops: o.gradient.length >= 2 ? const [0.0, 1.0] : null,
        ).createShader(full),
    );
    // 2) هایلایت سفید بالا-چپ — React: radial at 10% 0% white 0.35/0.15
    canvas.drawRect(
      full,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.8, -1.0),
          radius: 0.95,
          colors: [Colors.white.withValues(alpha: dark ? 0.15 : 0.35), Colors.transparent],
        ).createShader(full),
    );
    // ابعاد قوس — React: inset-x 24% top 19% h 67% (mini: 22%/20%/66%) با round 999px
    final ah = h * 0.67;
    final aw = math.min(w * 0.52, ah * 0.88); // معادل 164/186 نسبت
    final a = Rect.fromLTWH((w - aw) / 2, h * 0.19, aw, ah);
    final arch = RRect.fromRectAndCorners(
      a,
      topLeft: Radius.circular(aw / 2),
      topRight: Radius.circular(aw / 2),
      bottomLeft: Radius.circular(aw * 0.10),
      bottomRight: Radius.circular(aw * 0.10),
    );
    // سایه نرم زیر قوس — React: shadow-[0_20px_28px_rgba(0,0,0,0.28)]
    canvas.drawRRect(
      arch.shift(Offset(0, h * 0.035)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.055),
    );
    // پرده شیشه‌ای داخل قوس — linear white 0.45/0.10 (dark 0.12/0.03)
    canvas.drawRRect(
      arch,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: dark ? 0.12 : 0.45), Colors.white.withValues(alpha: dark ? 0.03 : 0.08)],
        ).createShader(a),
    );
    // قاب دوبل — outer 2px ink, inner 1.6px white 0.55 / ink 0.60
    final sw = math.max(0.9, w * 0.014);
    canvas.drawRRect(arch, _stroke(ink.withValues(alpha: 0.98), sw * 1.55));
    canvas.drawRRect(
      arch.deflate(aw * 0.075),
      _stroke((dark ? Colors.white : ink).withValues(alpha: dark ? 0.55 : 0.60), sw),
    );
    // نقطه طلایی بالای قوس — React: left-1/2 top 10% 2.5x2.5 با ink
    final dot = Offset(w / 2, a.top - h * 0.065);
    if (o.id == 'silkIvory') {
      canvas.drawCircle(dot, w * 0.020, _fill(Colors.white));
      canvas.drawCircle(dot, w * 0.020, _stroke(ink, sw * 0.7));
    } else {
      canvas.drawCircle(dot, w * 0.016, _fill(ink));
      canvas.drawCircle(dot, w * 0.016, _stroke(Colors.white.withValues(alpha: 0.9), sw * 0.45));
    }
    // shimmer ابریشمی — React silk-shimmer با glow
    canvas.save();
    canvas.clipRRect(arch);
    canvas.drawRect(
      a,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.8, -0.6),
          end: const Alignment(1, 0.8),
          colors: [Colors.transparent, glow.withValues(alpha: 0.22), Colors.transparent],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(a),
    );
    canvas.restore();

    // موتیف — کلیپ داخل قوس
    canvas.save();
    canvas.clipRRect(arch);
    _motif(canvas, a, ink, dark, glow);
    canvas.restore();
  }

  Color _glowFor(String id) {
    switch (id) {
      case 'silkIvory':
        return const Color(0xFFFFF6E8);
      case 'midnightGold':
        return const Color(0xFF4F5E83);
      case 'blushBloom':
        return const Color(0xFFFDEFF5);
      case 'sageWhisper':
        return const Color(0xFFF2FBF2);
      case 'terracottaDune':
        return const Color(0xFFF9D7BF);
      case 'oliveLinen':
        return const Color(0xFFDCE0BC);
      case 'persianCrimson':
        return const Color(0xFF8F3450);
      case 'turquoiseCourt':
        return const Color(0xFF84E2E8);
      default:
        return Colors.white;
    }
  }

  void _motif(Canvas c, Rect a, Color ink, bool dark, Color glow) {
    final ctr = Offset(a.center.dx, a.top + a.height * 0.56);
    final u = a.width; // واحد مقیاس — معادل ~164 در viewBox 320
    switch (o.id) {
      case 'silkIvory':
        // React: circle 54 white 0.3 at 160,152 + diamond 20 ink + small 8 at 189,132
        c.drawCircle(ctr.translate(0, -a.height * 0.04), u * 0.33, _fill(Colors.white.withValues(alpha: 0.30)));
        c.drawPath(_diamondPath(ctr.translate(0, a.height * 0.02), u * 0.122), _fill(ink));
        c.drawPath(_diamondPath(ctr.translate(u * 0.18, -a.height * 0.11), u * 0.049), _fill(ink.withValues(alpha: 0.75)));
        break;
      case 'midnightGold':
        // React: diamond 30 stroke 1.5 + inner 16 fill 0.2 + cross lines
        final r = u * 0.183; // 30/164
        c.drawPath(_diamondPath(ctr, r), _stroke(ink, u * 0.009));
        c.drawPath(_diamondPath(ctr, r * 0.533), _fill(ink.withValues(alpha: 0.22)));
        c.drawPath(_diamondPath(ctr, r * 0.533), _stroke(ink, u * 0.006));
        for (final dir in [const Offset(0, -1), const Offset(0, 1), const Offset(-1, 0), const Offset(1, 0)]) {
          final start = ctr + Offset(dir.dx * r * 1.05, dir.dy * r * 1.25);
          final end = ctr + Offset(dir.dx * r * 1.45, dir.dy * r * 1.65);
          if (dir.dx != 0) {
            // horizontal: 118→130 و 190→202 در viewBox
            c.drawLine(start, end, _stroke(ink, u * 0.007));
          } else {
            // vertical 112→100 و 208→196
            c.drawLine(start, end, _stroke(ink, u * 0.007));
          }
        }
        break;
      case 'blushBloom':
        // React: ellipse 58x72 white 0.25 + 5 petals 11x23 white 0.82 rotate + center dot r5
        c.drawOval(Rect.fromCenter(center: ctr, width: u * 0.354, height: u * 0.439), _fill(Colors.white.withValues(alpha: 0.25)));
        for (int i = 0; i < 5; i++) {
          c.save();
          c.translate(ctr.dx, ctr.dy);
          c.rotate(i * 2 * math.pi / 5);
          final petal = Rect.fromCenter(center: Offset(0, -u * 0.098), width: u * 0.067, height: u * 0.140);
          c.drawOval(petal, _fill(Colors.white.withValues(alpha: 0.82)));
          c.restore();
        }
        c.drawCircle(ctr, u * 0.030, _fill(ink));
        break;
      case 'sageWhisper':
        // React: circle r38 stroke 0.45 + 12 leaves 8x3
        final rr = u * 0.232; // 38/164
        c.drawCircle(ctr, rr, _stroke(ink.withValues(alpha: 0.45), u * 0.005));
        for (int i = 0; i < 12; i++) {
          final a0 = i * 2 * math.pi / 12;
          final p = ctr + Offset(math.cos(a0), math.sin(a0)) * rr;
          c.save();
          c.translate(p.dx, p.dy);
          c.rotate(a0 + math.pi / 2);
          c.drawOval(Rect.fromCenter(center: Offset.zero, width: u * 0.049, height: u * 0.018), _fill(ink.withValues(alpha: i.isEven ? 0.85 : 0.55)));
          c.restore();
        }
        break;
      case 'terracottaDune':
        // React: 10 lines y 102+14i x94-226 + 3 pampas stems
        for (int i = 0; i < 10; i++) {
          final y = a.top + a.height * 0.12 + i * a.height * 0.05;
          c.drawLine(Offset(a.left, y), Offset(a.right, y), _stroke(ink.withValues(alpha: 0.22), u * 0.005));
        }
        // 3 ساقه پامپاس
        for (final k in [-1.0, 0.0, 1.0]) {
          final base = Offset(ctr.dx + k * u * 0.12, a.bottom - a.height * 0.10);
          final tip = Offset(ctr.dx + k * u * 0.18, a.top + a.height * 0.28);
          final ctrl = Offset(ctr.dx + k * u * 0.06, a.top + a.height * 0.55);
          final p = Path()
            ..moveTo(base.dx, base.dy)
            ..quadraticBezierTo(ctrl.dx, ctrl.dy, tip.dx, tip.dy);
          c.drawPath(p, _stroke(ink, u * 0.0085));
          // خوشه پامپاس در نوک
          for (int j = 0; j < 7; j++) {
            final ang = -math.pi / 2 + (j - 3) * 0.22;
            c.drawLine(tip, tip + Offset(math.cos(ang), math.sin(ang)) * u * 0.04, _stroke(ink.withValues(alpha: 0.55), u * 0.004));
          }
        }
        break;
      case 'oliveLinen':
        // React: 12 vertical lines + stem + 6 leaves
        for (int i = 0; i < 12; i++) {
          final x = a.left + a.width * 0.06 + i * a.width * 0.067;
          c.drawLine(Offset(x, a.top), Offset(x, a.bottom), _stroke(ink.withValues(alpha: 0.20), u * 0.005));
        }
        final stem = Path()
          ..moveTo(ctr.dx - u * 0.18, a.bottom - a.height * 0.08)
          ..quadraticBezierTo(ctr.dx - u * 0.02, a.top + a.height * 0.55, ctr.dx + u * 0.17, a.top + a.height * 0.24);
        c.drawPath(stem, _stroke(ink, u * 0.009));
        // 6 برگ زیتون
        final m = stem.computeMetrics().first;
        for (int i = 1; i <= 6; i++) {
          final t = m.getTangentForOffset(m.length * (0.22 + i * 0.11));
          if (t == null) continue;
          c.save();
          c.translate(t.position.dx, t.position.dy);
          c.rotate(t.angle + (i.isEven ? 0.62 : -0.66));
          c.drawOval(Rect.fromLTWH(0, -u * 0.018, u * 0.085, u * 0.032), _fill(ink));
          c.drawOval(Rect.fromLTWH(0, -u * 0.018, u * 0.085, u * 0.032), _stroke(ink.withValues(alpha: 0.35), u * 0.003));
          c.restore();
        }
        break;
      case 'persianCrimson':
        // React: 4 eslimi spirals + central 8-point star 160,134
        final esOffset = u * 0.20;
        _eslimi(c, Offset(a.left + esOffset, a.top + a.height * 0.26), ink);
        _eslimi(c, Offset(a.right - esOffset, a.top + a.height * 0.26), ink, mirror: true);
        _eslimi(c, Offset(a.left + esOffset, a.bottom - a.height * 0.20), ink, flipY: true);
        _eslimi(c, Offset(a.right - esOffset, a.bottom - a.height * 0.20), ink, mirror: true, flipY: true);
        _star(c, ctr.translate(0, -a.height * 0.085), u * 0.095, 8, _fill(ink), inner: 0.48);
        break;
      case 'turquoiseCourt':
        // React: iwan arch 128-192,162-212 with dome 160,114
        final p = Path()
          ..moveTo(ctr.dx - u * 0.195, a.bottom - a.height * 0.06)
          ..lineTo(ctr.dx - u * 0.195, ctr.dy + a.height * 0.03)
          ..quadraticBezierTo(ctr.dx - u * 0.183, a.top + a.height * 0.22, ctr.dx, a.top + a.height * 0.13)
          ..quadraticBezierTo(ctr.dx + u * 0.183, a.top + a.height * 0.22, ctr.dx + u * 0.195, ctr.dy + a.height * 0.03)
          ..lineTo(ctr.dx + u * 0.195, a.bottom - a.height * 0.06)
          ..close();
        c.drawPath(p, _fill(ink.withValues(alpha: 0.16)));
        c.drawPath(p, _stroke(ink, u * 0.0085));
        c.drawCircle(Offset(ctr.dx, a.top + a.height * 0.24), u * 0.030, _fill(ink));
        // قوس کوچک داخل ایوان
        final innerArch = Path()
          ..moveTo(ctr.dx - u * 0.11, a.bottom - a.height * 0.06)
          ..quadraticBezierTo(ctr.dx, a.top + a.height * 0.30, ctr.dx + u * 0.11, a.bottom - a.height * 0.06);
        c.drawPath(innerArch, _stroke(ink.withValues(alpha: 0.55), u * 0.005));
        break;
    }
  }

  void _eslimi(Canvas c, Offset o, Color col, {bool mirror = false, bool flipY = false}) {
    final sx = mirror ? -1.0 : 1.0;
    final sy = flipY ? -1.0 : 1.0;
    final path = Path()
      ..moveTo(o.dx, o.dy)
      ..cubicTo(o.dx + sx * 24, o.dy + sy * 4, o.dx + sx * 22, o.dy + sy * 16, o.dx + sx * 10, o.dy + sy * 20)
      ..cubicTo(o.dx + sx * 2, o.dy + sy * 18, o.dx + sx * -2, o.dy + sy * 10, o.dx, o.dy);
    c.drawPath(path, _stroke(col, 1.3));
    // dot eslimi
    c.drawCircle(o.translate(sx * 8, sy * 10), 1.2, _fill(col.withValues(alpha: 0.35)));
  }

  void _none(Canvas c, Size s) {
    final full = Offset.zero & s;
    c.drawRect(full, _fill(const Color(0xFF2B2C31)));
    final ctr = s.center(Offset.zero);
    final r = s.width * 0.20;
    final col = const Color(0xFFB8B3AA).withValues(alpha: 0.78);
    c.drawCircle(ctr, r, _stroke(col, 1.9));
    final d = r * math.sqrt1_2;
    c.drawLine(ctr + Offset(-d, -d), ctr + Offset(d, d), _stroke(col, 1.9));
  }

  @override
  bool shouldRepaint(covariant HeroBannerArtPainter old) => old.o.id != o.id;
}

// ───────────────────────── قلب — React HeartVisual → Flutter ─────────────────────────
// heartPath React: 'M50 90 C17 66 8 33 26 20 C37 13 50 24 50 35 C50 24 63 13 74 20 C92 33 83 66 50 90 Z' viewBox 0 0 100 100
Path _heartFromViewBox(Rect r) {
  // نگاشت viewBox 100x100 به Rect r
  Matrix4 m = Matrix4.identity()
    ..translate(r.left, r.top)
    ..scale(r.width / 100, r.height / 100);
  final src = Path()
    ..moveTo(50, 90)
    ..cubicTo(17, 66, 8, 33, 26, 20)
    ..cubicTo(37, 13, 50, 24, 50, 35)
    ..cubicTo(50, 24, 63, 13, 74, 20)
    ..cubicTo(92, 33, 83, 66, 50, 90)
    ..close();
  return src.transform(m.storage);
}

void _bow(Canvas c, Offset p, double size, Color fill, Color edge) {
  for (final side in [-1.0, 1.0]) {
    final wing = Path()
      ..moveTo(p.dx, p.dy)
      ..cubicTo(p.dx + side * size * 0.95, p.dy - size * 0.75, p.dx + side * size * 1.05, p.dy + size * 0.75, p.dx, p.dy);
    c.drawPath(wing, _fill(fill));
    c.drawPath(wing, _stroke(edge, 0.95));
  }
  c.drawCircle(p, size * 0.20, _fill(fill));
  c.drawCircle(p, size * 0.20, _stroke(edge, 0.95));
}

class HeroHeartArtPainter extends CustomPainter {
  final HeroHeartOption o;
  const HeroHeartArtPainter(this.o);

  @override
  void paint(Canvas canvas, Size s) {
    // React: viewBox 100, heart با r 0.8w x 0.72h at 0.1/0.14
    final r = Rect.fromLTWH(s.width * 0.10, s.height * 0.14, s.width * 0.80, s.height * 0.72);
    final path = _heartFromViewBox(r);
    final base = o.base, acc = o.accent;

    // سایه — translate 0,6 opacity 0.36 (در React)
    canvas.drawPath(
      _heartFromViewBox(r.shift(Offset(0, r.height * 0.08))),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.36)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r.width * 0.10),
    );

    // بدنه — React linearGradient #ffffff 0% 0.2 → base 26% → #000 100% 0.36
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.22), base, Colors.black.withValues(alpha: 0.12)],
          stops: const [0.0, 0.32, 1.0],
        ).createShader(r),
    );

    canvas.save();
    canvas.clipPath(path);
    // glow — radial 24% 18% r65% white 0.36→0
    canvas.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.52, -0.64),
          radius: 0.88,
          colors: [Colors.white.withValues(alpha: 0.38), Colors.transparent],
        ).createShader(r),
    );
    _texture(canvas, r);
    canvas.restore();

    // لبه مشکی نازک — React stroke black 0.2 width 1
    canvas.drawPath(path, _stroke(Colors.black.withValues(alpha: 0.18), 0.9));

    // دوخت داش — React M50 84 ... dash 4 3 width 1.4/2.3
    final insetR = Rect.fromLTWH(r.left + r.width * 0.07, r.top + r.height * 0.07, r.width * 0.86, r.height * 0.78);
    final insetPath = _heartFromViewBox(insetR);
    final isCrimson = o.style == HeartStyle.crimsonGold;
    canvas.drawPath(
      _dashed(insetPath, r.width * 0.045, r.width * 0.032),
      _stroke(acc.withValues(alpha: 0.92), isCrimson ? 1.95 : 1.25),
    );

    _extras(canvas, r, insetPath);
  }

  void _texture(Canvas c, Rect r) {
    switch (o.style) {
      case HeartStyle.blushSuede:
        // React: 45 dots grid 8x14 white 0.12
        for (int i = 0; i < 45; i++) {
          final cx = 18 + (i % 9) * 8;
          final cy = 16 + (i ~/ 9) * 14;
          final x = r.left + (cx / 100) * r.width;
          final y = r.top + (cy / 100) * r.height;
          c.drawCircle(Offset(x, y), r.width * 0.009, _fill(Colors.white.withValues(alpha: 0.14)));
        }
        break;
      case HeartStyle.sageLinen:
        // React: grid 8 vertical + 7 horizontal white 0.16 width 0.55
        for (int i = 0; i < 8; i++) {
          final x = r.left + (24 + i * 7) / 100 * r.width;
          c.drawLine(Offset(x, r.top + 0.16 * r.height), Offset(x, r.top + 0.85 * r.height), _stroke(Colors.white.withValues(alpha: 0.16), 0.55));
        }
        for (int i = 0; i < 7; i++) {
          final y = r.top + (23 + i * 9) / 100 * r.height;
          c.drawLine(Offset(r.left + 0.20 * r.width, y), Offset(r.left + 0.80 * r.width, y), _stroke(Colors.white.withValues(alpha: 0.16), 0.55));
        }
        break;
      case HeartStyle.skyWatercolor:
        // React: circle 38,42 r16 white 0.18 + 64,58 r13 accent 0.28
        c.drawCircle(Offset(r.left + 0.38 * r.width, r.top + 0.42 * r.height), r.width * 0.16, _fill(Colors.white.withValues(alpha: 0.18)));
        c.drawCircle(Offset(r.left + 0.64 * r.width, r.top + 0.58 * r.height), r.width * 0.13, _fill(o.accent.withValues(alpha: 0.30)));
        break;
      default:
        break;
    }
  }

  void _extras(Canvas c, Rect r, Path inset) {
    final bowPos = Offset(r.center.dx, r.top + r.height * 0.34);
    switch (o.style) {
      case HeartStyle.pearlSatin:
      case HeartStyle.terracottaRuffle:
      case HeartStyle.crimsonGold:
        // React: ellipse 43,34 8x5 + 57,34 8x5 + circle 50,34 r2.8
        final fill = o.style == HeartStyle.terracottaRuffle ? const Color(0xFFF8E6CA) : const Color(0xFFF4EBE0);
        c.drawOval(Rect.fromCenter(center: Offset(r.left + 0.43 * r.width, r.top + 0.34 * r.height), width: r.width * 0.16, height: r.width * 0.10), _fill(fill));
        c.drawOval(Rect.fromCenter(center: Offset(r.left + 0.57 * r.width, r.top + 0.34 * r.height), width: r.width * 0.16, height: r.width * 0.10), _fill(fill));
        c.drawCircle(Offset(r.left + 0.50 * r.width, r.top + 0.34 * r.height), r.width * 0.028, _fill(const Color(0xFFF5DFBF)));
        c.drawCircle(Offset(r.left + 0.50 * r.width, r.top + 0.34 * r.height), r.width * 0.028, _stroke(o.accent, 0.9));
        if (o.style == HeartStyle.terracottaRuffle) {
          // scallops اضافه — React ندارد اما برای چین
          _scallops(c, inset, r, const Color(0xFFFFF1DC));
        }
        if (o.style != HeartStyle.pearlSatin) {
          // برای terracotta/crimson پاپیون هم
          _bow(c, bowPos.translate(0, r.height * 0.06), r.width * 0.11, const Color(0xFFF7E6CC), o.accent);
        } else {
          _bow(c, bowPos, r.width * 0.12, const Color(0xFFF3E9DA), o.accent.withValues(alpha: 0.85));
        }
        break;
      case HeartStyle.noirVelvet:
        // React: star at 50,42
        _star(c, Offset(r.left + 0.50 * r.width, r.top + 0.44 * r.height), r.width * 0.075, 5, _fill(o.accent), inner: 0.45);
        break;
      case HeartStyle.persianTurquoise:
        // React: 4 stars at 30,28 70,28 40,58 60,58
        for (final p in const [Offset(0.30, 0.30), Offset(0.70, 0.30), Offset(0.40, 0.60), Offset(0.60, 0.60)]) {
          _star(c, Offset(r.left + p.dx * r.width, r.top + p.dy * r.height), r.width * 0.050, 4, _fill(o.accent), inner: 0.38);
        }
        break;
      case HeartStyle.sageLinen:
        _scallops(c, inset, r, const Color(0xFFE7F0E4));
        break;
      default:
        break;
    }
  }

  void _scallops(Canvas c, Path inset, Rect r, Color col) {
    for (final m in inset.computeMetrics()) {
      const n = 24;
      for (int i = 0; i < n; i++) {
        final t = m.getTangentForOffset(m.length * i / n);
        if (t == null) continue;
        c.drawCircle(t.position, r.width * 0.022, _stroke(col.withValues(alpha: 0.55), 0.75));
      }
    }
  }

  @override
  bool shouldRepaint(covariant HeroHeartArtPainter old) => old.o.id != o.id;
}

// ───────────────────────── ویجت‌های Picker (React BannerPicker/HeartPicker → Flutter) ─────────────────────────
// React: motion.button whileHover y-3 scale1.02 tap 0.98, border #e1bc79 shadow 0 0 24 rgba, inner border white/70
const _kSelected = Color(0xFFE1BC79); // React selected '#e1bc79'

class HeroBannerThumb extends StatelessWidget {
  final HeroBannerOption option;
  final bool selected;
  final VoidCallback? onTap;
  final double width, height;
  const HeroBannerThumb({super.key, required this.option, this.selected = false, this.onTap, this.width = 62, this.height = 84});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.03 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? _kSelected : Colors.white.withValues(alpha: 0.20), width: selected ? 1.6 : 1),
            boxShadow: selected ? [BoxShadow(color: _kSelected.withValues(alpha: 0.35), blurRadius: 18)] : null,
          ),
          padding: const EdgeInsets.all(3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.70), width: 1)),
              child: CustomPaint(size: Size.infinite, painter: HeroBannerArtPainter(option)),
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
  const HeroHeartThumb({super.key, required this.option, this.selected = false, this.onTap, this.width = 62, this.height = 62});

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
            color: selected ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? _kSelected : Colors.white.withValues(alpha: 0.15), width: selected ? 1.4 : 1),
            boxShadow: selected ? [BoxShadow(color: _kSelected.withValues(alpha: 0.35), blurRadius: 18)] : null,
          ),
          child: CustomPaint(size: Size.infinite, painter: HeroHeartArtPainter(option)),
        ),
      ),
    );
  }
}

// ───────────────────────── قلب دو آواتاره — کدِ عکس ارسالی (S+S روی قلب) ─────────────────────────
// Flutter معادل _buildHeroPhoto در public_invite_screen.dart — دقیقا تصویر: قلب صورتی پشت + دو دایره S + قلب کوچیک وسط با پالس
class HeroCoupleHeart extends StatefulWidget {
  final String groomName;
  final String brideName;
  final String groomPhotoUrl;
  final String bridePhotoUrl;
  const HeroCoupleHeart({super.key, required this.groomName, required this.brideName, this.groomPhotoUrl = '', this.bridePhotoUrl = ''});
  @override
  State<HeroCoupleHeart> createState() => _HeroCoupleHeartState();
}

class _HeroCoupleHeartState extends State<HeroCoupleHeart> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String _initial(String s) => s.trim().isEmpty ? '♥' : String.fromCharCode(s.trim().runes.first);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 232,
      child: Center(
        child: AnimatedBuilder(
          animation: _pulse,
          child: SizedBox(
            width: 270,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.favorite_rounded, size: 218, color: Color(0xB8F8D8E0)),
                const Icon(Icons.favorite_border_rounded, size: 222, color: Color(0xDBF0A0B8)),
                Positioned(
                  top: 74,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _avatar(widget.groomPhotoUrl, _initial(widget.groomName)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xDBFFFBF0),
                            border: Border.all(color: const Color(0xB8D4AF37)),
                          ),
                          child: const Icon(Icons.favorite_rounded, color: Color(0xFFE8B4C2), size: 15),
                        ),
                      ),
                      _avatar(widget.bridePhotoUrl, _initial(widget.brideName)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          builder: (context, child) => Transform.scale(scale: 1 + _pulse.value * 0.06, child: child),
        ),
      ),
    );
  }

  Widget _avatar(String url, String initial) {
    return Container(
      width: 82,
      height: 82,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xE0FFFBF0),
        border: Border.all(color: const Color(0xF2C7D8C4), width: 1.4),
        boxShadow: [BoxShadow(color: const Color(0x1F1A4D2E), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipOval(
        child: url.trim().isEmpty
            ? _initialWidget(initial)
            : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initialWidget(initial)),
      ),
    );
  }

  Widget _initialWidget(String initial) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFFBF0), Color(0xFFC7D8C4), Color(0xFFF8D8E0)]),
      ),
      alignment: Alignment.center,
      child: Text(initial, style: const TextStyle(fontFamily: 'serif', color: Color(0xFF2B2C31), fontSize: 27, fontWeight: FontWeight.w700)),
    );
  }
}
