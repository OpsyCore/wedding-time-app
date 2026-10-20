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
    final data = (doc.data() as Map?) ?? const {};

    // دادهٔ قدیمی/دستی ممکن است String یا DateTime باشد؛ کست مستقیم
    // کل لیست مراسم را با خطا از کار می‌انداخت.
    final rawDate = data['weddingDate'];
    DateTime? date;
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is DateTime) {
      date = rawDate;
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate);
    }

    return WeddingModel(
      id: doc.id,
      brideName: (data['brideName'] ?? '').toString(),
      groomName: (data['groomName'] ?? '').toString(),
      weddingDate: date,
      brideUid: data['brideUid']?.toString(),
      groomUid: data['groomUid']?.toString(),
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