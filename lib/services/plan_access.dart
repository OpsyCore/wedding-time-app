import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_plans.dart';
import '../core/app_theme.dart';
import '../models/subscription_plan.dart';
import '../screens/plans_screen.dart';
import 'plans_service.dart';

/// سطح دسترسی هر پلن — منبع حقیقتِ اعمال محدودیت‌ها در کد.
/// (-1 یعنی نامحدود)
class PlanLimits {
  const PlanLimits({
    required this.maxGuests,
    required this.maxMedia,
    required this.maxStoryChapters,
    required this.maxShotsPerGuest,
    required this.budget,
    required this.vendors,
    required this.seating,
    required this.camera,
    required this.qr,
    required this.exportDocs,
    required this.templates,
    required this.maxWeddings,
    required this.supportTier,
  });

  final int maxGuests;
  final int maxMedia;
  final int maxStoryChapters;
  final int maxShotsPerGuest;
  final bool budget;
  final bool vendors;
  final bool seating;
  final bool camera;
  final bool qr;
  final bool exportDocs;
  final List<String> templates;
  final int maxWeddings;

  /// normal | priority | vip
  final String supportTier;

  bool get unlimitedGuests => maxGuests < 0;
  bool get unlimitedMedia => maxMedia < 0;
  bool get unlimitedChapters => maxStoryChapters < 0;

  static const free = PlanLimits(
    maxGuests: 100,
    maxMedia: 20,
    maxStoryChapters: 2,
    maxShotsPerGuest: 0,
    budget: false,
    vendors: false,
    seating: false,
    camera: false,
    qr: false,
    exportDocs: false,
    templates: ['classic'],
    maxWeddings: 1,
    supportTier: 'normal',
  );

  static const pro = PlanLimits(
    maxGuests: -1,
    maxMedia: 500,
    maxStoryChapters: -1,
    maxShotsPerGuest: 10,
    budget: true,
    vendors: true,
    seating: true,
    camera: true,
    qr: true,
    exportDocs: false,
    templates: ['classic'],
    maxWeddings: 1,
    supportTier: 'priority',
  );

  /// وقتی ادمین «محدودیت پلن‌ها» را خاموش می‌کند: همه‌چیز برای همه باز
  static const everythingOpen = PlanLimits(
    maxGuests: -1,
    maxMedia: -1,
    maxStoryChapters: -1,
    maxShotsPerGuest: -1,
    budget: true,
    vendors: true,
    seating: true,
    camera: true,
    qr: true,
    exportDocs: true,
    templates: ['classic', 'royal_gold', 'floral_rose', 'minimal_modern'],
    maxWeddings: -1,
    supportTier: 'vip',
  );

  static const premium = PlanLimits(
    maxGuests: -1,
    maxMedia: -1,
    maxStoryChapters: -1,
    maxShotsPerGuest: -1,
    budget: true,
    vendors: true,
    seating: true,
    camera: true,
    qr: true,
    exportDocs: true,
    templates: ['classic', 'royal_gold', 'floral_rose', 'minimal_modern'],
    maxWeddings: 2,
    supportTier: 'vip',
  );

  static PlanLimits forPlanId(String? planId) {
    switch ((planId ?? '').trim()) {
      case AppPlans.proId:
      case 'pro_monthly':
        return pro;
      case AppPlans.premiumId:
        return premium;
      default:
        return free;
    }
  }
}

/// سرویس دسترسی/اشتراک: خواندن پلن، اعمال محدودیت، فعال‌سازی و دیالوگ ارتقا.
class PlanAccess {
  PlanAccess._();
  static final PlanAccess I = PlanAccess._();

  final _db = FirebaseFirestore.instance;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;
  String? get email => FirebaseAuth.instance.currentUser?.email;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection('users').doc(uid);

  /// پلنِ یک مراسم — از سند مراسم (mirror شده هنگام فعال‌سازی)
  Stream<String> watchWeddingPlanId(String weddingId) {
    return _db
        .collection('weddings')
        .doc(weddingId)
        .snapshots()
        .map((s) => (s.data()?['planId'] ?? AppPlans.freeId).toString());
  }

  /// محدودیت‌ها = کد پایه + سوییچ‌های ادمین (app_config/plans).
  /// یعنی اگر ادمین قابلیتی را برای یک پلن روشن/خاموش کند، قفل‌ها واقعاً
  /// باز/بسته می‌شوند نه فقط نمایش متنی.
  static PlanLimits limitsFor(String planId, List<SubscriptionPlan> plans) {
    if (!PlansService.I.monetizationOn) return PlanLimits.everythingOpen;
    final base = PlanLimits.forPlanId(planId);
    SubscriptionPlan? plan;
    for (final p in plans) {
      if (p.id == planId) {
        plan = p;
        break;
      }
    }
    if (plan == null) return base;
    bool flag(String id, bool fallback) {
      for (final f in plan!.features) {
        if (f.id == id) return f.included;
      }
      return fallback;
    }

    return PlanLimits(
      maxGuests: base.maxGuests,
      maxMedia: base.maxMedia,
      maxStoryChapters: base.maxStoryChapters,
      maxShotsPerGuest: base.maxShotsPerGuest,
      budget: flag('budget', base.budget),
      vendors: flag('vendors', base.vendors),
      seating: flag('seating', base.seating),
      camera: flag('camera', base.camera),
      qr: flag('qr', base.qr),
      exportDocs: flag('export', base.exportDocs),
      templates: base.templates,
      maxWeddings: base.maxWeddings,
      supportTier: base.supportTier,
    );
  }

  Stream<PlanLimits> watchWeddingLimits(String weddingId) {
    late StreamController<PlanLimits> ctrl;
    StreamSubscription<String>? subPlan;
    StreamSubscription<List<SubscriptionPlan>>? subCfg;
    StreamSubscription<bool>? subMon;
    String planId = AppPlans.freeId;
    List<SubscriptionPlan> plans = const [];
    void push() {
      if (!ctrl.isClosed) ctrl.add(limitsFor(planId, plans));
    }

    ctrl = StreamController<PlanLimits>(
      onListen: () {
        subPlan = watchWeddingPlanId(weddingId).listen((v) {
          planId = v;
          push();
        });
        subCfg = PlansService.I.watchPlans().listen((v) {
          plans = v;
          push();
        });
        subMon = PlansService.I.watchMonetizationEnabled().listen((_) {
          push();
        });
      },
      onCancel: () async {
        await subPlan?.cancel();
        await subCfg?.cancel();
        await subMon?.cancel();
      },
    );
    return ctrl.stream;
  }

  Future<PlanLimits> weddingLimits(String weddingId) async {
    if (!PlansService.I.monetizationOn) return PlanLimits.everythingOpen;
    final s = await _db.collection('weddings').doc(weddingId).get();
    final plans = await PlansService.I.fetchPlans();
    return limitsFor((s.data()?['planId'] ?? '').toString(), plans);
  }

  /// محدودیت‌های مبتنی بر پلن خودِ کاربر (با رعایت سوییچ کلی مانتایزیشن)
  Future<PlanLimits> myLimits() async {
    if (!PlansService.I.monetizationOn) return PlanLimits.everythingOpen;
    final plans = await PlansService.I.fetchPlans();
    return limitsFor(await myPlanId(), plans);
  }

  Future<String> myPlanId() async {
    final u = uid;
    if (u == null) return AppPlans.freeId;
    final s = await _userRef(u).get();
    return (s.data()?['planId'] ?? AppPlans.freeId).toString();
  }

  Stream<String> watchMyPlanId() {
    final u = uid;
    if (u == null) return Stream.value(AppPlans.freeId);
    return _userRef(u)
        .snapshots()
        .map((s) => (s.data()?['planId'] ?? AppPlans.freeId).toString());
  }

  /// فعال‌سازی پلن برای کاربر + mirror به مراسم فعال او
  Future<void> activatePlan({
    required String targetUid,
    required String planId,
  }) async {
    await _userRef(targetUid).set({
      'planId': planId,
      'planActivatedAt': FieldValue.serverTimestamp(),
      'planActivatedBy': email ?? 'system',
    }, SetOptions(merge: true));

    final user = await _userRef(targetUid).get();
    final weddingId = (user.data()?['weddingId'] ?? '').toString();
    if (weddingId.isNotEmpty) {
      await _db.collection('weddings').doc(weddingId).set({
        'planId': planId,
      }, SetOptions(merge: true));
    }
  }

  /// ثبت درخواست ارتقا پس از پرداخت بیرونی (تأیید نهایی با ادمین)
  Future<void> requestPlan(String planId) async {
    final u = uid;
    if (u == null) return;
    await _db.collection('plan_requests').add({
      'uid': u,
      'email': email ?? '',
      'planId': planId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPendingRequests() {
    return _db
        .collection('plan_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> approveRequest(String docId, String uid, String planId) async {
    await activatePlan(targetUid: uid, planId: planId);
    await _db.collection('plan_requests').doc(docId).set({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': email ?? '',
    }, SetOptions(merge: true));
  }

  /// دیالوگ ارتقا — وقتی کاربر به قابلیت پولی زد
  Future<void> showUpgradeDialog(
    BuildContext context, {
    required String weddingId,
    required String featureFa,
    required String featureEn,
  }) async {
    final feature = AppLang.I.isFa ? featureFa : featureEn;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: AppLang.I.direction,
        child: AlertDialog(
          backgroundColor: AppTok.card(ctx),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.diamond_rounded, color: AppTok.accent(ctx), size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLang.I.isFa ? 'قابلیت پلن‌های پولی' : 'Premium feature',
                  style: TextStyle(
                    color: AppTok.text(ctx),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            AppLang.I.isFa
                ? '«$feature» در پلن رایگان فعال نیست. برای فعال‌سازی، پلن پرو یا پرمیوم را انتخاب کنید.'
                : '"$feature" is not available on the free plan. Upgrade to Pro or Premium to unlock it.',
            style: TextStyle(
              color: AppTok.textSoft(ctx),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppLang.I.isFa ? 'بعداً' : 'Later',
                style: TextStyle(color: AppTok.textSoft(ctx)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTok.accent(ctx),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(ctx).push(
                  MaterialPageRoute(
                    builder: (_) => PlansScreen(weddingId: weddingId),
                  ),
                );
              },
              child: Text(
                AppLang.I.isFa ? 'مشاهده پلن‌ها' : 'View plans',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
