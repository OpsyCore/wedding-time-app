import 'package:cloud_firestore/cloud_firestore.dart';

/// ماژول‌های سرگرمی مهمان‌ها — زوج تعیین می‌کند مهمان‌ها چه ببینند.
/// ذخیره در: weddings/{weddingId}/entertainmentSettings/main
class EntertainmentService {
  static const List<String> keys = [
    'timeline',
    'camera',
    'seating',
    'wishes',
    'gallery',
    'gifts',
    'supports',
    'story',
  ];

  static DocumentReference<Map<String, dynamic>> _doc(String weddingId) =>
      FirebaseFirestore.instance
          .collection('weddings')
          .doc(weddingId)
          .collection('entertainmentSettings')
          .doc('main');

  /// پیش‌فرض: همه روشن
  static Stream<Map<String, bool>> watch(String weddingId) {
    return _doc(weddingId).snapshots().map((s) {
      final d = s.data() ?? {};
      final m = <String, bool>{};
      for (final k in keys) {
        m[k] = d[k] != false;
      }
      return m;
    });
  }

  static Future<Map<String, bool>> fetch(String weddingId) async {
    final s = await _doc(weddingId).get();
    final d = s.data() ?? {};
    final m = <String, bool>{};
    for (final k in keys) {
      m[k] = d[k] != false;
    }
    return m;
  }

  static Future<void> set(String weddingId, String key, bool on) {
    return _doc(weddingId).set({
      key: on,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
