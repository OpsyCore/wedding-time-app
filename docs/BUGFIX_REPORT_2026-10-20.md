# گزارش رفع باگ و پایداری — ۲۸ مهر ۱۴۰۵ / 2026-10-20

شاخه: `arena/39ed5273-wedding-time-app`

این گزارش کارهایی است که در این پاس انجام شد، چطور بررسی شدند و چه ریسک‌هایی
باقی مانده است. هیچ تغییر ظاهریِ عمدی در طراحی صفحات انجام نشده؛ فقط رفتار
خطا، لایف‌سایکل و چند باگ واقعی UI اصلاح شده است.

---

## ۱) پایداری استارت اپ

**`lib/main.dart`**

- سه لایهٔ محافظ اضافه شد:
  - `FlutterError.onError` برای خطاهای build/layout
  - `platformDispatcher.onError` برای خطاهای asyncِ مدیریت‌نشده
    (قطعی شبکه، دادهٔ بد، …) تا اپ terminate نشود
  - `ErrorWidget.builder` با یک نمای آرام هم‌خوان با تم، به‌جای صفحهٔ
    قرمز (debug) یا خاکستری (release)
- راه‌اندازی Firebase و کنترلرها داخل `try/catch` رفت. اگر Firebase بالا
  نیاید، به‌جای صفحهٔ سفید یک صفحهٔ «اتصال برقرار نشد» با دکمهٔ
  «تلاش دوباره» و سوییچ فارسی/انگلیسی نمایش داده می‌شود.
- **باگ جدی:** `MaterialApp` کلید `ValueKey('wedding_time_root_$font')`
  داشت. با تغییر فونت در پروفایل، کل درخت Element از جمله `Navigator`
  دور ریخته می‌شد و کاربر به اسپلش (۱۰ ثانیه) پرت می‌شد. کلید حذف شد؛
  فونت مثل قبل از طریق `theme` اعمال می‌شود.

**`lib/screens/splash_screen.dart`**

- کاور و آماده‌سازی (auth + خواندن مراسم) حالا **موازی** اجرا می‌شوند؛
  قبلاً اول ۱۰ ثانیه کاور منتظر می‌ماند و بعد درخواست شبکه شروع می‌شد.
- کاور با ضربه **قابل رد کردن** است (`tap_to_continue`).
- درخواست‌های شبکه با `timeout` ۲۰ ثانیه محدود شدند. قبلاً روی اینترنت
  ضعیف اسپینر تا بی‌نهایت می‌ماند.
- در خطای شبکه، به‌جای فرستادن کاربر به صفحهٔ لاگین، کارت «تلاش دوباره»
  با گزینهٔ «ورود با حساب دیگر» نمایش داده می‌شود.

## ۲) باگ‌های لایف‌سایکل / setState بعد از dispose

- `checklist_screen.dart`
  - `deleteTask` و `resetChecklist` بعد از `await` بدون `mounted` ست‌ایت
    می‌کردند (کرش در صورت خروج از صفحه).
  - `updateTask` آپدیت خوش‌بینانه می‌زد ولی خطای ذخیره را نمی‌گرفت؛ حالا
    در صورت خطا مقدار قبلی برمی‌گردد و پیام «ذخیره ناموفق» می‌دهد.
  - `loadTasks` هیچ `catch` نداشت؛ با قطعی شبکه اسپینر برای همیشه می‌ماند.
    حالا نمای خطا + دکمهٔ تلاش دوباره دارد.
- `plans_screen.dart` — ارسال نظر پلن؛ `setState` بعد از await بدون
  `mounted`.
- `qr_gallery_screen.dart` — ذخیرهٔ لینک آلبوم؛ `setState` بعد از await.
- `wedding_setup_screen.dart` — `_createWedding` هنگام خروج از صفحه در
  میانهٔ درخواست کرش می‌کرد.
- `supports_manage_screen.dart` — دیالوگ دسته‌بندی: `setState` بعد از
  بسته شدن دیالوگ + کنترلرهای موقت که dispose نمی‌شدند.
- `home_screen.dart` — هر چهار listener فایراستور حالا `mounted` را چک
  می‌کنند و `weddingDate` با کست امن خوانده می‌شود (قبلاً اگر مقدار
  String بود، listener می‌شکست).

## ۳) باگ واقعی تایپ در فرم کارت‌های بانکی

**`lib/screens/supports_manage_screen.dart`**

برای هر کارت بانکی، سه `TextEditingController` **داخل `build`** ساخته
می‌شد. با هر keystroke (`onChanged` → `setState`) کنترلر جدید ساخته
می‌شد؛ نتیجه: پرش مکان‌نما به انتهای متن، از دست رفتن حالت IME و لیک
کنترلر. حالا کنترلرها در state نگه‌داری و هم‌زمان با افزودن/حذف کارت
مدیریت و در `dispose` آزاد می‌شوند.

## ۴) لیک کنترلر در پروفایل

**`lib/screens/profile_screen.dart`**

فیلدهای فقط‌خواندنی ایمیل و نقش، در هر rebuild یک
`TextEditingController(text: ...)` جدید می‌ساختند. با `InputDecorator`
جایگزین شدند (ظاهر یکسان، بدون لیک).

## ۵) کارایی صفحهٔ بودجه

**`lib/screens/budget_screen.dart`**

`FutureBuilder` جمع‌ها، در هر rebuild (تغییر تم/زبان/موسیقی/افکت) یک
کوئری Firestore برای **هر گروه** می‌زد. حالا نتیجه بر اساس هویت
`QuerySnapshot` کش می‌شود و فقط با تغییر واقعی داده دوباره محاسبه
می‌شود.

## ۶) دادهٔ خراب / قفل شدن روی permission-denied

- `lib/models/wedding_model.dart` — `weddingDate` ممکن است `String` یا
  `DateTime` باشد؛ کست مستقیم به `Timestamp` کل لیست مراسم را می‌شکست.
  حالا هر سه نوع پشتیبانی می‌شود و نام‌ها با `toString()` امن خوانده
  می‌شوند.
- `lib/services/wedding_service.dart` — اگر `weddingId` کاربر به مراسمی
  اشاره کند که عضو آن نیست (دادهٔ قدیمی/سند پاک‌شده)، قبلاً وارد پنل
  می‌شد و همهٔ خواندن‌های زیرمجموعه `permission-denied` می‌شدند.
  حالا `getWedding` عضویت را بررسی می‌کند و `null` برمی‌گرداند تا مسیر
  setup طی شود.

## ۷) overflow نوار پایین با ۷ تب

**`lib/main_navigation_screen.dart`**

آیتم‌های نوار پایین بدون `Expanded` و بدون محدودیت متن بودند. روی
عرض‌های کم (۳۶۰dp و کمتر) یا با `textScale` بزرگ‌تر، `Row` سرریز
می‌کرد. حالا هر تب `Expanded` است، متن یک‌خطی با `ellipsis` و پدینگ
افقی کمتر. مکان‌نما و ارتفاع لمس هم حفظ شده است.

## ۸) ترجمه‌های گم‌شده

۱۰ کلید در UI استفاده می‌شد ولی در هیچ‌کدام از جدول‌های fa/en نبود؛
یعنی متن خام مثل `item_saved` روی صفحه دیده می‌شد:

`checklist_load_error`، `currency_toman`، `go_to_login`، `item_saved`،
`love_story_guest_hint`، `no_results`، `select_city`،
`splash_network_error`، `splash_network_hint`، `tap_to_continue`،
`async_load_error`، `async_network_hint`

هر دو جدول حالا ۱۵۸۴ کلید یکسان دارند (بدون کلید تکراری).

## ۹) تکمیل پاس دوم (شاخهٔ `arena/a648bdc6-wedding-time-app`)

1. **رفع لودینگ بی‌نهایت در همهٔ `StreamBuilder`ها (`lib/widgets/async_state_views.dart`):**
   - ویجت مشترک `AsyncErrorView` (در دو حالت کامل و `compact`) و `AsyncLoadingView` ساخته شد.
   - تمام ۷۶ `StreamBuilder` پروژه در `lib/screens/` و `lib/widgets/` اکنون وضعیت `hasError` را مدیریت می‌کنند (نمایش `AsyncErrorView` با دکمهٔ تلاش مجدد برای استریم‌های اصلی صفحات، و fallback امن برای ویجت‌های جانبی/بج‌ها).
   - تست رگرسیون در `test/build_regression_test.dart` اضافه شد تا هیچ `StreamBuilder` جدیدی بدون مدیریت `hasError` وارد کد نشود.
2. **کوتاه شدن اسپلش (`lib/screens/splash_screen.dart`):**
   - زمان کاور اسپلش از ۱۰ ثانیه به **۴ ثانیه** کاهش یافت (همچنان با ضربه قابل رد شدن است و مهلت ۲۰ ثانیه‌ای شبکه حفظ شده است).
3. **حذف کلید هاردکد شدهٔ ImgBB از سورس (`lib/core/app_config.dart`):**
   - مقدار `defaultValue` کلید `IMGBB_API_KEY` در `AppConfig` خالی (`''`) شد و تست رگرسیون برای جلوگیری از هاردکد مجدد اضافه شد.
   - راهنمای کامل باطل کردن (Rotate) کلید قبلی در پنل ImgBB و تنظیم Secret `IMGBB_API_KEY` در GitHub Actions به `docs/ANDROID_RELEASE.md` اضافه شد.
4. **کاهش چشمگیر حجم APK در گیت‌هاب اکشنز (`.github/workflows/apk.yml`):**
   - بیلد گیت‌هاب از `--debug` (حجم ~۲۱۲ مگابایت شامل تمام معماری‌ها و ابزارهای دیباگ) به `--release --split-per-abi` تغییر یافت و سه فایل تفکیک‌شده (`app-arm64-v8a-release.apk` برای گوشی‌های جدید، `app-armeabi-v7a-release.apk` برای گوشی‌های قدیمی‌تر و `app-x86_64-release.apk`) در Release منتشر می‌شوند.

---

## ریسک‌های باقی‌مانده (به ترتیب اولویت)

1. **باطل کردن کلید قبلی در پنل ImgBB (اقدام دستی توسط شما):**
   کلید از سورس حذف شد، اما چون در تاریخچهٔ قبلی گیت بوده، حتماً در پنل `api.imgbb.com` کلید قبلی را Regenerate کنید و کلید جدید را در GitHub Secrets با نام `IMGBB_API_KEY` قرار دهید.
2. **۷ تب در نوار پایین** — overflow رفع شد، ولی در صورت تمایل در آینده می‌توان به ۵ تب اصلی + «بیشتر» بازطراحی کرد.
3. **کنترلرهای دیالوگ‌های محلی** — در چند صفحه کنترلرهای موقت دیالوگ‌ها پس از بسته شدن آزاد نمی‌شوند (لیک جزئی).
4. **تست‌های واحد بیشتر** — افزودن تست‌های مرزی برای `PlanLimits.isTrialValid` و `WeddingModel.fromDoc`.
