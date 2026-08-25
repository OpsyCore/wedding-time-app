import 'package:cloud_firestore/cloud_firestore.dart';

class VendorPaymentType {
  static const deposit = 'deposit'; // بیعانه
  static const installment = 'installment'; // قسط
  static const finalPay = 'final'; // تسویه
  static const other = 'other';

  static const Map<String, String> labels = {
    deposit: 'بیعانه',
    installment: 'قسط',
    finalPay: 'تسویه',
    other: 'سایر',
  };

  static String label(String? id) {
    if (id == null || id.isEmpty) return labels[installment]!;
    return labels[id] ?? id;
  }

  static List<String> get ids => labels.keys.toList();
}

class VendorPaymentModel {
  final String id;
  final String title;
  final String type;
  final double amount;
  final DateTime? dueDate;
  final bool isPaid;
  final DateTime? paidAt;
  final String note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VendorPaymentModel({
    required this.id,
    required this.title,
    this.type = VendorPaymentType.installment,
    this.amount = 0,
    this.dueDate,
    this.isPaid = false,
    this.paidAt,
    this.note = '',
    this.createdAt,
    this.updatedAt,
  });

  bool get isOverdue {
    if (isPaid || dueDate == null) return false;
    final now = DateTime.now();
    final d = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final t = DateTime(now.year, now.month, now.day);
    return d.isBefore(t);
  }

  bool isDueWithin(int days) {
    if (isPaid || dueDate == null) return false;
    final now = DateTime.now();
    final t = DateTime(now.year, now.month, now.day);
    final d = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final end = t.add(Duration(days: days));
    return !d.isBefore(t) && !d.isAfter(end);
  }

  factory VendorPaymentModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return VendorPaymentModel(
      id: doc.id,
      title: (d['title'] ?? '').toString(),
      type: (d['type'] ?? VendorPaymentType.installment).toString(),
      amount: ((d['amount'] ?? 0) as num).toDouble(),
      dueDate: (d['dueDate'] as Timestamp?)?.toDate(),
      isPaid: d['isPaid'] == true,
      paidAt: (d['paidAt'] as Timestamp?)?.toDate(),
      note: (d['note'] ?? '').toString(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap({bool isUpdate = false}) {
    return {
      'title': title.trim(),
      'type': type,
      'amount': amount,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isPaid': isPaid,
      'paidAt': isPaid
          ? (paidAt != null
              ? Timestamp.fromDate(paidAt!)
              : FieldValue.serverTimestamp())
          : null,
      'note': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (!isUpdate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  VendorPaymentModel copyWith({
    String? id,
    String? title,
    String? type,
    double? amount,
    DateTime? dueDate,
    bool? isPaid,
    DateTime? paidAt,
    String? note,
    bool clearDueDate = false,
  }) {
    return VendorPaymentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}