import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_effect_controller.dart';
import '../core/app_effects.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../screens/music_effects_screen.dart';
import '../screens/notifications_screen.dart';
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
            child: Row(
              children: [
                IconButton(
                  tooltip: AppLang.tr('menu'),
                  onPressed: onMenuPressed,
                  icon: Icon(Icons.menu, color: text),
                ),
                Expanded(
                  child: Text(
                    displayTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                // ── TASK 1: Theme + Effects beside notifications ──
                const _EffectsButton(),
                const _ThemeToggleButton(),
                if (showMusicButton)
                  _AmbientMusicButton(weddingId: weddingId)
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
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Theme toggle — cycles light/dark via AppThemeController
/// Reuses same behavior as profile screen (toggle)
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppThemeController.I, AppLang.I]),
      builder: (context, _) {
        final isDark = AppThemeController.I.isDark;
        final text = AppTok.text(context);
        // tooltip via AppLang — use 'theme' key if available, fallback to light/dark
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
        // tooltip via AppLang — prefer 'effects' key, fallback to 'effect'
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

/// Wrapper that reuses the same UI as EffectPicker's sheet
/// We duplicate the sheet UI here to avoid private access, but keep behavior identical
class _EffectSheetWrapper extends StatelessWidget {
  const _EffectSheetWrapper();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppEffectController.I]),
      builder: (context, _) {
        // Reuse EffectPicker's sheet by embedding the public EffectPicker logic
        // We import the file and reuse its internal builder via a local copy
        // to keep AppTok.*(context) and AppLang fa/en compliant.
        return const _LocalEffectSheet();
      },
    );
  }
}

class _LocalEffectSheet extends StatelessWidget {
  const _LocalEffectSheet();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppEffectController.I]),
      builder: (context, _) {
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
                  const _EffectGrid(),
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

class _EffectGrid extends StatelessWidget {
  const _EffectGrid();

  static String _normalizeForCompare(String id) {
    const legacyToNew = {
      'gold': 'champagne_gold',
      'lavender': 'lavender_dusk',
      'rose': 'blush_rose',
      'champagne': 'champagne_gold',
      'midnight': 'ocean_mist',
      'none': 'none',
      'misty_rose': 'misty_rose',
      'olive_grove': 'olive_grove',
      'candlelight': 'candlelight',
      'midnight_orchid': 'midnight_orchid',
      'pearl_sand': 'pearl_sand',
    };
    return legacyToNew[id] ?? id;
  }

  @override
  Widget build(BuildContext context) {
    final all = AppEffectStyle.all;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: all.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (c, i) {
        final style = all[i];
        final isSelected =
            AppEffectController.I.effectId == _normalizeForCompare(style.id);
        final isDark = AppTok.isDark(context);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              await AppEffectController.I.setEffect(style.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: isSelected
                    ? style.primary.withValues(alpha: isDark ? 0.18 : 0.14)
                    : AppTok.card(context).withValues(alpha: 0.88),
                border: Border.all(
                  color: isSelected
                      ? style.primary
                      : AppTok.border(context).withValues(alpha: 0.8),
                  width: isSelected ? 1.6 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.16 : 0.05),
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
                          color: style.isOff
                              ? AppTok.cardSoft(context)
                              : style.primary.withValues(alpha: 0.18),
                          border: Border.all(
                            color: style.isOff
                                ? AppTok.border(context)
                                : style.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(
                          style.icon,
                          color: style.isOff
                              ? AppTok.textSoft(context)
                              : style.primary,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: style.primary,
                          size: 20,
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    AppLang.tr(style.nameKey),
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
                    AppLang.tr(style.subtitleKey),
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
    );
  }
}

class _AmbientMusicButton extends StatefulWidget {
  const _AmbientMusicButton({required this.weddingId});

  final String weddingId;

  @override
  State<_AmbientMusicButton> createState() => _AmbientMusicButtonState();
}

class _AmbientMusicButtonState extends State<_AmbientMusicButton> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _settingsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _weddingSub;

  bool _enabled = false;
  String _ambientId = 'none';
  String _ambientUrl = '';
  bool _activeUi = false;
  bool _settingsSeen = false;

  DocumentReference<Map<String, dynamic>> get _settingsRef =>
      FirebaseFirestore.instance
          .collection('weddings')
          .doc(widget.weddingId)
          .collection('musicSettings')
          .doc('main');

  DocumentReference<Map<String, dynamic>> get _weddingRef =>
      FirebaseFirestore.instance.collection('weddings').doc(widget.weddingId);

  @override
  void initState() {
    super.initState();
    _settingsSub = _settingsRef.snapshots().listen((snap) {
      final d = snap.data();
      if (!mounted) return;
      if (d == null) {
        setState(() => _settingsSeen = true);
        return;
      }
      setState(() {
        _settingsSeen = true;
        _ambientId = (d['ambientId'] ?? 'none').toString();
        _ambientUrl = (d['ambientUrl'] ?? '').toString().trim();
        _enabled = d['ambientEnabled'] == true && _ambientId != 'none';
        if (!_enabled) _activeUi = false;
      });
    });

    _weddingSub = _weddingRef.snapshots().listen((snap) {
      final d = snap.data() ?? {};
      if (!mounted) return;
      if (_settingsSeen && _ambientId != 'none' && _ambientUrl.isNotEmpty) {
        return;
      }
      final mid = (d['musicAmbientId'] ?? '').toString().trim();
      final murl = (d['musicAmbientUrl'] ?? '').toString().trim();
      final men = d['musicAmbientEnabled'] == true;
      if (mid.isEmpty && murl.isEmpty && !men) return;
      setState(() {
        if (_ambientId == 'none' && mid.isNotEmpty) _ambientId = mid;
        if (_ambientUrl.isEmpty && murl.isNotEmpty) _ambientUrl = murl;
        if (!_enabled && men && _ambientId != 'none') _enabled = true;
      });
    });
  }

  @override
  void dispose() {
    _settingsSub?.cancel();
    _weddingSub?.cancel();
    super.dispose();
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    showAppSnack(context, msg, error: error);
  }

  Future<void> _openMusicScreen() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MusicEffectsScreen(weddingId: widget.weddingId),
      ),
    );
  }

  Future<bool> _launch(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _onPressed() async {
    if (!_enabled || _ambientId == 'none') {
      _toast(AppLang.tr('music_no_ambient'));
      await _openMusicScreen();
      return;
    }

    if (_activeUi) {
      setState(() => _activeUi = false);
      _toast(AppLang.tr('music_header_mute'));
      return;
    }

    if (_ambientUrl.isEmpty) {
      _toast(AppLang.tr('music_header_play'));
      await _openMusicScreen();
      return;
    }

    final ok = await _launch(_ambientUrl);
    if (!mounted) return;
    if (ok) {
      setState(() => _activeUi = true);
      _toast(AppLang.tr('music_header_open_link'));
    } else {
      _toast(AppLang.tr('could_not_open'), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final on = _enabled && _ambientId != 'none';
    final playing = on && _activeUi;
    final accent = AppTok.accent(context);
    final accentSoft = AppTok.accentSoft(context);
    final textSoft = AppTok.textSoft(context);

    return IconButton(
      tooltip: playing
          ? AppLang.tr('music_header_mute')
          : AppLang.tr('music_header_play'),
      onPressed: _onPressed,
      onLongPress: _openMusicScreen,
      icon: Icon(
        playing
            ? Icons.music_note_rounded
            : (on ? Icons.music_note_outlined : Icons.music_off_outlined),
        color: playing ? accent : (on ? accentSoft : textSoft),
      ),
    );
  }
}
