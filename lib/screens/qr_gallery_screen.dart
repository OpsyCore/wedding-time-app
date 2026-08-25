import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../core/app_config.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../models/guest_media_model.dart';
import '../services/disposable_camera_service.dart';
import 'camera_manage_screen.dart';
import 'guest_camera_screen.dart';

class QrGalleryScreen extends StatefulWidget {
  const QrGalleryScreen({super.key, this.weddingId});

  final String? weddingId;

  @override
  State<QrGalleryScreen> createState() => _QrGalleryScreenState();
}

class _QrGalleryScreenState extends State<QrGalleryScreen> {
  final _uuid = const Uuid();
  final _albumC = TextEditingController();

  String? _weddingId;
  String? _galleryCode;
  bool _loading = true;
  bool _saving = false;
  late DisposableCameraService _cameraService;

  /// اولویت: لینک آلبوم خارجی؛ وگرنه سایت عمومی اپ
  String get _shareLink {
    final album = _albumC.text.trim();
    if (album.isNotEmpty) return album;
    return AppConfig.publicBaseUrl;
  }

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _albumC.dispose();
    super.dispose();
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: AppTok.text(context))),
        backgroundColor:
            error ? AppTok.danger(context) : AppTok.card(context),
      ),
    );
  }

  Future<void> _prepare() async {
    try {
      String? weddingId = widget.weddingId;

      if (weddingId == null || weddingId.trim().isEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception(AppLang.tr('login_required'));
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        weddingId = userDoc.data()?['weddingId']?.toString();
      }

      if (weddingId == null || weddingId.trim().isEmpty) {
        throw Exception(AppLang.tr('no_active_wedding'));
      }

      _cameraService = DisposableCameraService(weddingId);

      final galleryRef = FirebaseFirestore.instance
          .collection('weddings')
          .doc(weddingId)
          .collection('gallery')
          .doc('settings');

      final settings = await galleryRef.get();
      String galleryCode = '';
      String albumUrl = '';

      if (settings.exists) {
        final d = settings.data() ?? {};
        galleryCode = (d['galleryCode'] ?? '').toString();
        albumUrl = (d['externalAlbumUrl'] ?? '').toString();
      }

      if (galleryCode.isEmpty) {
        final shortId =
            weddingId.length > 6 ? weddingId.substring(0, 6) : weddingId;
        galleryCode = '$shortId-${_uuid.v4().substring(0, 6)}'.toLowerCase();
        await galleryRef.set({
          'galleryCode': galleryCode,
          'isEnabled': true,
          'storageMode': 'imgbb_plus_external',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (albumUrl.isEmpty) {
        final cam = await _cameraService.ensureSettings();
        albumUrl = cam.externalAlbumUrl;
      }

      if (!mounted) return;
      setState(() {
        _weddingId = weddingId;
        _galleryCode = galleryCode;
        _albumC.text = albumUrl;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast('${AppLang.tr('error')}: $e', error: true);
    }
  }

  Future<void> _saveAlbum() async {
    final weddingId = _weddingId;
    if (weddingId == null) return;
    final url = _albumC.text.trim();

    setState(() => _saving = true);
    try {
      final current = await _cameraService.ensureSettings();
      await _cameraService.updateSettings(
        current.copyWith(externalAlbumUrl: url),
      );
      await _cameraService.syncAlbumToGallerySettings(url);

      await FirebaseFirestore.instance
          .collection('weddings')
          .doc(weddingId)
          .collection('gallery')
          .doc('settings')
          .set({
        'externalAlbumUrl': url,
        'storageMode': 'imgbb_plus_external',
        'isEnabled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _toast(AppLang.tr('album_link_saved'));
      setState(() {});
    } catch (e) {
      _toast('${AppLang.tr('save_failed')}: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openAlbum() async {
    final raw = _albumC.text.trim();
    if (raw.isEmpty) {
      _toast(AppLang.tr('enter_album_link_first'), error: true);
      return;
    }
    var uri = Uri.tryParse(raw);
    if (uri != null && !uri.hasScheme) {
      uri = Uri.tryParse('https://$raw');
    }
    if (uri == null) {
      _toast(AppLang.tr('invalid_link'), error: true);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _toast(AppLang.tr('could_not_open'), error: true);
  }

  Future<void> _share() async {
    await Share.share(
      '${AppLang.tr('share_album_text')}\n$_shareLink',
      subject: AppLang.tr('gallery_share_subject'),
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _shareLink));
    _toast(AppLang.tr('link_copied'));
  }

  void _openGuestCamera() {
    final id = _weddingId;
    if (id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuestCameraScreen(
          weddingId: id,
          isHostPreview: true,
        ),
      ),
    );
  }

  void _openManage() {
    final id = _weddingId;
    if (id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraManageScreen(weddingId: id),
      ),
    );
  }

  void _showQr() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTok.card(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLang.tr('album_qr'),
                style: TextStyle(
                  color: AppTok.text(ctx),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _shareLink,
                  size: 200,
                  version: QrVersions.auto,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                _shareLink,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: TextStyle(color: AppTok.accent(ctx), fontSize: 11),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  AppLang.tr('close'),
                  style: TextStyle(color: AppTok.accent(ctx)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setMediaStatus(GuestMediaModel item, String status) async {
    try {
      await _cameraService.setStatus(item.id, status);
      _toast(
        status == 'approved'
            ? AppLang.tr('approved_toast')
            : AppLang.tr('rejected_toast'),
      );
    } catch (e) {
      _toast('${AppLang.tr('error')}: $e', error: true);
    }
  }

  Future<void> _deleteMedia(GuestMediaModel item) async {
    try {
      await _cameraService.deleteMedia(item);
      _toast(AppLang.tr('deleted'));
    } catch (e) {
      _toast('${AppLang.tr('delete_failed')}: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onAccent =
        AppTok.isDark(context) ? AppDarkPalette.background : Colors.white;

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
              iconTheme: IconThemeData(color: AppTok.text(context)),
              title: Text(
                AppLang.tr('memories_gallery'),
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: AppLang.tr('guest_camera_sub'),
                  onPressed: _weddingId == null ? null : _openGuestCamera,
                  icon: const Icon(Icons.photo_camera_outlined, size: 22),
                ),
                IconButton(
                  tooltip: AppLang.tr('share'),
                  onPressed: _weddingId == null ? null : _share,
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                ),
              ],
            ),
            body: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTok.accent(context),
                    ),
                  )
                : _weddingId == null
                    ? Center(
                        child: Text(
                          AppLang.tr('no_wedding_found'),
                          style: TextStyle(color: AppTok.textSoft(context)),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTok.card(context),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTok.accent(context)
                                    .withValues(alpha: 0.28),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  AppLang.tr('guest_memories'),
                                  style: TextStyle(
                                    color: AppTok.accent(context),
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  AppLang.tr('qr_gallery_intro'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTok.textSoft(context),
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                InkWell(
                                  onTap: _showQr,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: QrImageView(
                                      data: _shareLink,
                                      size: 140,
                                      version: QrVersions.auto,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _tile(
                                  Icons.qr_code_2,
                                  AppLang.tr('qr_short'),
                                  _showQr,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _tile(
                                  Icons.photo_camera_outlined,
                                  AppLang.tr('camera'),
                                  _openGuestCamera,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _tile(
                                  Icons.copy_rounded,
                                  AppLang.tr('copy_short'),
                                  _copy,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _tile(
                                  Icons.share_outlined,
                                  AppLang.tr('share_short'),
                                  _share,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _tile(
                                  Icons.open_in_new_rounded,
                                  AppLang.tr('album_short'),
                                  _openAlbum,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _tile(
                                  Icons.settings_outlined,
                                  AppLang.tr('manage_short'),
                                  _openManage,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(child: SizedBox()),
                              const SizedBox(width: 8),
                              const Expanded(child: SizedBox()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTok.card(context),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  AppLang.tr('backup_album_link_optional'),
                                  style: TextStyle(
                                    color: AppTok.text(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _albumC,
                                  style: TextStyle(
                                    color: AppTok.text(context),
                                    fontSize: 13,
                                  ),
                                  keyboardType: TextInputType.url,
                                  textDirection: TextDirection.ltr,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText:
                                        'https://photos.google.com/share/...',
                                    hintStyle: TextStyle(
                                      color: AppTok.textSoft(context),
                                      fontSize: 12,
                                    ),
                                    filled: true,
                                    fillColor: AppTok.background(context),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 46,
                                  child: ElevatedButton.icon(
                                    onPressed: _saving ? null : _saveAlbum,
                                    icon: _saving
                                        ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: onAccent,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.save_outlined,
                                            size: 18,
                                          ),
                                    label: Text(AppLang.tr('save_link')),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTok.accent(context),
                                      foregroundColor: onAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            AppLang.tr('submitted_photos'),
                            style: TextStyle(
                              color: AppTok.text(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          StreamBuilder<List<GuestMediaModel>>(
                            stream: _cameraService.watchMedia(),
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AppTok.accent(context),
                                    ),
                                  ),
                                );
                              }
                              final items = snap.data ?? [];
                              if (items.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppTok.card(context),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    AppLang.tr('no_photos_yet_hint'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTok.textSoft(context),
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                );
                              }
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 0.78,
                                ),
                                itemBuilder: (context, i) {
                                  final m = items[i];
                                  return _mediaTile(m);
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTok.card(context),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${AppLang.tr('upload_imgbb_footer')}\n'
                              '${AppLang.tr('gallery_code')}: ${_galleryCode ?? '—'}',
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 12,
                                height: 1.55,
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

  Widget _mediaTile(GuestMediaModel m) {
    final pending = m.isPending;
    return Container(
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: pending
              ? const Color(0xFFE8A33D).withValues(alpha: 0.5)
              : AppTok.accent(context).withValues(alpha: 0.15),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: m.url.isEmpty
                ? ColoredBox(
                    color: AppTok.cardSoft(context),
                    child: Icon(
                      Icons.broken_image,
                      color: AppTok.textSoft(context),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: m.url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Icon(
                      Icons.broken_image,
                      color: AppTok.textSoft(context),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.uploaderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pending
                      ? AppLang.tr('waiting')
                      : (m.isApproved
                          ? AppLang.tr('approved_filter')
                          : m.status),
                  style: TextStyle(
                    color: pending
                        ? const Color(0xFFE8A33D)
                        : AppTok.textSoft(context),
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (pending) ...[
                      _miniIcon(
                        Icons.check_rounded,
                        const Color(0xFF4CD37B),
                        () => _setMediaStatus(m, 'approved'),
                      ),
                      const SizedBox(width: 4),
                      _miniIcon(
                        Icons.close_rounded,
                        AppTok.danger(context),
                        () => _setMediaStatus(m, 'rejected'),
                      ),
                      const SizedBox(width: 4),
                    ],
                    _miniIcon(
                      Icons.delete_outline,
                      AppTok.textSoft(context),
                      () => _deleteMedia(m),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: AppTok.card(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: AppTok.accent(context), size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}