import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_lang.dart';

class VendorCategories {
  static const unassigned = 'unassigned';

  /// id → کلید i18n (مقدار DB همیشه id انگلیسی است)
  static const Map<String, String> labelKeys = {
    unassigned: 'vendor_cat_unassigned',
    'clothing': 'vendor_cat_clothing',
    'beauty': 'vendor_cat_beauty',
    'music': 'vendor_cat_music',
    'flowers': 'vendor_cat_flowers',
    'accessories': 'vendor_cat_accessories',
    'jewelry': 'vendor_cat_jewelry',
    'photo_video': 'vendor_cat_photo_video',
    'ceremony': 'vendor_cat_ceremony',
    'venue': 'vendor_cat_venue',
    'cake': 'vendor_cat_cake',
    'catering': 'vendor_cat_catering',
    'cards': 'vendor_cat_cards',
    'transport': 'vendor_cat_transport',
    'lighting': 'vendor_cat_lighting',
    'hosting': 'vendor_cat_hosting',
    'hotel': 'vendor_cat_hotel',
    'gifts': 'vendor_cat_gifts',
    'other': 'vendor_cat_other',
  };

  /// سازگاری با کد قدیمی که `.all` می‌خواند — value = label ترجمه‌شده
  static Map<String, String> get all => {
        for (final e in labelKeys.entries) e.key: AppLang.tr(e.value),
      };

  static String label(String? id) {
    if (id == null || id.isEmpty) {
      return AppLang.tr(labelKeys[unassigned]!);
    }
    final key = labelKeys[id];
    if (key != null) return AppLang.tr(key);
    return id;
  }

  static List<String> get ids => labelKeys.keys.toList();
}

class VendorStatus {
  static const booked = 'booked';
  static const pending = 'pending';
  static const rejected = 'rejected';

  static const Map<String, String> labelKeys = {
    booked: 'status_booked',
    pending: 'pending',
    rejected: 'status_rejected',
  };

  static Map<String, String> get labels => {
        for (final e in labelKeys.entries) e.key: AppLang.tr(e.value),
      };

  static String label(String? id) {
    if (id == null || id.isEmpty) {
      return AppLang.tr(labelKeys[pending]!);
    }
    final key = labelKeys[id];
    if (key != null) return AppLang.tr(key);
    return id;
  }
}

class VendorModel {
  final String id;
  final String name;
  final String category;
  final String phone;
  final String email;
  final String website;
  final String address;
  final double cost;
  final bool addToBudget;
  final String status;
  final String note;
  final String? budgetGroupId;
  final String? budgetExpenseId;

  /// جمع پرداخت‌شده (از subcollection payments همگام می‌شود)
  final double paidTotal;
  final int paymentCount;
  final int unpaidCount;
  final DateTime? nextPaymentDue;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VendorModel({
    required this.id,
    required this.name,
    this.category = VendorCategories.unassigned,
    this.phone = '',
    this.email = '',
    this.website = '',
    this.address = '',
    this.cost = 0,
    this.addToBudget = false,
    this.status = VendorStatus.pending,
    this.note = '',
    this.budgetGroupId,
    this.budgetExpenseId,
    this.paidTotal = 0,
    this.paymentCount = 0,
    this.unpaidCount = 0,
    this.nextPaymentDue,
    this.createdAt,
    this.updatedAt,
  });

  bool get isDone => status == VendorStatus.booked;

  bool get isLinkedToBudget =>
      (budgetExpenseId ?? '').isNotEmpty && (budgetGroupId ?? '').isNotEmpty;

  double get remaining {
    final r = cost - paidTotal;
    return r < 0 ? 0 : r;
  }

  double get paidPercent {
    if (cost <= 0) {
      return paidTotal > 0 ? 1.0 : 0.0;
    }
    return (paidTotal / cost).clamp(0.0, 1.0);
  }

  bool get hasPayments => paymentCount > 0;

  /// مبلغ واقعی برای بودجه
  double get budgetActualAmount {
    if (paidTotal > 0) return paidTotal;
    if (status == VendorStatus.booked) return cost;
    return 0;
  }

  String get categoryLabel => VendorCategories.label(category);

  String get statusLabel => VendorStatus.label(status);

  factory VendorModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return VendorModel(
      id: doc.id,
      name: (d['name'] ?? '').toString(),
      category: (d['category'] ?? VendorCategories.unassigned).toString(),
      phone: (d['phone'] ?? '').toString(),
      email: (d['email'] ?? '').toString(),
      website: (d['website'] ?? '').toString(),
      address: (d['address'] ?? '').toString(),
      cost: ((d['cost'] ?? 0) as num).toDouble(),
      addToBudget: d['addToBudget'] == true,
      status: (d['status'] ?? VendorStatus.pending).toString(),
      note: (d['note'] ?? '').toString(),
      budgetGroupId: d['budgetGroupId']?.toString(),
      budgetExpenseId: d['budgetExpenseId']?.toString(),
      paidTotal: ((d['paidTotal'] ?? 0) as num).toDouble(),
      paymentCount: ((d['paymentCount'] ?? 0) as num).toInt(),
      unpaidCount: ((d['unpaidCount'] ?? 0) as num).toInt(),
      nextPaymentDue: (d['nextPaymentDue'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap({bool isUpdate = false}) {
    return {
      'name': name.trim(),
      'category': category,
      'phone': phone.trim(),
      'email': email.trim(),
      'website': website.trim(),
      'address': address.trim(),
      'cost': cost,
      'addToBudget': addToBudget,
      'status': status,
      'note': note.trim(),
      'done': status == VendorStatus.booked,
      if (budgetGroupId != null && budgetGroupId!.isNotEmpty)
        'budgetGroupId': budgetGroupId,
      if (budgetExpenseId != null && budgetExpenseId!.isNotEmpty)
        'budgetExpenseId': budgetExpenseId,
      'paidTotal': paidTotal,
      'paymentCount': paymentCount,
      'unpaidCount': unpaidCount,
      'nextPaymentDue': nextPaymentDue != null
          ? Timestamp.fromDate(nextPaymentDue!)
          : null,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!isUpdate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  VendorModel copyWith({
    String? id,
    String? name,
    String? category,
    String? phone,
    String? email,
    String? website,
    String? address,
    double? cost,
    bool? addToBudget,
    String? status,
    String? note,
    String? budgetGroupId,
    String? budgetExpenseId,
    double? paidTotal,
    int? paymentCount,
    int? unpaidCount,
    DateTime? nextPaymentDue,
    bool clearNextPaymentDue = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      cost: cost ?? this.cost,
      addToBudget: addToBudget ?? this.addToBudget,
      status: status ?? this.status,
      note: note ?? this.note,
      budgetGroupId: budgetGroupId ?? this.budgetGroupId,
      budgetExpenseId: budgetExpenseId ?? this.budgetExpenseId,
      paidTotal: paidTotal ?? this.paidTotal,
      paymentCount: paymentCount ?? this.paymentCount,
      unpaidCount: unpaidCount ?? this.unpaidCount,
      nextPaymentDue: clearNextPaymentDue
          ? null
          : (nextPaymentDue ?? this.nextPaymentDue),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}