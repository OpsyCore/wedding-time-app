import 'package:flutter/material.dart';

/// فیلدهای Firestore برای ظاهر هیروی خانه (بنر + قلب)
const heroBannerField = 'heroBannerId';
const heroHeartField = 'heroHeartId';
const heroHeartVisibleField = 'heroHeartVisible';
const heroBannerAnimatedField = 'heroBannerAnimated';

const kDefaultHeroBannerId = 'none';
const kDefaultHeroHeartId = 'purpleBow'; // ۶ قلب جدید — پیش‌فرض بنفش پاپیونی

/// ── بنرهای پشت هیرو — ۵ طرح + حالت «بدون بنر» ──
class HeroBannerOption {
  final String id;
  final String nameFa;
  final String nameEn;
  final List<Color> gradient; // top → bottom
  final Color archTint;
  final IconData icon;

  const HeroBannerOption({
    required this.id,
    required this.nameFa,
    required this.nameEn,
    required this.gradient,
    required this.archTint,
    required this.icon,
  });

  String name(bool isFa) => isFa ? nameFa : nameEn;

  static const List<HeroBannerOption> all = [
    HeroBannerOption(
      id: 'none',
      nameFa: 'بدون بنر',
      nameEn: 'No banner',
      gradient: [Color(0x00000000), Color(0x00000000)],
      archTint: Colors.transparent,
      icon: Icons.block_rounded,
    ),
    HeroBannerOption(
      id: 'skyHeart',
      nameFa: 'قلب آسمانی',
      nameEn: 'Sky Heart',
      gradient: [Color(0xFFB8D8F0), Color(0xFFEAF3FB)],
      archTint: Color(0xFFFFFFFF),
      icon: Icons.favorite_border_rounded,
    ),
    HeroBannerOption(
      id: 'royalBlue',
      nameFa: 'پرده سلطنتی',
      nameEn: 'Royal Curtain',
      gradient: [Color(0xFF14365E), Color(0xFF2E6AA6)],
      archTint: Color(0xFF7EB8E8),
      icon: Icons.waves_rounded,
    ),
    HeroBannerOption(
      id: 'iceGarden',
      nameFa: 'باغ یخی',
      nameEn: 'Ice Garden',
      gradient: [Color(0xFFC8DDF0), Color(0xFFEFF6FD)],
      archTint: Color(0xFF6FA8D8),
      icon: Icons.ac_unit_rounded,
    ),
    HeroBannerOption(
      id: 'crimsonPetal',
      nameFa: 'طاق رز',
      nameEn: 'Rose Arch',
      gradient: [Color(0xFF5E0F2A), Color(0xFFD96B8A)],
      archTint: Color(0xFFFFD1DC),
      icon: Icons.local_florist_rounded,
    ),
    HeroBannerOption(
      id: 'classicIvory',
      nameFa: 'کلاسیک کرم',
      nameEn: 'Classic Ivory',
      gradient: [Color(0xFFF5F1E8), Color(0xFFE8E0D0)],
      archTint: Color(0xFFC2A981),
      icon: Icons.account_balance_rounded,
    ),
  ];

  static HeroBannerOption byId(String id) {
    final v = id.trim();
    for (final o in all) {
      if (o.id == v) return o;
    }
    return all.first; // none
  }
}

/// ── ۶ قلب دقیقاً مثل عکس ارسالی ──
// از چپ به راست عکس: purpleBow | pinkStars | blueWatercolor | goldVelvet | pinkRuffleBow | greenRuffle
class HeroHearts {
  static const List<HeroHeartOption> all = [
    HeroHeartOption(
      id: 'purpleBow',
      nameFa: 'بنفش پاپیونی',
      nameEn: 'Purple Bow',
      base: Color(0xFF7A4DB8),
      accent: Color(0xFFD6C6F5),
      style: HeartStyle.purpleBow,
    ),
    HeroHeartOption(
      id: 'pinkStars',
      nameFa: 'صورتی ستاره‌ای',
      nameEn: 'Pink Stars',
      base: Color(0xFFF0627B),
      accent: Color(0xFFFFE066),
      style: HeartStyle.pinkStars,
    ),
    HeroHeartOption(
      id: 'blueWatercolor',
      nameFa: 'آبی آبرنگی',
      nameEn: 'Blue Watercolor',
      base: Color(0xFF8ECFE0),
      accent: Color(0xFF5AA9C8),
      style: HeartStyle.blueWatercolor,
    ),
    HeroHeartOption(
      id: 'goldVelvet',
      nameFa: 'طلایی مخملی',
      nameEn: 'Gold Velvet',
      base: Color(0xFFE6B800),
      accent: Color(0xFF8C6F00),
      style: HeartStyle.goldVelvet,
    ),
    HeroHeartOption(
      id: 'pinkRuffleBow',
      nameFa: 'صورتی چین‌دار',
      nameEn: 'Pink Ruffle',
      base: Color(0xFFFADADD),
      accent: Color(0xFFE53935),
      style: HeartStyle.pinkRuffleBow,
    ),
    HeroHeartOption(
      id: 'greenRuffle',
      nameFa: 'سبز چین‌دار',
      nameEn: 'Green Ruffle',
      base: Color(0xFF8BC34A),
      accent: Color(0xFF547A26),
      style: HeartStyle.greenRuffle,
    ),
  ];

  static HeroHeartOption byId(String id) {
    final v = id.trim();
    for (final o in all) {
      if (o.id == v) return o;
    }
    // سازگاری با قلب‌های قدیمی — نگاشت به معادل جدید
    switch (v) {
      case 'crimson':
      case 'pinkDotted':
        return all[1]; // pinkStars
      case 'bowLace':
        return all[4]; // pinkRuffleBow
      case 'mochaBow':
        return all[0]; // purpleBow
      case 'watercolor':
        return all[2]; // blueWatercolor
      default:
        return all.first; // purpleBow
    }
  }
}

enum HeartStyle { purpleBow, pinkStars, blueWatercolor, goldVelvet, pinkRuffleBow, greenRuffle }

class HeroHeartOption {
  final String id;
  final String nameFa;
  final String nameEn;
  final Color base;
  final Color accent;
  final HeartStyle style;
  // برای سازگاری قدیمی
  bool get hasBow => style == HeartStyle.purpleBow || style == HeartStyle.pinkRuffleBow;
  bool get hasDots => false;
  bool get lace => style == HeartStyle.pinkRuffleBow || style == HeartStyle.greenRuffle;
  bool get watercolor => style == HeartStyle.blueWatercolor;

  const HeroHeartOption({
    required this.id,
    required this.nameFa,
    required this.nameEn,
    required this.base,
    required this.accent,
    required this.style,
  });

  String name(bool isFa) => isFa ? nameFa : nameEn;
}
