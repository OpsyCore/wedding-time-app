import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseItemModel {
  /// مقدار legacy در Firestore (فارسی) — UI با cat_* ترجمه می‌شود
  static const String defaultCategoryDb = 'سایر';

  final String id;
  final String title;
  final int estimatedAmount;
  final int actualAmount;
  final String payer;
  final String note;
  final String category;
  final bool isDefault;

  ExpenseItemModel({
    required this.id,
    required this.title,
    required this.estimatedAmount,
    required this.actualAmount,
    required this.payer,
    required this.note,
    required this.category,
    required this.isDefault,
  });

  factory ExpenseItemModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ExpenseItemModel(
      id: doc.id,
      title: data["title"] ?? "",
      estimatedAmount: data["estimatedAmount"] ?? 0,
      actualAmount: data["actualAmount"] ?? 0,
      payer: data["payer"] ?? "shared",
      note: data["note"] ?? "",
      category: (data["category"] ?? defaultCategoryDb).toString(),
      isDefault: data["isDefault"] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "estimatedAmount": estimatedAmount,
      "actualAmount": actualAmount,
      "payer": payer,
      "note": note,
      "category": category,
      "isDefault": isDefault,
      "createdAt": FieldValue.serverTimestamp(),
    };
  }
}