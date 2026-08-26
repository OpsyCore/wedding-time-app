import 'package:cloud_firestore/cloud_firestore.dart';

class GiftItemModel {
  final String id;
  final String title;
  final String note;
  final String imageUrl;
  final String status; // open | claimed | received
  final String? claimedByName;
  final String? claimedByUid;
  final DateTime? claimedAt;
  final int sortOrder;

  /// اگر false باشد این هدیه در نمای عمومی/مهمان نمایش داده نمی‌شود.
  final bool isPublic;

  const GiftItemModel({
    required this.id,
    required this.title,
    required this.note,
    required this.imageUrl,
    required this.status,
    required this.claimedByName,
    required this.claimedByUid,
    required this.claimedAt,
    required this.sortOrder,
    this.isPublic = true,
  });

  bool get isOpen => status == 'open';
  bool get isClaimed => status == 'claimed' || status == 'received';
  bool get isReceived => status == 'received';

  GiftItemModel copyWith({
    String? title,
    String? note,
    String? imageUrl,
    String? status,
    String? claimedByName,
    String? claimedByUid,
    DateTime? claimedAt,
    int? sortOrder,
    bool? isPublic,
  }) {
    return GiftItemModel(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      claimedByName: claimedByName ?? this.claimedByName,
      claimedByUid: claimedByUid ?? this.claimedByUid,
      claimedAt: claimedAt ?? this.claimedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  factory GiftItemModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    DateTime? claimedAt;
    final raw = d['claimedAt'];
    if (raw is Timestamp) claimedAt = raw.toDate();

    return GiftItemModel(
      id: doc.id,
      title: (d['title'] ?? '').toString(),
      note: (d['note'] ?? '').toString(),
      imageUrl: (d['imageUrl'] ?? '').toString(),
      status: (d['status'] ?? 'open').toString(),
      claimedByName: d['claimedByName']?.toString(),
      claimedByUid: d['claimedByUid']?.toString(),
      claimedAt: claimedAt,
      sortOrder: (d['sortOrder'] as num?)?.toInt() ?? 0,
      isPublic: d['isPublic'] != false,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'note': note,
        'imageUrl': imageUrl,
        'status': status,
        'claimedByName': claimedByName,
        'claimedByUid': claimedByUid,
        'claimedAt': claimedAt == null ? null : Timestamp.fromDate(claimedAt!),
        'sortOrder': sortOrder,
        'isPublic': isPublic,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

/// لاگ هدیه‌های دریافت‌شده (جدا از خودِ هدیه در subcollection).
class ReceivedGiftModel {
  final String id;
  final String giftId;
  final String giftTitle;

  /// از طرف چه کسی / یادداشت کوتاه (اختیاری)
  final String name;
  final DateTime? receivedAt;
  final String note;
  final String createdBy;
  final DateTime? createdAt;

  const ReceivedGiftModel({
    required this.id,
    required this.giftId,
    required this.giftTitle,
    this.name = '',
    this.receivedAt,
    this.note = '',
    this.createdBy = '',
    this.createdAt,
  });

  factory ReceivedGiftModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    DateTime? parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      return DateTime.tryParse(raw?.toString() ?? '');
    }

    return ReceivedGiftModel(
      id: doc.id,
      giftId: (d['giftId'] ?? '').toString(),
      giftTitle: (d['giftTitle'] ?? d['title'] ?? '').toString(),
      name: (d['name'] ?? '').toString(),
      receivedAt: parseDate(d['receivedAt'] ?? d['date']),
      note: (d['note'] ?? '').toString(),
      createdBy: (d['createdBy'] ?? '').toString(),
      createdAt: parseDate(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'giftId': giftId,
        'giftTitle': giftTitle,
        'name': name,
        'receivedAt': receivedAt == null ? null : Timestamp.fromDate(receivedAt!),
        'note': note,
        'createdBy': createdBy,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

class GiftCardInfo {
  final String holderName;
  final String bankName;
  final String cardNumber;
  final bool enabled;

  const GiftCardInfo({
    required this.holderName,
    required this.bankName,
    required this.cardNumber,
    required this.enabled,
  });

  factory GiftCardInfo.fromMap(Map<String, dynamic> m) => GiftCardInfo(
        holderName: (m['holderName'] ?? '').toString(),
        bankName: (m['bankName'] ?? '').toString(),
        cardNumber: (m['cardNumber'] ?? '').toString(),
        enabled: m['enabled'] == true,
      );

  Map<String, dynamic> toMap() => {
        'holderName': holderName,
        'bankName': bankName,
        'cardNumber': cardNumber,
        'enabled': enabled,
      };
}

class GiftSettingsModel {
  final bool showRegistry;
  final bool cardEnabled;
  final List<GiftCardInfo> cards;

  const GiftSettingsModel({
    required this.showRegistry,
    required this.cardEnabled,
    required this.cards,
  });

  factory GiftSettingsModel.defaults() => const GiftSettingsModel(
        showRegistry: true,
        cardEnabled: false,
        cards: [],
      );

  factory GiftSettingsModel.fromMap(Map<String, dynamic>? m) {
    if (m == null) return GiftSettingsModel.defaults();
    final raw = (m['cards'] as List?) ?? [];
    final cards = <GiftCardInfo>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        cards.add(GiftCardInfo.fromMap(e));
      } else if (e is Map) {
        cards.add(GiftCardInfo.fromMap(Map<String, dynamic>.from(e)));
      }
    }
    return GiftSettingsModel(
      showRegistry: m['showRegistry'] != false,
      cardEnabled: m['cardEnabled'] == true,
      cards: cards,
    );
  }

  Map<String, dynamic> toMap() => {
        'showRegistry': showRegistry,
        'cardEnabled': cardEnabled,
        'cards': cards.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}