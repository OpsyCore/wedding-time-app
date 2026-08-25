import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_lang.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService(this.weddingId)
      : _ref = FirebaseFirestore.instance
            .collection('weddings')
            .doc(weddingId)
            .collection('notifications');

  final String weddingId;
  final CollectionReference<Map<String, dynamic>> _ref;

  // ───────────────── streams ─────────────────

  Stream<List<AppNotification>> watchStored() {
    return _ref.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map(AppNotification.fromDoc).toList(),
        );
  }

  Stream<int> watchUnreadCount() {
    return _ref.where('read', isEqualTo: false).snapshots().map(
          (snap) => snap.docs.length,
        );
  }

  // ───────────────── base add ─────────────────

  Future<void> add({
    required AppNotificationType type,
    required String title,
    required String body,
    String? relatedId,
  }) async {
    await _ref.add({
      'type': type.name,
      'title': title,
      'body': body,
      'read': false,
      'relatedId': relatedId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ───────────────── typed helpers ─────────────────

  /// vendor_payments_screen
  Future<void> notifyPayment({
    required String vendorName,
    required num amount,
    String? paymentId,
  }) async {
    final name = vendorName.trim().isEmpty
        ? AppLang.tr('vendor_default')
        : vendorName.trim();
    final amountText = _formatAmount(amount);

    await add(
      type: AppNotificationType.payment,
      title: AppLang.tr('notif_payment_title'),
      body: AppLang.tr('notif_payment_body')
          .replaceAll('{amount}', amountText)
          .replaceAll('{name}', name),
      relatedId: paymentId,
    );
  }

  /// wishes_screen
  Future<void> notifyWish({
    required String guestName,
    String? wishId,
  }) async {
    final name =
        guestName.trim().isEmpty ? AppLang.tr('a_guest') : guestName.trim();

    await add(
      type: AppNotificationType.wish,
      title: AppLang.tr('notif_wish_title'),
      body: AppLang.tr('notif_wish_body').replaceAll('{name}', name),
      relatedId: wishId,
    );
  }

  /// disposable_camera_service
  Future<void> notifyGallery({
    required String uploaderName,
    required bool isVideo,
    String? mediaId,
  }) async {
    final name = uploaderName.trim().isEmpty
        ? AppLang.tr('a_guest')
        : uploaderName.trim();
    final kind =
        isVideo ? AppLang.tr('kind_video') : AppLang.tr('kind_photo');

    await add(
      type: AppNotificationType.gallery,
      title: AppLang.tr('notif_gallery_title').replaceAll('{kind}', kind),
      body: AppLang.tr('notif_gallery_body')
          .replaceAll('{name}', name)
          .replaceAll('{kind}', kind),
      relatedId: mediaId,
    );
  }

  /// invitation_service / public invite RSVP
  Future<void> notifyRsvp({
    required String guestName,
    required bool attending,
    String? guestId,
  }) async {
    final name =
        guestName.trim().isEmpty ? AppLang.tr('a_guest') : guestName.trim();

    await add(
      type: AppNotificationType.rsvp,
      title: attending
          ? AppLang.tr('notif_rsvp_yes_title')
          : AppLang.tr('notif_rsvp_no_title'),
      body: attending
          ? AppLang.tr('notif_rsvp_yes_body').replaceAll('{name}', name)
          : AppLang.tr('notif_rsvp_no_body').replaceAll('{name}', name),
      relatedId: guestId,
    );
  }

  // ───────────────── mark / delete ─────────────────

  Future<void> markRead(String notificationId) async {
    await _ref.doc(notificationId).set({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markAllRead() async {
    final batch = FirebaseFirestore.instance.batch();
    final unread = await _ref.where('read', isEqualTo: false).get();

    for (final doc in unread.docs) {
      batch.set(
        doc.reference,
        {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> delete(String notificationId) async {
    await _ref.doc(notificationId).delete();
  }

  Future<void> clearAll() async {
    final batch = FirebaseFirestore.instance.batch();
    final all = await _ref.get();
    for (final doc in all.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ───────────────── smart ─────────────────

  Future<void> syncEventNotifications() async {}

  Future<List<AppNotification>> buildSmartReminders() async {
    return <AppNotification>[];
  }

  // ───────────────── utils ─────────────────

  String _formatAmount(num amount) {
    final raw = amount.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i != 0 && (raw.length - i) % 3 == 0) buf.write(',');
      buf.write(raw[i]);
    }
    final s = buf.toString();
    return AppLang.I.isFa ? _fa(s) : s;
  }

  String _fa(String input) {
    const digits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return input.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? digits[i] : c;
    }).join();
  }
}