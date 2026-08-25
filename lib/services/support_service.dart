import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/support_item_model.dart';

class SupportService {
  SupportService(this.weddingId);

  final String weddingId;
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection('weddings').doc(weddingId).collection('supports');

  CollectionReference<Map<String, dynamic>> get _contrib =>
      _db.collection('weddings').doc(weddingId).collection('supportContribs');

  DocumentReference<Map<String, dynamic>> get _settings => _db
      .collection('weddings')
      .doc(weddingId)
      .collection('supportSettings')
      .doc('main');

  Stream<SupportSettings> watchSettings() =>
      _settings.snapshots().map((s) => SupportSettings.fromMap(s.data()));

  Future<SupportSettings> fetchSettings() async {
    final s = await _settings.get();
    return SupportSettings.fromMap(s.data());
  }

  Future<void> saveSettings(SupportSettings settings) async {
    await _settings.set(settings.toMap(), SetOptions(merge: true));
  }

  Stream<List<SupportItem>> watchItemsSimple() {
    return _items.snapshots().map((snap) {
      final list = snap.docs.map(SupportItem.fromDoc).toList();
      list.sort((a, b) {
        final c = a.sortOrder.compareTo(b.sortOrder);
        if (c != 0) return c;
        return a.title.compareTo(b.title);
      });
      return list;
    });
  }

  Future<void> addItem({
    required String title,
    String note = '',
    String categoryId = 'general',
    String imageUrl = '',
    int targetToman = 0,
    double targetUsd = 0,
    bool allowPartial = true,
  }) async {
    final t = title.trim();
    if (t.isEmpty) throw Exception('empty_title');

    await _items.add({
      'title': t,
      'note': note.trim(),
      'categoryId': categoryId,
      'imageUrl': imageUrl.trim(),
      'sortOrder': DateTime.now().millisecondsSinceEpoch,
      'status': SupportStatus.open.name,
      'targetToman': targetToman,
      'targetUsd': targetUsd,
      'raisedToman': 0,
      'raisedUsd': 0,
      'allowPartial': allowPartial,
      'claimedByName': '',
      'claimedByUid': '',
      'claimedByPhone': '',
      'claimedNote': '',
      'claimedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateItem(SupportItem item) async {
    final t = item.title.trim();
    if (t.isEmpty) throw Exception('empty_title');

    await _items.doc(item.id).set({
      'title': t,
      'note': item.note.trim(),
      'categoryId': item.categoryId,
      'imageUrl': item.imageUrl.trim(),
      'sortOrder': item.sortOrder,
      'status': item.status.name,
      'targetToman': item.targetToman,
      'targetUsd': item.targetUsd,
      'raisedToman': item.raisedToman,
      'raisedUsd': item.raisedUsd,
      'allowPartial': item.allowPartial,
      'claimedByName': item.claimedByName,
      'claimedByUid': item.claimedByUid,
      'claimedByPhone': item.claimedByPhone,
      'claimedNote': item.claimedNote,
      'claimedAt':
          item.claimedAt == null ? null : Timestamp.fromDate(item.claimedAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteItem(String id) async {
    await _items.doc(id).delete();
  }

  Future<void> markReceived(String id) async {
    await _items.doc(id).set({
      'status': SupportStatus.received.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> releaseClaim(String id) async {
    await _items.doc(id).set({
      'status': SupportStatus.open.name,
      'claimedByName': '',
      'claimedByUid': '',
      'claimedByPhone': '',
      'claimedNote': '',
      'claimedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// تنظیم دستی مبلغ جمع‌شده (ادمین/زوج)
  Future<void> setRaised({
    required String itemId,
    required int raisedToman,
    required double raisedUsd,
  }) async {
    await _items.doc(itemId).set({
      'raisedToman': raisedToman < 0 ? 0 : raisedToman,
      'raisedUsd': raisedUsd < 0 ? 0 : raisedUsd,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// کمک / رزرو مهمان — با مبلغ (مثل استریم)
  Future<void> contribute({
    required String itemId,
    required String name,
    String phone = '',
    String note = '',
    int amountToman = 0,
    double amountUsd = 0,
    bool fullClaim = false,
  }) async {
    final n = name.trim();
    if (n.isEmpty) throw Exception('empty_name');
    if (!fullClaim && amountToman <= 0 && amountUsd <= 0) {
      throw Exception('empty_amount');
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final ref = _items.doc(itemId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('not_found');

      final data = snap.data() ?? {};
      final item = SupportItem.fromMap(itemId, data);

      if (item.status == SupportStatus.received) {
        throw Exception('already_claimed');
      }
      if (item.isFullyFunded && item.hasTarget) {
        throw Exception('already_claimed');
      }

      var nextRaisedT = item.raisedToman;
      var nextRaisedU = item.raisedUsd;
      var nextStatus = item.status;
      var claimName = item.claimedByName;
      var claimUid = item.claimedByUid;
      var claimPhone = item.claimedByPhone;
      var claimNote = item.claimedNote;

      if (fullClaim || !item.allowPartial || !item.hasTarget) {
        // رزرو کامل
        nextStatus = SupportStatus.claimed;
        claimName = n;
        claimUid = uid;
        claimPhone = phone.trim();
        claimNote = note.trim();
        if (item.hasTarget) {
          nextRaisedT = item.targetToman;
          nextRaisedU = item.targetUsd;
        }
      } else {
        nextRaisedT = item.raisedToman + amountToman;
        nextRaisedU = item.raisedUsd + amountUsd;
        if (item.targetToman > 0 && nextRaisedT > item.targetToman) {
          nextRaisedT = item.targetToman;
        }
        if (item.targetUsd > 0 && nextRaisedU > item.targetUsd) {
          nextRaisedU = item.targetUsd;
        }
        final filled = (item.targetToman <= 0 || nextRaisedT >= item.targetToman) &&
            (item.targetUsd <= 0 || nextRaisedU >= item.targetUsd);
        if (filled) {
          nextStatus = SupportStatus.claimed;
          claimName = n;
          claimUid = uid;
          claimPhone = phone.trim();
          claimNote = note.trim();
        } else {
          nextStatus = SupportStatus.open;
        }
      }

      tx.update(ref, {
        'raisedToman': nextRaisedT,
        'raisedUsd': nextRaisedU,
        'status': nextStatus.name,
        'claimedByName': claimName,
        'claimedByUid': claimUid,
        'claimedByPhone': claimPhone,
        'claimedNote': claimNote,
        'claimedAt': nextStatus == SupportStatus.claimed
            ? FieldValue.serverTimestamp()
            : data['claimedAt'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _contrib.add({
      'itemId': itemId,
      'name': n,
      'uid': uid,
      'phone': phone.trim(),
      'note': note.trim(),
      'amountToman': amountToman,
      'amountUsd': amountUsd,
      'fullClaim': fullClaim,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// سازگاری با claim ساده قبلی
  Future<void> claimItem({
    required String itemId,
    required String name,
    String phone = '',
    String note = '',
  }) {
    return contribute(
      itemId: itemId,
      name: name,
      phone: phone,
      note: note,
      fullClaim: true,
    );
  }
}