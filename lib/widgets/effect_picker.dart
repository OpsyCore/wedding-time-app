import 'package:flutter/material.dart';
import '../core/app_effect.dart';
import '../core/app_effect_controller.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import 'page_glass.dart';

/// Compact effect picker — used in guest AppBar + couple profile
/// Now shows 10 effects + none in a grid (per task)
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
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: eff.isNone
                        ? AppTok.cardSoft(context)
                        : eff.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: eff.isNone
                          ? AppTok.border(context)
                          : eff.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    eff.icon,
                    color: eff.isNone ? AppTok.textSoft(context) : eff.primary,
                    size: 20,
                  ),
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
        const all = AppEffect.all;
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
                              '${all.length} ${AppLang.I.isFa ? 'جلوه' : 'effects'} · ${AppLang.tr('effect_hint')}',
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
                    child: GridView.builder(
                      shrinkWrap: true,
                      itemCount: all.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.35,
                      ),
                      itemBuilder: (ctx, i) {
                        final eff = all[i];
                        final selected =
                            AppEffectController.I.effectId == eff.id;
                        final isDark = AppTok.isDark(context);
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () async {
                              await AppEffectController.I.setEffect(eff.id);
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: selected
                                    ? eff.primary.withValues(alpha: isDark ? 0.18 : 0.14)
                                    : AppTok.card(context).withValues(alpha: 0.88),
                                border: Border.all(
                                  color: selected
                                      ? eff.primary
                                      : AppTok.border(context).withValues(alpha: 0.8),
                                  width: selected ? 1.6 : 1,
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
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          gradient: eff.isNone
                                              ? null
                                              : LinearGradient(
                                                  colors: [
                                                    eff.primary.withValues(alpha: 0.32),
                                                    eff.secondary.withValues(alpha: 0.20),
                                                  ],
                                                ),
                                          color: eff.isNone
                                              ? AppTok.cardSoft(context)
                                              : null,
                                          border: Border.all(
                                            color: eff.isNone
                                                ? AppTok.border(context)
                                                : eff.primary.withValues(alpha: 0.25),
                                          ),
                                        ),
                                        child: Icon(
                                          eff.icon,
                                          color: eff.isNone
                                              ? AppTok.textSoft(context)
                                              : eff.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (selected)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: eff.primary,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    AppLang.tr(eff.nameKey),
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
                                    AppLang.tr(eff.subtitleKey),
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
