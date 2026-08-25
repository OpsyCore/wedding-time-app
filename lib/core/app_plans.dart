import 'package:flutter/material.dart';

import '../models/subscription_plan.dart';

/// پیش‌فرض پلن‌ها — ادمین از Firestore override می‌کند.
/// ترتیب نمایش کارت‌ها (چپ→راست): free | pro | premium
class AppPlans {
  AppPlans._();

  static const freeId = 'free';
  static const proId = 'pro';
  static const premiumId = 'premium';

  /// ترتیب ثابت چپ / وسط / راست
  static const displayOrder = [freeId, proId, premiumId];

  static List<SubscriptionPlan> get defaults => [
        SubscriptionPlan(
          id: freeId,
          nameFa: 'هدیه ما به شما',
          nameEn: 'Our gift to you',
          subtitleFa: 'شروع ساده برای برنامه‌ریزی مراسم',
          subtitleEn: 'A simple start for wedding planning',
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
              id: 'checklist',
              labelFa: 'چک‌لیست مراسم',
              labelEn: 'Wedding checklist',
              included: true,
            ),
            PlanFeature(
              id: 'guests',
              labelFa: 'مهمان‌ها',
              labelEn: 'Guests',
              included: true,
              valueFa: '۵۰',
              valueEn: '50',
            ),
            PlanFeature(
              id: 'calendar',
              labelFa: 'تقویم',
              labelEn: 'Calendar',
              included: true,
            ),
            PlanFeature(
              id: 'invite',
              labelFa: 'دعوت‌نامه دیجیتال پایه',
              labelEn: 'Basic digital invite',
              included: true,
            ),
            PlanFeature(
              id: 'media',
              labelFa: 'کتابخانه رسانه',
              labelEn: 'Media library',
              included: true,
              valueFa: 'محدود',
              valueEn: 'Limited',
            ),
            PlanFeature(
              id: 'budget',
              labelFa: 'بودجه و هزینه‌ها',
              labelEn: 'Budget & expenses',
              included: false,
            ),
            PlanFeature(
              id: 'vendors',
              labelFa: 'تأمین‌کننده‌ها',
              labelEn: 'Vendors',
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
              labelFa: 'دوربین مهمان',
              labelEn: 'Guest camera',
              included: false,
            ),
            PlanFeature(
              id: 'support',
              labelFa: 'پشتیبانی اولویت‌دار',
              labelEn: 'Priority support',
              included: false,
            ),
          ],
        ),
        SubscriptionPlan(
          id: proId,
          nameFa: 'پرو (۱ ساله)',
          nameEn: 'Pro (1 year)',
          subtitleFa: 'تجربه‌ای کامل و حرفه‌ای',
          subtitleEn: 'Complete professional experience',
          ctaFa: 'انتخاب پرو',
          ctaEn: 'Choose Pro',
          iconCode: Icons.workspace_premium_rounded.codePoint,
          priceToman: 499000,
          priceUsd: 12,
          discountPercent: 0,
          periodFa: 'سالانه',
          periodEn: 'per year',
          badgeFa: 'محبوب‌ترین انتخاب',
          badgeEn: 'Most popular',
          popular: true,
          highlighted: true,
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
              valueFa: '∞',
              valueEn: '∞',
            ),
            PlanFeature(
              id: 'budget',
              labelFa: 'بودجه و هزینه‌ها',
              labelEn: 'Budget & expenses',
              included: true,
            ),
            PlanFeature(
              id: 'vendors',
              labelFa: 'تأمین‌کننده‌ها + اقساط',
              labelEn: 'Vendors & payments',
              included: true,
            ),
            PlanFeature(
              id: 'seating',
              labelFa: 'چیدمان نشیمن',
              labelEn: 'Seating chart',
              included: true,
            ),
            PlanFeature(
              id: 'invite',
              labelFa: 'دعوت‌نامه کامل + QR',
              labelEn: 'Full invite + QR',
              included: true,
            ),
            PlanFeature(
              id: 'media',
              labelFa: 'رسانه + کاورها',
              labelEn: 'Media + covers',
              included: true,
              valueFa: 'کامل',
              valueEn: 'Full',
            ),
            PlanFeature(
              id: 'camera',
              labelFa: 'دوربین مهمان + گالری',
              labelEn: 'Guest camera + gallery',
              included: true,
            ),
            PlanFeature(
              id: 'music',
              labelFa: 'موسیقی و تایم‌لاین',
              labelEn: 'Music & timeline',
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
          subtitleEn: 'Fullest experience, forever',
          ctaFa: 'انتخاب پرمیوم',
          ctaEn: 'Choose Premium',
          iconCode: Icons.diamond_rounded.codePoint,
          priceToman: 1299000,
          priceUsd: 29,
          discountPercent: 0,
          periodFa: 'یک‌بار پرداخت',
          periodEn: 'one-time',
          sortOrder: 2,
          features: const [
            PlanFeature(
              id: 'all_pro',
              labelFa: 'تمام امکانات پرو',
              labelEn: 'Everything in Pro',
              included: true,
            ),
            PlanFeature(
              id: 'lifetime',
              labelFa: 'دسترسی مادام‌العمر',
              labelEn: 'Lifetime access',
              included: true,
            ),
            PlanFeature(
              id: 'vip',
              labelFa: 'پشتیبانی VIP',
              labelEn: 'VIP support',
              included: true,
            ),
            PlanFeature(
              id: 'consult',
              labelFa: 'مشاوره اختصاصی',
              labelEn: 'Private consult',
              included: true,
            ),
            PlanFeature(
              id: 'early',
              labelFa: 'دسترسی زودهنگام',
              labelEn: 'Early access',
              included: true,
            ),
            PlanFeature(
              id: 'report',
              labelFa: 'گزارش و شخصی‌سازی',
              labelEn: 'Custom reports',
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