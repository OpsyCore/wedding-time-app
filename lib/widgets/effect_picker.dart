import 'package:flutter/material.dart';
import '../core/app_effect.dart';
import '../core/app_effect_controller.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';

/// Compact effect picker — used in guest AppBar + couple profile
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
      backgroundColor: AppTok.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => const _EffectSheet(),
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

        return Material(
          color: AppTok.card(context),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTok.border(context)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: eff.isNone
                          ? AppTok.cardSoft(context)
                          : eff.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: AppTok.accent(context), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppLang.tr('choose_effect'),
                        style: TextStyle(
                          color: AppTok.text(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: AppTok.textSoft(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLang.tr('effect_hint'),
                    style: TextStyle(
                      color: AppTok.textSoft(context),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: AppEffect.all.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final eff = AppEffect.all[i];
                        final selected =
                            AppEffectController.I.effectId == eff.id;
                        final isDark = AppTok.isDark(context);
                        return Material(
                          color: selected
                              ? eff.primary.withValues(alpha: isDark ? 0.16 : 0.12)
                              : AppTok.card(context),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              await AppEffectController.I.setEffect(eff.id);
                              if (context.mounted) Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected
                                      ? eff.primary
                                      : AppTok.border(context),
                                  width: selected ? 1.4 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: eff.isNone
                                          ? null
                                          : LinearGradient(
                                              colors: [
                                                eff.primary
                                                    .withValues(alpha: 0.28),
                                                eff.secondary
                                                    .withValues(alpha: 0.18),
                                              ],
                                            ),
                                      color: eff.isNone
                                          ? AppTok.cardSoft(context)
                                          : null,
                                    ),
                                    child: Icon(
                                      eff.icon,
                                      color: eff.isNone
                                          ? AppTok.textSoft(context)
                                          : eff.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLang.tr(eff.nameKey),
                                          style: TextStyle(
                                            color: AppTok.text(context),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          AppLang.tr(eff.subtitleKey),
                                          style: TextStyle(
                                            color: AppTok.textSoft(context),
                                            fontSize: 11.5,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: eff.primary,
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
              backgroundColor: AppTok.card(context),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              builder: (_) => const _EffectSheet(),
            );
          },
          icon: Icon(
            eff.isNone ? Icons.palette_outlined : eff.icon,
            color: eff.isNone
                ? AppTok.accent(context)
                : eff.primary,
            size: 22,
          ),
        );
      },
    );
  }
}
