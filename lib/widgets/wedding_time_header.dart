import 'package:flutter/material.dart';

import '../core/app_effect_controller.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../screens/notifications_screen.dart';
import 'ambient_music_controls.dart';
import 'effect_grid.dart';
import 'notification_badge_icon.dart';
import 'page_glass.dart';

class WeddingTimeHeader extends StatelessWidget {
  const WeddingTimeHeader({
    super.key,
    required this.weddingId,
    this.onMenuPressed,
    this.title,
    this.showMusicButton = true,
  });

  final String weddingId;
  final VoidCallback? onMenuPressed;
  final String? title;
  final bool showMusicButton;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppLang.I,
        AppThemeController.I,
        AppEffectController.I,
      ]),
      builder: (context, _) {
        final displayTitle = title ?? AppLang.tr('app_name');
        final text = AppTok.text(context);
        final accent = AppTok.accent(context);

        return Directionality(
          textDirection: AppLang.I.direction,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
            child: SizedBox(
              height: 48,
              child: LayoutBuilder(
                builder: (context, cons) {
                  final menuBtn = IconButton(
                    tooltip: AppLang.tr('menu'),
                    onPressed: onMenuPressed,
                    icon: Icon(Icons.menu, color: text),
                  );
                  final actions = <Widget>[
                    const _EffectsButton(),
                    const _ThemeToggleButton(),
                    if (showMusicButton)
                      const AmbientMusicActionButton()
                    else
                      const SizedBox(width: 4),
                    NotificationBadgeIcon(
                      weddingId: weddingId,
                      iconColor: text,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                NotificationsScreen(weddingId: weddingId),
                          ),
                        );
                      },
                    ),
                  ];
                  final title = Text(
                    displayTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontSize: 21,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'Henny Penny',
                      fontFamilyFallback: const [
                        'Henny Penny',
                        'HennyPenny',
                        'cursive',
                        'serif',
                      ],
                      letterSpacing: 0.8,
                    ),
                  );

                  // صفحهٔ پهن: عنوان دقیقاً وسطِ کل نوار (طرح مرجع)
                  if (cons.maxWidth >= 640) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 56),
                          child: Center(child: title),
                        ),
                        Row(
                          children: [menuBtn, const Spacer(), ...actions],
                        ),
                      ],
                    );
                  }

                  // موبایل: عنوان بین دکمه‌ها — هرگز روی هم نمی‌افتند
                  return Row(
                    children: [
                      menuBtn,
                      Expanded(child: Center(child: title)),
                      ...actions,
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Theme toggle — cycles light/dark via AppThemeController
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppThemeController.I, AppLang.I]),
      builder: (context, _) {
        final isDark = AppThemeController.I.isDark;
        final text = AppTok.text(context);
        final themeTooltip = AppLang.tr('theme');
        final modeTooltip = isDark
            ? AppLang.tr('light_mode')
            : AppLang.tr('dark_mode');
        final tooltip = themeTooltip == 'theme' || themeTooltip == 'تم'
            ? modeTooltip
            : '$themeTooltip · $modeTooltip';

        return IconButton(
          tooltip: tooltip.isEmpty ? AppLang.tr('theme') : tooltip,
          onPressed: () => AppThemeController.I.toggle(),
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: text,
            size: 22,
          ),
        );
      },
    );
  }
}

/// Effects button — opens existing EffectPicker sheet via AppEffectController
class _EffectsButton extends StatelessWidget {
  const _EffectsButton();

  void _openEffectSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const GlassSheet(
        child: _EffectSheetWrapper(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppEffectController.I, AppLang.I]),
      builder: (context, _) {
        final eff = AppEffectController.I.effect;
        final text = AppTok.text(context);
        final isNone = eff.isNone;
        final fxTooltip = AppLang.tr('effects');
        final tooltip = fxTooltip == 'effects' ? AppLang.tr('effect') : fxTooltip;

        return IconButton(
          tooltip: tooltip,
          onPressed: () => _openEffectSheet(context),
          icon: Icon(
            isNone ? Icons.auto_awesome_outlined : eff.icon,
            color: isNone ? text : (eff.primary.withValues(alpha: 0.95)),
            size: 22,
          ),
        );
      },
    );
  }
}

class _EffectSheetWrapper extends StatelessWidget {
  const _EffectSheetWrapper();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppLang.I.direction,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTok.accent(context).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.auto_awesome_rounded,
                        color: AppTok.accent(context), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLang.tr('choose_effect'),
                          style: TextStyle(
                            color: AppTok.text(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          AppLang.tr('effect_hint'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTok.textSoft(context),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppTok.textSoft(context)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              EffectGrid(
                onSelect: (eff) async {
                  await AppEffectController.I.setEffect(eff.id);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  AppLang.I.isFa
                      ? '۱۰ جلوه + بدون جلوه — خیلی لطیف و خوانا'
                      : '10 effects + none — very light & readable',
                  style: TextStyle(
                    color: AppTok.textSoft(context).withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
