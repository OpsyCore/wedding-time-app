import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetGroupModel {
  final String id;
  final String title;
  final bool isDefault;
  final int order;

  BudgetGroupModel({
    required this.id,
    required this.title,
    required this.isDefault,
    required this.order,
  });

  factory BudgetGroupModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return BudgetGroupModel(
      id: doc.id,
      title: data["title"] ?? "",
      isDefault: data["isDefault"] ?? true,
      order: data["order"] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "isDefault": isDefault,
      "order": order,
      "createdAt": FieldValue.serverTimestamp(),
    };
  }
}