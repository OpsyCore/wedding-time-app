import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/app_effects.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({
    super.key,
    required this.weddingId,
  });

  final String weddingId;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen>
    with SingleTickerProviderStateMixin {
  final _uuid = const Uuid();
  bool _seeding = false;

  late final AnimationController _fxCtrl;
  String _effectStyleId = AppEffectStyle.noneId;

  CollectionReference<Map<String, dynamic>> get _timelineRef =>
      FirebaseFirestore.instance
          .collection('weddings')
          .doc(widget.weddingId)
          .collection('timeline');

  DocumentReference<Map<String, dynamic>> get _weddingDoc =>
      FirebaseFirestore.instance.collection('weddings').doc(widget.weddingId);

  DocumentReference<Map<String, dynamic>> get _musicSettingsDoc =>
      _weddingDoc.collection('musicSettings').doc('main');

  @override
  void initState() {
    super.initState();
    _fxCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _weddingDoc.snapshots().listen((doc) {
      final data = doc.data();
      if (data == null || !mounted) return;
      final style = data['effectStyleId']?.toString().trim();
      if (style != null && style.isNotEmpty) {
        setState(() => _effectStyleId = style);
      } else if (data['effectsParticles'] == true) {
        setState(() => _effectStyleId = AppEffectStyle.goldId);
      }
    });

    _musicSettingsDoc.snapshots().listen((doc) {
      final m = doc.data();
      if (m == null || !mounted) return;
      String? styleId;
      final effects = m['effects'];
      if (effects is Map) {
        styleId = effects['styleId']?.toString().trim();
        if ((styleId == null || styleId.isEmpty) &&
            effects['particles'] == true) {
          styleId = AppEffectStyle.goldId;
        }
      }
      styleId ??= m['effectStyleId']?.toString().trim();
      if (styleId != null && styleId.isNotEmpty) {
        setState(() => _effectStyleId = styleId!);
      }
    });
  }

  @override
  void dispose() {
    _fxCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _defaultEvents => [
        {
          'time': '10:00',
          'title': AppLang.tr('tl_prep'),
          'icon': 'ring',
          'order': 1,
        },
        {
          'time': '11:00',
          'title': AppLang.tr('tl_guests_arrive'),
          'icon': 'guests',
          'order': 2,
        },
        {
          'time': '12:00',
          'title': AppLang.tr('tl_ceremony_start'),
          'icon': 'home',
          'order': 3,
        },
        {
          'time': '12:30',
          'title': AppLang.tr('tl_reception_start'),
          'icon': 'party',
          'order': 4,
        },
        {
          'time': '13:00',
          'title': AppLang.tr('tl_lunch_tables'),
          'icon': 'food',
          'order': 5,
        },
        {
          'time': '14:00',
          'title': AppLang.tr('tl_speeches'),
          'icon': 'mic',
          'order': 6,
        },
        {
          'time': '15:00',
          'title': AppLang.tr('tl_games'),
          'icon': 'music',
          'order': 7,
        },
        {
          'time': '16:00',
          'title': AppLang.tr('tl_first_dance'),
          'icon': 'heart',
          'order': 8,
        },
        {
          'time': '16:30',
          'title': AppLang.tr('tl_cake_group_photo'),
          'icon': 'cake',
          'order': 9,
        },
        {
          'time': '18:00',
          'title': AppLang.tr('tl_farewell'),
          'icon': 'car',
          'order': 10,
        },
      ];

  Future<void> _seedDefaultsIfEmpty(int currentCount) async {
    if (currentCount > 0 || _seeding) return;
    _seeding = true;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final event in _defaultEvents) {
        batch.set(_timelineRef.doc(), {
          ...event,
          'note': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (_) {
    } finally {
      _seeding = false;
    }
  }

  IconData _iconOf(String? key) {
    switch (key) {
      case 'ring':
        return Icons.diamond_outlined;
      case 'guests':
        return Icons.groups_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'party':
        return Icons.celebration_outlined;
      case 'food':
        return Icons.restaurant_outlined;
      case 'mic':
        return Icons.mic_none_rounded;
      case 'music':
        return Icons.music_note_outlined;
      case 'heart':
        return Icons.favorite_border;
      case 'cake':
        return Icons.cake_outlined;
      case 'car':
        return Icons.directions_car_outlined;
      case 'camera':
        return Icons.photo_camera_outlined;
      case 'place':
        return Icons.place_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor:
            isError ? AppTok.danger(context) : AppTok.accentDeep(context),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _openEventSheet({
    String? docId,
    Map<String, dynamic>? initial,
  }) async {
    final timeCtrl =
        TextEditingController(text: initial?['time']?.toString() ?? '12:00');
    final titleCtrl =
        TextEditingController(text: initial?['title']?.toString() ?? '');
    final noteCtrl =
        TextEditingController(text: initial?['note']?.toString() ?? '');
    String selectedIcon = initial?['icon']?.toString() ?? 'heart';

    final icons = <String, IconData>{
      'ring': Icons.diamond_outlined,
      'guests': Icons.groups_outlined,
      'home': Icons.home_outlined,
      'party': Icons.celebration_outlined,
      'food': Icons.restaurant_outlined,
      'mic': Icons.mic_none_rounded,
      'music': Icons.music_note_outlined,
      'heart': Icons.favorite_border,
      'cake': Icons.cake_outlined,
      'car': Icons.directions_car_outlined,
      'camera': Icons.photo_camera_outlined,
      'place': Icons.place_outlined,
    };

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTok.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: AppLang.I.direction,
          child: StatefulBuilder(
            builder: (sheetCtx, setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 18,
                  bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTok.textSoft(sheetCtx)
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        docId == null
                            ? AppLang.tr('add_event')
                            : AppLang.tr('edit_event'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTok.text(sheetCtx),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _field(
                        sheetCtx,
                        timeCtrl,
                        AppLang.tr('time_hint_example'),
                        Icons.schedule_rounded,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        sheetCtx,
                        titleCtrl,
                        AppLang.tr('event_title'),
                        Icons.edit_outlined,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        sheetCtx,
                        noteCtrl,
                        AppLang.tr('note_optional'),
                        Icons.notes_rounded,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLang.tr('icon_label'),
                        style: TextStyle(
                          color: AppTok.textSoft(sheetCtx),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: icons.entries.map((e) {
                          final selected = selectedIcon == e.key;
                          return InkWell(
                            onTap: () =>
                                setModalState(() => selectedIcon = e.key),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTok.accent(sheetCtx)
                                        .withValues(alpha: 0.18)
                                    : AppTok.cardSoft(sheetCtx),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? AppTok.accent(sheetCtx)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Icon(
                                e.value,
                                color: selected
                                    ? AppTok.accent(sheetCtx)
                                    : AppTok.textSoft(sheetCtx),
                                size: 20,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton(
                        onPressed: () {
                          if (titleCtrl.text.trim().isEmpty ||
                              timeCtrl.text.trim().isEmpty) {
                            return;
                          }
                          Navigator.pop(sheetCtx, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTok.accent(sheetCtx),
                          foregroundColor: AppTok.isDark(sheetCtx)
                              ? AppDarkPalette.background
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          docId == null
                              ? AppLang.tr('register_event')
                              : AppLang.tr('save_changes'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    final time = timeCtrl.text.trim();
    final title = titleCtrl.text.trim();
    final note = noteCtrl.text.trim();
    timeCtrl.dispose();
    titleCtrl.dispose();
    noteCtrl.dispose();
    if (result != true) return;

    try {
      if (docId == null) {
        final snap = await _timelineRef.get();
        await _timelineRef.doc(_uuid.v4()).set({
          'time': time,
          'title': title,
          'note': note,
          'icon': selectedIcon,
          'order': snap.docs.length + 1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _showMessage(AppLang.tr('event_added'));
      } else {
        await _timelineRef.doc(docId).update({
          'time': time,
          'title': title,
          'note': note,
          'icon': selectedIcon,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _showMessage(AppLang.tr('event_updated'));
      }
    } catch (e) {
      _showMessage('${AppLang.tr('save_error')}: $e', isError: true);
    }
  }

  Widget _field(
    BuildContext context,
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: AppTok.text(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTok.textSoft(context)),
        prefixIcon: Icon(icon, color: AppTok.accent(context), size: 20),
        filled: true,
        fillColor: AppTok.cardSoft(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _deleteEvent(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: AppLang.I.direction,
        child: AlertDialog(
          backgroundColor: AppTok.card(context),
          title: Text(
            AppLang.tr('delete_event'),
            style: TextStyle(color: AppTok.text(context)),
          ),
          content: Text(
            AppLang.tr('delete_event_confirm'),
            style: TextStyle(color: AppTok.textSoft(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                AppLang.tr('cancel'),
                style: TextStyle(color: AppTok.textSoft(context)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppLang.tr('delete'),
                style: TextStyle(color: AppTok.danger(context)),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await _timelineRef.doc(docId).delete();
      _showMessage(AppLang.tr('event_deleted'));
    } catch (e) {
      _showMessage('${AppLang.tr('delete_failed')}: $e', isError: true);
    }
  }

  Future<void> _resetDefaults() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: AppLang.I.direction,
        child: AlertDialog(
          backgroundColor: AppTok.card(context),
          title: Text(
            AppLang.tr('reset_timeline'),
            style: TextStyle(color: AppTok.text(context)),
          ),
          content: Text(
            AppLang.tr('reset_timeline_body'),
            style: TextStyle(color: AppTok.textSoft(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                AppLang.tr('cancel'),
                style: TextStyle(color: AppTok.textSoft(context)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppLang.tr('reset'),
                style: TextStyle(color: AppTok.accent(context)),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final docs = await _timelineRef.get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in docs.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      _seeding = false;
      await _seedDefaultsIfEmpty(0);
      _showMessage(AppLang.tr('timeline_reset_done'));
    } catch (e) {
      _showMessage('${AppLang.tr('reset_failed')}: $e', isError: true);
    }
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  String _displayTime(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '--:--';
    if (t.toUpperCase().contains('AM') || t.toUpperCase().contains('PM')) {
      return t.toUpperCase();
    }
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final mm = m.toString().padLeft(2, '0');
    if (AppLang.I.isFa) {
      return '${parts[0].padLeft(2, '0')}:$mm';
    }
    final isAm = h < 12;
    var h12 = h % 12;
    if (h12 == 0) h12 = 12;
    return '$h12:$mm ${isAm ? 'AM' : 'PM'}';
  }

  double _fxIntensity() {
    switch (_effectStyleId) {
      case AppEffectStyle.lavenderId:
      case AppEffectStyle.roseId:
        return 0.7;
      case AppEffectStyle.goldId:
      case AppEffectStyle.champagneId:
        return 0.65;
      case AppEffectStyle.midnightId:
        return 0.55;
      default:
        return 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        final bg = AppTok.background(context);
        final dark = AppTok.isDark(context);
        final accent = AppTok.accent(context);
        final text = AppTok.text(context);
        final textSoft = AppTok.textSoft(context);

        return Directionality(
          textDirection: AppLang.I.direction,
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: bg,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: text),
              title: Text(
                AppLang.tr('timeline_title'),
                style: TextStyle(
                  color: text,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: AppLang.tr('reset'),
                  onPressed: _resetDefaults,
                  icon: Icon(Icons.refresh_rounded, color: textSoft),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'timeline_fab',
              onPressed: () => _openEventSheet(),
              backgroundColor: accent,
              foregroundColor:
                  dark ? AppDarkPalette.background : Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                AppLang.tr('add_event'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            body: Stack(
              children: [
                // پس‌زمینه گرادیان نرم تم
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          bg,
                          AppTok.cardSoft(context).withValues(alpha: 0.55),
                          bg,
                        ],
                      ),
                    ),
                  ),
                ),

                // جلوه متحرک اختصاصی تایم‌لاین (همیشه مشخص)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _fxCtrl,
                      builder: (_, __) => CustomPaint(
                        painter: _TimelineAmbientPainter(
                          t: _fxCtrl.value,
                          accent: accent,
                          accentSoft: AppTok.accentSoft(context),
                          dark: dark,
                        ),
                      ),
                    ),
                  ),
                ),

                // جلوه اپ (اگر در music/effects ست شده)
                if (_effectStyleId != AppEffectStyle.noneId)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AppEffectOverlay(
                        effectId: _effectStyleId,
                        intensity: _fxIntensity(),
                      ),
                    ),
                  ),

                // محتوا
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _timelineRef.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            '${AppLang.tr('timeline_load_error')}\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTok.danger(context)),
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(color: accent),
                      );
                    }

                    final docs = snapshot.data!.docs.toList();
                    if (docs.isEmpty) {
                      _seedDefaultsIfEmpty(0);
                      return Center(
                        child: CircularProgressIndicator(color: accent),
                      );
                    }

                    docs.sort((a, b) {
                      final ta =
                          _timeToMinutes(a.data()['time']?.toString() ?? '');
                      final tb =
                          _timeToMinutes(b.data()['time']?.toString() ?? '');
                      if (ta != tb) return ta.compareTo(tb);
                      final oa = (a.data()['order'] ?? 0) as num;
                      final ob = (b.data()['order'] ?? 0) as num;
                      return oa.compareTo(ob);
                    });

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                      itemCount: docs.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 22),
                            child: _HeaderCard(count: docs.length),
                          );
                        }

                        final i = index - 1;
                        final doc = docs[i];
                        final data = doc.data();
                        final isLast = i == docs.length - 1;
                        final onStart = i.isEven;

                        return _TimelineNode(
                          isLast: isLast,
                          onStartSide: onStart,
                          time: _displayTime(data['time']?.toString() ?? ''),
                          title: data['title']?.toString() ?? '',
                          note: data['note']?.toString() ?? '',
                          icon: _iconOf(data['icon']?.toString()),
                          onTap: () =>
                              _openEventSheet(docId: doc.id, initial: data),
                          onLongPress: () => _deleteEvent(doc.id),
                        );
                      },
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

// ═══════════════════════════════════════════
// هدر جمع‌وجور
// ═══════════════════════════════════════════

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final accent = AppTok.accent(context);
    final accentDeep = AppTok.accentDeep(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final border = AppTok.border(context);
    final card = AppTok.card(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: AppTok.progressGradient(context),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: AppTok.shadow(context),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: card.withValues(alpha: 0.85),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Icon(Icons.view_timeline_rounded, color: accent, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            'WEDDING TIMELINE',
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accentDeep,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLang.tr('timeline_hero_body'),
            textAlign: TextAlign.center,
            style: TextStyle(color: textSoft, fontSize: 12.5, height: 1.5),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: card.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_available_outlined, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(
                  '$count  ·  ${AppLang.tr('timeline_chip_edit')}',
                  style: TextStyle(
                    color: text,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// نود تایم‌لاین حرفه‌ای (وسط + چپ/راست)
// ═══════════════════════════════════════════

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.isLast,
    required this.onStartSide,
    required this.time,
    required this.title,
    required this.note,
    required this.icon,
    required this.onTap,
    required this.onLongPress,
  });

  final bool isLast;
  final bool onStartSide;
  final String time;
  final String title;
  final String note;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final accent = AppTok.accent(context);
    final accentDeep = AppTok.accentDeep(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final border = AppTok.border(context);
    final card = AppTok.card(context);
    final cardSoft = AppTok.cardSoft(context);

    Widget eventCard({required bool alignEnd}) {
      final cross =
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
      final ta = alignEnd ? TextAlign.end : TextAlign.start;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: card.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: AppTok.shadow(context),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: cross,
              children: [
                Row(
                  mainAxisAlignment: alignEnd
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!alignEnd) ...[
                      _iconBadge(context, icon, accent, cardSoft),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Column(
                        crossAxisAlignment: cross,
                        children: [
                          Text(
                            time,
                            textDirection: TextDirection.ltr,
                            textAlign: ta,
                            style: TextStyle(
                              color: accentDeep,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            textAlign: ta,
                            style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.2,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (alignEnd) ...[
                      const SizedBox(width: 10),
                      _iconBadge(context, icon, accent, cardSoft),
                    ],
                  ],
                ),
                if (note.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    note,
                    textAlign: ta,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textSoft,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: onStartSide
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: 10,
                      top: 4,
                      bottom: 4,
                    ),
                    child: eventCard(alignEnd: true),
                  )
                : const SizedBox.shrink(),
          ),

          // ستون وسط
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2.2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent.withValues(alpha: 0.15),
                          accent.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: card,
                    border: Border.all(color: accent, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2.2,
                    color: isLast
                        ? Colors.transparent
                        : accent.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: !onStartSide
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 10,
                      top: 4,
                      bottom: 4,
                    ),
                    child: eventCard(alignEnd: false),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _iconBadge(
    BuildContext context,
    IconData icon,
    Color accent,
    Color soft,
  ) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: accent, size: 20),
    );
  }
}

// ═══════════════════════════════════════════
// ذرات / پَر / درخشش متحرک پس‌زمینه
// ═══════════════════════════════════════════

class _TimelineAmbientPainter extends CustomPainter {
  _TimelineAmbientPainter({
    required this.t,
    required this.accent,
    required this.accentSoft,
    required this.dark,
  });

  final double t;
  final Color accent;
  final Color accentSoft;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    const n = 28;

    for (var i = 0; i < n; i++) {
      final seedX = rnd.nextDouble();
      final seedY = rnd.nextDouble();
      final speed = 0.15 + rnd.nextDouble() * 0.55;
      final drift = math.sin((t * math.pi * 2 * speed) + i) * 18;
      final rise = (seedY + t * speed) % 1.2;

      final x = seedX * size.width + drift;
      final y = size.height * (1.15 - rise);

      final pulse =
          0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * math.pi * 2 + i * 0.7));
      final r = (2.0 + rnd.nextDouble() * 3.8) * pulse;

      final col = (i.isEven ? accent : accentSoft).withValues(
        alpha: (dark ? 0.14 : 0.18) * pulse,
      );

      // نقطه نور
      canvas.drawCircle(Offset(x, y), r, Paint()..color = col);

      // هاله نرم
      canvas.drawCircle(
        Offset(x, y),
        r * 2.4,
        Paint()
          ..color = col.withValues(alpha: col.a * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // چند تا پَر/بیضی کج
      if (i % 4 == 0) {
        final ang = t * math.pi * 2 * 0.4 + i;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(ang);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: r * 3.2, height: r * 1.3),
          Paint()..color = accentSoft.withValues(alpha: dark ? 0.10 : 0.14),
        );
        canvas.restore();
      }
    }

    // دو لکه نوری بزرگ و آهسته
    final g1 = Offset(
      size.width * (0.2 + 0.05 * math.sin(t * math.pi * 2)),
      size.height * 0.18,
    );
    final g2 = Offset(
      size.width * (0.8 + 0.04 * math.cos(t * math.pi * 2)),
      size.height * 0.72,
    );

    canvas.drawCircle(
      g1,
      size.width * 0.28,
      Paint()
        ..color = accent.withValues(alpha: dark ? 0.06 : 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );
    canvas.drawCircle(
      g2,
      size.width * 0.24,
      Paint()
        ..color = accentSoft.withValues(alpha: dark ? 0.05 : 0.09)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36),
    );
  }

  @override
  bool shouldRepaint(covariant _TimelineAmbientPainter old) =>
      old.t != t ||
      old.accent != accent ||
      old.accentSoft != accentSoft ||
      old.dark != dark;
}