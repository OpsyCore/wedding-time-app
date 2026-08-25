import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ───────────────── Bank card ─────────────────

class SupportBankCard {
  const SupportBankCard({
    required this.id,
    this.holderName = '',
    this.bankName = '',
    this.cardNumber = '',
    this.enabled = true,
  });

  final String id;
  final String holderName;
  final String bankName;
  final String cardNumber;
  final bool enabled;

  SupportBankCard copyWith({
    String? id,
    String? holderName,
    String? bankName,
    String? cardNumber,
    bool? enabled,
  }) {
    return SupportBankCard(
      id: id ?? this.id,
      holderName: holderName ?? this.holderName,
      bankName: bankName ?? this.bankName,
      cardNumber: cardNumber ?? this.cardNumber,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'holderName': holderName,
        'bankName': bankName,
        'cardNumber': cardNumber,
        'enabled': enabled,
      };

  factory SupportBankCard.fromMap(Map<String, dynamic> map) {
    return SupportBankCard(
      id: (map['id'] ?? '').toString(),
      holderName: (map['holderName'] ?? '').toString(),
      bankName: (map['bankName'] ?? '').toString(),
      cardNumber: (map['cardNumber'] ?? '').toString(),
      enabled: map['enabled'] != false,
    );
  }
}

// ───────────────── Category ─────────────────

class SupportCategory {
  const SupportCategory({
    required this.id,
    required this.titleFa,
    required this.titleEn,
    this.descFa = '',
    this.descEn = '',
    this.iconKey = 'gift',
    this.sortOrder = 0,
    this.enabled = true,
  });

  final String id;
  final String titleFa;
  final String titleEn;
  final String descFa;
  final String descEn;
  final String iconKey;
  final int sortOrder;
  final bool enabled;

  String title(bool isFa) => isFa ? titleFa : (titleEn.isEmpty ? titleFa : titleEn);
  String desc(bool isFa) => isFa ? descFa : (descEn.isEmpty ? descFa : descEn);

  IconData get icon {
    switch (iconKey) {
      case 'home':
        return Icons.home_outlined;
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'ring':
        return Icons.diamond_outlined;
      case 'party':
        return Icons.celebration_outlined;
      case 'cash':
        return Icons.payments_outlined;
      case 'heart':
        return Icons.favorite_outline;
      default:
        return Icons.card_giftcard_rounded;
    }
  }

  SupportCategory copyWith({
    String? id,
    String? titleFa,
    String? titleEn,
    String? descFa,
    String? descEn,
    String? iconKey,
    int? sortOrder,
    bool? enabled,
  }) {
    return SupportCategory(
      id: id ?? this.id,
      titleFa: titleFa ?? this.titleFa,
      titleEn: titleEn ?? this.titleEn,
      descFa: descFa ?? this.descFa,
      descEn: descEn ?? this.descEn,
      iconKey: iconKey ?? this.iconKey,
      sortOrder: sortOrder ?? this.sortOrder,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'titleFa': titleFa,
        'titleEn': titleEn,
        'descFa': descFa,
        'descEn': descEn,
        'iconKey': iconKey,
        'sortOrder': sortOrder,
        'enabled': enabled,
      };

  factory SupportCategory.fromMap(Map<String, dynamic> map) {
    return SupportCategory(
      id: (map['id'] ?? '').toString(),
      titleFa: (map['titleFa'] ?? map['title'] ?? '').toString(),
      titleEn: (map['titleEn'] ?? '').toString(),
      descFa: (map['descFa'] ?? map['description'] ?? '').toString(),
      descEn: (map['descEn'] ?? '').toString(),
      iconKey: (map['iconKey'] ?? 'gift').toString(),
      sortOrder: _asInt(map['sortOrder']),
      enabled: map['enabled'] != false,
    );
  }
}

// ───────────────── Settings ─────────────────

class SupportSettings {
  const SupportSettings({
    this.enabled = true,
    this.cardSectionEnabled = false,
    this.showProgress = true,
    this.showRemaining = true,
    this.currencyMode = 'both', // toman | usd | both
    this.introFa = '',
    this.introEn = '',
    this.thanksFa = '',
    this.thanksEn = '',
    this.cards = const <SupportBankCard>[],
    this.categories = const <SupportCategory>[],
  });

  final bool enabled;
  final bool cardSectionEnabled;
  final bool showProgress;
  final bool showRemaining;

  /// toman | usd | both
  final String currencyMode;
  final String introFa;
  final String introEn;
  final String thanksFa;
  final String thanksEn;
  final List<SupportBankCard> cards;
  final List<SupportCategory> categories;

  List<SupportBankCard> get enabledCards => cards
      .where((c) => c.enabled && c.cardNumber.trim().isNotEmpty)
      .toList();

  List<SupportCategory> get enabledCategories {
    final list = categories.where((c) => c.enabled).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  String intro(bool isFa) => (isFa ? introFa : introEn).trim();
  String thanks(bool isFa) => (isFa ? thanksFa : thanksEn).trim();

  SupportSettings copyWith({
    bool? enabled,
    bool? cardSectionEnabled,
    bool? showProgress,
    bool? showRemaining,
    String? currencyMode,
    String? introFa,
    String? introEn,
    String? thanksFa,
    String? thanksEn,
    List<SupportBankCard>? cards,
    List<SupportCategory>? categories,
  }) {
    return SupportSettings(
      enabled: enabled ?? this.enabled,
      cardSectionEnabled: cardSectionEnabled ?? this.cardSectionEnabled,
      showProgress: showProgress ?? this.showProgress,
      showRemaining: showRemaining ?? this.showRemaining,
      currencyMode: currencyMode ?? this.currencyMode,
      introFa: introFa ?? this.introFa,
      introEn: introEn ?? this.introEn,
      thanksFa: thanksFa ?? this.thanksFa,
      thanksEn: thanksEn ?? this.thanksEn,
      cards: cards ?? this.cards,
      categories: categories ?? this.categories,
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'cardSectionEnabled': cardSectionEnabled,
        'showProgress': showProgress,
        'showRemaining': showRemaining,
        'currencyMode': currencyMode,
        'introFa': introFa,
        'introEn': introEn,
        'thanksFa': thanksFa,
        'thanksEn': thanksEn,
        'cards': cards.map((e) => e.toMap()).toList(),
        'categories': categories.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory SupportSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const SupportSettings();

    final cards = <SupportBankCard>[];
    final rawCards = map['cards'];
    if (rawCards is List) {
      for (final e in rawCards) {
        if (e is Map) {
          cards.add(SupportBankCard.fromMap(Map<String, dynamic>.from(e)));
        }
      }
    }

    final cats = <SupportCategory>[];
    final rawCats = map['categories'];
    if (rawCats is List) {
      for (final e in rawCats) {
        if (e is Map) {
          cats.add(SupportCategory.fromMap(Map<String, dynamic>.from(e)));
        }
      }
    }

    // پیش‌فرض اگر دسته‌ای نبود
    if (cats.isEmpty) {
      cats.addAll(defaultCategories());
    }

    return SupportSettings(
      enabled: map['enabled'] != false,
      cardSectionEnabled: map['cardSectionEnabled'] == true,
      showProgress: map['showProgress'] != false,
      showRemaining: map['showRemaining'] != false,
      currencyMode: (map['currencyMode'] ?? 'both').toString(),
      introFa: (map['introFa'] ?? '').toString(),
      introEn: (map['introEn'] ?? '').toString(),
      thanksFa: (map['thanksFa'] ?? '').toString(),
      thanksEn: (map['thanksEn'] ?? '').toString(),
      cards: cards,
      categories: cats,
    );
  }

  static List<SupportCategory> defaultCategories() {
    return const [
      SupportCategory(
        id: 'general',
        titleFa: 'عمومی',
        titleEn: 'General',
        descFa: 'حمایت‌های آزاد برای شروع زندگی مشترک',
        descEn: 'Open supports for the couple',
        iconKey: 'heart',
        sortOrder: 0,
      ),
      SupportCategory(
        id: 'home',
        titleFa: 'خانه و زندگی',
        titleEn: 'Home',
        descFa: 'وسایل خانه و جهیزیه',
        descEn: 'Home essentials',
        iconKey: 'home',
        sortOrder: 1,
      ),
      SupportCategory(
        id: 'honeymoon',
        titleFa: 'ماه عسل',
        titleEn: 'Honeymoon',
        descFa: 'سفر و خاطره ماه‌عسل',
        descEn: 'Honeymoon trip',
        iconKey: 'travel',
        sortOrder: 2,
      ),
      SupportCategory(
        id: 'cash',
        titleFa: 'کمک نقدی',
        titleEn: 'Cash gift',
        descFa: 'واریز مستقیم به کارت',
        descEn: 'Direct bank transfer',
        iconKey: 'cash',
        sortOrder: 3,
      ),
    ];
  }
}

// ───────────────── Item + progress ─────────────────

enum SupportStatus { open, claimed, received }

SupportStatus supportStatusFromRaw(dynamic raw) {
  switch ((raw ?? 'open').toString().toLowerCase().trim()) {
    case 'claimed':
      return SupportStatus.claimed;
    case 'received':
      return SupportStatus.received;
    default:
      return SupportStatus.open;
  }
}

class SupportItem {
  const SupportItem({
    required this.id,
    required this.title,
    this.note = '',
    this.categoryId = 'general',
    this.imageUrl = '',
    this.sortOrder = 0,
    this.status = SupportStatus.open,
    this.targetToman = 0,
    this.targetUsd = 0,
    this.raisedToman = 0,
    this.raisedUsd = 0,
    this.allowPartial = true,
    this.claimedByName = '',
    this.claimedByUid = '',
    this.claimedByPhone = '',
    this.claimedNote = '',
    this.claimedAt,
    this.createdAt,
  });

  final String id;
  final String title;
  final String note;
  final String categoryId;
  final String imageUrl;
  final int sortOrder;
  final SupportStatus status;

  /// هدف کل
  final int targetToman;
  final double targetUsd;

  /// تا الان جمع‌شده (مثل استریم)
  final int raisedToman;
  final double raisedUsd;

  /// اجازه کمک جزئی / چند نفر
  final bool allowPartial;

  final String claimedByName;
  final String claimedByUid;
  final String claimedByPhone;
  final String claimedNote;
  final DateTime? claimedAt;
  final DateTime? createdAt;

  bool get hasTarget => targetToman > 0 || targetUsd > 0;

  /// 0.0 .. 1.0
  double get progressToman {
    if (targetToman <= 0) return 0;
    final p = raisedToman / targetToman;
    if (p < 0) return 0;
    if (p > 1) return 1;
    return p;
  }

  double get progressUsd {
    if (targetUsd <= 0) return 0;
    final p = raisedUsd / targetUsd;
    if (p < 0) return 0;
    if (p > 1) return 1;
    return p;
  }

  /// درصد پر شده 0..100
  int get percentFilled {
    if (targetToman > 0) return (progressToman * 100).round().clamp(0, 100);
    if (targetUsd > 0) return (progressUsd * 100).round().clamp(0, 100);
    return status == SupportStatus.open ? 0 : 100;
  }

  /// درصد باقی‌مانده
  int get percentRemaining => (100 - percentFilled).clamp(0, 100);

  int get remainingToman {
    final r = targetToman - raisedToman;
    return r < 0 ? 0 : r;
  }

  double get remainingUsd {
    final r = targetUsd - raisedUsd;
    return r < 0 ? 0 : r;
  }

  bool get isFullyFunded {
    if (!hasTarget) {
      return status == SupportStatus.claimed || status == SupportStatus.received;
    }
    final tOk = targetToman <= 0 || raisedToman >= targetToman;
    final uOk = targetUsd <= 0 || raisedUsd >= targetUsd;
    return tOk && uOk;
  }

  bool get isOpen => status == SupportStatus.open && !isFullyFunded;

  bool get isClaimed =>
      status == SupportStatus.claimed ||
      status == SupportStatus.received ||
      isFullyFunded;

  SupportItem copyWith({
    String? id,
    String? title,
    String? note,
    String? categoryId,
    String? imageUrl,
    int? sortOrder,
    SupportStatus? status,
    int? targetToman,
    double? targetUsd,
    int? raisedToman,
    double? raisedUsd,
    bool? allowPartial,
    String? claimedByName,
    String? claimedByUid,
    String? claimedByPhone,
    String? claimedNote,
    DateTime? claimedAt,
    DateTime? createdAt,
  }) {
    return SupportItem(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      status: status ?? this.status,
      targetToman: targetToman ?? this.targetToman,
      targetUsd: targetUsd ?? this.targetUsd,
      raisedToman: raisedToman ?? this.raisedToman,
      raisedUsd: raisedUsd ?? this.raisedUsd,
      allowPartial: allowPartial ?? this.allowPartial,
      claimedByName: claimedByName ?? this.claimedByName,
      claimedByUid: claimedByUid ?? this.claimedByUid,
      claimedByPhone: claimedByPhone ?? this.claimedByPhone,
      claimedNote: claimedNote ?? this.claimedNote,
      claimedAt: claimedAt ?? this.claimedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'note': note,
        'categoryId': categoryId,
        'imageUrl': imageUrl,
        'sortOrder': sortOrder,
        'status': status.name,
        'targetToman': targetToman,
        'targetUsd': targetUsd,
        'raisedToman': raisedToman,
        'raisedUsd': raisedUsd,
        'allowPartial': allowPartial,
        'claimedByName': claimedByName,
        'claimedByUid': claimedByUid,
        'claimedByPhone': claimedByPhone,
        'claimedNote': claimedNote,
        'claimedAt': claimedAt == null ? null : Timestamp.fromDate(claimedAt!),
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory SupportItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return SupportItem.fromMap(doc.id, doc.data() ?? {});
  }

  factory SupportItem.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      return DateTime.tryParse(raw?.toString() ?? '');
    }

    return SupportItem(
      id: id,
      title: (map['title'] ?? '').toString(),
      note: (map['note'] ?? '').toString(),
      categoryId: (map['categoryId'] ?? 'general').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      sortOrder: _asInt(map['sortOrder']),
      status: supportStatusFromRaw(map['status']),
      targetToman: _asInt(map['targetToman']),
      targetUsd: _asDouble(map['targetUsd']),
      raisedToman: _asInt(map['raisedToman']),
      raisedUsd: _asDouble(map['raisedUsd']),
      allowPartial: map['allowPartial'] != false,
      claimedByName: (map['claimedByName'] ?? '').toString(),
      claimedByUid: (map['claimedByUid'] ?? '').toString(),
      claimedByPhone: (map['claimedByPhone'] ?? '').toString(),
      claimedNote: (map['claimedNote'] ?? '').toString(),
      claimedAt: parseDate(map['claimedAt']),
      createdAt: parseDate(map['createdAt']),
    );
  }
}

// ───────────────── Contribution log ─────────────────

class SupportContribution {
  const SupportContribution({
    required this.id,
    required this.itemId,
    required this.name,
    this.uid = '',
    this.phone = '',
    this.note = '',
    this.amountToman = 0,
    this.amountUsd = 0,
    this.createdAt,
  });

  final String id;
  final String itemId;
  final String name;
  final String uid;
  final String phone;
  final String note;
  final int amountToman;
  final double amountUsd;
  final DateTime? createdAt;

  factory SupportContribution.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final m = doc.data() ?? {};
    DateTime? dt;
    final raw = m['createdAt'];
    if (raw is Timestamp) dt = raw.toDate();
    return SupportContribution(
      id: doc.id,
      itemId: (m['itemId'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      uid: (m['uid'] ?? '').toString(),
      phone: (m['phone'] ?? '').toString(),
      note: (m['note'] ?? '').toString(),
      amountToman: _asInt(m['amountToman']),
      amountUsd: _asDouble(m['amountUsd']),
      createdAt: dt,
    );
  }
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse('$v') ?? 0;
}

double _asDouble(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}