import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../core/app_lang.dart';
import '../models/wedding_model.dart';
import 'budget_seeder.dart';

class CreateWeddingResult {
  const CreateWeddingResult({
    required this.weddingId,
    required this.inviteCode,
  });

  final String weddingId;
  final String inviteCode;
}

class WeddingService {
  static final _firestore = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  static String _newInviteCode() {
    final raw = _uuid.v4().replaceAll('-', '').toUpperCase();
    return 'WT-${raw.substring(0, 6)}';
  }

  static DocumentReference<Map<String, dynamic>> _inviteCodeRef(String code) {
    return _firestore.collection('invite_codes').doc(code);
  }

  static Future<CreateWeddingResult> createWedding({
    required String uid,
    required String role,
    required String brideName,
    required String groomName,
    required DateTime weddingDate,
    String? email,
  }) async {
    if (role != 'bride' && role != 'groom') {
      throw Exception(AppLang.tr('err_invalid_role'));
    }

    final weddingId = _uuid.v4();
    final inviteCode = _newInviteCode();

    final weddingRef = _firestore.collection('weddings').doc(weddingId);
    final userRef = _firestore.collection('users').doc(uid);
    final codeRef = _inviteCodeRef(inviteCode);

    // مرحله ۱: wedding + user (عضویت از brideUid/groomUid)
    // FIX-02: کد پیوستن روی سند عمومی مراسم ذخیره نمی‌شود؛
    // کد فقط در سند خصوصی کاربر و در invite_codes نگه داشته می‌شود.
    final batch = _firestore.batch();

    batch.set(weddingRef, {
      'brideName': brideName.trim(),
      'groomName': groomName.trim(),
      'weddingDate': Timestamp.fromDate(weddingDate),
      if (role == 'bride') 'brideUid': uid,
      if (role == 'groom') 'groomUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(
      userRef,
      {
        if (email != null && email.isNotEmpty) 'email': email,
        'weddingId': weddingId,
        'role': role,
        'plan': 'free',
        'language': AppLang.I.code,
        'inviteCode': inviteCode,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    // مرحله ۲: invite_codes (بعد از وجود wedding + member)
    await codeRef.set({
      'weddingId': weddingId,
      'inviteCode': inviteCode,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    try {
      await BudgetSeeder.seedDefaultBudget(weddingId);
    } catch (_) {}

    return CreateWeddingResult(
      weddingId: weddingId,
      inviteCode: inviteCode,
    );
  }

  /// پیوستن پارتنر با کد WT-XXXXXX
  static Future<String> joinWedding({
    required String uid,
    required String role,
    required String code,
    String? email,
  }) async {
    if (role != 'bride' && role != 'groom') {
      throw Exception(AppLang.tr('err_invalid_role'));
    }

    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw Exception(AppLang.tr('err_enter_invite_code'));
    }

    // 1) weddingId از invite_codes
    final codeSnap = await _inviteCodeRef(normalized).get();
    if (!codeSnap.exists) {
      throw Exception(AppLang.tr('err_invalid_invite_code'));
    }

    final weddingId = (codeSnap.data()?['weddingId'] ?? '').toString();
    if (weddingId.isEmpty) {
      throw Exception(AppLang.tr('err_invalid_invite_code'));
    }

    // 2) خواندن مراسم
    final weddingRef = _firestore.collection('weddings').doc(weddingId);
    final weddingDoc = await weddingRef.get();
    if (!weddingDoc.exists) {
      throw Exception(AppLang.tr('wedding_not_found'));
    }

    final data = weddingDoc.data() ?? {};
    final field = role == 'bride' ? 'brideUid' : 'groomUid';
    final existing = data[field];

    if (existing != null &&
        existing.toString().isNotEmpty &&
        existing.toString() != uid) {
      throw Exception(
        role == 'bride'
            ? AppLang.tr('err_bride_role_taken')
            : AppLang.tr('err_groom_role_taken'),
      );
    }

    // 3) اتمیک: user + نقش روی wedding
    final batch = _firestore.batch();

    batch.set(
      _firestore.collection('users').doc(uid),
      {
        if (email != null && email.isNotEmpty) 'email': email,
        'weddingId': weddingId,
        'role': role,
        'plan': 'free',
        'language': AppLang.I.code,
        // FIX-02: کد پیوستن برای نمایش در پروفایل هر دو طرف
        'inviteCode': normalized,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      weddingRef,
      {
        field: uid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    try {
      await batch.commit();
    } catch (e) {
      throw Exception(
        AppLang.tr('err_join_failed').replaceAll('{error}', '$e'),
      );
    }

    return weddingId;
  }

  static Future<String?> getUserWeddingId(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final id = doc.data()?['weddingId']?.toString();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  static Future<String?> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['role']?.toString();
  }

  static Future<WeddingModel?> getWedding(String weddingId) async {
    final doc = await _firestore.collection('weddings').doc(weddingId).get();
    if (!doc.exists) return null;

    // FIX-02: پاک‌سازی خودبه‌خودی مراسم‌های قدیمی که هنوز کد پیوستن
    // روی سند عمومی آن‌ها مانده است.
    await _stripLeakedInviteCode(doc);

    return WeddingModel.fromDoc(doc);
  }

  /// اگر سند مراسم هنوز inviteCode دارد، اول آن را برای عضو زوج
  /// در سند خصوصی کاربرش حفظ کن و سپس از سند عمومی حذف کن.
  static Future<void> _stripLeakedInviteCode(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    try {
      final data = doc.data() ?? {};
      if (!data.containsKey('inviteCode')) return;

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final isMember = data['brideUid'] == uid || data['groomUid'] == uid;
      if (!isMember) return;

      final code = (data['inviteCode'] ?? '').toString();
      if (code.isNotEmpty) {
        await _firestore.collection('users').doc(uid).set(
          {'inviteCode': code},
          SetOptions(merge: true),
        );
      }
      await doc.reference.update({'inviteCode': FieldValue.delete()});
    } catch (_) {
      // پاک‌سازی بهترین‌تلاش است؛ نباید جریان اصلی را خراب کند.
    }
  }

  static Future<bool> userWeddingIsValid(String uid) async {
    final weddingId = await getUserWeddingId(uid);
    if (weddingId == null) return false;
    final wedding = await getWedding(weddingId);
    return wedding != null;
  }

  static Future<void> clearUserWedding(String uid) async {
    await _firestore.collection('users').doc(uid).set({
      'weddingId': FieldValue.delete(),
      'role': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
