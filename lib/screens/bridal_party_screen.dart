import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_effects.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../services/media_upload_service.dart';

/// ساقدوش‌ها — دو ستون عروس/داماد در یک صفحه + جزئیات با ضربه
class BridalPartyScreen extends StatefulWidget {
  const BridalPartyScreen({super.key, required this.weddingId});

  final String weddingId;

  @override
  State<BridalPartyScreen> createState() => _BridalPartyScreenState();
}

class _BridalPartyScreenState extends State<BridalPartyScreen> {
  bool _saving = false;
  bool _uploading = false;
  String? _uploadingDocId;
  String? _expandedId;

  final _picker = ImagePicker();

  CollectionReference<Map<String, dynamic>> get _ref => FirebaseFirestore.instance
      .collection('weddings')
      .doc(widget.weddingId)
      .collection('bridalParty');

  void _toast(String msg, {bool error = false}) =>
      showAppSnack(context, msg, error: error);

  Future<void> _addPerson(String side) async {
    try {
      final doc = await _ref.add({
        'side': side,
        'name': '',
        'role': '',
        'note': '',
        'photoUrl': '',
        'storagePath': '',
        'provider': 'imgbb',
        'order': DateTime.now().millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
      });
      if (mounted) setState(() => _expandedId = doc.id);
    } catch (e) {
      _toast('${AppLang.tr('add_person_error')}: $e', error: true);
    }
  }

  Future<void> _deletePerson(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: AppLang.I.direction,
        child: AlertDialog(
          backgroundColor: AppTok.card(context),
          title: Text(
            AppLang.tr('delete_party_member'),
            style: TextStyle(
              color: AppTok.text(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            AppLang.tr('delete_person_confirm'),
            style: TextStyle(color: AppTok.text(context), height: 1.4),
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
                style: TextStyle(
                  color: AppTok.danger(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await _ref.doc(id).delete();
      if (_expandedId == id) _expandedId = null;
      _toast(AppLang.tr('deleted'));
    } catch (e) {
      _toast('${AppLang.tr('delete_error')}$e', error: true);
    }
  }

  String _urlFrom(dynamic result) {
    try {
      final u = (result.url ?? result.displayUrl ?? result.imageUrl ?? '')
          .toString()
          .trim();
      if (u.isNotEmpty) return u;
    } catch (_) {}
    throw Exception(AppLang.tr('photo_upload_failed'));
  }

  String _pathFrom(dynamic result, String url) {
    try {
      final id = result.id ?? result.providerId ?? result.imageId;
      if (id != null) {
        final s = id.toString();
        if (s.isNotEmpty) return s.startsWith('imgbb:') ? s : 'imgbb:$s';
      }
    } catch (_) {}
    final last = Uri.tryParse(url)?.pathSegments.lastOrNull ?? 'photo';
    return 'imgbb:$last';
  }

  Future<void> _pickPhoto(String docId) async {
    if (_uploading) return;
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 900,
      );
      if (image == null) return;

      setState(() {
        _uploading = true;
        _uploadingDocId = docId;
      });

      final raw = await image.readAsBytes();
      if (raw.isEmpty) {
        _toast(AppLang.tr('empty_file'), error: true);
        return;
      }

      final result = await MediaUploadService.uploadImageBytes(
        bytes: Uint8List.fromList(raw),
        fileName:
            'bridal_${docId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final url = _urlFrom(result);
      final path = _pathFrom(result, url);

      await _ref.doc(docId).set({
        'photoUrl': url,
        'storagePath': path,
        'provider': 'imgbb',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _toast(AppLang.tr('photo_saved_ok'));
    } catch (e) {
      _toast('${AppLang.tr('photo_upload_failed')}: $e', error: true);
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadingDocId = null;
        });
      }
    }
  }

  Future<void> _saveAndBack() async {
    setState(() => _saving = true);
    try {
      _toast(AppLang.tr('saved'));
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        return Directionality(
          textDirection: AppLang.I.direction,
          child: Scaffold(
            backgroundColor: AppTok.background(context),
            appBar: AppBar(
              backgroundColor: AppTok.background(context),
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppTok.accent(context),
                  size: 20,
                ),
              ),
              title: Text(
                AppLang.tr('bridal_party_title'),
                style: TextStyle(
                  color: AppTok.text(context),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: (_saving || _uploading) ? null : _saveAndBack,
                  icon: _saving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTok.accent(context),
                          ),
                        )
                      : Icon(
                          Icons.check_rounded,
                          color: AppTok.accent(context),
                          size: 26,
                        ),
                ),
              ],
            ),
            body: Stack(
              children: [
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _ref.snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            '${AppLang.tr('data_load_error')}\n${snap.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTok.danger(context),
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    }
                    if (!snap.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppTok.accent(context),
                        ),
                      );
                    }

                    final all = snap.data!.docs.toList()
                      ..sort((a, b) {
                        final oa = (a.data()['order'] ?? 0) as num;
                        final ob = (b.data()['order'] ?? 0) as num;
                        return oa.compareTo(ob);
                      });

                    final brides = all
                        .where((d) => (d.data()['side'] ?? '') == 'bride')
                        .toList();
                    final grooms = all
                        .where((d) => (d.data()['side'] ?? '') == 'groom')
                        .toList();

                    return LayoutBuilder(
                      builder: (context, c) {
                        final wide = c.maxWidth >= 700;
                        final pad = EdgeInsets.fromLTRB(
                          wide ? 20 : 12,
                          8,
                          wide ? 20 : 12,
                          24,
                        );

                        final brideCol = _sideColumn(
                          context: context,
                          side: 'bride',
                          title: AppLang.tr('bride_party'),
                          accent: const Color(0xFFE8B4C8),
                          icon: Icons.woman_2_rounded,
                          docs: brides,
                        );
                        final groomCol = _sideColumn(
                          context: context,
                          side: 'groom',
                          title: AppLang.tr('groom_party'),
                          accent: const Color(0xFFB8C9E0),
                          icon: Icons.man_2_rounded,
                          docs: grooms,
                        );

                        if (wide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ListView(
                                  padding: pad,
                                  children: [brideCol],
                                ),
                              ),
                              Container(
                                width: 1,
                                color: AppTok.border(context),
                              ),
                              Expanded(
                                child: ListView(
                                  padding: pad,
                                  children: [groomCol],
                                ),
                              ),
                            ],
                          );
                        }

                        // موبایل: دو ستون کنار هم با اسکرول عمودی مشترک
                        return SingleChildScrollView(
                          padding: pad,
                          child: Column(
                            children: [
                              _heroBanner(context, brides.length, grooms.length),
                              const SizedBox(height: 14),
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: brideCol),
                                    const SizedBox(width: 10),
                                    Expanded(child: groomCol),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                if (_uploading)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black54,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppTok.card(context),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppTok.accent(context)
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  color: AppTok.accent(context),
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                AppLang.tr('photo_uploading'),
                                style: TextStyle(
                                  color: AppTok.text(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _heroBanner(BuildContext context, int b, int g) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTok.card(context),
            AppTok.accent(context).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTok.accent(context).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTok.accent(context).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.groups_2_rounded, color: AppTok.accent(context)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLang.tr('bridal_party_title'),
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppLang.tr('bridal_party_hint'),
                  style: TextStyle(
                    color: AppTok.textSoft(context),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${b + g}',
            style: TextStyle(
              color: AppTok.accent(context),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideColumn({
    required BuildContext context,
    required String side,
    required String title,
    required Color accent,
    required IconData icon,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${docs.length}',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (docs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                AppLang.tr('bridal_empty_side'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            )
          else
            ...docs.map((d) => _personTile(context, d, accent, side)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _uploading ? null : () => _addPerson(side),
            icon: Icon(Icons.add_rounded, color: accent, size: 18),
            label: Text(
              AppLang.tr('add_person'),
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: accent.withValues(alpha: 0.55)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _personTile(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Color accent,
    String side,
  ) {
    final data = doc.data();
    final name = (data['name'] ?? '').toString().trim();
    final role = (data['role'] ?? '').toString().trim();
    final note = (data['note'] ?? '').toString().trim();
    final photo = (data['photoUrl'] ?? '').toString();
    final expanded = _expandedId == doc.id;
    final busy = _uploading && _uploadingDocId == doc.id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTok.cardSoft(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expanded
              ? accent.withValues(alpha: 0.65)
              : AppTok.border(context),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() {
              _expandedId = expanded ? null : doc.id;
            }),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: busy ? null : () => _pickPhoto(doc.id),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: accent.withValues(alpha: 0.15),
                      backgroundImage:
                          photo.isNotEmpty ? NetworkImage(photo) : null,
                      child: busy
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTok.accent(context),
                              ),
                            )
                          : (photo.isEmpty
                              ? Icon(
                                  side == 'bride'
                                      ? Icons.woman_2_rounded
                                      : Icons.man_2_rounded,
                                  color: accent,
                                  size: 22,
                                )
                              : null),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? AppLang.tr('display_name') : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: name.isEmpty
                                ? AppTok.textSoft(context)
                                : AppTok.text(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (role.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            role,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 2),
                          Text(
                            AppLang.tr('bridal_tap_details'),
                            style: TextStyle(
                              color: AppTok.textSoft(context),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTok.textSoft(context),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            _ExpandedEditor(
              key: ValueKey('ed-${doc.id}'),
              accent: accent,
              initialName: name,
              initialRole: role,
              initialNote: note,
              onSave: (n, r, noteV) {
                _ref.doc(doc.id).set({
                  'name': n.trim(),
                  'role': r.trim(),
                  'note': noteV.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
              },
              onPhoto: () => _pickPhoto(doc.id),
              onDelete: () => _deletePerson(doc.id),
            ),
        ],
      ),
    );
  }
}

class _ExpandedEditor extends StatefulWidget {
  const _ExpandedEditor({
    super.key,
    required this.accent,
    required this.initialName,
    required this.initialRole,
    required this.initialNote,
    required this.onSave,
    required this.onPhoto,
    required this.onDelete,
  });

  final Color accent;
  final String initialName;
  final String initialRole;
  final String initialNote;
  final void Function(String name, String role, String note) onSave;
  final VoidCallback onPhoto;
  final VoidCallback onDelete;

  @override
  State<_ExpandedEditor> createState() => _ExpandedEditorState();
}

class _ExpandedEditorState extends State<_ExpandedEditor> {
  late final TextEditingController _name;
  late final TextEditingController _role;
  late final TextEditingController _note;
  Timer? _deb;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _role = TextEditingController(text: widget.initialRole);
    _note = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _deb?.cancel();
    _name.dispose();
    _role.dispose();
    _note.dispose();
    super.dispose();
  }

  void _schedule() {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 450), () {
      widget.onSave(_name.text, _role.text, _note.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(
            color: AppTok.border(context).withValues(alpha: 0.6),
            height: 1,
          ),
          const SizedBox(height: 12),
          Text(
            AppLang.tr('name_required_label'),
            style: TextStyle(color: AppTok.textSoft(context), fontSize: 11),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            style: TextStyle(color: AppTok.text(context), fontSize: 13),
            cursorColor: AppTok.accent(context),
            onChanged: (_) => _schedule(),
            decoration: _dec(context, AppLang.tr('display_name')),
          ),
          const SizedBox(height: 10),
          Text(
            AppLang.tr('bridal_role_label'),
            style: TextStyle(color: AppTok.textSoft(context), fontSize: 11),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _role,
            style: TextStyle(color: AppTok.text(context), fontSize: 13),
            cursorColor: AppTok.accent(context),
            onChanged: (_) => _schedule(),
            decoration: _dec(context, AppLang.tr('bridal_role_hint')),
          ),
          const SizedBox(height: 10),
          Text(
            AppLang.tr('description'),
            style: TextStyle(color: AppTok.textSoft(context), fontSize: 11),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 4,
            style: TextStyle(color: AppTok.text(context), fontSize: 13),
            cursorColor: AppTok.accent(context),
            onChanged: (_) => _schedule(),
            decoration: _dec(context, AppLang.tr('description')),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: widget.onPhoto,
                icon: Icon(
                  Icons.photo_camera_outlined,
                  size: 16,
                  color: widget.accent,
                ),
                label: Text(
                  AppLang.tr('add_photo').replaceAll('\n', ' '),
                  style: TextStyle(color: widget.accent, fontSize: 12),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: widget.onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: AppTok.danger(context),
                ),
                label: Text(
                  AppLang.tr('delete'),
                  style: TextStyle(
                    color: AppTok.danger(context),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppTok.textSoft(context).withValues(alpha: 0.75),
      ),
      filled: true,
      fillColor: AppTok.background(context),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTok.border(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTok.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: widget.accent),
      ),
    );
  }
}

extension _LastOrNull<E> on List<E> {
  E? get lastOrNull => isEmpty ? null : last;
}