# اتصال پرداخت درون‌برنامه‌ای کافه‌بازار با Netlify Functions

## کالاهای بازار

| شناسهٔ کالا | محصول | نوع خرید | دسترسی |
|---|---|---|---|
| `pro` | پرو یک‌ساله | یک‌بار خرید | ۳۶۵ روز؛ خرید سالانه پس از تأیید سرور مصرف می‌شود تا امکان خرید دوباره فراهم باشد |
| `premium` | پرمیوم مادام‌العمر | یک‌بار خرید | بدون انقضا؛ مصرف نمی‌شود |

## معماری

برنامه خرید را با Poolakey انجام می‌دهد و رسید را همراه Firebase ID token به تابع زیر می‌فرستد:

`https://wedding-time-app2.netlify.app/.netlify/functions/verify-bazaar-purchase`

تابع Netlify توکن ورود را با Firebase Admin تأیید می‌کند، امضای RSA رسید را بررسی می‌کند، از استفادهٔ دوبارهٔ توکن خرید جلوگیری می‌کند و پلن را با دسترسی مدیر در Firestore ثبت می‌کند. اعتبارسنجی فقط به برنامهٔ اندروید واگذار نمی‌شود.

این روش **Firebase Cloud Functions را استفاده نمی‌کند و برای استقرار این تابع نیازی به Blaze ندارد**. ورود Firebase و Firestore فعلی برنامه همچنان استفاده می‌شوند. طرح و سهمیه‌های خود Netlify جداگانه اعمال می‌شوند.

## کلیدهای لازم

برای ساخت APK، Repository variable به نام `BAZAAR_RSA_PUBLIC_KEY` باید در GitHub مسیر **Settings → Secrets and variables → Actions → Variables** مقداردهی شود. این همان کلید عمومی RSA پیشخان بازار است و داخل APK قرار می‌گیرد.

در Netlify، سایت `wedding-time-app2` را باز کنید و از مسیر **Site configuration → Environment variables** این دو متغیر را برای Production و دسترسی Functions تنظیم کنید:

1. `BAZAAR_RSA_PUBLIC_KEY` — همان **کلید عمومی RSA** بازار که در GitHub Actions ثبت کرده‌اید.
2. `FIREBASE_SERVICE_ACCOUNT_JSON` — محتوای کامل فایل JSON یک Service Account از پروژهٔ Firebase با شناسهٔ `wedding-time-8240d`.

برای Service Account، در Google Cloud Console همان پروژه یک حساب خدماتی بسازید، نقش دسترسی Firestore با نام **Cloud Datastore User** را بدهید و یک JSON key بسازید. این JSON حاوی کلید خصوصی است: آن را فقط در Netlify به‌عنوان متغیر محرمانه قرار دهید؛ **هرگز در GitHub، مخزن، APK یا گفتگو قرار ندهید**. کلید RSA بازار عمومی است؛ کلید خصوصی Service Account محرمانه است.

پس از افزودن متغیرها، از Netlify یک Deploy برای Production اجرا کنید تا تابع با تنظیمات تازه منتشر شود. اگر مخزن به Netlify متصل است، مطمئن شوید Deploy شامل شاخه/کدی است که تابع `netlify/functions/verify-bazaar-purchase.js` را دارد.

## ساخت و تست برنامه

GitHub Actions متغیر عمومی `BAZAAR_RSA_PUBLIC_KEY` را هنگام ساخت APK به Poolakey می‌دهد. نشانی تابع به‌طور پیش‌فرض از دامنهٔ `wedding-time-app2.netlify.app` استفاده می‌کند. اگر تابع روی دامنهٔ دیگری منتشر شد، یک Repository variable اختیاری به نام `BAZAAR_VERIFY_URL` با نشانی کامل تابع بسازید؛ قالب آن `https://<دامنه>/.netlify/functions/verify-bazaar-purchase` است. سپس APK جدید بسازید و خرید را با حساب آزمایشی بازار امتحان کنید.

اگر خرید با خطای 401 روبه‌رو شد، ورود Firebase را تازه کنید. خطای 503 دربارهٔ کلیدها معمولاً یعنی یکی از متغیرهای Netlify تنظیم یا Deploy نشده است. برای پاک‌کردن داده‌های محرمانه از Netlify یا بررسی هزینه‌ها، بخش تنظیمات و Usage همان سایت را ببینید.
