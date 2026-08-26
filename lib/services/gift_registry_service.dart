import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/gift_item_model.dart';

class GiftRegistryService {
  GiftRegistryService(this.weddingId);

  final String weddingId;
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _gifts =>
      _db.collection('weddings').doc(weddingId).collection('gifts');

  CollectionReference<Map<String, dynamic>> get _received =>
      _db.collection('weddings').doc(weddingId).collection('receivedGifts');

  DocumentReference<Map<String, dynamic>> get _settings => _db
      .collection('weddings')
      .doc(weddingId)
      .collection('giftSettings')
      .doc('main');

  Stream<List<GiftItemModel>> watchGifts() {
    return _gifts.orderBy('sortOrder').snapshots().map(
          (s) => s.docs.map(GiftItemModel.fromDoc).toList(),
        );
  }

  Stream<GiftSettingsModel> watchSettings() {
    return _settings.snapshots().map(
          (s) => GiftSettingsModel.fromMap(s.data()),
        );
  }

  Stream<List<ReceivedGiftModel>> watchReceivedGifts() {
    return _received
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ReceivedGiftModel.fromDoc).toList());
  }

  Future<void> saveSettings(GiftSettingsModel model) async {
    await _settings.set(model.toMap(), SetOptions(merge: true));
  }

  Future<void> addGift({
    required String title,
    String note = '',
    String imageUrl = '',
    int sortOrder = 0,
    bool isPublic = true,
  }) async {
    await _gifts.add({
      'title': title.trim(),
      'note': note.trim(),
      'imageUrl': imageUrl.trim(),
      'status': 'open',
      'claimedByName': null,
      'claimedByUid': null,
      'claimedAt': null,
      'sortOrder': sortOrder,
      'isPublic': isPublic,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateGift(GiftItemModel gift) async {
    await _gifts.doc(gift.id).set(gift.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteGift(String id) async {
    await _gifts.doc(id).delete();
  }

  /// نمایش/عدم نمایش عمومی یک هدیه (مهمان read-only).
  Future<void> setPublic(String giftId, bool isPublic) async {
    await _gifts.doc(giftId).set({
      'isPublic': isPublic,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// ثبت «دریافت شد» — یک سند در receivedGifts می‌سازد و وضعیت هدیه را
  /// به received می‌برد.
  Future<void> markReceived({
    required String giftId,
    required String giftTitle,
    String name = '',
    String note = '',
    DateTime? receivedAt,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final body = {
      'giftId': giftId,
      'giftTitle': giftTitle.trim(),
      'name': name.trim(),
      'receivedAt':
          receivedAt == null ? FieldValue.serverTimestamp() : receivedAt,
      'note': note.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
    };
    await _received.add(body);
    await _gifts.doc(giftId).set({
      'status': 'received',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// پاک کردن «دریافت شد» و برگرداندن هدیه به آزاد.
  Future<void> unmarkReceived(String receivedDocId, String giftId) async {
    await _received.doc(receivedDocId).delete();
    await _gifts.doc(giftId).set({
      'status': 'open',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
