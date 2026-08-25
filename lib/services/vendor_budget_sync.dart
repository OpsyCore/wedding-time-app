import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_lang.dart';
import '../models/vendor_model.dart';
import '../models/vendor_payment_model.dart';

/// همگام‌سازی تأمین‌کننده با بخش بودجه + خلاصه اقساط
class VendorBudgetSync {
  VendorBudgetSync._();

  /// عنوان گروه در Firestore — legacy فارسی؛ برای lookup عوض نشود
  static const vendorsGroupTitle = 'تأمین‌کنندگان';

  static CollectionReference<Map<String, dynamic>> _groupsRef(String weddingId) {
    return FirebaseFirestore.instance
        .collection('weddings')
        .doc(weddingId)
        .collection('budgetGroups');
  }

  static CollectionReference<Map<String, dynamic>> _vendorsRef(String weddingId) {
    return FirebaseFirestore.instance
        .collection('weddings')
        .doc(weddingId)
        .collection('vendors');
  }

  static CollectionReference<Map<String, dynamic>> paymentsRef(
    String weddingId,
    String vendorId,
  ) {
    return _vendorsRef(weddingId).doc(vendorId).collection('payments');
  }

  /// خروجی = مقدار category در DB بودجه (فارسی legacy) — UI با cat_* ترجمه می‌شود
  static String budgetCategoryOf(String vendorCategory) {
    switch (vendorCategory) {
      case 'clothing':
      case 'accessories':
        return 'لباس';
      case 'beauty':
        return 'زیبایی';
      case 'photo_video':
        return 'عکاسی';
      case 'flowers':
        return 'گل‌آرایی';
      case 'jewelry':
        return 'جواهرات';
      case 'gifts':
        return 'هدایا';
      case 'transport':
        return 'حمل‌ونقل';
      case 'cards':
        return 'چاپ';
      case 'cake':
      case 'catering':
        return 'پذیرایی';
      case 'music':
      case 'ceremony':
      case 'venue':
      case 'lighting':
      case 'hosting':
        return 'تشریفات';
      case 'hotel':
      case 'other':
      case VendorCategories.unassigned:
      default:
        return 'سایر';
    }
  }

  static Future<String> ensureVendorsGroupId(String weddingId) async {
    final groups = _groupsRef(weddingId);
    final q = await groups
        .where('title', isEqualTo: vendorsGroupTitle)
        .limit(1)
        .get();

    if (q.docs.isNotEmpty) return q.docs.first.id;

    final existing = await groups.get();
    final doc = await groups.add({
      'title': vendorsGroupTitle,
      'isDefault': false,
      'order': existing.docs.length,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// خواندن همه پرداخت‌ها و نوشتن خلاصه روی vendor
  static Future<VendorModel> refreshPaymentSummary({
    required String weddingId,
    required String vendorId,
  }) async {
    final vendorRef = _vendorsRef(weddingId).doc(vendorId);
    final vendorSnap = await vendorRef.get();
    if (!vendorSnap.exists) {
      throw Exception(AppLang.tr('err_vendor_not_found'));
    }

    var vendor = VendorModel.fromDoc(vendorSnap);
    final paySnap = await paymentsRef(weddingId, vendorId).get();
    final payments =
        paySnap.docs.map(VendorPaymentModel.fromDoc).toList(growable: false);

    double paid = 0;
    var unpaid = 0;
    DateTime? nextDue;

    for (final p in payments) {
      if (p.isPaid) {
        paid += p.amount;
      } else {
        unpaid++;
        if (p.dueDate != null) {
          if (nextDue == null || p.dueDate!.isBefore(nextDue)) {
            nextDue = p.dueDate;
          }
        }
      }
    }

    await vendorRef.set({
      'paidTotal': paid,
      'paymentCount': payments.length,
      'unpaidCount': unpaid,
      'nextPaymentDue':
          nextDue != null ? Timestamp.fromDate(nextDue) : FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    vendor = vendor.copyWith(
      paidTotal: paid,
      paymentCount: payments.length,
      unpaidCount: unpaid,
      nextPaymentDue: nextDue,
      clearNextPaymentDue: nextDue == null,
    );

    // اگر به بودجه وصل است، actual را با پرداخت‌ها هم‌تراز کن
    if (vendor.addToBudget || vendor.isLinkedToBudget) {
      await sync(
        weddingId: weddingId,
        vendorId: vendorId,
        vendor: vendor,
        previousGroupId: vendor.budgetGroupId,
        previousExpenseId: vendor.budgetExpenseId,
      );
      final again = await vendorRef.get();
      if (again.exists) vendor = VendorModel.fromDoc(again);
    }

    return vendor;
  }

  static Map<String, dynamic> _expenseData({
    required VendorModel vendor,
    required String vendorId,
  }) {
    final cost = vendor.cost.round();
    final actual = vendor.budgetActualAmount.round();

    final noteParts = <String>[
      if (vendor.phone.isNotEmpty)
        AppLang.tr('budget_note_phone').replaceAll('{phone}', vendor.phone),
      if (vendor.note.isNotEmpty) vendor.note,
      if (vendor.paymentCount > 0)
        AppLang.tr('budget_note_paid_of')
            .replaceAll('{paid}', '${vendor.paidTotal.round()}')
            .replaceAll('{total}', '$cost'),
      AppLang.tr('budget_note_source_vendor'),
    ];

    return {
      'title': vendor.name.trim(),
      'estimatedAmount': cost,
      'actualAmount': actual,
      'payer': 'shared',
      'category': budgetCategoryOf(vendor.category),
      'note': noteParts.join('\n'),
      'isDefault': false,
      'source': 'vendor',
      'vendorId': vendorId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Future<Map<String, String?>> sync({
    required String weddingId,
    required String vendorId,
    required VendorModel vendor,
    String? previousGroupId,
    String? previousExpenseId,
  }) async {
    final vendorRef = _vendorsRef(weddingId).doc(vendorId);

    if (!vendor.addToBudget) {
      await _deleteExpense(
        weddingId: weddingId,
        groupId: previousGroupId ?? vendor.budgetGroupId,
        expenseId: previousExpenseId ?? vendor.budgetExpenseId,
      );
      await vendorRef.set({
        'budgetGroupId': FieldValue.delete(),
        'budgetExpenseId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return {'budgetGroupId': null, 'budgetExpenseId': null};
    }

    final groupId =
        (previousGroupId ?? vendor.budgetGroupId)?.isNotEmpty == true
            ? (previousGroupId ?? vendor.budgetGroupId)!
            : await ensureVendorsGroupId(weddingId);

    final expensesRef =
        _groupsRef(weddingId).doc(groupId).collection('expenses');
    final data = _expenseData(vendor: vendor, vendorId: vendorId);

    String expenseId = previousExpenseId ?? vendor.budgetExpenseId ?? '';

    if (expenseId.isNotEmpty) {
      final existing = await expensesRef.doc(expenseId).get();
      if (existing.exists) {
        await expensesRef.doc(expenseId).set(data, SetOptions(merge: true));
      } else {
        final created = await expensesRef.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
        expenseId = created.id;
      }
    } else {
      final created = await expensesRef.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      expenseId = created.id;
    }

    await vendorRef.set({
      'budgetGroupId': groupId,
      'budgetExpenseId': expenseId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return {
      'budgetGroupId': groupId,
      'budgetExpenseId': expenseId,
    };
  }

  static Future<void> deleteLinkedExpense({
    required String weddingId,
    required VendorModel vendor,
  }) async {
    // پرداخت‌ها
    final pays = await paymentsRef(weddingId, vendor.id).get();
    for (final d in pays.docs) {
      await d.reference.delete();
    }

    await _deleteExpense(
      weddingId: weddingId,
      groupId: vendor.budgetGroupId,
      expenseId: vendor.budgetExpenseId,
    );
  }

  static Future<void> _deleteExpense({
    required String weddingId,
    String? groupId,
    String? expenseId,
  }) async {
    if (groupId == null ||
        groupId.isEmpty ||
        expenseId == null ||
        expenseId.isEmpty) {
      return;
    }
    try {
      await _groupsRef(weddingId)
          .doc(groupId)
          .collection('expenses')
          .doc(expenseId)
          .delete();
    } catch (_) {}
  }
}