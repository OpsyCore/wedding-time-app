import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_poolakey/flutter_poolakey.dart';
import 'package:uuid/uuid.dart';

class BazaarPurchaseResult {
  const BazaarPurchaseResult({
    required this.planId,
    required this.expiresAt,
    required this.duplicate,
    required this.annualProductConsumed,
  });

  final String planId;
  final DateTime? expiresAt;
  final bool duplicate;
  final bool annualProductConsumed;
}

/// Café Bazaar billing bridge.
///
/// Receipt signatures are checked locally by Poolakey and again by the
/// `verifyBazaarPurchase` Firebase callable before any paid entitlement is
/// written to Firestore. The RSA key is a public key, supplied at build time.
class BazaarBillingService {
  BazaarBillingService._();
  static final BazaarBillingService I = BazaarBillingService._();

  static const _rsaPublicKey =
      String.fromEnvironment('BAZAAR_RSA_PUBLIC_KEY', defaultValue: '');
  static const _supportedProducts = {'pro', 'premium'};

  bool _connected = false;
  Future<void>? _connecting;

  Future<void> _ensureConnected() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw StateError('پرداخت بازار فقط در نسخهٔ اندروید قابل استفاده است.');
    }
    if (_rsaPublicKey.trim().isEmpty) {
      throw StateError('کلید عمومی پرداخت بازار در نسخهٔ برنامه تنظیم نشده است.');
    }
    if (_connected) return;
    final pending = _connecting;
    if (pending != null) return pending;

    final completer = Completer<void>();
    _connecting = completer.future;
    try {
      await FlutterPoolakey.connect(
        _rsaPublicKey.trim(),
        onSucceed: () {
          _connected = true;
          if (!completer.isCompleted) completer.complete();
        },
        onFailed: () {
          _connected = false;
          if (!completer.isCompleted) {
            completer.completeError(
              StateError('اتصال به پرداخت کافه‌بازار برقرار نشد.'),
            );
          }
        },
        onDisconnected: () => _connected = false,
      );
      await completer.future.timeout(const Duration(seconds: 20));
    } catch (_) {
      _connected = false;
      rethrow;
    } finally {
      _connecting = null;
    }
  }

  Future<BazaarPurchaseResult> purchasePlan(String productId) async {
    if (!_supportedProducts.contains(productId)) {
      throw ArgumentError.value(productId, 'productId', 'محصول بازار ناشناخته است.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('برای خرید ابتدا وارد حساب کاربری شو.');

    await _ensureConnected();
    final payload = '${user.uid}:${const Uuid().v4()}';
    final purchase = await FlutterPoolakey.purchase(
      productId,
      payload: payload,
    );

    if (purchase.purchaseState != PurchaseState.PURCHASED ||
        purchase.productId != productId ||
        purchase.packageName != 'wedding.time.app' ||
        purchase.payload != payload) {
      throw StateError('اطلاعات خرید با محصول یا حساب کاربری هم‌خوانی ندارد.');
    }

    final callable = FirebaseFunctions.instance.httpsCallable(
      'verifyBazaarPurchase',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    final response = await callable.call<Map<String, dynamic>>({
      'productId': purchase.productId,
      'payload': purchase.payload,
      'originalJson': purchase.originalJson,
      'dataSignature': purchase.dataSignature,
    });
    final data = Map<String, dynamic>.from(response.data);
    final grantedPlan = (data['planId'] ?? '').toString();
    if (grantedPlan != 'pro' && grantedPlan != 'premium') {
      throw StateError('تأیید خرید از سرور نتیجهٔ معتبری برنگرداند.');
    }

    var consumed = productId != 'pro';
    if (productId == 'pro') {
      try {
        consumed = await FlutterPoolakey.consume(purchase.purchaseToken);
      } on PlatformException {
        // Entitlement is already granted server-side. Keep it and surface the
        // consume state so the UI can direct the user to support if needed.
        consumed = false;
      }
    }

    final rawExpiry = data['expiresAtMs'];
    final expiryMs = rawExpiry is num ? rawExpiry.toInt() : null;
    return BazaarPurchaseResult(
      planId: grantedPlan,
      expiresAt: expiryMs == null ? null : DateTime.fromMillisecondsSinceEpoch(expiryMs),
      duplicate: data['duplicate'] == true,
      annualProductConsumed: consumed,
    );
  }
}
