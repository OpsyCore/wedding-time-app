import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../widgets/page_glass.dart';

class _Tutorial {
  final String id;
  final String fa;
  final String en;
  final IconData icon;
  final String faDesc;
  final String enDesc;
  final List<String> faSteps;
  final List<String> enSteps;
  final String videoHintFa;
  final String videoHintEn;
  const _Tutorial({
    required this.id,
    required this.fa,
    required this.en,
    required this.icon,
    required this.faDesc,
    required this.enDesc,
    required this.faSteps,
    required this.enSteps,
    this.videoHintFa = '',
    this.videoHintEn = '',
  });
}

final List<_Tutorial> _all = [
  _Tutorial(
    id: 'home',
    fa: 'خانه — داشبورد و تایمر',
    en: 'Home — Dashboard & Timer',
    icon: Icons.home_rounded,
    faDesc: 'قلب تپنده برنامه — تاریخ عروسی، شمارش‌معکوس، فوکوس امروز و میانبرها',
    enDesc: 'Heart of the app — date, countdown, today focus & shortcuts',
    faSteps: [
      'تاریخ عروسی را در پروفایل زوج تنظیم کن — تایمر 4 باکس (روز/ساعت/دقیقه/ثانیه) اتومات می‌شمارد.',
      'بنر پشت کارت و قلب را در پروفایل → ظاهر کارت خانه انتخاب کن (8 بنر ادیتوریال + 8 قلب مخملی).',
      'کارت “فوکوس امروز” را هر روز چک کن: اقساط سررسید، ایونت‌های امروز/هفته، تسک‌های چک‌لیست.',
      'از میانبرهای پایین کارت برای رفتن سریع به مهمان‌ها، بودجه، چک‌لیست استفاده کن.',
    ],
    enSteps: [
      'Set wedding date in Couple Profile — 4-box timer counts automatically.',
      'Pick banner & heart in Profile → Hero Appearance (8 banners + 8 velvet hearts).',
      'Check “Today Focus” daily: due installments, events, checklist tasks.',
      'Use shortcuts below the card to jump to Guests, Budget, Checklist.',
    ],
  ),
  _Tutorial(
    id: 'guests',
    fa: 'مهمان‌ها + RSVP',
    en: 'Guests + RSVP',
    icon: Icons.groups_rounded,
    faDesc: 'تا 40 نفر رایگان، نامحدود در پرو — پاسخ دعوت‌نامه (RSVP) همین‌جاست',
    enDesc: '40 free, unlimited on Pro — RSVP lives here',
    faSteps: [
      'مهمان را با نام، شماره و گروه (خانواده/دوست/همکار) اضافه کن.',
      'وضعیت را بگذار: دعوت شده / تایید / رد / در انتظار — فیلتر بالا کمک می‌کند.',
      'چیدمان صندلی را بعدا در تب “چیدمان” به مهمان‌ها وصل کن.',
      'خروجی اکسل/PDF مهمان‌ها فقط در پرمیوم فعال است (دکمه خروجی در بودجه).',
      'لینک دعوت‌نامه را از دعوت‌نامه → اشتراک‌گذاری بفرست؛ پاسخ‌ها در صندوق RSVP می‌آید.',
    ],
    enSteps: [
      'Add guest with name, phone, group (family/friend/colleague).',
      'Set status: invited/confirmed/declined/pending — use top filters.',
      'Link guests to seats later in Seating tab.',
      'Excel/PDF export is Premium only.',
      'Share invite link from Invitation → Share; replies land in RSVP inbox.',
    ],
  ),
  _Tutorial(
    id: 'invitation',
    fa: 'دعوت‌نامه دیجیتال',
    en: 'Digital Invitation',
    icon: Icons.mail_rounded,
    faDesc: 'کارت دعوت هوشمند با پالت، تم و QR',
    enDesc: 'Smart invite with palette, theme & QR',
    faSteps: [
      'متن دعوت، لوکیشن و ساعت را پر کن — پیش‌نمایش زنده می‌بینی.',
      'از “پالت عروسی” رنگ برندت را بساز؛ دعوت‌نامه اتومات همان پالت را می‌گیرد.',
      'تم را انتخاب کن: کلاسیک رایگان، 3 تم دیگر فقط پرمیوم.',
      'QR دعوت‌نامه (پرو) را فعال کن تا مهمان با اسکن مستقیم RSVP بدهد.',
      'لینک عمومی (public_invite) را برای هر مهمان شخصی‌سازی کن.',
    ],
    enSteps: [
      'Fill invite text, location, time — live preview.',
      'Build palette in Wedding Palette; invite auto-applies it.',
      'Pick theme: classic free, 3 more Premium only.',
      'Enable Invite QR (Pro) for one-scan RSVP.',
      'Personalize public invite link per guest.',
    ],
  ),
  _Tutorial(
    id: 'checklist',
    fa: 'چک‌لیست و تقویم',
    en: 'Checklist & Calendar',
    icon: Icons.checklist_rtl_rounded,
    faDesc: 'از خواستگاری تا روز عروسی — هیچ کاری جا نمی‌ماند',
    enDesc: 'From proposal to big day — nothing missed',
    faSteps: [
      'تسک بساز، تاریخ سررسید و دسته (مکان/لباس/غذا…) بگذار.',
      'تسک تیک بخورد → در تقویم و تایم‌لاین هم سبز می‌شود.',
      'تسک‌های امروز/هفته در “فوکوس امروز” خانه هایلایت می‌شوند.',
      'تقویم را ماهانه/هفتگی ببین و تسک را با Drag جابجا کن.',
    ],
    enSteps: [
      'Create task with due date & category (venue/dress/food…).',
      'Tick task → also green in Calendar & Timeline.',
      'Today/Week tasks highlight in Home Focus.',
      'View calendar monthly/weekly, drag to reschedule.',
    ],
  ),
  _Tutorial(
    id: 'budget',
    fa: 'بودجه و تامین‌کننده‌ها',
    en: 'Budget & Vendors',
    icon: Icons.account_balance_wallet_rounded,
    faDesc: 'پرو: بودجه چندبخشی + اقساط — پرمیوم: خروجی',
    enDesc: 'Pro: multi-section + installments — Premium: export',
    faSteps: [
      'گروه بودجه بساز (تالار، گل، عکاسی…) و سقف تعیین کن.',
      'تامین‌کننده اضافه کن، مبلغ و اقساطش را ثبت کن — اقساط عقب‌افتاده در فوکوس امروز قرمز می‌شود.',
      'پرداخت هر قسط را تیک بزن — نمودار پیشرفت پر می‌شود.',
      'خروجی PDF/اکسل بودجه (پرمیوم) از FAB خروجی بگیر.',
    ],
    enSteps: [
      'Create budget groups (venue, flowers…) set cap.',
      'Add vendor with amount & installments — overdue red in Focus.',
      'Tick each payment — progress fills.',
      'Export PDF/Excel (Premium) via FAB.',
    ],
  ),
  _Tutorial(
    id: 'seating',
    fa: 'چیدمان نشیمن',
    en: 'Seating Chart',
    icon: Icons.table_restaurant_rounded,
    faDesc: 'پرو: سالن چندتایی با Drag & Drop',
    enDesc: 'Pro: multi-hall drag & drop',
    faSteps: [
      'سالن بساز (مثلا سالن A/B) و میزها را با ظرفیت بچین.',
      'مهمان را از لیست بکش روی صندلی — ذخیره اتومات.',
      'مهمان بدون صندلی زرد می‌ماند تا جا نگیرد.',
      'پرینت چیدمان از گالری QR بگیر.',
    ],
    enSteps: [
      'Create halls (A/B) and tables with capacity.',
      'Drag guest onto seat — auto-save.',
      'Unseated guests stay yellow.',
      'Print from QR gallery.',
    ],
  ),
  _Tutorial(
    id: 'media',
    fa: 'کتابخانه رسانه',
    en: 'Media Library',
    icon: Icons.collections_rounded,
    faDesc: 'رایگان 10 آیتم، پرو 500، پرمیوم نامحدود',
    enDesc: 'Free 10, Pro 500, Premium unlimited',
    faSteps: [
      'عکس/ویدیو آپلود کن — اتومات فشرده و در کلاد ذخیره می‌شود.',
      'آلبوم بساز و رسانه را تگ کن (آماده‌سازی، مراسم، ماه‌عسل).',
      'رسانه را به داستان عشق یا دعوت‌نامه لینک کن.',
      'حذف رسانه از کتابخانه، از همه جا حذف می‌شود — تایید می‌خواهد.',
    ],
    enSteps: [
      'Upload photo/video — auto-compressed to cloud.',
      'Make albums, tag media.',
      'Link media to Love Story or Invite.',
      'Delete needs confirm — removed everywhere.',
    ],
  ),
  _Tutorial(
    id: 'camera',
    fa: 'دوربین مهمان (یک‌بارمصرف)',
    en: 'Guest Disposable Camera',
    icon: Icons.camera_alt_rounded,
    faDesc: 'پرو: 10 شات/مهمان، پرمیوم: نامحدود — نیاز به تایید شما',
    enDesc: 'Pro: 10 shots/guest, Premium unlimited — needs your approval',
    faSteps: [
      'در “مدیریت دوربین” دوربین را فعال کن و سقف شات را بگذار.',
      'QR دوربین را به مهمان بده — مهمان بدون نصب اپ عکس می‌گیرد.',
      'عکس‌ها در “تایید گالری” می‌آید — تایید/رد کن تا در گالری اصلی برود.',
      'گالری QR فقط با QR فعال می‌شود (پرو).',
    ],
    enSteps: [
      'Enable camera in Camera Manage, set cap.',
      'Give QR to guest — no app install needed.',
      'Photos land in Approvals — approve/reject to main gallery.',
      'QR Gallery needs QR (Pro).',
    ],
  ),
  _Tutorial(
    id: 'love',
    fa: 'داستان عشق',
    en: 'Love Story',
    icon: Icons.auto_stories_rounded,
    faDesc: 'رایگان 1 فصل، پرو/پرمیوم نامحدود',
    enDesc: 'Free 1 chapter, Pro/Premium unlimited',
    faSteps: [
      'فصل بساز (آشنایی، خواستگاری…) متن + عکس بگذار.',
      'ترتیب فصل‌ها را با Drag عوض کن.',
      'پیشنهاد متن با هوش مصنوعی — “پیشنهاد بده” را بزن و ویرایش کن.',
      'داستان در دعوت‌نامه و پورتال مهمان هم نمایش داده می‌شود.',
    ],
    enSteps: [
      'Create chapter (how we met…) text + photo.',
      'Reorder via drag.',
      'AI suggest — tap Suggest and edit.',
      'Story shows in invite & guest portal.',
    ],
  ),
  _Tutorial(
    id: 'palette',
    fa: 'پالت عروسی',
    en: 'Wedding Palette',
    icon: Icons.palette_rounded,
    faDesc: '5 رنگ برند عروسی — روی دعوت‌نامه، هدر و بنر اعمال می‌شود',
    enDesc: '5 brand colors — applied to invite, header & banner',
    faSteps: [
      'در همبرگر → پالت عروسی برو (زیر Bridal Party).',
      'از FullColorPicker رنگ‌ها را انتخاب کن یا از پیشنهادها الهام بگیر.',
      'ذخیره → دعوت‌نامه و هدر سایت اتومات با پالت تو رنگ می‌گیرد.',
      'پالت در Firestore ذخیره و بین زوج همگام می‌شود.',
    ],
    enSteps: [
      'Go Hamburger → Wedding Palette (under Bridal Party).',
      'Pick via FullColorPicker or presets.',
      'Save → invite & header auto-tint.',
      'Palette syncs between couple via Firestore.',
    ],
  ),
  _Tutorial(
    id: 'catering',
    fa: 'شام و نوشیدنی (Catering)',
    en: 'Catering',
    icon: Icons.restaurant_rounded,
    faDesc: 'حرفه‌ای و کامل — منو، نوشیدنی، آلرژن، چیدمان میز غذا',
    enDesc: 'Pro & complete — menu, drinks, allergens, buffet layout',
    faSteps: [
      'منوی شام/ناهار/عصرانه را بساز: پیش‌غذا، غذای اصلی، دسر.',
      'نوشیدنی و دسته “بدون الکل/الکلی” را جدا کن (≥10 پرِست هر بخش).',
      'حسابداری دقیق: تعداد مهمان × قیمت واحد + مالیات + انعام.',
      'خروجی لیست خرید و چیدمان بوفه را پرینت بگیر.',
    ],
    enSteps: [
      'Build dinner/lunch menu: starter, main, dessert.',
      'Separate drinks incl. alcohol category (≥10 presets each).',
      'Accurate accounting: guests × unit + tax + tip.',
      'Export shopping & buffet layout.',
    ],
  ),
  _Tutorial(
    id: 'honeymoon',
    fa: 'ماه عسل',
    en: 'Honeymoon',
    icon: Icons.flight_takeoff_rounded,
    faDesc: 'مقصد، بودجه، فصل و چک‌لیست سفر',
    enDesc: 'Destination, budget, season & travel checklist',
    faSteps: [
      'بودجه ماه‌عسل را بگذار و فیلتر فصل/استایل (ساحلی/کوهی) بزن.',
      'مقصد پیشنهاد می‌شود — اگر بودجه کم است قرمز می‌شود.',
      'چک‌لیست ویزا، بلیط، هتل را تیک بزن.',
      'یادداشت‌های سفر را در نوت‌بوک لینک کن.',
    ],
    enSteps: [
      'Set budget, filter season/style (beach/mountain).',
      'Destinations suggested — red if over budget.',
      'Tick visa/ticket/hotel checklist.',
      'Link travel notes in Notebook.',
    ],
  ),
  _Tutorial(
    id: 'notes',
    fa: 'نوت‌بوک — حرفه‌ای و کامل',
    en: 'Notebook — Pro & Complete',
    icon: Icons.note_alt_rounded,
    faDesc: 'یادداشت، چک‌لیست، فایل و صوت برای هر بخش',
    enDesc: 'Notes, checklists, files & audio per section',
    faSteps: [
      'نوت جدید بساز، برچسب بزن (ایده/خرید/تماس).',
      'چک‌لیست داخل نوت و فایل/صدا ضمیمه کن.',
      'نوت را به مهمان یا تامین‌کننده لینک کن.',
      'جستجو و فیلتر برچسب از بالا.',
    ],
    enSteps: [
      'New note, tag (idea/buy/call).',
      'Add checklist, attach file/audio.',
      'Link note to guest or vendor.',
      'Search & filter by tag on top.',
    ],
  ),
  _Tutorial(
    id: 'music',
    fa: 'موزیک و افکت ambient',
    en: 'Music & Ambient',
    icon: Icons.music_note_rounded,
    faDesc: 'موزیک پس‌زمینه + افکت گلبرگ/قلب — فقط دارایی',
    enDesc: 'Background music + petals/hearts — asset only',
    faSteps: [
      'در تب موزیک، آهنگ ambient را انتخاب کن (نام فایل خودت نمایش داده می‌شود).',
      'افکت گلبرگ/قلب را روشن کن — شدت را با اسلایدر تنظیم کن.',
      'پخش فقط وقتی اپ باز است؛ مهمان هم همان موزیک را می‌شنود اگر فعال باشد.',
    ],
    enSteps: [
      'In Music tab pick ambient track (your filename shows).',
      'Enable petals/hearts — tune intensity via slider.',
      'Plays while app open; guests hear same if enabled.',
    ],
  ),
  _Tutorial(
    id: 'timeline',
    fa: 'تایم‌لاین روز عروسی',
    en: 'Wedding Day Timeline',
    icon: Icons.view_timeline_rounded,
    faDesc: 'از آرایش تا شام — با ساعت دقیق',
    enDesc: 'From makeup to dinner — timed',
    faSteps: [
      'ایونت بساز (ورود عروس 18:00) و لوکیشن بگذار.',
      'تایم‌لاین را کشویی ببین — تاخیر را با هشدار زرد می‌بینی.',
      'ایونت را به مسئول (ساقدوش/فیلمبردار) assign کن.',
    ],
    enSteps: [
      'Create event (bride entrance 18:00) with location.',
      'See timeline — delay shows yellow warn.',
      'Assign to responsible (bridesmaid/videographer).',
    ],
  ),
  _Tutorial(
    id: 'plans',
    fa: 'پلن‌ها و پرداخت',
    en: 'Plans & Payment',
    icon: Icons.workspace_premium_rounded,
    faDesc: 'تریال 30 روز فول → هدیه محدود 40 نفر → پرو/پرمیوم',
    enDesc: '30d trial → free 40 → pro/premium',
    faSteps: [
      'همه با trial 30 روز full شروع می‌کنند — بعدش free محدود می‌شوی.',
      'از همبرگر → پلن‌ها برو؛ مقایسه کن و “درخواست ارتقا” بزن.',
      'ادمین بعد از پرداخت خارجی، پلن را فعال می‌کند (plan_requests).',
      'قفل‌ها واقعا می‌بندد — نه فقط متن (PlanLimits).',
    ],
    enSteps: [
      'Everyone starts on 30d full trial → then free limited.',
      'Go Hamburger → Plans, compare, Request upgrade.',
      'Admin activates after external payment.',
      'Gates really lock (PlanLimits).',
    ],
  ),
];

class TutorialsScreen extends StatefulWidget {
  const TutorialsScreen({super.key, required this.weddingId});
  final String weddingId;

  @override
  State<TutorialsScreen> createState() => _TutorialsScreenState();
}

class _TutorialsScreenState extends State<TutorialsScreen> {
  String _query = '';
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final isFa = AppLang.I.isFa;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _all
        : _all.where((t) {
            final hay = '${t.fa} ${t.en} ${t.faDesc} ${t.enDesc}'.toLowerCase();
            return hay.contains(q);
          }).toList();

    return Directionality(
      textDirection: AppLang.I.direction,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 64,
          iconTheme: IconThemeData(color: AppTok.text(context)),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFa ? 'آموزش استفاده' : 'How to use',
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isFa
                    ? 'قدم‌به‌قدم هر قسمت'
                    : 'Step-by-step for each section',
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        body: PageGlass(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: TextStyle(color: AppTok.text(context)),
                  decoration: InputDecoration(
                    hintText: isFa ? 'جستجو: مثلا مهمان، بودجه، پالت…' : 'Search: e.g. guests, budget, palette…',
                    hintStyle: TextStyle(color: AppTok.textSoft(context), fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: AppTok.textSoft(context)),
                    filled: true,
                    fillColor: AppTok.cardSoft(context),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final t = filtered[i];
                    final expanded = _expandedId == t.id;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        color: AppTok.card(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: expanded ? AppTok.accent(context).withValues(alpha: 0.35) : AppTok.border(context).withValues(alpha: 0.6)),
                        boxShadow: expanded ? [BoxShadow(color: AppTok.accent(context).withValues(alpha: 0.10), blurRadius: 12)] : null,
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => setState(() => _expandedId = expanded ? null : t.id),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: AppTok.accent(context).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                    child: Icon(t.icon, size: 18, color: AppTok.accent(context)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(isFa ? t.fa : t.en, style: TextStyle(color: AppTok.text(context), fontSize: 13.5, fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 2),
                                        Text(isFa ? t.faDesc : t.enDesc, style: TextStyle(color: AppTok.textSoft(context), fontSize: 11, height: 1.4)),
                                      ],
                                    ),
                                  ),
                                  Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppTok.textSoft(context)),
                                ],
                              ),
                            ),
                          ),
                          if (expanded)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(color: AppTok.border(context).withValues(alpha: 0.6), height: 16),
                                  for (int s = 0; s < (isFa ? t.faSteps : t.enSteps).length; s++)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(color: AppTok.accent(context), shape: BoxShape.circle),
                                            child: Text('${s + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              (isFa ? t.faSteps : t.enSteps)[s],
                                              style: TextStyle(color: AppTok.text(context), fontSize: 12.5, height: 1.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTok.accent(context).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTok.accent(context).withValues(alpha: 0.18)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppTok.accent(context)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            isFa
                                                ? 'نکته: اگر قفل دیدی → همبرگر → پلن‌ها → ارتقا بده. تریال 30 روزه‌ات فعال است!'
                                                : 'Tip: If you see a lock → Hamburger → Plans → Upgrade. Your 30-day trial is active!',
                                            style: TextStyle(color: AppTok.textSoft(context), fontSize: 11, height: 1.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
