import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/app_effects.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';

/// نوت‌بوک برنامه‌ریزی مراسم — یادداشت‌های سریع و مهم زوج
/// ذخیره در: weddings/{weddingId}/notes/{noteId}
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, required this.weddingId});

  final String weddingId;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const _noteColors = [
    0xFFD1A36B, // طلایی
    0xFFE58FA2, // صورتی
    0xFF6F9B76, // سبز
    0xFF6F9BB5, // آبی
    0xFF9B7FB5, // بنفش
    0xFF9AA0A6, // خاکستری
  ];

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('weddings')
      .doc(widget.weddingId)
      .collection('notes');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _faNum(Object v) {
    if (!AppLang.I.isFa) return '$v';
    const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return '$v'.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? fa[i] : c;
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        final bg = AppTok.background(context);
        final text = AppTok.text(context);
        final textSoft = AppTok.textSoft(context);
        final accent = AppTok.accent(context);
        final isFa = AppLang.I.isFa;

        return Directionality(
          textDirection: AppLang.I.direction,
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: bg,
              surfaceTintColor: Colors.transparent,
              title: Text(
                isFa ? 'نوت‌بوک مراسم' : 'Wedding notebook',
                style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              iconTheme: IconThemeData(color: text),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    style: TextStyle(color: text, fontSize: 13.5),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AppTok.cardSoft(context),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: textSoft,
                        size: 20,
                      ),
                      hintText: isFa
                          ? 'جستجو در یادداشت‌ها…'
                          : 'Search notes…',
                      hintStyle: TextStyle(color: textSoft, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _col.snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      isFa ? 'خطا در بارگذاری' : 'Load error',
                      style: TextStyle(color: textSoft),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: accent),
                  );
                }

                var docs = snap.data!.docs.toList();
                docs.sort((a, b) {
                  final pa = a.data()['pinned'] == true ? 0 : 1;
                  final pb = b.data()['pinned'] == true ? 0 : 1;
                  if (pa != pb) return pa.compareTo(pb);
                  final ta = (a.data()['updatedAt'] as Timestamp?)
                          ?.millisecondsSinceEpoch ??
                      0;
                  final tb = (b.data()['updatedAt'] as Timestamp?)
                          ?.millisecondsSinceEpoch ??
                      0;
                  return tb.compareTo(ta);
                });

                if (_query.isNotEmpty) {
                  final q = _query.toLowerCase();
                  docs = docs.where((d) {
                    final t =
                        (d.data()['title'] ?? '').toString().toLowerCase();
                    final b =
                        (d.data()['body'] ?? '').toString().toLowerCase();
                    return t.contains(q) || b.contains(q);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            size: 64,
                            color: textSoft.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _query.isNotEmpty
                                ? (isFa
                                    ? 'یادداشتی پیدا نشد'
                                    : 'No notes found')
                                : (isFa
                                    ? 'هنوز یادداشتی ندارید.\nیادداشت‌های مهم و سریع مراسم‌تان را اینجا بنویسید.'
                                    : 'No notes yet.\nWrite your quick & important wedding notes here.'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textSoft,
                              fontSize: 13,
                              height: 1.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _noteCard(docs[i]),
                );
              },
            ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              onPressed: () => _editNote(null, null),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                isFa ? 'یادداشت جدید' : 'New note',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _noteCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final title = (d['title'] ?? '').toString();
    final body = (d['body'] ?? '').toString();
    final pinned = d['pinned'] == true;
    final colorInt = d['color'] is int ? d['color'] as int : _noteColors[0];
    final noteColor = Color(colorInt);
    final updated = (d['updatedAt'] as Timestamp?)?.toDate();

    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final card = AppTok.card(context);
    final isFa = AppLang.I.isFa;

    return Material(
      color: card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _editNote(doc.id, d),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: noteColor.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: noteColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title.isEmpty
                          ? (isFa ? 'بدون عنوان' : 'Untitled')
                          : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: text,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: isFa ? 'سنجاق/برداشتن' : 'Pin/Unpin',
                    icon: Icon(
                      pinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      size: 18,
                      color: pinned ? noteColor : textSoft,
                    ),
                    onPressed: () => _togglePin(doc.id, d),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: isFa ? 'حذف' : 'Delete',
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppTok.danger(context),
                    ),
                    onPressed: () => _confirmDelete(doc.id),
                  ),
                ],
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  body,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textSoft,
                    fontSize: 12.5,
                    height: 1.7,
                  ),
                ),
              ],
              if (updated != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: textSoft.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_faNum(updated.year)}/${_faNum(updated.month)}/${_faNum(updated.day)}  ${_faNum(updated.hour.toString().padLeft(2, '0'))}:${_faNum(updated.minute.toString().padLeft(2, '0'))}',
                      style: TextStyle(
                        color: textSoft.withValues(alpha: 0.7),
                        fontSize: 10.5,
                      ),
                    ),
                    if (pinned) ...[
                      const SizedBox(width: 8),
                      Text(
                        isFa ? 'سنجاق‌شده' : 'Pinned',
                        style: TextStyle(
                          color: noteColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _togglePin(
    String id,
    Map<String, dynamic> d,
  ) async {
    await _col.doc(id).set({
      'pinned': !(d['pinned'] == true),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _confirmDelete(String id) async {
    final isFa = AppLang.I.isFa;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: AppLang.I.direction,
        child: AlertDialog(
          backgroundColor: AppTok.card(ctx),
          surfaceTintColor: Colors.transparent,
          title: Text(
            isFa ? 'حذف یادداشت' : 'Delete note',
            style: TextStyle(color: AppTok.text(ctx)),
          ),
          content: Text(
            isFa
                ? 'این یادداشت برای همیشه حذف می‌شود. مطمئنید؟'
                : 'This note will be deleted forever. Are you sure?',
            style: TextStyle(color: AppTok.textSoft(ctx), height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                isFa ? 'انصراف' : 'Cancel',
                style: TextStyle(color: AppTok.textSoft(ctx)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                isFa ? 'حذف' : 'Delete',
                style: TextStyle(
                  color: AppTok.danger(ctx),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await _col.doc(id).delete();
    }
  }

  Future<void> _editNote(String? id, Map<String, dynamic>? existing) async {
    final isFa = AppLang.I.isFa;
    final titleCtrl =
        TextEditingController(text: (existing?['title'] ?? '').toString());
    final bodyCtrl =
        TextEditingController(text: (existing?['body'] ?? '').toString());
    var color = existing?['color'] is int
        ? existing!['color'] as int
        : _noteColors[0];
    var pinned = existing?['pinned'] == true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTok.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: AppLang.I.direction,
        child: StatefulBuilder(
          builder: (sheetCtx, setSheet) => Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              16,
              18,
              MediaQuery.of(sheetCtx).viewInsets.bottom + 18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTok.border(sheetCtx),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  id == null
                      ? (isFa ? 'یادداشت جدید' : 'New note')
                      : (isFa ? 'ویرایش یادداشت' : 'Edit note'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTok.text(sheetCtx),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  maxLines: 1,
                  style: TextStyle(color: AppTok.text(sheetCtx)),
                  decoration: InputDecoration(
                    labelText: isFa ? 'عنوان' : 'Title',
                    labelStyle:
                        TextStyle(color: AppTok.textSoft(sheetCtx)),
                    filled: true,
                    fillColor: AppTok.cardSoft(sheetCtx),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.of(sheetCtx).size.height * 0.35,
                  ),
                  child: TextField(
                    controller: bodyCtrl,
                    maxLines: null,
                    style: TextStyle(
                      color: AppTok.text(sheetCtx),
                      height: 1.7,
                    ),
                    decoration: InputDecoration(
                      labelText: isFa
                          ? 'متن یادداشت (یادآوری‌ها، ایده‌ها، کارهای فوری…)'
                          : 'Note text (reminders, ideas, urgent tasks…)',
                      labelStyle:
                          TextStyle(color: AppTok.textSoft(sheetCtx)),
                      filled: true,
                      fillColor: AppTok.cardSoft(sheetCtx),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ..._noteColors.map(
                      (c) => GestureDetector(
                        onTap: () => setSheet(() => color = c),
                        child: Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsetsDirectional.only(end: 8),
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: color == c
                                ? Border.all(
                                    color: AppTok.text(sheetCtx),
                                    width: 2.5,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.push_pin_rounded,
                          size: 18,
                          color: AppTok.textSoft(sheetCtx),
                        ),
                        const SizedBox(width: 4),
                        Switch(
                          value: pinned,
                          onChanged: (v) => setSheet(() => pinned = v),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTok.accent(sheetCtx),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final t = titleCtrl.text.trim();
                    final b = bodyCtrl.text.trim();
                    if (t.isEmpty && b.isEmpty) return;
                    try {
                      await _col.doc(id ?? _col.doc().id).set({
                        'title': t,
                        'body': b,
                        'color': color,
                        'pinned': pinned,
                        'updatedAt': FieldValue.serverTimestamp(),
                        if (id == null)
                          'createdAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                    } catch (e) {
                      if (mounted) {
                        showAppSnack(
                          context,
                          '${AppLang.tr('save_error')}: $e',
                          error: true,
                        );
                      }
                      return;
                    }
                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                  },
                  child: Text(
                    isFa ? 'ذخیره' : 'Save',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // صبر تا پایان کامل انیمیشن بستن شیت، بعد dispose —
    // جلوگیری از assert «_dependents.isEmpty» فریم‌ورک
    await Future<void>.delayed(const Duration(milliseconds: 400));
    titleCtrl.dispose();
    bodyCtrl.dispose();
  }
}
