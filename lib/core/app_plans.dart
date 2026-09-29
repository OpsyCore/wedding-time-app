import 'package:flutter/material.dart';

import '../models/subscription_plan.dart';

/// پیش‌فرض پلن‌ها — ادمین از Firestore override می‌کند.
/// ترتیب نمایش کارت‌ها: free | pro_monthly | pro | premium
class AppPlans {
  AppPlans._();

  static const freeId = 'free';
  static const proMonthlyId = 'pro_monthly';
  static const proId = 'pro';
  static const premiumId = 'premium';

  /// ترتیب ثابت نمایش
  static const displayOrder = [freeId, proMonthlyId, proId, premiumId];

  static List<SubscriptionPlan> get defaults => [
        SubscriptionPlan(
          id: freeId,
          nameFa: 'هدیه ما به شما',
          nameEn: 'Our gift to you',
          subtitleFa: 'شروع واقعی برنامه‌ریزی — بدون کارت بانکی',
          subtitleEn: 'A real start — no card required',
          ctaFa: 'انتخاب هدیه ما',
          ctaEn: 'Choose free gift',
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
              valueFa: 'تا ۱۰۰ نفر',
              valueEn: 'Up to 100',
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
              valueFa: '۲ فصل',
              valueEn: '2 chapters',
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
              valueFa: '۲۰ آیتم',
              valueEn: '20 items',
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
          id: proMonthlyId,
          nameFa: 'پرو ماهانه',
          nameEn: 'Pro Monthly',
          subtitleFa: 'همه‌چیز برای اجرای مراسم — ماه به ماه',
          subtitleEn: 'Everything to run your wedding, monthly',
          ctaFa: 'شروع پرو ماهانه',
          ctaEn: 'Start Pro monthly',
          iconCode: Icons.auto_awesome_rounded.codePoint,
          priceToman: 89000,
          priceUsd: 2,
          periodFa: 'ماهانه',
          periodEn: 'per month',
          sortOrder: 1,
          features: const [
            PlanFeature(
              id: 'all_free',
              labelFa: 'تمام امکانات هدیه',
              labelEn: 'Everything in gift',
              included: true,
            ),
            PlanFeature(
              id: 'guests',
              labelFa: 'مهمان‌ها',
              labelEn: 'Guests',
              included: true,
              valueFa: 'نامحدود',
              valueEn: 'Unlimited',
            ),
            PlanFeature(
              id: 'budget',
              labelFa: 'بودجه + تأمین‌کننده‌ها + اقساط',
              labelEn: 'Budget + vendors + payments',
              included: true,
            ),
            PlanFeature(
              id: 'seating',
              labelFa: 'چیدمان نشیمن چندسالنه',
              labelEn: 'Multi-hall seating',
              included: true,
            ),
            PlanFeature(
              id: 'camera',
              labelFa: 'دوربین مهمان + گالری تأیید',
              labelEn: 'Guest camera + approvals',
              included: true,
              valueFa: '۱۰ شات/مهمان',
              valueEn: '10 shots/guest',
            ),
            PlanFeature(
              id: 'qr',
              labelFa: 'دعوت‌نامه کامل + QR',
              labelEn: 'Full invite + QR',
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
          id: proId,
          nameFa: 'پرو (۱ ساله)',
          nameEn: 'Pro (1 year)',
          subtitleFa: 'یک پرداخت، یک سال آرامش',
          subtitleEn: 'One payment, a year of calm',
          ctaFa: 'انتخاب پرو',
          ctaEn: 'Choose Pro',
          iconCode: Icons.workspace_premium_rounded.codePoint,
          priceToman: 499000,
          priceUsd: 12,
          discountPercent: 53,
          periodFa: 'سالانه',
          periodEn: 'per year',
          badgeFa: 'محبوب‌ترین انتخاب',
          badgeEn: 'Most popular',
          popular: true,
          highlighted: true,
          sortOrder: 2,
          features: const [
            PlanFeature(
              id: 'all_monthly',
              labelFa: 'تمام امکانات پرو ماهانه',
              labelEn: 'Everything in Pro monthly',
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
          priceToman: 1299000,
          priceUsd: 29,
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
      if (!displayOrder.contains(p.id) && p.enabled) out.add(p);
    }
    return out;
  }
}
