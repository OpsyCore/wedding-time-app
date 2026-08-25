import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_lang.dart';
import '../models/invitation_model.dart';
import 'notification_service.dart';

class PublicInviteData {
  const PublicInviteData({
    required this.weddingId,
    required this.invitation,
  });

  final String weddingId;
  final InvitationModel invitation;
}

class InvitationService {
  static final _firestore = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> inviteRef(String weddingId) {
    return _firestore
        .collection('weddings')
        .doc(weddingId)
        .collection('invitation')
        .doc('main');
  }

  static DocumentReference<Map<String, dynamic>> publicSlugRef(String slug) {
    return _firestore.collection('public_slugs').doc(slug);
  }

  static Future<InvitationModel?> getByWeddingId(String weddingId) async {
    final snap = await inviteRef(weddingId).get();
    if (!snap.exists) return null;
    return InvitationModel.fromMap(snap.data() ?? {});
  }

  static Future<PublicInviteData?> getBySlug(String slug) async {
    final normalized = slug.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    // 1) مسیر امن عمومی
    try {
      final slugSnap = await publicSlugRef(normalized).get();
      if (slugSnap.exists) {
        final weddingId = (slugSnap.data()?['weddingId'] ?? '').toString();
        if (weddingId.isNotEmpty) {
          final invitation = await getByWeddingId(weddingId);
          if (invitation != null) {
            return PublicInviteData(
              weddingId: weddingId,
              invitation: invitation,
            );
          }
        }
      }
    } catch (_) {}

    // 2) سازگاری با داده‌های قدیمی
    try {
      final byWedding = await _firestore
          .collection('weddings')
          .where('inviteSlug', isEqualTo: normalized)
          .limit(1)
          .get();

      if (byWedding.docs.isNotEmpty) {
        final weddingId = byWedding.docs.first.id;
        final invitation = await getByWeddingId(weddingId);
        if (invitation != null) {
          // backfill ایندکس عمومی
          try {
            await publicSlugRef(normalized).set({
              'weddingId': weddingId,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (_) {}
          return PublicInviteData(
            weddingId: weddingId,
            invitation: invitation,
          );
        }
      }
    } catch (_) {}

    try {
      final byGroup = await _firestore
          .collectionGroup('invitation')
          .where('slug', isEqualTo: normalized)
          .limit(1)
          .get();

      if (byGroup.docs.isNotEmpty) {
        final doc = byGroup.docs.first;
        final weddingId = doc.reference.parent.parent?.id;
        if (weddingId != null) {
          try {
            await publicSlugRef(normalized).set({
              'weddingId': weddingId,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (_) {}
          return PublicInviteData(
            weddingId: weddingId,
            invitation: InvitationModel.fromMap(doc.data()),
          );
        }
      }
    } catch (_) {}

    return null;
  }

  static Future<void> saveInvitation({
    required String weddingId,
    required InvitationModel model,
  }) async {
    final slug = model.slug.trim().isEmpty
        ? weddingId.toLowerCase()
        : model.slug.trim().toLowerCase();

    // جلوگیری از تداخل slug با مراسم دیگر
    final existing = await publicSlugRef(slug).get();
    if (existing.exists) {
      final owner = (existing.data()?['weddingId'] ?? '').toString();
      if (owner.isNotEmpty && owner != weddingId) {
        throw Exception(AppLang.tr('err_slug_taken'));
      }
    }

    final weddingSnap =
        await _firestore.collection('weddings').doc(weddingId).get();
    final oldSlug = (weddingSnap.data()?['inviteSlug'] ?? '').toString();

    final payload = Map<String, dynamic>.from(model.toMap());
    payload['slug'] = slug;
    payload['showRsvp'] = model.showRsvp;

    final batch = _firestore.batch();

    batch.set(inviteRef(weddingId), payload, SetOptions(merge: true));

    batch.set(
      _firestore.collection('weddings').doc(weddingId),
      {
        'inviteSlug': slug,
        'showRsvp': model.showRsvp,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      publicSlugRef(slug),
      {
        'weddingId': weddingId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (oldSlug.isNotEmpty && oldSlug != slug) {
      batch.delete(publicSlugRef(oldSlug));
    }

    await batch.commit();
  }

  static Future<void> saveShowRsvp({
    required String weddingId,
    required bool showRsvp,
  }) async {
    final batch = _firestore.batch();

    batch.set(
      inviteRef(weddingId),
      {
        'showRsvp': showRsvp,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      _firestore.collection('weddings').doc(weddingId),
      {
        'showRsvp': showRsvp,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// RSVP عمومی — بدون query روی guests (امن برای Rules)
  static Future<void> submitRsvp({
    required String weddingId,
    required String name,
    String phone = '',
    required bool attending,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError(AppLang.tr('err_rsvp_name_required'));
    }

    final trimmedPhone = phone.trim();
    final guestStatus = attending ? 'confirmed' : 'declined';
    final rsvpStatus = attending ? 'yes' : 'no';
    final digitalNote = AppLang.tr('note_from_digital_invite');

    final guestsRef = _firestore
        .collection('weddings')
        .doc(weddingId)
        .collection('guests');

    late final String guestId;

    // اگر تلفن بود: upsert بدون read/list (id قابل پیش‌بینی)
    final phoneDigits = trimmedPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phoneDigits.isNotEmpty) {
      guestId = 'rsvp_$phoneDigits';
      await guestsRef.doc(guestId).set({
        'name': trimmedName,
        'phone': trimmedPhone,
        'group': 'other',
        'status': guestStatus,
        'note': digitalNote,
        'rsvpSource': 'public_invite',
        'rsvpAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      // بدون تلفن: همیشه مهمان جدید (بدون match روی نام)
      final doc = await guestsRef.add({
        'name': trimmedName,
        'phone': '',
        'group': 'other',
        'status': guestStatus,
        'note': digitalNote,
        'rsvpSource': 'public_invite',
        'rsvpAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      guestId = doc.id;
    }

    await _firestore
        .collection('weddings')
        .doc(weddingId)
        .collection('rsvps')
        .add({
      'name': trimmedName,
      'phone': trimmedPhone,
      'status': rsvpStatus,
      'guestId': guestId,
      'source': 'public_invite',
      'createdAt': FieldValue.serverTimestamp(),
    });

    try {
      await NotificationService(weddingId).notifyRsvp(
        guestName: trimmedName,
        attending: attending,
        guestId: guestId,
      );
    } catch (_) {
      // fallback — همان helper اگر add جدا لازم شد
      try {
        await NotificationService(weddingId).notifyRsvp(
          guestName: trimmedName,
          attending: attending,
          guestId: guestId,
        );
      } catch (_) {}
    }
  }
}