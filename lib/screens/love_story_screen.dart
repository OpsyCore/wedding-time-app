import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../services/media_upload_service.dart';

/// داستان عشق
/// - آپلود: ImgBB (بدون Firebase Storage / بدون dart:io)
/// - تم: AppTok
/// - i18n کامل
class LoveStoryScreen extends StatefulWidget {
  const LoveStoryScreen({super.key, required this.weddingId});

  final String weddingId;

  @override
  State<LoveStoryScreen> createState() => _LoveStoryScreenState();
}

class _LoveStoryScreenState extends State<LoveStoryScreen> {
  bool _saving = false;
  bool _uploading = false;
  String? _uploadingDocId;

  final _picker = ImagePicker();

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance
          .collection('weddings')
          .doc(widget.weddingId)
          .collection('loveStories');

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            error ? AppTok.danger(context) : AppTok.card(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _addStory() async {
    try {
      await _ref.add({
        'title': '',
        'dateText': '',
        'content': '',
        'photoUrl': '',
        'storagePath': '',
        'provider': 'imgbb',
        'order': DateTime.now().millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
      });
    } catch (e) {
      _toast('${AppLang.tr('add_story_error')}: $e', error: true);
    }
  }

  Future<void> _deleteStory(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: AppLang.I.direction,
        child: AlertDialog(
          backgroundColor: AppTok.card(context),
          title: Text(
            AppLang.tr('delete_story'),
            style: TextStyle(color: AppTok.text(context)),
          ),
          content: Text(
            AppLang.tr('delete_story_confirm'),
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
      // ImgBB — فقط سند Firestore
      await _ref.doc(id).delete();
      _toast(AppLang.tr('deleted'));
    } catch (e) {
      _toast('${AppLang.tr('delete_error')}$e', error: true);
    }
  }

  String _urlFromUploadResult(dynamic result) {
    try {
      final u = (result.url ?? result.displayUrl ?? result.imageUrl ?? '')
          .toString()
          .trim();
      if (u.isNotEmpty) return u;
    } catch (_) {}
    throw Exception(AppLang.tr('photo_upload_failed'));
  }

  String _pathFromUploadResult(dynamic result, String url) {
    try {
      final dynamic id = result.id ??
          result.providerId ??
          result.imageId ??
          result.deleteUrl;
      if (id != null) {
        final s = id.toString().trim();
        if (s.isNotEmpty) {
          return s.startsWith('imgbb:') ? s : 'imgbb:$s';
        }
      }
    } catch (_) {}

    try {
      final dynamic path = result.path ?? result.storagePath ?? result.ref;
      if (path != null) {
        final s = path.toString().trim();
        if (s.isNotEmpty) return s;
      }
    } catch (_) {}

    final uri = Uri.tryParse(url);
    final last = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : 'photo';
    return 'imgbb:$last';
  }

  Future<void> _pickPhoto(String docId) async {
    if (_uploading) return;

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1400,
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

      final bytes = Uint8List.fromList(raw);
      final fileName =
          'love_${docId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await MediaUploadService.uploadImageBytes(
        bytes: bytes,
        fileName: fileName,
      );

      final url = _urlFromUploadResult(result);
      final storagePath = _pathFromUploadResult(result, url);

      await _ref.doc(docId).update({
        'photoUrl': url,
        'storagePath': storagePath,
        'provider': 'imgbb',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) _toast(AppLang.tr('photo_saved_ok'));
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

  Future<void> _applySuggestion(String docId) async {
    final suggestions = [
      {
        'title': AppLang.tr('suggestion_first_look_title'),
        'dateText': AppLang.tr('suggestion_first_look_date'),
        'content': AppLang.tr('suggestion_first_look_body'),
      },
      {
        'title': AppLang.tr('suggestion_first_date_title'),
        'dateText': AppLang.tr('suggestion_first_date_date'),
        'content': AppLang.tr('suggestion_first_date_body'),
      },
      {
        'title': AppLang.tr('suggestion_yes_title'),
        'dateText': AppLang.tr('suggestion_yes_date'),
        'content': AppLang.tr('suggestion_yes_body'),
      },
    ];

    final index = DateTime.now().millisecond % suggestions.length;
    final s = suggestions[index];

    try {
      await _ref.doc(docId).update({
        'title': s['title'],
        'dateText': s['dateText'],
        'content': s['content'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _toast(AppLang.tr('suggestion_applied'));
    } catch (e) {
      _toast('${AppLang.tr('error')}: $e', error: true);
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
                AppLang.tr('love_story_title'),
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
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            '${AppLang.tr('stories_load_error')}:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTok.danger(context)),
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppTok.accent(context),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs.toList()
                      ..sort((a, b) {
                        final oa = (a.data()['order'] ?? 0) as num;
                        final ob = (b.data()['order'] ?? 0) as num;
                        return oa.compareTo(ob);
                      });

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                      children: [
                        _heroCard(context, docs.length),
                        const SizedBox(height: 14),
                        if (docs.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: AppTok.card(context),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: AppTok.border(context),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.favorite_border_rounded,
                                  color: AppTok.accent(context)
                                      .withValues(alpha: 0.75),
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  AppLang.tr('no_stories_yet'),
                                  style: TextStyle(
                                    color: AppTok.textSoft(context),
                                    height: 1.6,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ...List.generate(docs.length, (index) {
                          final doc = docs[index];
                          final busy =
                              _uploading && _uploadingDocId == doc.id;
                          return _StoryCard(
                            key: ValueKey(doc.id),
                            index: index + 1,
                            doc: doc,
                            uploading: busy,
                            onPickPhoto: () => _pickPhoto(doc.id),
                            onSuggest: () => _applySuggestion(doc.id),
                            onDelete: () => _deleteStory(doc.id),
                            onChanged: (title, dateText, content) {
                              _ref.doc(doc.id).set({
                                'title': title,
                                'dateText': dateText,
                                'content': content,
                                'updatedAt': FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));
                            },
                          );
                        }),
                        const SizedBox(height: 8),
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: _uploading ? null : _addStory,
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: AppTok.accent(context),
                            ),
                            label: Text(
                              AppLang.tr('add_story'),
                              style: TextStyle(
                                color: AppTok.accent(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppTok.accent(context)
                                    .withValues(alpha: 0.45),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                                  fontSize: 13,
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

  Widget _heroCard(BuildContext context, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTok.accent(context).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTok.accent(context).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: AppTok.accent(context),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLang.tr('love_story'),
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLang.tr('tell_this_part_of_story'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTok.textSoft(context),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTok.cardSoft(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTok.accent(context).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: AppTok.text(context),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatefulWidget {
  const _StoryCard({
    super.key,
    required this.index,
    required this.doc,
    required this.uploading,
    required this.onPickPhoto,
    required this.onSuggest,
    required this.onDelete,
    required this.onChanged,
  });

  final int index;
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool uploading;
  final VoidCallback onPickPhoto;
  final VoidCallback onSuggest;
  final VoidCallback onDelete;
  final void Function(String title, String dateText, String content) onChanged;

  @override
  State<_StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<_StoryCard> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _contentCtrl;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final data = widget.doc.data();
    _titleCtrl = TextEditingController(text: data['title']?.toString() ?? '');
    _dateCtrl =
        TextEditingController(text: data['dateText']?.toString() ?? '');
    _contentCtrl =
        TextEditingController(text: data['content']?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant _StoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // فقط وقتی پیشنهاد اعمال شده / داده بیرون عوض شده
    if (oldWidget.doc.id != widget.doc.id) return;
    final data = widget.doc.data();
    final newTitle = data['title']?.toString() ?? '';
    final newDate = data['dateText']?.toString() ?? '';
    final newContent = data['content']?.toString() ?? '';

    if (_titleCtrl.text != newTitle && !_titleCtrl.selection.isValid) {
      _titleCtrl.text = newTitle;
    } else if (_titleCtrl.text != newTitle &&
        oldWidget.doc.data()['title'] != data['title']) {
      // suggestion apply
      _titleCtrl.value = TextEditingValue(
        text: newTitle,
        selection: TextSelection.collapsed(offset: newTitle.length),
      );
    }

    if (_dateCtrl.text != newDate &&
        oldWidget.doc.data()['dateText'] != data['dateText']) {
      _dateCtrl.value = TextEditingValue(
        text: newDate,
        selection: TextSelection.collapsed(offset: newDate.length),
      );
    }

    if (_contentCtrl.text != newContent &&
        oldWidget.doc.data()['content'] != data['content']) {
      _contentCtrl.value = TextEditingValue(
        text: newContent,
        selection: TextSelection.collapsed(offset: newContent.length),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleCtrl.dispose();
    _dateCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _scheduleEmit() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      widget.onChanged(
        _titleCtrl.text.trim(),
        _dateCtrl.text.trim(),
        _contentCtrl.text.trim(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data();
    final photoUrl = data['photoUrl']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTok.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTok.accent(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.index}',
                  style: TextStyle(
                    color: AppTok.accent(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${AppLang.tr('story_n')} ${widget.index}',
                style: TextStyle(
                  color: AppTok.text(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: widget.uploading ? null : widget.onPickPhoto,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppTok.cardSoft(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTok.accent(context).withValues(alpha: 0.25),
                    ),
                    image: photoUrl.isNotEmpty && !widget.uploading
                        ? DecorationImage(
                            image: NetworkImage(photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: widget.uploading
                      ? Center(
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppTok.accent(context),
                            ),
                          ),
                        )
                      : (photoUrl.isEmpty
                          ? Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppTok.accent(context),
                              size: 28,
                            )
                          : Align(
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                margin: const EdgeInsets.all(6),
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: AppTok.accent(context),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            )),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.uploading ? null : widget.onSuggest,
                  icon: Icon(
                    Icons.auto_awesome,
                    color: AppTok.accent(context),
                    size: 18,
                  ),
                  label: Text(
                    AppLang.tr('suggest'),
                    style: TextStyle(
                      color: AppTok.accent(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppTok.accent(context).withValues(alpha: 0.35),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: AppTok.cardSoft(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppLang.tr('event_name_required'),
            style: TextStyle(color: AppTok.textSoft(context), fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            style: TextStyle(color: AppTok.text(context)),
            cursorColor: AppTok.accent(context),
            decoration: _dec(context, AppLang.tr('title')),
            onChanged: (_) => _scheduleEmit(),
          ),
          const SizedBox(height: 14),
          Text(
            AppLang.tr('date_required_label'),
            style: TextStyle(color: AppTok.textSoft(context), fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _dateCtrl,
            style: TextStyle(color: AppTok.text(context)),
            cursorColor: AppTok.accent(context),
            decoration: _dec(context, AppLang.tr('when_did_this_happen')),
            onChanged: (_) => _scheduleEmit(),
          ),
          const SizedBox(height: 14),
          Text(
            AppLang.tr('content_required_label'),
            style: TextStyle(color: AppTok.textSoft(context), fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentCtrl,
            style: TextStyle(color: AppTok.text(context), height: 1.6),
            cursorColor: AppTok.accent(context),
            minLines: 4,
            maxLines: 8,
            decoration: _dec(context, AppLang.tr('tell_this_part_of_story')),
            onChanged: (_) => _scheduleEmit(),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: widget.uploading ? null : widget.onDelete,
              icon: Icon(
                Icons.delete_outline,
                color: AppTok.danger(context),
                size: 18,
              ),
              label: Text(
                AppLang.tr('delete'),
                style: TextStyle(color: AppTok.danger(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppTok.textSoft(context).withValues(alpha: 0.7),
      ),
      filled: true,
      fillColor: AppTok.cardSoft(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTok.border(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTok.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTok.accent(context)),
      ),
    );
  }
}