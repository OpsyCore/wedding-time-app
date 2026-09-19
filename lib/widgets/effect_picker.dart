import 'package:flutter/material.dart';
import '../core/app_effect.dart';
import '../core/app_effect_controller.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import 'effect_grid.dart';
import 'page_glass.dart';

/// Compact effect picker — used in guest AppBar + couple profile
/// Now shows 10 effects + none in a grid with visual patterns
class EffectPicker extends StatelessWidget {
  const EffectPicker({
    super.key,
    this.compact = false,
    this.showLabel = true,
  });

  final bool compact;
  final bool showLabel;

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const GlassSheet(
        child: _EffectSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppEffectController.I]),
      builder: (context, _) {
        final eff = AppEffectController.I.effect;
        final isDark = AppTok.isDark(context);
        final accent = AppTok.accent(context);

        if (compact) {
          return IconButton(
            tooltip: AppLang.tr('effect'),
            onPressed: () => _openSheet(context),
            icon: Icon(
              eff.isNone ? Icons.auto_awesome_outlined : eff.icon,
              color: eff.isNone
                  ? (isDark ? AppTok.textSoft(context) : accent)
                  : eff.primary,
              size: 22,
            ),
          );
        }

        return PageGlass(
          borderRadius: 16,
          opacity: 0.82,
          blurSigma: 10,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openSheet(context),
            child: Row(
              children: [
                EffectPatternIcon(
                  effect: eff,
                  size: 38,
                  iconSize: 20,
                  borderRadius: 12,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showLabel)
                        Text(
                          AppLang.tr('effect'),
                          style: TextStyle(
                            color: AppTok.textSoft(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        AppLang.tr(eff.nameKey),
                        style: TextStyle(
                          color: AppTok.text(context),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        AppLang.tr(eff.subtitleKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTok.textSoft(context),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  AppLang.I.isFa
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: AppTok.textSoft(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EffectSheet extends StatelessWidget {
  const _EffectSheet();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppEffectController.I]),
      builder: (context, _) {
        return Directionality(
          textDirection: AppLang.I.direction,
          child: SafeArea(
            child: Padding(
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
                              '${AppEffect.all.length} ${AppLang.I.isFa ? 'جلوه' : 'effects'} · ${AppLang.tr('effect_hint')}',
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
                  Flexible(
                    child: EffectGrid(
                      physics: const ClampingScrollPhysics(),
                      onSelect: (eff) async {
                        await AppEffectController.I.setEffect(eff.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
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
      },
    );
  }
}

/// Small chip used in AppBar actions row
class EffectActionButton extends StatelessWidget {
  const EffectActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppEffectController.I,
      builder: (context, _) {
        final eff = AppEffectController.I.effect;
        return IconButton(
          tooltip: AppLang.tr('effect'),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => const GlassSheet(child: _EffectSheet()),
            );
          },
          icon: Icon(
            eff.isNone ? Icons.palette_outlined : eff.icon,
            color: eff.isNone ? AppTok.accent(context) : eff.primary,
            size: 22,
          ),
        );
      },
    );
  }
}
