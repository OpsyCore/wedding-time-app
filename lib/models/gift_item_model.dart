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
  });

  bool get isOpen => status == 'open';
  bool get isClaimed => status == 'claimed' || status == 'received';

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