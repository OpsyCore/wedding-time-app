import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../core/app_effect.dart';
import '../core/app_effect_controller.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../core/app_lang.dart';

/// Very light glass + gradient background
/// - low opacity gradient (0.08 - 0.16)
/// - optional mild blur (skip heavy blur on web)
/// - works with light & dark via AppTok
class EffectBackground extends StatelessWidget {
  const EffectBackground({
    super.key,
    required this.child,
    this.opacity = 1.0,
    this.enableBlur = true,
    this.blurSigma = 8,
  });

  final Widget child;
  final double opacity;
  final bool enableBlur;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppEffectController.I,
        AppThemeController.I,
      ]),
      builder: (context, _) {
        final eff = AppEffectController.I.effect;
        if (eff.isNone) return child;

        final isDark = AppTok.isDark(context);
        final gradient = eff.gradientForBrightness(
          isDark ? Brightness.dark : Brightness.light,
        );

        final bg = Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: gradient),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      eff.primary.withValues(alpha: isDark ? 0.08 : 0.10),
                      eff.secondary.withValues(alpha: isDark ? 0.06 : 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SoftBlobsPainter(
                    primary: eff.primary,
                    secondary: eff.secondary,
                    isDark: isDark,
                    opacityFactor: opacity,
                  ),
                ),
              ),
            ),
            if (enableBlur && !kIsWeb)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: blurSigma,
                      sigmaY: blurSigma,
                    ),
                    child: Container(
                      color: (isDark
                              ? AppDarkPalette.background
                              : AppPalette.background)
                          .withValues(alpha: isDark ? 0.02 : 0.04),
                    ),
                  ),
                ),
              ),
          ],
        );

        return Stack(
          children: [
            Positioned.fill(child: child),
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: (0.32 * opacity).clamp(0.0, 1.0),
                  child: bg,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Background stack that provides base + subtle effect behind child
/// Use this to wrap Scaffolds — Scaffold should be transparent
class EffectBackgroundStack extends StatelessWidget {
  const EffectBackgroundStack({
    super.key,
    required this.child,
    this.opacity = 1.0,
    this.enableBlur = false,
    this.blurSigma = 6,
  });

  final Widget child;
  final double opacity;
  final bool enableBlur;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppEffectController.I,
        AppThemeController.I,
      ]),
      builder: (context, _) {
        final eff = AppEffectController.I.effect;
        final isDark = AppTok.isDark(context);
        final baseBg = AppTok.background(context);

        if (eff.isNone) {
          // even when none, provide base bg for consistency
          return ColoredBox(color: baseBg, child: child);
        }

        final gradient = eff.gradientForBrightness(
          isDark ? Brightness.dark : Brightness.light,
        );

        return Stack(
          children: [
            // base
            Positioned.fill(child: ColoredBox(color: baseBg)),
            // gradient very light
            Positioned.fill(
              child: Opacity(
                opacity: (0.38 * opacity).clamp(0.0, 1.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: gradient),
                ),
              ),
            ),
            // wash
            Positioned.fill(
              child: Opacity(
                opacity: (0.22 * opacity).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        eff.primary.withValues(alpha: isDark ? 0.12 : 0.14),
                        eff.secondary.withValues(alpha: isDark ? 0.08 : 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // blobs
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: (0.32 * opacity).clamp(0.0, 1.0),
                  child: CustomPaint(
                    painter: _SoftBlobsPainter(
                      primary: eff.primary,
                      secondary: eff.secondary,
                      isDark: isDark,
                      opacityFactor: opacity,
                    ),
                  ),
                ),
              ),
            ),
            if (enableBlur && !kIsWeb)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: blurSigma,
                      sigmaY: blurSigma,
                    ),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
            Positioned.fill(child: child),
          ],
        );
      },
    );
  }
}

/// Light glass card — very subtle, readable
class EffectGlass extends StatelessWidget {
  const EffectGlass({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 18,
    this.opacity = 0.72,
    this.enableBlur = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double opacity;
  final bool enableBlur;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppEffectController.I,
        AppThemeController.I,
        AppLang.I,
      ]),
      builder: (context, _) {
        final eff = AppEffectController.I.effect;
        final isDark = AppTok.isDark(context);
        final baseCard = AppTok.card(context);
        final border = AppTok.border(context);

        final cardColor = eff.isNone
            ? baseCard.withValues(alpha: opacity)
            : Color.lerp(
                  baseCard,
                  eff.secondary,
                  isDark ? 0.18 : 0.22,
                )!
                .withValues(alpha: opacity);

        Widget content = Container(
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: eff.isNone
                  ? border
                  : eff.primary.withValues(alpha: isDark ? 0.22 : 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );

        if (enableBlur && !kIsWeb && !eff.isNone) {
          content = ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: content,
            ),
          );
        }

        return content;
      },
    );
  }
}

class _SoftBlobsPainter extends CustomPainter {
  _SoftBlobsPainter({
    required this.primary,
    required this.secondary,
    required this.isDark,
    required this.opacityFactor,
  });

  final Color primary;
  final Color secondary;
  final bool isDark;
  final double opacityFactor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paints = [
      Paint()
        ..color = primary.withValues(
          alpha: (isDark ? 0.10 : 0.12) * opacityFactor,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
      Paint()
        ..color = secondary.withValues(
          alpha: (isDark ? 0.08 : 0.10) * opacityFactor,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32),
    ];

    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.18),
      size.width * 0.28,
      paints[0],
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.78),
      size.width * 0.32,
      paints[1],
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.22,
      paints[0]..color = paints[0].color.withValues(alpha: paints[0].color.a * 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _SoftBlobsPainter old) =>
      old.primary != primary ||
      old.secondary != secondary ||
      old.isDark != isDark ||
      old.opacityFactor != opacityFactor;
}
