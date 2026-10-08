import 'package:flutter/material.dart';

/// فیلدهای Firestore برای ظاهر هیروی خانه (بنر + قلب)
const heroBannerField = 'heroBannerId';
const heroHeartField = 'heroHeartId';
const heroHeartVisibleField = 'heroHeartVisible';
const heroBannerAnimatedField = 'heroBannerAnimated';

const kDefaultHeroBannerId = 'none';
const kDefaultHeroHeartId = 'pearlSatin'; // پیش‌فرض جدید — صدفی لوکس

/// ── بنرهای پشت هیرو — ۸ طرح حرفه‌ای (هر استایل ۲ بنر) + بدون بنر ──
//  Luxury: silkIvory + midnightGold | Soft Modern: blushBloom + sageWhisper
//  Boho: terracottaDune + oliveLinen | Persian Classic: persianCrimson + turquoiseCourt
class HeroBannerOption {
  final String id;
  final String nameFa;
  final String nameEn;
  final List<Color> gradient; // top → bottom (2-3 stops)
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
    // ── Luxury Editorial (2) ──
    HeroBannerOption(
      id: 'silkIvory',
      nameFa: 'ابریشم عاجی',
      nameEn: 'Silk Ivory',
      gradient: [Color(0xFFFDFCF8), Color(0xFFF5F1E8), Color(0xFFEDE6D5)],
      archTint: Color(0xFFC9A86A),
      icon: Icons.auto_awesome_rounded, // gold sparkle
    ),
    HeroBannerOption(
      id: 'midnightGold',
      nameFa: 'شب طلاکوب',
      nameEn: 'Midnight Gold',
      gradient: [Color(0xFF0B1E35), Color(0xFF1A365D), Color(0xFF2A4B7A)],
      archTint: Color(0xFFD4AF37),
      icon: Icons.diamond_outlined, // art-deco
    ),
    // ── Soft Modern (2) ──
    HeroBannerOption(
      id: 'blushBloom',
      nameFa: 'شکوفه صورتی',
      nameEn: 'Blush Bloom',
      gradient: [Color(0xFFFDF2F4), Color(0xFFF8D8E0), Color(0xFFE8B4C2)],
      archTint: Color(0xFFE8B4C2),
      icon: Icons.local_florist_outlined,
    ),
    HeroBannerOption(
      id: 'sageWhisper',
      nameFa: 'نجوای مریم‌گلی',
      nameEn: 'Sage Whisper',
      gradient: [Color(0xFFF2F4F1), Color(0xFFE2EBE4), Color(0xFFC7D8CB)],
      archTint: Color(0xFF9CAF88),
      icon: Icons.spa_outlined, // eucalyptus
    ),
    // ── Boho Garden (2) ──
    HeroBannerOption(
      id: 'terracottaDune',
      nameFa: 'تپه سفالی',
      nameEn: 'Terracotta Dune',
      gradient: [Color(0xFFF9E8D9), Color(0xFFE8C4A8), Color(0xFFD9A07A)],
      archTint: Color(0xFFA07A52),
      icon: Icons.grass_rounded, // pampas
    ),
    HeroBannerOption(
      id: 'oliveLinen',
      nameFa: 'کتان زیتونی',
      nameEn: 'Olive Linen',
      gradient: [Color(0xFFF5F3E8), Color(0xFFE8E2C8), Color(0xFFD0C5A0)],
      archTint: Color(0xFF8B8A5A),
      icon: Icons.eco_outlined,
    ),
    // ── Persian Classic (2) ──
    HeroBannerOption(
      id: 'persianCrimson',
      nameFa: 'زرشکی درباری',
      nameEn: 'Persian Crimson',
      gradient: [Color(0xFF3D0E18), Color(0xFF7A1A2E), Color(0xFFBA4558)],
      archTint: Color(0xFFE8C39E),
      icon: Icons.stars_rounded, // eslimi hint
    ),
    HeroBannerOption(
      id: 'turquoiseCourt',
      nameFa: 'فیروزه درباری',
      nameEn: 'Turquoise Court',
      gradient: [Color(0xFF0F3A45), Color(0xFF1A6B7A), Color(0xFF3EB0B8)],
      archTint: Color(0xFFF0D9B5),
      icon: Icons.account_balance_outlined,
    ),
  ];

  static HeroBannerOption byId(String id) {
    final v = id.trim();
    for (final o in all) {
      if (o.id == v) return o;
    }
    // نگاشت بنرهای قدیمی → معادل لوکس جدید
    switch (v) {
      case 'classicIvory':
        return all.firstWhere((o) => o.id == 'silkIvory');
      case 'crimsonPetal':
        return all.firstWhere((o) => o.id == 'persianCrimson');
      case 'iceGarden':
        return all.firstWhere((o) => o.id == 'sageWhisper');
      case 'royalBlue':
        return all.firstWhere((o) => o.id == 'midnightGold');
      case 'skyHeart':
        return all.firstWhere((o) => o.id == 'blushBloom');
      default:
        return all.first; // none
    }
  }
}

/// ── ۸ قلب حرفه‌ای — هر استایل ۲ قلب ──
enum HeartStyle {
  pearlSatin,       // Luxury: صدفی ساتن با پاپیون مرواریدی
  noirVelvet,       // Luxury: مخمل شب با دوخت طلایی
  blushSuede,       // Soft Modern: صورتی مات مخملی
  skyWatercolor,    // Soft Modern: آبی آبرنگی با ستاره نرم
  terracottaRuffle, // Boho: سفالی چین‌دار
  sageLinen,        // Boho: زیتونی کتان با دوخت
  persianTurquoise, // Persian: فیروزه با اسلیمی طلایی
  crimsonGold,      // Persian: زرشکی با حاشیه طلاکوب
}

class HeroHeartOption {
  final String id;
  final String nameFa;
  final String nameEn;
  final Color base;
  final Color accent;
  final HeartStyle style;
  bool get hasBow => style == HeartStyle.pearlSatin || style == HeartStyle.crimsonGold;
  bool get hasDots => false;
  bool get lace => style == HeartStyle.terracottaRuffle || style == HeartStyle.sageLinen;
  bool get watercolor => style == HeartStyle.skyWatercolor;

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

class HeroHearts {
  static const List<HeroHeartOption> all = [
    // Luxury (2)
    HeroHeartOption(
      id: 'pearlSatin',
      nameFa: 'صدفی ساتن',
      nameEn: 'Pearl Satin',
      base: Color(0xFFFDF8F0),
      accent: Color(0xFFD4AF37),
      style: HeartStyle.pearlSatin,
    ),
    HeroHeartOption(
      id: 'noirVelvet',
      nameFa: 'مخمل شب',
      nameEn: 'Noir Velvet',
      base: Color(0xFF1A1C1E),
      accent: Color(0xFFC9A86A),
      style: HeartStyle.noirVelvet,
    ),
    // Soft Modern (2)
    HeroHeartOption(
      id: 'blushSuede',
      nameFa: 'صورتی مخملی',
      nameEn: 'Blush Suede',
      base: Color(0xFFD8A8B8),
      accent: Color(0xFFF0D6DE),
      style: HeartStyle.blushSuede,
    ),
    HeroHeartOption(
      id: 'skyWatercolor',
      nameFa: 'آبی آبرنگی',
      nameEn: 'Sky Watercolor',
      base: Color(0xFFB8D8E8),
      accent: Color(0xFF7AB3D1),
      style: HeartStyle.skyWatercolor,
    ),
    // Boho (2)
    HeroHeartOption(
      id: 'terracottaRuffle',
      nameFa: 'سفالی چین‌دار',
      nameEn: 'Terracotta Ruffle',
      base: Color(0xFFD9A07A),
      accent: Color(0xFFB87A52),
      style: HeartStyle.terracottaRuffle,
    ),
    HeroHeartOption(
      id: 'sageLinen',
      nameFa: 'کتان زیتونی',
      nameEn: 'Sage Linen',
      base: Color(0xFFA8BEA3),
      accent: Color(0xFF7A9A76),
      style: HeartStyle.sageLinen,
    ),
    // Persian (2)
    HeroHeartOption(
      id: 'persianTurquoise',
      nameFa: 'فیروزه اسلیمی',
      nameEn: 'Persian Turquoise',
      base: Color(0xFF2A9B9B),
      accent: Color(0xFFD4AF37),
      style: HeartStyle.persianTurquoise,
    ),
    HeroHeartOption(
      id: 'crimsonGold',
      nameFa: 'زرشکی طلاکوب',
      nameEn: 'Crimson Gold',
      base: Color(0xFF7A1A2E),
      accent: Color(0xFFE8C39E),
      style: HeartStyle.crimsonGold,
    ),
  ];

  static HeroHeartOption byId(String id) {
    final v = id.trim();
    for (final o in all) {
      if (o.id == v) return o;
    }
    // نگاشت قلب‌های قدیمی → معادل حرفه‌ای جدید
    switch (v) {
      case 'purpleBow':
        return all.firstWhere((o) => o.id == 'crimsonGold');
      case 'pinkStars':
        return all.firstWhere((o) => o.id == 'blushSuede');
      case 'blueWatercolor':
        return all.firstWhere((o) => o.id == 'skyWatercolor');
      case 'goldVelvet':
        return all.firstWhere((o) => o.id == 'pearlSatin');
      case 'pinkRuffleBow':
        return all.firstWhere((o) => o.id == 'terracottaRuffle');
      case 'greenRuffle':
        return all.firstWhere((o) => o.id == 'sageLinen');
      case 'crimson':
      case 'pinkDotted':
        return all.firstWhere((o) => o.id == 'blushSuede');
      case 'bowLace':
        return all.firstWhere((o) => o.id == 'terracottaRuffle');
      case 'mochaBow':
        return all.firstWhere((o) => o.id == 'crimsonGold');
      case 'watercolor':
        return all.firstWhere((o) => o.id == 'skyWatercolor');
      default:
        return all.firstWhere((o) => o.id == 'pearlSatin');
    }
  }
}
