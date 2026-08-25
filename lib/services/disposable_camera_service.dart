import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../core/app_lang.dart';
import '../models/guest_media_model.dart';
import 'media_upload_service.dart';
import 'notification_service.dart';

/// دوربین یک‌بارمصرف — ذخیره روی ImgBB (نه Firebase Storage)
class DisposableCameraService {
  DisposableCameraService(this.weddingId);

  final String weddingId;
  final _uuid = const Uuid();

  DocumentReference<Map<String, dynamic>> get settingsRef =>
      FirebaseFirestore.instance
          .collection('weddings')
          .doc(weddingId)
          .collection('cameraSettings')
          .doc('main');

  CollectionReference<Map<String, dynamic>> get mediaRef =>
      FirebaseFirestore.instance
          .collection('weddings')
          .doc(weddingId)
          .collection('guestMedia');

  DocumentReference<Map<String, dynamic>> get gallerySettingsRef =>
      FirebaseFirestore.instance
          .collection('weddings')
          .doc(weddingId)
          .collection('gallery')
          .doc('settings');

  Future<CameraSettingsModel> ensureSettings() async {
    final snap = await settingsRef.get();
    if (!snap.exists) {
      final defaults = CameraSettingsModel.defaults();
      await settingsRef.set({
        ...defaults.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return defaults;
    }
    return CameraSettingsModel.fromMap(snap.data());
  }

  Stream<CameraSettingsModel> watchSettings() {
    return settingsRef.snapshots().map((s) {
      if (!s.exists) return CameraSettingsModel.defaults();
      return CameraSettingsModel.fromMap(s.data());
    });
  }

  Future<void> updateSettings(CameraSettingsModel settings) {
    return settingsRef.set(settings.toMap(), SetOptions(merge: true));
  }

  Future<void> syncAlbumToGallerySettings(String albumUrl) async {
    final url = albumUrl.trim();
    await gallerySettingsRef.set({
      'externalAlbumUrl': url,
      'isEnabled': url.isNotEmpty,
      'storageMode': 'imgbb_plus_external',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> getExternalAlbumUrl() async {
    final cam = await ensureSettings();
    if (cam.hasAlbum) return cam.externalAlbumUrl.trim();
    final g = await gallerySettingsRef.get();
    return (g.data()?['externalAlbumUrl'] ?? '').toString().trim();
  }

  Future<bool> openExternalAlbum([String? url]) async {
    final raw = (url ?? await getExternalAlbumUrl()).trim();
    if (raw.isEmpty) return false;
    var uri = Uri.tryParse(raw);
    if (uri == null) return false;
    if (!uri.hasScheme) uri = Uri.tryParse('https://$raw');
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Stream<List<GuestMediaModel>> watchMedia({String? status}) {
    Query<Map<String, dynamic>> query =
        mediaRef.orderBy('createdAt', descending: true);
    if (status != null && status != 'all') {
      query = mediaRef
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true);
    }
    return query.snapshots().map(
          (s) => s.docs.map(GuestMediaModel.fromDoc).toList(),
        );
  }

  Future<String> getUploaderKey() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'guest_camera_uploader_key';
    var value = prefs.getString(key);
    if (value == null || value.isEmpty) {
      value = _uuid.v4();
      await prefs.setString(key, value);
    }
    return value;
  }

  Future<String> getUploaderName() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('guest_camera_uploader_name')?.trim();
    if (saved == null ||
        saved.isEmpty ||
        saved == 'مهمان' ||
        saved.toLowerCase() == 'guest') {
      return AppLang.tr('guest');
    }
    return saved;
  }

  Future<void> setUploaderName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('guest_camera_uploader_name', name.trim());
  }

  Future<Map<String, int>> getUsage(String uploaderKey) async {
    final snap =
        await mediaRef.where('uploaderKey', isEqualTo: uploaderKey).get();
    int photos = 0;
    int videos = 0;
    for (final d in snap.docs) {
      final type = d.data()['type'];
      if (type == 'video') {
        videos++;
      } else {
        photos++;
      }
    }
    return {'photos': photos, 'videos': videos};
  }

  /// آپلود عکس به ImgBB + ذخیره متادیتا در Firestore
  Future<GuestMediaModel> uploadBytes({
    required List<int> bytes,
    required String type, // photo | video
    required String uploaderName,
    required String uploaderKey,
    required bool autoApprove,
  }) async {
    if (type == 'video') {
      throw Exception(AppLang.tr('video_not_supported_free'));
    }

    final id = _uuid.v4();
    final uploaded = await MediaUploadService.uploadImageBytes(
      bytes: bytes,
      fileName: '$id.jpg',
    );

    final status = autoApprove ? 'approved' : 'pending';
    final finalName = uploaderName.trim().isEmpty
        ? AppLang.tr('guest')
        : uploaderName.trim();

    await mediaRef.doc(id).set({
      'url': uploaded.url,
      'storagePath': 'imgbb:${uploaded.providerId}',
      'deleteUrl': uploaded.deleteUrl,
      'provider': 'imgbb',
      'type': 'photo',
      'status': status,
      'uploaderName': finalName,
      'uploaderKey': uploaderKey,
      'createdAt': FieldValue.serverTimestamp(),
    });

    try {
      await NotificationService(weddingId).notifyGallery(
        uploaderName: finalName,
        isVideo: false,
        mediaId: id,
      );
    } catch (_) {}

    final doc = await mediaRef.doc(id).get();
    return GuestMediaModel.fromDoc(doc);
  }

  Future<void> setStatus(String id, String status) {
    return mediaRef.doc(id).update({
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMedia(GuestMediaModel item) async {
    // فقط سند Firestore — ImgBB delete_url اختیاری بعداً
    await mediaRef.doc(item.id).delete();
  }
}