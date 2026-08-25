import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_config.dart';
import '../core/app_plans.dart';
import '../models/subscription_plan.dart';

class PlansService {
  PlansService._();
  static final PlansService I = PlansService._();

  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _plansDoc =>
      _db.collection('app_config').doc('plans');

  CollectionReference<Map<String, dynamic>> get _reviewsCol =>
      _db.collection('plan_reviews');

  bool get isAdmin {
    final email = FirebaseAuth.instance.currentUser?.email;
    return AppConfig.isAdminEmail(email);
  }

  Stream<List<SubscriptionPlan>> watchPlans() {
    return _plansDoc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return AppPlans.ordered(AppPlans.defaults);
      }
      final data = snap.data()!;
      final raw = data['plans'];
      if (raw is! List || raw.isEmpty) {
        return AppPlans.ordered(AppPlans.defaults);
      }
      final list = <SubscriptionPlan>[];
      for (final item in raw) {
        if (item is Map) {
          list.add(SubscriptionPlan.fromMap(Map<String, dynamic>.from(item)));
        }
      }
      if (list.isEmpty) return AppPlans.ordered(AppPlans.defaults);
      return AppPlans.ordered(list);
    });
  }

  Future<List<SubscriptionPlan>> fetchPlans() async {
    try {
      final snap = await _plansDoc.get();
      if (!snap.exists || snap.data() == null) {
        return AppPlans.ordered(AppPlans.defaults);
      }
      final raw = snap.data()!['plans'];
      if (raw is! List || raw.isEmpty) {
        return AppPlans.ordered(AppPlans.defaults);
      }
      final list = <SubscriptionPlan>[];
      for (final item in raw) {
        if (item is Map) {
          list.add(SubscriptionPlan.fromMap(Map<String, dynamic>.from(item)));
        }
      }
      return list.isEmpty
          ? AppPlans.ordered(AppPlans.defaults)
          : AppPlans.ordered(list);
    } catch (_) {
      return AppPlans.ordered(AppPlans.defaults);
    }
  }

  Future<void> savePlans(List<SubscriptionPlan> plans) async {
    if (!isAdmin) {
      throw Exception('admin_only');
    }
    await _plansDoc.set({
      'plans': plans.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': FirebaseAuth.instance.currentUser?.email,
    }, SetOptions(merge: true));
  }

  Future<void> seedDefaultsIfEmpty() async {
    if (!isAdmin) return;
    final snap = await _plansDoc.get();
    final raw = snap.data()?['plans'];
    if (snap.exists && raw is List && raw.isNotEmpty) return;
    await savePlans(AppPlans.defaults);
  }

  Stream<List<PlanReview>> watchApprovedReviews({int limit = 30}) {
    return _reviewsCol
        .where('approved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((d) => PlanReview.fromMap(d.id, d.data()))
            .toList());
  }

  /// اگر index نداری، از این بدون orderBy استفاده می‌شود در UI به‌عنوان fallback
  Stream<List<PlanReview>> watchApprovedReviewsSimple({int limit = 40}) {
    return _reviewsCol
        .where('approved', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => PlanReview.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<PlanReview>> watchAllReviewsAdmin() {
    return _reviewsCol.limit(100).snapshots().map((s) {
      final list =
          s.docs.map((d) => PlanReview.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> submitReview({
    required String name,
    required double rating,
    required String comment,
    String planId = '',
  }) async {
    final n = name.trim();
    final c = comment.trim();
    if (n.isEmpty || c.isEmpty) {
      throw Exception('empty');
    }
    final r = rating.clamp(1, 5);
    await _reviewsCol.add({
      'name': n,
      'rating': r,
      'comment': c,
      'planId': planId,
      'approved': true,
      'createdAt': FieldValue.serverTimestamp(),
      'uid': FirebaseAuth.instance.currentUser?.uid,
    });
  }

  Future<void> setReviewApproved(String id, bool approved) async {
    if (!isAdmin) throw Exception('admin_only');
    await _reviewsCol.doc(id).set({
      'approved': approved,
    }, SetOptions(merge: true));
  }

  Future<void> deleteReview(String id) async {
    if (!isAdmin) throw Exception('admin_only');
    await _reviewsCol.doc(id).delete();
  }
}