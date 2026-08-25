import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_effects.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../screens/music_effects_screen.dart';
import '../screens/notifications_screen.dart';
import 'notification_badge_icon.dart';

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
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
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
                if (showMusicButton)
                  _AmbientMusicButton(weddingId: weddingId)
                else
                  const SizedBox(width: 12),
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