import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Shared light-glass style for real page chrome
/// - background: surface with alpha 0.70-0.88
/// - border: 1px light white/gold/sage low alpha
/// - shadow: soft small
/// - BackdropFilter blur sigma 8-14 where perf allows
/// - WEB fallback: translucent fill WITHOUT blur
class PageGlass extends StatelessWidget {
  const PageGlass({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.blurSigma = 12,
    this.opacity = 0.82,
    this.enableBlur = true,
    this.borderColor,
    this.backgroundColor,
    this.elevation = 1,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurSigma;
  final double opacity;
  final bool enableBlur;
  final Color? borderColor;
  final Color? backgroundColor;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTok.isDark(context);
    final baseCard = backgroundColor ?? AppTok.card(context);
    final card = baseCard.withValues(alpha: opacity.clamp(0.65, 0.92));
    final border = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppPalette.brandGreenSoft.withValues(alpha: 0.55));

    Widget content = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppTok.accent(context).withValues(alpha: isDark ? 0.06 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    final useBlur = enableBlur && !kIsWeb;

    if (useBlur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Glass AppBar — light elegant, always LIGHT for invite, but adapts for dark outer
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.height = 56,
    this.forceLight = false,
    this.opacity = 0.84,
    this.blurSigma = 12,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final double height;
  final bool forceLight;
  final double opacity;
  final double blurSigma;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final isDark = forceLight ? false : AppTok.isDark(context);
    final bg = (forceLight ? AppPalette.card : AppTok.card(context))
        .withValues(alpha: opacity);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : AppPalette.border.withValues(alpha: 0.7);
    final textColor = forceLight ? AppPalette.text : AppTok.text(context);

    final bar = Container(
      height: height,
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              if (leading != null) leading! else const SizedBox(width: 48),
              Expanded(
                child: Center(
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      fontFamily: AppPalette.fontFamily,
                    ),
                    child: title ?? const SizedBox(),
                  ),
                ),
              ),
              if (actions != null)
                Row(mainAxisSize: MainAxisSize.min, children: actions!)
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );

    if (kIsWeb) return bar;

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: bar,
      ),
    );
  }
}

/// Glass Bottom Navigation / Bar
class GlassBottomBar extends StatelessWidget {
  const GlassBottomBar({
    super.key,
    required this.child,
    this.opacity = 0.86,
    this.blurSigma = 12,
    this.forceLight = false,
  });

  final Widget child;
  final double opacity;
  final double blurSigma;
  final bool forceLight;

  @override
  Widget build(BuildContext context) {
    final isDark = forceLight ? false : AppTok.isDark(context);
    final bg = (forceLight ? AppPalette.card : AppTok.card(context))
        .withValues(alpha: opacity);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : AppPalette.border.withValues(alpha: 0.7);

    final bar = Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(top: false, child: child),
    );

    if (kIsWeb) return bar;

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: bar,
      ),
    );
  }
}

/// Glass Sheet wrapper for modal bottom sheets
class GlassSheet extends StatelessWidget {
  const GlassSheet({
    super.key,
    required this.child,
    this.opacity = 0.88,
    this.blurSigma = 14,
  });

  final Widget child;
  final double opacity;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final bg = AppTok.card(context).withValues(alpha: opacity);
    final border = AppTok.border(context);

    final content = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: child,
    );

    if (kIsWeb) return content;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: content,
      ),
    );
  }
}

/// Glass Dialog
class GlassDialog extends StatelessWidget {
  const GlassDialog({
    super.key,
    required this.child,
    this.opacity = 0.88,
    this.blurSigma = 14,
    this.borderRadius = 22,
  });

  final Widget child;
  final double opacity;
  final double blurSigma;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final bg = AppTok.card(context).withValues(alpha: opacity);

    final content = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTok.border(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );

    if (kIsWeb) return content;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: content,
      ),
    );
  }
}
