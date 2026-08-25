import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../models/media_item_model.dart';
import '../services/media_library_service.dart';
import '../widgets/floral_decor.dart';

class MediaLibraryScreen extends StatefulWidget {
  const MediaLibraryScreen({
    super.key,
    required this.weddingId,
    this.pickMode = false,
    this.initialKind,
  });

  final String weddingId;
  final bool pickMode;
  final MediaKind? initialKind;

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen> {
  late final MediaLibraryService _service;
  final _picker = ImagePicker();

  MediaKind? _filter;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _service = MediaLibraryService(widget.weddingId);
    _filter = widget.initialKind;
  }

  Future<void> _upload() async {
    if (_uploading) return;

    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2000,
    );
    if (x == null) return;

    final bytes = await x.readAsBytes();
    if (bytes.isEmpty) return;

    final kind = await _askKindAndTitle();
    if (kind == null) return;

    setState(() => _uploading = true);
    try {
      await _service.uploadImage(
        bytes: bytes,
        fileName: x.name.isNotEmpty ? x.name : 'photo.jpg',
        title: kind.$2,
        kind: kind.$1,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLang.tr('media_upload_ok'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLang.tr('media_upload_failed')}: $e'),
          backgroundColor: AppTok.danger(context),
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<(MediaKind, String)?> _askKindAndTitle({
    MediaKind initialKind = MediaKind.general,
    String initialTitle = '',
  }) async {
    var kind = initialKind;
    final titleC = TextEditingController(text: initialTitle);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final text = AppTok.text(ctx);
            final textSoft = AppTok.textSoft(ctx);
            final card = AppTok.card(ctx);
            final accent = AppTok.accent(ctx);

            return AlertDialog(
              backgroundColor: card,
              surfaceTintColor: Colors.transparent,
              title: Text(
                AppLang.tr('media_upload_title'),
                style: TextStyle(color: text, fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleC,
                    style: TextStyle(color: text),
                    decoration: InputDecoration(
                      labelText: AppLang.tr('media_title'),
                      labelStyle: TextStyle(color: textSoft),
                      filled: true,
                      fillColor: AppTok.background(ctx),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<MediaKind>(
                    initialValue: kind,
                    dropdownColor: card,
                    style: TextStyle(color: text),
                    decoration: InputDecoration(
                      labelText: AppLang.tr('media_kind'),
                      labelStyle: TextStyle(color: textSoft),
                      filled: true,
                      fillColor: AppTok.background(ctx),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: MediaKind.values
                        .map(
                          (k) => DropdownMenuItem(
                            value: k,
                            child: Text(
                              _kindLabel(k),
                              style: TextStyle(color: text),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setLocal(() => kind = v);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    AppLang.tr('cancel'),
                    style: TextStyle(color: textSoft),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    AppLang.tr('save'),
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    final title = titleC.text.trim();
    titleC.dispose();
    if (ok != true) return null;
    return (kind, title);
  }

  String _kindLabel(MediaKind k) {
    return MediaItemModel(
      id: '',
      url: '',
      deleteUrl: '',
      providerId: '',
      storagePath: '',
      fileName: '',
      title: '',
      kind: k,
      createdAt: null,
      uploadedBy: '',
    ).kindLabel;
  }

  Future<void> _edit(MediaItemModel item) async {
    final res = await _askKindAndTitle(
      initialKind: item.kind,
      initialTitle: item.title,
    );
    if (res == null) return;
    await _service.updateMeta(id: item.id, kind: res.$1, title: res.$2);
  }

  Future<void> _delete(MediaItemModel item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTok.card(ctx),
        surfaceTintColor: Colors.transparent,
        title: Text(
          AppLang.tr('media_delete_title'),
          style: TextStyle(color: AppTok.text(ctx)),
        ),
        content: Text(
          AppLang.tr('media_delete_body'),
          style: TextStyle(color: AppTok.textSoft(ctx)),
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
              style: TextStyle(color: AppTok.danger(ctx)),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.deleteItem(item);
  }

  Future<void> _copyUrl(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLang.tr('media_link_copied'))),
    );
  }

  void _onTapItem(MediaItemModel item) {
    if (widget.pickMode) {
      Navigator.pop(context, item);
      return;
    }
    _openPreview(item);
  }

  void _openPreview(MediaItemModel item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTok.card(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final text = AppTok.text(ctx);
        final textSoft = AppTok.textSoft(ctx);
        final accent = AppTok.accent(ctx);
        final accentDeep = AppTok.accentDeep(ctx);
        final danger = AppTok.danger(ctx);
        final border = AppTok.border(ctx);
        final bg = AppTok.background(ctx);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CachedNetworkImage(
                      imageUrl: item.url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => ColoredBox(
                        color: bg,
                        child: Center(
                          child: CircularProgressIndicator(color: accent),
                        ),
                      ),
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: bg,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: textSoft,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.title.isEmpty ? item.fileName : item.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.kindLabel,
                  style: TextStyle(
                    color: accentDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyUrl(item.url),
                        icon: Icon(Icons.link, size: 18, color: accentDeep),
                        label: Text(AppLang.tr('media_copy_link')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: text,
                          side: BorderSide(color: border),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _edit(item);
                        },
                        icon: Icon(Icons.edit_outlined,
                            size: 18, color: accentDeep),
                        label: Text(AppLang.tr('edit')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: text,
                          side: BorderSide(color: border),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _delete(item);
                    },
                    icon: Icon(Icons.delete_outline, color: danger, size: 18),
                    label: Text(
                      AppLang.tr('delete'),
                      style: TextStyle(color: danger),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: danger.withValues(alpha: 0.45)),
                    ),
                  ),
                ),
                if (widget.pickMode) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context, item);
                      },
                      icon: const Icon(Icons.check),
                      label: Text(AppLang.tr('media_use_this')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
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
        final dark = AppTok.isDark(context);

        return Directionality(
          textDirection: AppLang.I.direction,
          child: Scaffold(
            backgroundColor: bg,
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'media_library_fab',
              onPressed: _uploading ? null : _upload,
              backgroundColor: accent,
              foregroundColor: Colors.white,
              icon: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _uploading
                    ? AppLang.tr('media_uploading')
                    : AppLang.tr('media_upload'),
              ),
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  // در Dark گل‌های روشن صفحه را «سفید» می‌کنند → کم‌رنگ / خاموش
                  if (!dark)
                    const Positioned.fill(
                      child: FloralDecor(intensity: 0.8),
                    )
                  else
                    const Positioned.fill(
  child: IgnorePointer(
    child: Opacity(
      opacity: 0.22,
      child: FloralDecor(intensity: 0.45),
    ),
  ),
),
                  // لایهٔ نیمه‌شفاف تا grid روی تم بنشیند
                  if (dark)
                    Positioned.fill(
                      child: ColoredBox(
                        color: bg.withValues(alpha: 0.72),
                      ),
                    ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                AppLang.I.isFa
                                    ? Icons.arrow_forward
                                    : Icons.arrow_back,
                                color: text,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.pickMode
                                    ? AppLang.tr('media_pick_title')
                                    : AppLang.tr('media_library'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: text,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 42,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            _chip(
                              label: AppLang.tr('media_filter_all'),
                              selected: _filter == null,
                              onTap: () => setState(() => _filter = null),
                            ),
                            ...MediaKind.values.map(
                              (k) => _chip(
                                label: _kindLabel(k),
                                selected: _filter == k,
                                onTap: () => setState(() => _filter = k),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: StreamBuilder<List<MediaItemModel>>(
                          stream: _service.watchAll(kind: _filter),
                          builder: (context, snap) {
                            if (snap.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    '${AppLang.tr('media_load_error')}\n${snap.error}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: textSoft),
                                  ),
                                ),
                              );
                            }
                            if (!snap.hasData) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: accent,
                                ),
                              );
                            }
                            final items = snap.data!;
                            if (items.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(28),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.photo_library_outlined,
                                        size: 48,
                                        color: textSoft,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        AppLang.tr('media_empty'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: text,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        AppLang.tr('media_empty_hint'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: textSoft,
                                          fontSize: 12.5,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return GridView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 8, 12, 96),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 0.78,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, i) {
                                final item = items[i];
                                return _MediaTile(
                                  item: item,
                                  onTap: () => _onTapItem(item),
                                  onLongPress: () => _openPreview(item),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final dark = AppTok.isDark(context);
    final brandSoft =
        dark ? AppDarkPalette.brandGreenSoft : AppPalette.brandGreenSoft;
    final card = AppTok.card(context);
    final border = AppTok.border(context);
    final accent = AppTok.accent(context);
    final accentDeep = AppTok.accentDeep(context);
    final textSoft = AppTok.textSoft(context);

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Material(
        color: selected ? brandSoft : card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? accent : border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? accentDeep : textSoft,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  final MediaItemModel item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final card = AppTok.card(context);
    final cardSoft = AppTok.cardSoft(context);
    final border = AppTok.border(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);
    final accentDeep = AppTok.accentDeep(context);

    return Material(
      color: card,
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(13),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: item.url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => ColoredBox(
                      color: cardSoft,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => ColoredBox(
                      color: cardSoft,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: textSoft,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? item.fileName : item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: text,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.kindLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accentDeep,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<MediaItemModel?> pickFromMediaLibrary(
  BuildContext context, {
  required String weddingId,
  MediaKind? kind,
}) {
  return Navigator.of(context).push<MediaItemModel>(
    MaterialPageRoute(
      builder: (_) => MediaLibraryScreen(
        weddingId: weddingId,
        pickMode: true,
        initialKind: kind,
      ),
    ),
  );
}