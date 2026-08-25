import 'package:cloud_firestore/cloud_firestore.dart';

/// مدل مراسم عروسی — نقطه‌ی مرکزی تمام داده‌های مشترک بین عروس و داماد
/// شناسه (id) همان کد دعوتی است که برای پیوستن استفاده می‌شود (مثلاً "482913")
class WeddingModel {
  final String id;
  final String brideName;
  final String groomName;
  final DateTime? weddingDate;
  final String? brideUid;
  final String? groomUid;

  WeddingModel({
    required this.id,
    required this.brideName,
    required this.groomName,
    required this.weddingDate,
    required this.brideUid,
    required this.groomUid,
  });

  factory WeddingModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return WeddingModel(
      id: doc.id,
      brideName: data['brideName'] ?? '',
      groomName: data['groomName'] ?? '',
      weddingDate: (data['weddingDate'] as Timestamp?)?.toDate(),
      brideUid: data['brideUid'],
      groomUid: data['groomUid'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brideName': brideName,
      'groomName': groomName,
      'weddingDate':
          weddingDate != null ? Timestamp.fromDate(weddingDate!) : null,
      'brideUid': brideUid,
      'groomUid': groomUid,
    };
  }
}