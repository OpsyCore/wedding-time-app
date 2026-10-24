const crypto = require("node:crypto");
const { initializeApp } = require("firebase-admin/app");
const { FieldValue, Timestamp, getFirestore } = require("firebase-admin/firestore");
const { defineString } = require("firebase-functions/params");
const { HttpsError, onCall } = require("firebase-functions/v2/https");

initializeApp();
const db = getFirestore();
const bazaarRsaPublicKey = defineString("BAZAAR_RSA_PUBLIC_KEY");
const ANDROID_PACKAGE = "wedding.time.app";
const PRODUCT_PLANS = Object.freeze({
  pro: { planId: "pro", durationDays: 365, consumable: true },
  premium: { planId: "premium", durationDays: null, consumable: false },
});

function publicKeyFromBase64(value) {
  const normalized = String(value || "").trim();
  if (!normalized) throw new Error("BAZAAR_RSA_PUBLIC_KEY is not configured");
  if (normalized.includes("BEGIN PUBLIC KEY")) return normalized;
  const compact = normalized.replace(/\s/g, "");
  const wrapped = compact.match(/.{1,64}/g).join("\n");
  return `-----BEGIN PUBLIC KEY-----\n${wrapped}\n-----END PUBLIC KEY-----`;
}

function verifyReceiptSignature(originalJson, signature, encodedKey) {
  const verifier = crypto.createVerify("RSA-SHA1");
  verifier.update(originalJson, "utf8");
  verifier.end();
  return verifier.verify(publicKeyFromBase64(encodedKey), signature, "base64");
}

function toMillis(value) {
  if (!value) return 0;
  if (typeof value.toMillis === "function") return value.toMillis();
  if (value instanceof Date) return value.getTime();
  if (typeof value === "number" && Number.isFinite(value)) return value;
  return 0;
}

exports.verifyBazaarPurchase = onCall({ region: "us-central1" }, async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError("unauthenticated", "ورود به حساب لازم است.");

  const data = request.data || {};
  const originalJson = typeof data.originalJson === "string" ? data.originalJson : "";
  const dataSignature = typeof data.dataSignature === "string" ? data.dataSignature : "";
  const suppliedPayload = typeof data.payload === "string" ? data.payload : "";
  if (!originalJson || !dataSignature || !suppliedPayload) {
    throw new HttpsError("invalid-argument", "رسید خرید کامل نیست.");
  }

  let receipt;
  try {
    receipt = JSON.parse(originalJson);
  } catch (_) {
    throw new HttpsError("invalid-argument", "رسید خرید قابل خواندن نیست.");
  }

  let validSignature = false;
  try {
    validSignature = verifyReceiptSignature(
      originalJson,
      dataSignature,
      bazaarRsaPublicKey.value(),
    );
  } catch (_) {
    throw new HttpsError("failed-precondition", "کلید اعتبارسنجی بازار تنظیم نشده است.");
  }
  if (!validSignature) {
    throw new HttpsError("permission-denied", "امضای رسید خرید معتبر نیست.");
  }

  const productId = String(receipt.productId || "");
  const product = PRODUCT_PLANS[productId];
  const signedPayload = String(receipt.developerPayload || receipt.payload || "");
  const purchaseState = receipt.purchaseState;
  const purchased = purchaseState === 0 || purchaseState === "0" || purchaseState === "PURCHASED";
  const purchaseToken = String(receipt.purchaseToken || "");
  const orderId = String(receipt.orderId || "");

  if (receipt.packageName !== ANDROID_PACKAGE) {
    throw new HttpsError("permission-denied", "این رسید برای برنامهٔ دیگری است.");
  }
  if (!product || productId !== String(data.productId || "")) {
    throw new HttpsError("invalid-argument", "شناسهٔ محصول در رسید معتبر نیست.");
  }
  if (!purchased || !purchaseToken || !orderId) {
    throw new HttpsError("failed-precondition", "خرید کامل یا معتبر نیست.");
  }
  if (signedPayload !== suppliedPayload || !signedPayload.startsWith(`${uid}:`)) {
    throw new HttpsError("permission-denied", "رسید به این حساب کاربری تعلق ندارد.");
  }

  const receiptId = crypto.createHash("sha256").update(purchaseToken).digest("hex");
  const orderRef = db.collection("bazaar_orders").doc(receiptId);
  const userRef = db.collection("users").doc(uid);

  return db.runTransaction(async (transaction) => {
    const [orderSnap, userSnap] = await Promise.all([
      transaction.get(orderRef),
      transaction.get(userRef),
    ]);
    if (!userSnap.exists) throw new HttpsError("failed-precondition", "حساب کاربری پیدا نشد.");

    const userData = userSnap.data() || {};
    const weddingId = String(userData.weddingId || "").trim();
    const weddingRef = weddingId ? db.collection("weddings").doc(weddingId) : null;
    const weddingSnap = weddingRef ? await transaction.get(weddingRef) : null;
    const weddingData = weddingSnap && weddingSnap.exists ? weddingSnap.data() || {} : {};

    if (orderSnap.exists) {
      const previous = orderSnap.data() || {};
      if (previous.uid !== uid || previous.productId !== productId) {
        throw new HttpsError("already-exists", "این رسید قبلاً برای حساب دیگری ثبت شده است.");
      }
      const storedExpiresAtMs = Number(previous.expiresAtMs || 0);
      const effectivePlanId = previous.planId === "premium"
        ? "premium"
        : (productId === "premium" ? "premium" : "pro");
      const stillEntitled = effectivePlanId === "premium" || storedExpiresAtMs > Date.now();
      if (stillEntitled) {
        const userWrite = {
          plan: effectivePlanId,
          planId: effectivePlanId,
          planActivatedAt: FieldValue.serverTimestamp(),
          planActivatedBy: uid,
          planSource: "bazaar",
        };
        if (effectivePlanId === "premium") userWrite.planExpiresAt = FieldValue.delete();
        else userWrite.planExpiresAt = Timestamp.fromMillis(storedExpiresAtMs);
        transaction.set(userRef, userWrite, { merge: true });
        if (weddingRef && weddingSnap && weddingSnap.exists) {
          const weddingWrite = { planId: effectivePlanId, planSource: "bazaar" };
          if (effectivePlanId === "premium") weddingWrite.planExpiresAt = FieldValue.delete();
          else weddingWrite.planExpiresAt = Timestamp.fromMillis(storedExpiresAtMs);
          transaction.set(weddingRef, weddingWrite, { merge: true });
        }
      }
      return {
        planId: stillEntitled ? effectivePlanId : "free",
        expiresAtMs: productId === "premium" ? null : storedExpiresAtMs,
        duplicate: true,
      };
    }

    const userPlan = String(userData.planId || userData.plan || "");
    const weddingPlan = String(weddingData.planId || weddingData.plan || "");
    // Prefer the strongest entitlement found on either profile, so a stale
    // wedding document cannot downgrade a user's lifetime Premium purchase.
    const activePlan = userPlan === "premium" || weddingPlan === "premium"
      ? "premium"
      : (userPlan === "pro" || weddingPlan === "pro"
        ? "pro"
        : (weddingPlan || userPlan));
    let planId = product.planId;
    let expiresAtMs = null;

    // مادام‌العمر همیشه بالاتر از پلن سالانه است و با خرید سالانه تنزل نمی‌کند.
    if (productId === "pro" && activePlan === "premium") {
      planId = "premium";
    } else if (productId === "pro") {
      const now = Date.now();
      const baseExpiry = Math.max(
        now,
        activePlan === "pro" ? toMillis(weddingData.planExpiresAt) : 0,
        String(userData.planId || "") === "pro" ? toMillis(userData.planExpiresAt) : 0,
        activePlan === "trial" ? toMillis(weddingData.trialEndsAt) : 0,
        String(userData.planId || "") === "trial" ? toMillis(userData.trialEndsAt) : 0,
      );
      expiresAtMs = baseExpiry + product.durationDays * 24 * 60 * 60 * 1000;
    }

    const userWrite = {
      plan: planId,
      planId,
      planActivatedAt: FieldValue.serverTimestamp(),
      planActivatedBy: uid,
      planSource: "bazaar",
      bazaarOrderId: orderId,
    };
    if (planId === "premium") userWrite.planExpiresAt = FieldValue.delete();
    else userWrite.planExpiresAt = Timestamp.fromMillis(expiresAtMs);
    transaction.set(userRef, userWrite, { merge: true });

    if (weddingRef && weddingSnap && weddingSnap.exists) {
      const weddingWrite = {
        planId,
        planSource: "bazaar",
        bazaarOrderId: orderId,
      };
      if (planId === "premium") weddingWrite.planExpiresAt = FieldValue.delete();
      else weddingWrite.planExpiresAt = Timestamp.fromMillis(expiresAtMs);
      transaction.set(weddingRef, weddingWrite, { merge: true });
    }

    transaction.create(orderRef, {
      uid,
      productId,
      planId,
      orderId,
      purchaseTime: Number(receipt.purchaseTime || 0),
      verifiedAt: FieldValue.serverTimestamp(),
      expiresAtMs,
      packageName: ANDROID_PACKAGE,
    });

    return { planId, expiresAtMs, duplicate: false };
  });
});
