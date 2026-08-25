import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_lang.dart';

enum MediaKind {
  general,
  cover,
  couple,
  invite,
  gallery,
  story,
  other,
}

class MediaItemModel {
  final String id;
  final String url;
  final String deleteUrl;
  final String providerId;
  final String storagePath;
  final String fileName;
  final String title;
  final MediaKind kind;
  final DateTime? createdAt;
  final String uploadedBy;

  const MediaItemModel({
    required this.id,
    required this.url,
    required this.deleteUrl,
    required this.providerId,
    required this.storagePath,
    required this.fileName,
    required this.title,
    required this.kind,
    required this.createdAt,
    required this.uploadedBy,
  });

  static MediaKind kindFromString(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'cover':
        return MediaKind.cover;
      case 'couple':
        return MediaKind.couple;
      case 'invite':
        return MediaKind.invite;
      case 'gallery':
        return MediaKind.gallery;
      case 'story':
        return MediaKind.story;
      case 'other':
        return MediaKind.other;
      default:
        return MediaKind.general;
    }
  }

  static String kindToString(MediaKind k) {
    switch (k) {
      case MediaKind.cover:
        return 'cover';
      case MediaKind.couple:
        return 'couple';
      case MediaKind.invite:
        return 'invite';
      case MediaKind.gallery:
        return 'gallery';
      case MediaKind.story:
        return 'story';
      case MediaKind.other:
        return 'other';
      case MediaKind.general:
        return 'general';
    }
  }

  String get kindLabel {
    switch (kind) {
      case MediaKind.cover:
        return AppLang.tr('media_kind_cover');
      case MediaKind.couple:
        return AppLang.tr('media_kind_couple');
      case MediaKind.invite:
        return AppLang.tr('media_kind_invite');
      case MediaKind.gallery:
        return AppLang.tr('media_kind_gallery');
      case MediaKind.story:
        return AppLang.tr('media_kind_story');
      case MediaKind.other:
        return AppLang.tr('media_kind_other');
      case MediaKind.general:
        return AppLang.tr('media_kind_general');
    }
  }

  factory MediaItemModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return MediaItemModel(
      id: doc.id,
      url: (d['url'] ?? '').toString(),
      deleteUrl: (d['deleteUrl'] ?? '').toString(),
      providerId: (d['providerId'] ?? '').toString(),
      storagePath: (d['storagePath'] ?? '').toString(),
      fileName: (d['fileName'] ?? '').toString(),
      title: (d['title'] ?? '').toString(),
      kind: kindFromString(d['kind']?.toString()),
      createdAt: (d['createdAt'] is Timestamp)
          ? (d['createdAt'] as Timestamp).toDate()
          : null,
      uploadedBy: (d['uploadedBy'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'deleteUrl': deleteUrl,
      'providerId': providerId,
      'storagePath': storagePath,
      'fileName': fileName,
      'title': title,
      'kind': kindToString(kind),
      'provider': 'imgbb',
      'uploadedBy': uploadedBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}