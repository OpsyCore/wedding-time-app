const crypto = require("node:crypto");
const { cert, getApps, initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { FieldValue, Timestamp, getFirestore } = require("firebase-admin/firestore");

const ANDROID_PACKAGE = "wedding.time.app";
const PRODUCT_PLANS = Object.freeze({
  pro: { planId: "pro", durationDays: 365 },
  premium: { planId: "premium", durationDays: null },
});

const CORS_HEADERS = Object.freeze({
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Cache-Control": "no-store",
  "Content-Type": "application/json; charset=utf-8",
});

class ApiError extends Error {
  constructor(statusCode, message) {
    super(message);
    this.statusCode = statusCode;
  }
}

function jsonResponse(statusCode, body) {
  return {
    statusCode,
    headers: CORS_HEADERS,
    body: JSON.stringify(body),
  };
}

function getFirebaseServices() {
  const rawServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!rawServiceAccount) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is not configured");
  }

  const serviceAccount = JSON.parse(rawServiceAccount);
  if (typeof serviceAccount.private_key === "string") {
    serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, "\n");
  }

  const app = getApps()[0] || initializeApp({ credential: cert(serviceAccount) });
  return { auth: getAuth(app), db: getFirestore(app) };
}

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

function decodeRequestBody(event) {
  if (typeof event.body !== "string") return {};
  const body = event.isBase64Encoded
    ? Buffer.from(event.body, "base64").toString("utf8")
    : event.body;
  if (Buffer.byteLength(body, "utf8") > 128 * 1024) {
    throw new ApiError(413, "بدنهٔ درخواست بیش از اندازه بزرگ است.");
  }
  try {
    return JSON.parse(body);
  } catch (_) {
    throw new ApiError(400, "درخواست خرید قابل خواندن نیست.");
  }
}

function requestHeader(event, name) {
  const key = Object.keys(event.headers || {}).find(
    (candidate) => candidate.toLowerCase() === name.toLowerCase(),
  );
  return key ? event.headers[key] : "";
}

exports.handler = async (event) => {
  if (event.httpMethod === "OPTIONS") {
    return { statusCode: 204, headers: CORS_HEADERS, body: "" };
  }
  if (event.httpMethod !== "POST") {
    return jsonResponse(405, { error: "فقط درخواست POST مجاز است." });
  }

  try {
    const authorization = String(requestHeader(event, "authorization") || "");
    const bearerMatch = authorization.match(/^Bearer\s+(.+)$/i);
    if (!bearerMatch) {
      throw new ApiError(401, "ورود به حساب کاربری لازم است.");
    }

    const { auth, db } = getFirebaseServices();
    let decodedToken;
    try {
      decodedToken = await auth.verifyIdToken(bearerMatch[1]);
    } catch (_) {
      throw new ApiError(401, "نشست کاربری معتبر نیست؛ دوباره وارد حساب شوید.");
    }
    const uid = decodedToken.uid;
    const data = decodeRequestBody(event);

    const originalJson = typeof data.originalJson === "string" ? data.originalJson : "";
    const dataSignature = typeof data.dataSignature === "string" ? data.dataSignature : "";
    const suppliedPayload = typeof data.payload === "string" ? data.payload : "";
    if (!originalJson || !dataSignature || !suppliedPayload) {
      throw new ApiError(400, "رسید خرید کامل نیست.");
    }

    let receipt;
    try {
      receipt = JSON.parse(originalJson);
    } catch (_) {
      throw new ApiError(400, "رسید خرید قابل خواندن نیست.");
    }

    let validSignature = false;
    try {
      validSignature = verifyReceiptSignature(
        originalJson,
        dataSignature,
        process.env.BAZAAR_RSA_PUBLIC_KEY,
      );
    } catch (_) {
      throw new ApiError(503, "کلید اعتبارسنجی بازار روی سرور تنظیم نشده است.");
    }
    if (!validSignature) {
      throw new ApiError(403, "امضای رسید خرید معتبر نیست.");
    }

    const productId = String(receipt.productId || "");
    const product = PRODUCT_PLANS[productId];
    const signedPayload = String(receipt.developerPayload || receipt.payload || "");
    const purchaseState = receipt.purchaseState;
    const purchased =
      purchaseState === 0 || purchaseState === "0" || purchaseState === "PURCHASED";
    const purchaseToken = String(receipt.purchaseToken || "");
    const orderId = String(receipt.orderId || "");

    if (receipt.packageName !== ANDROID_PACKAGE) {
      throw new ApiError(403, "این رسید برای برنامهٔ دیگری است.");
    }
    if (!product || productId !== String(data.productId || "")) {
      throw new ApiError(400, "شناسهٔ محصول در رسید معتبر نیست.");
    }
    if (!purchased || !purchaseToken || !orderId) {
      throw new ApiError(412, "خرید کامل یا معتبر نیست.");
    }
    if (signedPayload !== suppliedPayload || !signedPayload.startsWith(`${uid}:`)) {
      throw new ApiError(403, "رسید به این حساب کاربری تعلق ندارد.");
    }

    const receiptId = crypto.createHash("sha256").update(purchaseToken).digest("hex");
    const orderRef = db.collection("bazaar_orders").doc(receiptId);
    const userRef = db.collection("users").doc(uid);

    const result = await db.runTransaction(async (transaction) => {
      const [orderSnap, userSnap] = await Promise.all([
        transaction.get(orderRef),
        transaction.get(userRef),
      ]);
      if (!userSnap.exists) {
        throw new ApiError(412, "حساب کاربری پیدا نشد.");
      }

      const userData = userSnap.data() || {};
      const weddingId = String(userData.weddingId || "").trim();
      const weddingRef = weddingId ? db.collection("weddings").doc(weddingId) : null;
      const weddingSnap = weddingRef ? await transaction.get(weddingRef) : null;
      const weddingData = weddingSnap && weddingSnap.exists ? weddingSnap.data() || {} : {};

      if (orderSnap.exists) {
        const previous = orderSnap.data() || {};
        if (previous.uid !== uid || previous.productId !== productId) {
          throw new ApiError(409, "این رسید قبلاً برای حساب دیگری ثبت شده است.");
        }
        const storedExpiresAtMs = Number(previous.expiresAtMs || 0);
        const currentUserPlan = String(userData.planId || userData.plan || "");
        const currentWeddingPlan = String(weddingData.planId || weddingData.plan || "");
        const effectivePlanId =
          previous.planId === "premium" ||
          productId === "premium" ||
          currentUserPlan === "premium" ||
          currentWeddingPlan === "premium"
            ? "premium"
            : "pro";
        const stillEntitled =
          effectivePlanId === "premium" || storedExpiresAtMs > Date.now();
        if (stillEntitled) {
          const userWrite = {
            plan: effectivePlanId,
            planId: effectivePlanId,
            planActivatedAt: FieldValue.serverTimestamp(),
            planActivatedBy: uid,
            planSource: "bazaar",
          };
          if (effectivePlanId === "premium") {
            userWrite.planExpiresAt = FieldValue.delete();
          } else {
            userWrite.planExpiresAt = Timestamp.fromMillis(storedExpiresAtMs);
          }
          transaction.set(userRef, userWrite, { merge: true });
          if (weddingRef && weddingSnap && weddingSnap.exists) {
            const weddingWrite = { planId: effectivePlanId, planSource: "bazaar" };
            if (effectivePlanId === "premium") {
              weddingWrite.planExpiresAt = FieldValue.delete();
            } else {
              weddingWrite.planExpiresAt = Timestamp.fromMillis(storedExpiresAtMs);
            }
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
      const activePlan = userPlan === "premium" || weddingPlan === "premium"
        ? "premium"
        : (userPlan === "pro" || weddingPlan === "pro"
          ? "pro"
          : (weddingPlan || userPlan));
      let planId = product.planId;
      let expiresAtMs = null;

      if (productId === "pro" && activePlan === "premium") {
        planId = "premium";
      } else if (productId === "pro") {
        const now = Date.now();
        const baseExpiry = Math.max(
          now,
          activePlan === "pro" ? toMillis(weddingData.planExpiresAt) : 0,
          userPlan === "pro" ? toMillis(userData.planExpiresAt) : 0,
          activePlan === "trial" ? toMillis(weddingData.trialEndsAt) : 0,
          userPlan === "trial" ? toMillis(userData.trialEndsAt) : 0,
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
      if (planId === "premium") {
        userWrite.planExpiresAt = FieldValue.delete();
      } else {
        userWrite.planExpiresAt = Timestamp.fromMillis(expiresAtMs);
      }
      transaction.set(userRef, userWrite, { merge: true });

      if (weddingRef && weddingSnap && weddingSnap.exists) {
        const weddingWrite = {
          planId,
          planSource: "bazaar",
          bazaarOrderId: orderId,
        };
        if (planId === "premium") {
          weddingWrite.planExpiresAt = FieldValue.delete();
        } else {
          weddingWrite.planExpiresAt = Timestamp.fromMillis(expiresAtMs);
        }
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

    return jsonResponse(200, result);
  } catch (error) {
    if (error instanceof ApiError) {
      return jsonResponse(error.statusCode, { error: error.message });
    }
    console.error("Bazaar receipt verification failed:", error);
    return jsonResponse(500, { error: "تأیید خرید موقتاً ممکن نیست؛ کمی بعد دوباره تلاش کنید." });
  }
};
