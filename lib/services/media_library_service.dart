import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_lang.dart';
import '../models/media_item_model.dart';
import 'media_upload_service.dart';

class MediaLibraryService {
  MediaLibraryService(this.weddingId);

  final String weddingId;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('weddings')
      .doc(weddingId)
      .collection('mediaLibrary');

  Stream<List<MediaItemModel>> watchAll({MediaKind? kind}) {
    // فیلتر سمت کلاینت — بدون composite index
    return _col.orderBy('createdAt', descending: true).snapshots().map((snap) {
      final all = snap.docs.map(MediaItemModel.fromDoc).toList();
      if (kind == null) return all;
      return all.where((e) => e.kind == kind).toList();
    });
  }

    Future<MediaItemModel> uploadImage({
    required Uint8List bytes,
    required String fileName,
    String title = '',
    MediaKind kind = MediaKind.general,
  }) async {
    final uploaded = await MediaUploadService.uploadImageBytes(
      bytes: bytes,
      fileName: fileName,
    );

    final url = uploaded.url.trim();
    if (url.isEmpty) {
      throw Exception(AppLang.tr('media_upload_failed'));
    }

    final deleteUrl = uploaded.deleteUrl;
    final providerId = uploaded.providerId;
    final storagePath =
        providerId.trim().isEmpty ? 'imgbb' : 'imgbb:${providerId.trim()}';

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final doc = _col.doc();

    final item = MediaItemModel(
      id: doc.id,
      url: url,
      deleteUrl: deleteUrl,
      providerId: providerId,
      storagePath: storagePath,
      fileName: fileName,
      title: title.trim().isEmpty ? fileName : title.trim(),
      kind: kind,
      createdAt: DateTime.now(),
      uploadedBy: uid,
    );

    await doc.set(item.toMap());
    return item;
  }

  Future<void> updateMeta({
    required String id,
    String? title,
    MediaKind? kind,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (title != null) data['title'] = title.trim();
    if (kind != null) data['kind'] = MediaItemModel.kindToString(kind);
    await _col.doc(id).update(data);
  }

  Future<void> deleteItem(MediaItemModel item) async {
    await _col.doc(item.id).delete();
  }
}