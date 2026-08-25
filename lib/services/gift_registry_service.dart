import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/gift_item_model.dart';

class GiftRegistryService {
  GiftRegistryService(this.weddingId);

  final String weddingId;
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _gifts =>
      _db.collection('weddings').doc(weddingId).collection('gifts');

  DocumentReference<Map<String, dynamic>> get _settings =>
      _db.collection('weddings').doc(weddingId).collection('giftSettings').doc('main');

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

  Future<void> saveSettings(GiftSettingsModel model) async {
    await _settings.set(model.toMap(), SetOptions(merge: true));
  }

  Future<void> addGift({
    required String title,
    String note = '',
    String imageUrl = '',
    int sortOrder = 0,
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

  /// رزرو هدیه — با یا بدون لاگین (نام اجباری).
  /// FIX-01: مطابق firestore.rules (isValidPublicGiftClaim) مهمانِ
  /// بدون حساب هم می‌تواند فقط با نام هدیه را رزرو کند.
  /// فیلدهای لمس‌شده دقیقاً همان‌هایی است که rules مجاز می‌داند.
  Future<void> claimGift({
    required String giftId,
    required String guestName,
  }) async {
    final name = guestName.trim();
    if (name.isEmpty) {
      throw Exception('name_required');
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;

    await _gifts.doc(giftId).update({
      'status': 'claimed',
      'claimedByUid': uid,
      'claimedByName': name,
      'claimedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// لغو رزرو هدیه — با یا بدون لاگین.
  Future<void> unclaimGift(String giftId) async {
    await _gifts.doc(giftId).update({
      'status': 'open',
      'claimedByUid': null,
      'claimedByName': null,
      'claimedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
