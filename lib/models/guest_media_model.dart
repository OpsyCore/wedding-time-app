import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_lang.dart';

class CameraSettingsModel {
  final bool enabled;
  final int maxShotsPerGuest;
  final int maxVideosPerGuest;
  final bool autoApprove;
  final String externalAlbumUrl;

  const CameraSettingsModel({
    required this.enabled,
    required this.maxShotsPerGuest,
    required this.maxVideosPerGuest,
    required this.autoApprove,
    this.externalAlbumUrl = '',
  });

  factory CameraSettingsModel.defaults() => const CameraSettingsModel(
        enabled: true,
        maxShotsPerGuest: 30,
        maxVideosPerGuest: 3,
        autoApprove: false,
        externalAlbumUrl: '',
      );

  factory CameraSettingsModel.fromMap(Map<String, dynamic>? data) {
    final d = data ?? {};
    return CameraSettingsModel(
      enabled: d['enabled'] ?? true,
      maxShotsPerGuest: (d['maxShotsPerGuest'] ?? 30) as int,
      maxVideosPerGuest: (d['maxVideosPerGuest'] ?? 3) as int,
      autoApprove: d['autoApprove'] ?? false,
      externalAlbumUrl: (d['externalAlbumUrl'] ?? '').toString(),
    );
  }

  CameraSettingsModel copyWith({
    bool? enabled,
    int? maxShotsPerGuest,
    int? maxVideosPerGuest,
    bool? autoApprove,
    String? externalAlbumUrl,
  }) {
    return CameraSettingsModel(
      enabled: enabled ?? this.enabled,
      maxShotsPerGuest: maxShotsPerGuest ?? this.maxShotsPerGuest,
      maxVideosPerGuest: maxVideosPerGuest ?? this.maxVideosPerGuest,
      autoApprove: autoApprove ?? this.autoApprove,
      externalAlbumUrl: externalAlbumUrl ?? this.externalAlbumUrl,
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'maxShotsPerGuest': maxShotsPerGuest,
        'maxVideosPerGuest': maxVideosPerGuest,
        'autoApprove': autoApprove,
        'externalAlbumUrl': externalAlbumUrl.trim(),
        'storageMode': 'external',
        'updatedAt': FieldValue.serverTimestamp(),
      };

  bool get hasAlbum => externalAlbumUrl.trim().isNotEmpty;
}

class GuestMediaModel {
  final String id;
  final String url;
  final String storagePath;
  final String type;
  final String status;
  final String uploaderName;
  final String uploaderKey;
  final DateTime? createdAt;

  GuestMediaModel({
    required this.id,
    required this.url,
    required this.storagePath,
    required this.type,
    required this.status,
    required this.uploaderName,
    required this.uploaderKey,
    required this.createdAt,
  });

  factory GuestMediaModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    // fallback خالی — نمایش با displayUploaderName / AppLang
    final rawName = (data['uploaderName'] ?? '').toString().trim();
    return GuestMediaModel(
      id: doc.id,
      url: (data['url'] ?? '').toString(),
      storagePath: (data['storagePath'] ?? '').toString(),
      type: (data['type'] ?? 'photo').toString(),
      status: (data['status'] ?? 'pending').toString(),
      uploaderName: rawName,
      uploaderKey: (data['uploaderKey'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// نام نمایشی آپلودکننده (i18n)
  String get displayUploaderName {
    final n = uploaderName.trim();
    if (n.isEmpty || n == 'مهمان' || n.toLowerCase() == 'guest') {
      return AppLang.tr('guest');
    }
    return n;
  }

  bool get isPhoto => type == 'photo';
  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
}