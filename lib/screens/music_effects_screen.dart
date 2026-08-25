import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_effects.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';

class MusicEffectsScreen extends StatefulWidget {
  const MusicEffectsScreen({super.key, required this.weddingId});
  final String weddingId;

  @override
  State<MusicEffectsScreen> createState() => _MusicEffectsScreenState();
}

class _MusicEffectsScreenState extends State<MusicEffectsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  bool _seeding = false;
  bool _savingSettings = false;
  bool _settingsLoaded = false;

  String _ambientId = 'none';
  String _ambientUrl = '';
  bool _ambientEnabled = false;
  String _effectId = AppEffectStyle.noneId;

  final _ambientUrlCtrl = TextEditingController();

  static const _romanticPresets = <Map<String, String>>[
    {'id': 'none', 'nameKey': 'music_amb_none', 'url': ''},
    {
      'id': 'romantic_piano',
      'nameKey': 'music_amb_romantic_piano',
      'url': 'https://www.youtube.com/watch?v=4Tr0otuiQuU',
    },
    {
      'id': 'romantic_strings',
      'nameKey': 'music_amb_romantic_strings',
      'url': 'https://www.youtube.com/watch?v=1ZYbU82GVz4',
    },
    {
      'id': 'romantic_acoustic',
      'nameKey': 'music_amb_romantic_acoustic',
      'url': 'https://www.youtube.com/watch?v=lTRiuFIWV54',
    },
    {
      'id': 'romantic_jazz',
      'nameKey': 'music_amb_romantic_jazz',
      'url': 'https://www.youtube.com/watch?v=Dx5qFachd3A',
    },
    {
      'id': 'romantic_cinematic',
      'nameKey': 'music_amb_romantic_cinematic',
      'url': 'https://www.youtube.com/watch?v=UfcAVejslrU',
    },
    {'id': 'custom', 'nameKey': 'music_amb_custom', 'url': ''},
  ];

  static const _defaultSections = <String>[
    'guests_arrive',
    'ceremony',
    'reception',
    'dinner',
    'speeches',
    'first_dance',
    'party',
    'cake',
    'farewell',
  ];

  CollectionReference<Map<String, dynamic>> get _playlistRef =>
      FirebaseFirestore.instance
          .collection('weddings')
          .doc(widget.weddingId)
          .collection('musicPlaylist');

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
    _tabs = TabController(length: 3, vsync: this);
    _loadSettings();
    _ensureSeedIfEmpty();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _ambientUrlCtrl.dispose();
    super.dispose();
  }

  void _toast(String m, {bool error = false}) =>
      showAppSnack(context, m, error: error);

  Color _onAccent(BuildContext context) =>
      AppTok.isDark(context) ? AppTok.background(context) : Colors.white;

  String _sectionTitle(String key) {
    switch (key) {
      case 'guests_arrive':
        return AppLang.tr('music_sec_guests_arrive');
      case 'ceremony':
        return AppLang.tr('music_sec_ceremony');
      case 'reception':
        return AppLang.tr('music_sec_reception');
      case 'dinner':
        return AppLang.tr('music_sec_dinner');
      case 'speeches':
        return AppLang.tr('music_sec_speeches');
      case 'first_dance':
        return AppLang.tr('music_sec_first_dance');
      case 'party':
        return AppLang.tr('music_sec_party');
      case 'cake':
        return AppLang.tr('music_sec_cake');
      case 'farewell':
        return AppLang.tr('music_sec_farewell');
      default:
        return key;
    }
  }

  IconData _sectionIcon(String key) {
    switch (key) {
      case 'guests_arrive':
        return Icons.door_front_door_outlined;
      case 'ceremony':
        return Icons.favorite_border_rounded;
      case 'reception':
        return Icons.waving_hand_outlined;
      case 'dinner':
        return Icons.restaurant_outlined;
      case 'speeches':
        return Icons.mic_none_rounded;
      case 'first_dance':
        return Icons.nightlife_rounded;
      case 'party':
        return Icons.celebration_outlined;
      case 'cake':
        return Icons.cake_outlined;
      case 'farewell':
        return Icons.emoji_people_outlined;
      default:
        return Icons.music_note_outlined;
    }
  }

  String _ambientName(String id) {
    for (final p in _romanticPresets) {
      if (p['id'] == id) return AppLang.tr(p['nameKey']!);
    }
    return AppLang.tr('music_amb_none');
  }

  Future<void> _loadSettings() async {
    try {
      final snap = await _settingsRef.get();
      final d = snap.data() ?? {};
      _ambientId = (d['ambientId'] ?? 'none').toString();
      _ambientUrl = (d['ambientUrl'] ?? '').toString();
      _ambientEnabled = d['ambientEnabled'] == true;
      final fx = d['effects'];
      if (fx is Map) {
        _effectId = (fx['styleId'] ?? fx['effectId'] ?? 'none').toString();
        if (_effectId == 'none' || _effectId.isEmpty) {
          if (fx['inviteHearts'] == true) {
            _effectId = AppEffectStyle.lavenderId;
          } else if (fx['particles'] == true) {
            _effectId = AppEffectStyle.goldId;
          }
        }
      }
      if (_ambientId == 'classic' ||
          _ambientId == 'piano' ||
          _ambientId == 'gold') {
        _ambientId = 'romantic_piano';
        if (_ambientUrl.isEmpty) {
          _ambientUrl = _romanticPresets
              .firstWhere((e) => e['id'] == 'romantic_piano')['url']!;
        }
      }
      _ambientUrlCtrl.text = _ambientUrl;
    } catch (_) {
    } finally {
      if (mounted) setState(() => _settingsLoaded = true);
    }
  }

  Future<void> _ensureSeedIfEmpty() async {
    if (_seeding) return;
    _seeding = true;
    try {
      final existing = await _playlistRef.limit(1).get();
      if (existing.docs.isNotEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      for (var i = 0; i < _defaultSections.length; i++) {
        final doc = _playlistRef.doc();
        batch.set(doc, {
          'sectionKey': _defaultSections[i],
          'sectionTitle': '',
          'timeText': '',
          'trackTitle': '',
          'artist': '',
          'url': '',
          'note': '',
          'status': 'draft',
          'order': i,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': uid,
        });
      }
      await batch.commit();
    } catch (_) {
    } finally {
      _seeding = false;
    }
  }

  Future<void> _saveSettings({bool quiet = false}) async {
    if (_savingSettings) return;
    setState(() => _savingSettings = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      var url = _ambientUrlCtrl.text.trim();
      if (_ambientId != 'custom' && _ambientId != 'none') {
        final preset = _romanticPresets.firstWhere(
          (e) => e['id'] == _ambientId,
          orElse: () => _romanticPresets.first,
        );
        if (url.isEmpty) url = preset['url'] ?? '';
      }
      final enabled = _ambientEnabled && _ambientId != 'none';
      final style = AppEffectStyle.byId(_effectId);

      await _settingsRef.set({
        'ambientId': _ambientId,
        'ambientUrl': url,
        'ambientEnabled': enabled,
        'effects': {
          'styleId': style.id,
          'particles': style.id == AppEffectStyle.goldId ||
              style.id == AppEffectStyle.champagneId ||
              style.id == AppEffectStyle.midnightId,
          'inviteHearts': style.id == AppEffectStyle.lavenderId ||
              style.id == AppEffectStyle.roseId,
        },
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
      }, SetOptions(merge: true));

      await _weddingRef.set({
        'musicAmbientId': _ambientId,
        'musicAmbientUrl': url,
        'musicAmbientEnabled': enabled,
        'effectStyleId': style.id,
        'effectsParticles': style.id != AppEffectStyle.noneId,
        'effectsInviteHearts': style.id == AppEffectStyle.lavenderId ||
            style.id == AppEffectStyle.roseId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _ambientUrl = url;
          if (_ambientId != 'custom') {
            _ambientUrlCtrl.text = url;
          }
        });
        if (!quiet) _toast(AppLang.tr('settings_saved'));
      }
    } catch (e) {
      _toast('${AppLang.tr('save_error')}: $e', error: true);
    } finally {
      if (mounted) setState(() => _savingSettings = false);
    }
  }

  Future<void> _selectEffect(String id) async {
    setState(() => _effectId = id);
    await _saveSettings();
  }

  Future<void> _selectAmbient(String id) async {
    setState(() {
      _ambientId = id;
      if (id == 'none') {
        _ambientEnabled = false;
        _ambientUrl = '';
        _ambientUrlCtrl.clear();
      } else if (id != 'custom') {
        _ambientEnabled = true;
        final preset = _romanticPresets.firstWhere((e) => e['id'] == id);
        _ambientUrl = preset['url'] ?? '';
        _ambientUrlCtrl.text = _ambientUrl;
      } else {
        _ambientEnabled = true;
      }
    });
    if (id != 'custom') {
      await _saveSettings();
    }
  }

  Future<void> _addCustomSection() async {
    final titleCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTok.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => ListenableBuilder(
        listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
        builder: (_, __) => Directionality(
          textDirection: AppLang.I.direction,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLang.tr('music_add_section'),
                  style: TextStyle(
                    color: AppTok.text(ctx),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  style: TextStyle(color: AppTok.text(ctx)),
                  decoration: _dec(ctx, AppLang.tr('music_section_name')),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTok.accent(ctx),
                      foregroundColor: _onAccent(ctx),
                    ),
                    child: Text(AppLang.tr('add')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok != true) return;
    final title = titleCtrl.text.trim();
    if (title.isEmpty) return;
    try {
      await _playlistRef.add({
        'sectionKey': 'custom',
        'sectionTitle': title,
        'timeText': '',
        'trackTitle': '',
        'artist': '',
        'url': '',
        'note': '',
        'status': 'draft',
        'order': DateTime.now().millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
      });
    } catch (e) {
      _toast('${AppLang.tr('error')}: $e', error: true);
    }
  }

  Future<void> _editItem(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final d = doc.data();
    final timeCtrl =
        TextEditingController(text: d['timeText']?.toString() ?? '');
    final trackCtrl =
        TextEditingController(text: d['trackTitle']?.toString() ?? '');
    final artistCtrl =
        TextEditingController(text: d['artist']?.toString() ?? '');
    final urlCtrl = TextEditingController(text: d['url']?.toString() ?? '');
    final noteCtrl = TextEditingController(text: d['note']?.toString() ?? '');
    final customTitleCtrl =
        TextEditingController(text: d['sectionTitle']?.toString() ?? '');
    var status = (d['status'] ?? 'draft').toString();
    if (status != 'final') status = 'draft';
    final sectionKey = (d['sectionKey'] ?? 'custom').toString();
    final displayTitle = sectionKey == 'custom' &&
            (d['sectionTitle']?.toString().isNotEmpty ?? false)
        ? d['sectionTitle'].toString()
        : _sectionTitle(sectionKey);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTok.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => ListenableBuilder(
          listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
          builder: (_, __) => Directionality(
            textDirection: AppLang.I.direction,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(_sectionIcon(sectionKey),
                            color: AppTok.accent(ctx)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            displayTitle,
                            style: TextStyle(
                              color: AppTok.text(ctx),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (sectionKey == 'custom') ...[
                      Text(AppLang.tr('music_section_name'), style: _lbl(ctx)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: customTitleCtrl,
                        style: TextStyle(color: AppTok.text(ctx)),
                        decoration: _dec(ctx, AppLang.tr('music_section_name')),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(AppLang.tr('music_time_optional'), style: _lbl(ctx)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: timeCtrl,
                      style: TextStyle(color: AppTok.text(ctx)),
                      decoration: _dec(ctx, AppLang.tr('time_hint_example')),
                    ),
                    const SizedBox(height: 12),
                    Text(AppLang.tr('music_track_title'), style: _lbl(ctx)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: trackCtrl,
                      style: TextStyle(color: AppTok.text(ctx)),
                      decoration: _dec(ctx, AppLang.tr('music_track_title')),
                    ),
                    const SizedBox(height: 12),
                    Text(AppLang.tr('music_artist'), style: _lbl(ctx)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: artistCtrl,
                      style: TextStyle(color: AppTok.text(ctx)),
                      decoration: _dec(ctx, AppLang.tr('music_artist')),
                    ),
                    const SizedBox(height: 12),
                    Text(AppLang.tr('music_link'), style: _lbl(ctx)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: urlCtrl,
                      style: TextStyle(color: AppTok.text(ctx)),
                      decoration: _dec(ctx, AppLang.tr('music_link_hint')),
                    ),
                    const SizedBox(height: 12),
                    Text(AppLang.tr('music_dj_note'), style: _lbl(ctx)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 3,
                      style: TextStyle(color: AppTok.text(ctx)),
                      decoration: _dec(ctx, AppLang.tr('music_dj_note_hint')),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(AppLang.tr('music_status_draft')),
                          selected: status == 'draft',
                          onSelected: (_) => setModal(() => status = 'draft'),
                          selectedColor: AppTok.accent(ctx),
                          labelStyle: TextStyle(
                            color: status == 'draft'
                                ? _onAccent(ctx)
                                : AppTok.text(ctx),
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: AppTok.cardSoft(ctx),
                        ),
                        ChoiceChip(
                          label: Text(AppLang.tr('music_status_final')),
                          selected: status == 'final',
                          onSelected: (_) => setModal(() => status = 'final'),
                          selectedColor: AppTok.accent(ctx),
                          labelStyle: TextStyle(
                            color: status == 'final'
                                ? _onAccent(ctx)
                                : AppTok.text(ctx),
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: AppTok.cardSoft(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTok.accent(ctx),
                          foregroundColor: _onAccent(ctx),
                        ),
                        child: Text(AppLang.tr('save')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (saved != true) return;
    try {
      await doc.reference.set({
        if (sectionKey == 'custom')
          'sectionTitle': customTitleCtrl.text.trim(),
        'timeText': timeCtrl.text.trim(),
        'trackTitle': trackCtrl.text.trim(),
        'artist': artistCtrl.text.trim(),
        'url': urlCtrl.text.trim(),
        'note': noteCtrl.text.trim(),
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _toast(AppLang.tr('saved'));
    } catch (e) {
      _toast('${AppLang.tr('save_error')}: $e', error: true);
    }
  }

  Future<void> _deleteItem(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ListenableBuilder(
        listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
        builder: (_, __) => Directionality(
          textDirection: AppLang.I.direction,
          child: AlertDialog(
            backgroundColor: AppTok.card(ctx),
            title: Text(
              AppLang.tr('delete'),
              style: TextStyle(color: AppTok.text(ctx)),
            ),
            content: Text(
              AppLang.tr('music_delete_section_confirm'),
              style: TextStyle(color: AppTok.text(ctx)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  AppLang.tr('cancel'),
                  style: TextStyle(color: AppTok.textSoft(ctx)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  AppLang.tr('delete'),
                  style: TextStyle(
                    color: AppTok.danger(ctx),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await _playlistRef.doc(id).delete();
      _toast(AppLang.tr('deleted'));
    } catch (e) {
      _toast('${AppLang.tr('delete_error')}$e', error: true);
    }
  }

  Future<void> _openUrl(String url) async {
    final u = url.trim();
    if (u.isEmpty) {
      _toast(AppLang.tr('no_link'), error: true);
      return;
    }
    final uri = Uri.tryParse(u);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      _toast(AppLang.tr('invalid_link'), error: true);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _toast(AppLang.tr('could_not_open'), error: true);
  }

  String _shareText(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final b = StringBuffer()
      ..writeln(AppLang.tr('music_share_header'))
      ..writeln('');
    for (final doc in docs) {
      final d = doc.data();
      final key = (d['sectionKey'] ?? 'custom').toString();
      final title = key == 'custom' &&
              (d['sectionTitle']?.toString().isNotEmpty ?? false)
          ? d['sectionTitle'].toString()
          : _sectionTitle(key);
      final time = (d['timeText'] ?? '').toString().trim();
      final track = (d['trackTitle'] ?? '').toString().trim();
      final artist = (d['artist'] ?? '').toString().trim();
      final url = (d['url'] ?? '').toString().trim();
      final note = (d['note'] ?? '').toString().trim();
      final mark = (d['status'] ?? '') == 'final' ? '✓' : '·';
      b.writeln('$mark $title${time.isEmpty ? '' : ' ($time)'}');
      if (track.isNotEmpty || artist.isNotEmpty) {
        b.writeln(
          '  ${track.isEmpty ? '—' : track}${artist.isEmpty ? '' : ' — $artist'}',
        );
      }
      if (url.isNotEmpty) b.writeln('  $url');
      if (note.isNotEmpty) b.writeln('  ${AppLang.tr('note')}: $note');
      b.writeln('');
    }
    b.writeln(AppLang.tr('music_share_footer'));
    return b.toString();
  }

  TextStyle _lbl(BuildContext context) => TextStyle(
        color: AppTok.textSoft(context),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      );

  InputDecoration _dec(BuildContext context, String hint) {
    final border = AppTok.border(context).withValues(alpha: 0.35);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppTok.textSoft(context).withValues(alpha: 0.75),
      ),
      filled: true,
      fillColor: AppTok.cardSoft(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTok.accent(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) => Directionality(
        textDirection: AppLang.I.direction,
        child: Scaffold(
          backgroundColor: AppTok.background(context),
          appBar: AppBar(
            backgroundColor: AppTok.background(context),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: AppTok.accent(context)),
            title: Text(
              AppLang.tr('music_effects_title'),
              style: TextStyle(
                color: AppTok.text(context),
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: AppTok.accent(context),
              labelColor: AppTok.accent(context),
              unselectedLabelColor: AppTok.textSoft(context),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              tabs: [
                Tab(text: AppLang.tr('music_tab_timeline')),
                Tab(text: AppLang.tr('music_tab_ambient')),
                Tab(text: AppLang.tr('music_tab_effects')),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              _timelineTab(),
              _ambientTab(),
              _effectsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timelineTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _playlistRef.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              '${AppLang.tr('data_load_error')}\n${snap.error}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTok.danger(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return Center(
            child: CircularProgressIndicator(color: AppTok.accent(context)),
          );
        }
        final docs = snap.data!.docs.toList()
          ..sort((a, b) => ((a.data()['order'] ?? 0) as num)
              .compareTo((b.data()['order'] ?? 0) as num));
        final filled = docs.where((d) {
          final t = (d.data()['trackTitle'] ?? '').toString().trim();
          final u = (d.data()['url'] ?? '').toString().trim();
          return t.isNotEmpty || u.isNotEmpty;
        }).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            _info(
              Icons.queue_music_rounded,
              AppLang.tr('music_timeline_title'),
              AppLang.tr('music_timeline_body'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _chipBtn(
                    Icons.ios_share_rounded,
                    AppLang.tr('music_share_dj'),
                    () async {
                      await Share.share(
                        _shareText(docs),
                        subject: AppLang.tr('music_share_subject'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _chipBtn(
                    Icons.copy_rounded,
                    AppLang.tr('copy_text'),
                    () async {
                      await Clipboard.setData(
                        ClipboardData(text: _shareText(docs)),
                      );
                      _toast(AppLang.tr('music_playlist_copied'));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${AppLang.tr('music_filled_count')}: $filled / ${docs.length}',
              style: TextStyle(
                color: AppTok.textSoft(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...docs.map(_playlistCard),
            const SizedBox(height: 8),
            Center(
              child: OutlinedButton.icon(
                onPressed: _addCustomSection,
                icon: Icon(Icons.add, color: AppTok.accent(context)),
                label: Text(
                  AppLang.tr('music_add_section'),
                  style: TextStyle(
                    color: AppTok.accent(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppTok.accent(context).withValues(alpha: 0.45),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _playlistCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final key = (d['sectionKey'] ?? 'custom').toString();
    final custom = (d['sectionTitle'] ?? '').toString().trim();
    final title =
        key == 'custom' && custom.isNotEmpty ? custom : _sectionTitle(key);
    final time = (d['timeText'] ?? '').toString().trim();
    final track = (d['trackTitle'] ?? '').toString().trim();
    final artist = (d['artist'] ?? '').toString().trim();
    final url = (d['url'] ?? '').toString().trim();
    final note = (d['note'] ?? '').toString().trim();
    final isFinal = (d['status'] ?? '') == 'final';
    final hasMusic = track.isNotEmpty || url.isNotEmpty;

    final subtleBorder = AppTok.border(context).withValues(alpha: 0.35);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFinal
              ? AppTok.accent(context).withValues(alpha: 0.45)
              : subtleBorder,
        ),
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
                  color: AppTok.accent(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _sectionIcon(key),
                  color: AppTok.accent(context),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTok.text(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (time.isNotEmpty)
                      Text(
                        time,
                        style: TextStyle(
                          color: AppTok.textSoft(context),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isFinal
                      ? AppTok.accent(context).withValues(alpha: 0.18)
                      : AppTok.cardSoft(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isFinal
                      ? AppLang.tr('music_status_final')
                      : AppLang.tr('music_status_draft'),
                  style: TextStyle(
                    color: isFinal
                        ? AppTok.accent(context)
                        : AppTok.textSoft(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasMusic)
            Text(
              AppLang.tr('music_not_set'),
              style: TextStyle(
                color: AppTok.textSoft(context),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            Text(
              track.isEmpty ? '—' : track,
              style: TextStyle(
                color: AppTok.text(context),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (artist.isNotEmpty)
              Text(
                artist,
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 12,
                ),
              ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                note,
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (url.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _openUrl(url),
                  icon: Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: AppTok.accent(context),
                  ),
                  label: Text(
                    AppLang.tr('open'),
                    style: TextStyle(color: AppTok.accent(context)),
                  ),
                ),
              TextButton.icon(
                onPressed: () => _editItem(doc),
                icon: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: AppTok.textSoft(context),
                ),
                label: Text(
                  AppLang.tr('edit'),
                  style: TextStyle(color: AppTok.textSoft(context)),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _deleteItem(doc.id),
                icon: Icon(
                  Icons.delete_outline,
                  color: AppTok.danger(context),
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ambientTab() {
    if (!_settingsLoaded) {
      return Center(
        child: CircularProgressIndicator(color: AppTok.accent(context)),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        _info(
          Icons.headphones_rounded,
          AppLang.tr('music_ambient_title'),
          AppLang.tr('music_ambient_body'),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTok.card(context),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppLang.tr('music_ambient_enabled'),
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch(
                value: _ambientEnabled && _ambientId != 'none',
                activeThumbColor: AppTok.accent(context),
                activeTrackColor:
                    AppTok.accent(context).withValues(alpha: 0.45),
                onChanged: (v) async {
                  setState(() {
                    _ambientEnabled = v;
                    if (v && _ambientId == 'none') {
                      _ambientId = 'romantic_piano';
                      _ambientUrl = _romanticPresets
                          .firstWhere((e) => e['id'] == 'romantic_piano')['url']!;
                      _ambientUrlCtrl.text = _ambientUrl;
                    }
                  });
                  await _saveSettings();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          AppLang.tr('music_choose_ambient'),
          style: TextStyle(
            color: AppTok.text(context),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        ..._romanticPresets.map((p) {
          final id = p['id']!;
          final selected = _ambientId == id;
          final subtleBorder = AppTok.border(context).withValues(alpha: 0.35);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: selected
                  ? AppTok.accent(context).withValues(alpha: 0.14)
                  : AppTok.card(context),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _savingSettings ? null : () => _selectAmbient(id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppTok.accent(context) : subtleBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        id == 'none'
                            ? Icons.music_off_outlined
                            : Icons.music_note_rounded,
                        color: selected
                            ? AppTok.accent(context)
                            : AppTok.textSoft(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLang.tr(p['nameKey']!),
                          style: TextStyle(
                            color: AppTok.text(context),
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppTok.accent(context),
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        if (_ambientId == 'custom') ...[
          const SizedBox(height: 8),
          Text(AppLang.tr('music_link'), style: _lbl(context)),
          const SizedBox(height: 6),
          TextField(
            controller: _ambientUrlCtrl,
            style: TextStyle(color: AppTok.text(context)),
            decoration: _dec(context, AppLang.tr('music_link_hint')),
          ),
          TextButton.icon(
            onPressed: () => _openUrl(_ambientUrlCtrl.text),
            icon: Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: AppTok.accent(context),
            ),
            label: Text(
              AppLang.tr('preview'),
              style: TextStyle(color: AppTok.accent(context)),
            ),
          ),
        ] else if (_ambientId != 'none' && _ambientUrl.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _openUrl(_ambientUrl),
            icon: Icon(
              Icons.play_circle_outline,
              color: AppTok.accent(context),
            ),
            label: Text(
              '${AppLang.tr('preview')} · ${_ambientName(_ambientId)}',
              style: TextStyle(color: AppTok.accent(context)),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTok.cardSoft(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            AppLang.tr('music_ambient_note'),
            style: TextStyle(
              color: AppTok.textSoft(context),
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _saveBtn(),
      ],
    );
  }

  Widget _effectsTab() {
    if (!_settingsLoaded) {
      return Center(
        child: CircularProgressIndicator(color: AppTok.accent(context)),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        _info(
          Icons.auto_awesome,
          AppLang.tr('music_effects_tab_title'),
          AppLang.tr('music_effects_tab_body'),
        ),
        const SizedBox(height: 14),
        Text(
          AppLang.tr('music_choose_effect'),
          style: TextStyle(
            color: AppTok.text(context),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        ...AppEffectStyle.all.map((s) {
          final selected = _effectId == s.id;
          final subtleBorder = AppTok.border(context).withValues(alpha: 0.35);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: AppTok.card(context),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _savingSettings ? null : () => _selectEffect(s.id),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? s.primary : subtleBorder,
                      width: selected ? 1.4 : 1,
                    ),
                    gradient: selected
                        ? LinearGradient(
                            colors: [
                              s.primary.withValues(alpha: 0.16),
                              AppTok.card(context),
                            ],
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              s.primary.withValues(alpha: 0.35),
                              s.secondary.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                        child: Icon(s.icon, color: s.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLang.tr(s.nameKey),
                              style: TextStyle(
                                color: AppTok.text(context),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              AppLang.tr(s.subtitleKey),
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 11.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_savingSettings && selected)
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTok.accent(context),
                          ),
                        )
                      else if (selected)
                        Icon(Icons.check_circle_rounded, color: s.primary),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: AppTok.card(context)),
                AppEffectOverlay(effectId: _effectId, intensity: 1.2),
                Center(
                  child: Text(
                    AppLang.tr('music_fx_preview'),
                    style: TextStyle(
                      color: AppTok.text(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTok.cardSoft(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            AppLang.tr('music_fx_note'),
            style: TextStyle(
              color: AppTok.textSoft(context),
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _saveBtn(),
      ],
    );
  }

  Widget _saveBtn() => SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          onPressed: _savingSettings ? null : () => _saveSettings(),
          style: FilledButton.styleFrom(
            backgroundColor: AppTok.accent(context),
            foregroundColor: _onAccent(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            _savingSettings ? AppLang.tr('saving') : AppLang.tr('save_settings'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );

  Widget _info(IconData icon, String title, String body) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTok.card(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTok.accent(context).withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTok.accent(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTok.accent(context), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTok.text(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      color: AppTok.textSoft(context),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _chipBtn(IconData icon, String label, VoidCallback onTap) => Material(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTok.accent(context).withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppTok.accent(context), size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTok.accent(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}