import 'package:flutter/material.dart';

import '../models/subscription_plan.dart';

/// پیش‌فرض پلن‌ها — ادمین از Firestore override می‌کند.
/// ترتیب نمایش کارت‌ها: free | pro (یک‌ساله) | premium (مادام‌العمر)
/// + پلن مخفی trial: هر نصب جدید ۱ ماه فول رایگان (everythingOpen)، بعد از ۳۰ روز اتومات به free برمی‌گردد
class AppPlans {
  AppPlans._();

  static const trialId = 'trial';
  static const freeId = 'free';
  static const proMonthlyId = 'pro_monthly';
  static const proId = 'pro';
  static const premiumId = 'premium';

  /// ترتیب ثابت نمایش؛ پلن‌های فروش بازار فقط سالانه و مادام‌العمر هستند.
  static const displayOrder = [freeId, proId, premiumId];

  static List<SubscriptionPlan> get defaults => [
        // ── TRIAL مخفی — ۱ ماه فول رایگان Auto (everythingOpen) — نمایش داده نمی‌شود ──
        SubscriptionPlan(
          id: trialId,
          nameFa: '۱ ماه فول رایگان',
          nameEn: '1 Month Full — Trial',
          subtitleFa: '۳۰ روز دسترسی کامل به همه امکانات — بدون پرداخت',
          subtitleEn: '30 days full access — no payment',
          ctaFa: 'شروع تریال',
          ctaEn: 'Start trial',
          iconCode: Icons.all_inclusive_rounded.codePoint,
          priceToman: 0,
          priceUsd: 0,
          periodFa: '۳۰ روز رایگان',
          periodEn: '30 days free',
          sortOrder: -1,
          enabled: true,
          features: const [
            PlanFeature(id: 'trial_all', labelFa: 'همه امکانات پرمیوم به مدت ۳۰ روز', labelEn: 'Everything in Premium for 30 days', included: true),
            PlanFeature(id: 'trial_expire', labelFa: 'پس از ۳۰ روز → اتومات هدیه محدود', labelEn: 'After 30 days → free limited', included: true),
          ],
        ),
        SubscriptionPlan(
          id: freeId,
          nameFa: 'هدیه محدود',
          nameEn: 'Free — Limited',
          subtitleFa: 'برای آشنایی — بعد از تریال',
          subtitleEn: 'For starters — after trial',
          ctaFa: 'ادامه با هدیه',
          ctaEn: 'Continue free',
          iconCode: Icons.card_giftcard_rounded.codePoint,
          priceToman: 0,
          priceUsd: 0,
          periodFa: 'رایگان',
          periodEn: 'Free',
          sortOrder: 0,
          features: const [
            PlanFeature(
              id: 'invite',
              labelFa: 'دعوت‌نامه دیجیتال + پورتال مهمان',
              labelEn: 'Digital invite + guest portal',
              included: true,
            ),
            PlanFeature(
              id: 'guests',
              labelFa: 'مهمان‌ها + RSVP',
              labelEn: 'Guests + RSVP',
              included: true,
              valueFa: 'تا ۴۰ نفر',
              valueEn: 'Up to 40',
            ),
            PlanFeature(
              id: 'checklist',
              labelFa: 'چک‌لیست + تقویم',
              labelEn: 'Checklist + calendar',
              included: true,
            ),
            PlanFeature(
              id: 'story',
              labelFa: 'داستان عشق',
              labelEn: 'Love story',
              included: true,
              valueFa: '۱ فصل',
              valueEn: '1 chapter',
            ),
            PlanFeature(
              id: 'wishes',
              labelFa: 'آرزوها / هدایا / حمایت‌ها',
              labelEn: 'Wishes / gifts / supports',
              included: true,
            ),
            PlanFeature(
              id: 'media',
              labelFa: 'کتابخانه رسانه',
              labelEn: 'Media library',
              included: true,
              valueFa: '۱۰ آیتم',
              valueEn: '10 items',
            ),
            PlanFeature(
              id: 'budget',
              labelFa: 'بودجه و تأمین‌کننده‌ها',
              labelEn: 'Budget & vendors',
              included: false,
            ),
            PlanFeature(
              id: 'seating',
              labelFa: 'چیدمان نشیمن',
              labelEn: 'Seating chart',
              included: false,
            ),
            PlanFeature(
              id: 'camera',
              labelFa: 'دوربین یک‌بارمصرف مهمان',
              labelEn: 'Disposable guest camera',
              included: false,
            ),
            PlanFeature(
              id: 'qr',
              labelFa: 'QR دعوت‌نامه',
              labelEn: 'Invite QR',
              included: false,
            ),
          ],
        ),
        SubscriptionPlan(
          id: proId,
          nameFa: 'پرو (۱ ساله)',
          nameEn: 'Pro (1 year)',
          subtitleFa: 'یک پرداخت، یک سال آرامش',
          subtitleEn: 'One payment, a year of calm',
          ctaFa: 'انتخاب پرو',
          ctaEn: 'Choose Pro',
          iconCode: Icons.workspace_premium_rounded.codePoint,
          priceToman: 2327500,
          priceUsd: 0,
          discountPercent: 0,
          periodFa: 'سالانه',
          periodEn: 'per year',
          badgeFa: 'محبوب‌ترین انتخاب',
          badgeEn: 'Most popular',
          popular: true,
          highlighted: true,
          sortOrder: 2,
          features: const [
            PlanFeature(
              id: 'all_pro',
              labelFa: 'تمام امکانات پرو',
              labelEn: 'All Pro features',
              included: true,
            ),
            PlanFeature(
              id: 'year',
              labelFa: '۱۲ ماه به‌جای ۱ ماه',
              labelEn: '12 months instead of 1',
              included: true,
            ),
            PlanFeature(
              id: 'media',
              labelFa: 'رسانه',
              labelEn: 'Media',
              included: true,
              valueFa: '۵۰۰ آیتم',
              valueEn: '500 items',
            ),
            PlanFeature(
              id: 'story_u',
              labelFa: 'داستان عشق نامحدود',
              labelEn: 'Unlimited love story',
              included: true,
            ),
            PlanFeature(
              id: 'support',
              labelFa: 'پشتیبانی اولویت‌دار',
              labelEn: 'Priority support',
              included: true,
            ),
          ],
        ),
        SubscriptionPlan(
          id: premiumId,
          nameFa: 'پرمیوم (مادام‌العمر)',
          nameEn: 'Premium (Lifetime)',
          subtitleFa: 'کامل‌ترین تجربه، برای همیشه',
          subtitleEn: 'The fullest experience, forever',
          ctaFa: 'انتخاب پرمیوم',
          ctaEn: 'Choose Premium',
          iconCode: Icons.diamond_rounded.codePoint,
          priceToman: 5220000,
          priceUsd: 0,
          discountPercent: 0,
          periodFa: 'یک‌بار پرداخت',
          periodEn: 'one-time',
          sortOrder: 3,
          features: const [
            PlanFeature(
              id: 'all_pro',
              labelFa: 'تمام امکانات پرو',
              labelEn: 'Everything in Pro',
              included: true,
            ),
            PlanFeature(
              id: 'lifetime',
              labelFa: 'دسترسی مادام‌العمر + همه به‌روزرسانی‌ها',
              labelEn: 'Lifetime access + all updates',
              included: true,
            ),
            PlanFeature(
              id: 'export',
              labelFa: 'خروجی PDF/اکسل (مهمان‌ها و بودجه)',
              labelEn: 'PDF/Excel export (guests & budget)',
              included: true,
            ),
            PlanFeature(
              id: 'templates',
              labelFa: 'قالب‌های اختصاصی دعوت‌نامه',
              labelEn: 'Exclusive invite templates',
              included: true,
              valueFa: '۴ تم',
              valueEn: '4 themes',
            ),
            PlanFeature(
              id: 'multi',
              labelFa: 'دو مراسم هم‌زمان',
              labelEn: 'Two active weddings',
              included: true,
            ),
            PlanFeature(
              id: 'unl',
              labelFa: 'رسانه و شات دوربین نامحدود',
              labelEn: 'Unlimited media & camera shots',
              included: true,
            ),
            PlanFeature(
              id: 'vip',
              labelFa: 'پشتیبانی VIP + مشاوره اختصاصی',
              labelEn: 'VIP support + private consult',
              included: true,
            ),
          ],
        ),
      ];

  static List<SubscriptionPlan> ordered(List<SubscriptionPlan> input) {
    final map = {for (final p in input) p.id: p};
    final out = <SubscriptionPlan>[];
    for (final id in displayOrder) {
      final p = map[id];
      if (p != null && p.enabled) out.add(p);
    }
    for (final p in input) {
      if (p.id == trialId || p.id == proMonthlyId) continue; // تریال مخفی؛ ماهانه ارائه نمی‌شود
      if (!displayOrder.contains(p.id) && p.enabled) out.add(p);
    }
    return out;
  }
}
