import 'package:flutter/material.dart';

/// دوربین تزئینی شبیه رفرنس: بدنه mint + گریپ مشکی + لنز چندلایه
class GuestCameraVisual extends StatelessWidget {
  const GuestCameraVisual({
    super.key,
    this.width = 280,
    this.onTap,
    this.pressed = false,
  });

  final double width;
  final VoidCallback? onTap;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    final h = width * 0.52;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: width,
          height: h + 12,
          child: CustomPaint(
            painter: _CameraPainter(),
            size: Size(width, h + 12),
          ),
        ),
      ),
    );
  }
}

class _CameraPainter extends CustomPainter {
  // رنگ‌ها نزدیک رفرنس
  static const mint = Color(0xFF9BB8A8);
  static const mintDeep = Color(0xFF7F9E90);
  static const mintHi = Color(0xFFB7D0C4);
  static const grip = Color(0xFF2A2A2E);
  static const gripHi = Color(0xFF3A3A40);
  static const lensBlack = Color(0xFF1A1A1E);
  static const glass = Color(0xFF2C3338);
  static const glassHi = Color(0xFF5A6A72);
  static const accentDot = Color(0xFFD4A574);
  static const redDot = Color(0xFFC45C5C);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height - 8;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 8, w, h),
      const Radius.circular(18),
    );

    // سایه
    canvas.drawRRect(
      body.shift(const Offset(0, 6)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // بدنه mint
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [mintHi, mint, mintDeep],
      ).createShader(Rect.fromLTWH(0, 8, w, h));
    canvas.drawRRect(body, bodyPaint);

    // لبه ملایم
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.14),
    );

    final gripW = w * 0.16;
    final gripR = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 8, gripW, h),
      const Radius.circular(18),
    );
    final gripL = RRect.fromRectAndRadius(
      Rect.fromLTWH(w - gripW, 8, gripW, h),
      const Radius.circular(18),
    );

    final gripPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF1E1E22), grip, gripHi],
      ).createShader(Rect.fromLTWH(0, 8, gripW, h));

    canvas.drawRRect(gripR, gripPaint);
    canvas.drawRRect(
      gripL,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xFF1E1E22), grip, gripHi],
        ).createShader(Rect.fromLTWH(w - gripW, 8, gripW, h)),
    );

    // بافت گریپ (خطوط ظریف)
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var i = 0; i < 6; i++) {
      final y = 20.0 + i * (h / 7);
      canvas.drawLine(Offset(10, y), Offset(gripW - 10, y), linePaint);
      canvas.drawLine(
        Offset(w - gripW + 10, y),
        Offset(w - 10, y),
        linePaint,
      );
    }

    // نوار بالای بدنه (پل ویزور)
    final topY = 8 + h * 0.12;
    final topH = h * 0.22;
    final topRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(gripW + 8, topY, w - gripW * 2 - 16, topH),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      topRect,
      Paint()..color = mintDeep.withValues(alpha: 0.55),
    );

    // نقطه چپ (نارنجی/چرم)
    final dot1 = Offset(gripW + 22, topY + topH / 2);
    canvas.drawCircle(dot1, 6, Paint()..color = accentDot);
    canvas.drawCircle(
      dot1,
      6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black26,
    );

    // ویزور چپ
    _viewfinder(canvas, Offset(gripW + 48, topY + topH / 2), 13);
    // فلش وسط
    _flash(canvas, Offset(w / 2 - 10, topY + topH / 2 - 2));
    // ویزور راست (کمی بزرگ‌تر)
    _viewfinder(canvas, Offset(w - gripW - 48, topY + topH / 2), 15);

    // دکمه شاتر روی گریپ راست
    final shutter = Offset(w - gripW / 2, 8 + h * 0.38);
    canvas.drawCircle(shutter, 11, Paint()..color = const Color(0xFF4A4A52));
    canvas.drawCircle(shutter, 7.5, Paint()..color = const Color(0xFF2E2E34));
    canvas.drawCircle(
      shutter.translate(-1.5, -1.5),
      3,
      Paint()..color = Colors.white24,
    );

    // دکمه کوچک پایین راست بدنه mint
    final smallBtn = Offset(w - gripW - 18, 8 + h * 0.72);
    canvas.drawCircle(smallBtn, 5, Paint()..color = grip);
    canvas.drawCircle(smallBtn, 2.5, Paint()..color = const Color(0xFF5A5A62));

    // —— لنز بزرگ وسط ——
    final lensC = Offset(w / 2, 8 + h * 0.62);
    final r0 = h * 0.34;

    // Outer ring
    canvas.drawCircle(lensC, r0 + 6, Paint()..color = const Color(0xFF3D3D44));
    canvas.drawCircle(lensC, r0 + 3, Paint()..color = const Color(0xFF2A2A30));
    canvas.drawCircle(lensC, r0, Paint()..color = lensBlack);

    // Metal ring
    canvas.drawCircle(
      lensC,
      r0 * 0.82,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = const Color(0xFF4E4E56),
    );
    canvas.drawCircle(
      lensC,
      r0 * 0.72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF6A6A72),
    );

    // Glass
    final glassR = r0 * 0.62;
    canvas.drawCircle(
      lensC,
      glassR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            glassHi.withValues(alpha: 0.85),
            glass,
            const Color(0xFF15181C),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: lensC, radius: glassR)),
    );

    // Inner iris
    canvas.drawCircle(lensC, glassR * 0.42, Paint()..color = const Color(0xFF0E1014));
    canvas.drawCircle(
      lensC,
      glassR * 0.22,
      Paint()..color = const Color(0xFF1A2228),
    );

    // Reflect highlight
    final hi = Path()
      ..addOval(
        Rect.fromCenter(
          center: lensC.translate(-glassR * 0.28, -glassR * 0.28),
          width: glassR * 0.55,
          height: glassR * 0.28,
        ),
      );
    canvas.drawPath(
      hi,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    // نقطه قرمز کوچک روی گریپ چپ (مثل رکورد/برند)
    canvas.drawCircle(
      Offset(gripW / 2, 8 + h * 0.22),
      3.2,
      Paint()..color = redDot,
    );
  }

  void _viewfinder(Canvas canvas, Offset c, double r) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: r * 2.1, height: r * 1.6),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFF1C1C20));
    canvas.drawRRect(
      rect.deflate(2.2),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6A7A82).withValues(alpha: 0.7),
            const Color(0xFF2A3036),
          ],
        ).createShader(rect.outerRect),
    );
    canvas.drawCircle(
      c.translate(-r * 0.15, -r * 0.1),
      r * 0.2,
      Paint()..color = Colors.white24,
    );
  }

  void _flash(Canvas canvas, Offset c) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(c.dx, c.dy, 22, 12),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFF2A2A2E));
    // خطوط فلش
    final p = Paint()
      ..color = const Color(0xFFC5C8CE)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 4; i++) {
      final x = c.dx + 4 + i * 4.2;
      canvas.drawLine(Offset(x, c.dy + 3), Offset(x, c.dy + 9), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}