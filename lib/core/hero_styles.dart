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
    // ── Luxury Editorial (2) — دقیقا React BANNERS ──
    HeroBannerOption(
      id: 'silkIvory',
      nameFa: 'ابریشم عاجی',
      nameEn: 'Silk Ivory',
      gradient: [Color(0xFFF5EADC), Color(0xFFC9A674)], // ['#f5eadc','#c9a674']
      archTint: Color(0xFFB68A45), // ink '#b68a45' glow '#fff6e8'
      icon: Icons.auto_awesome_rounded,
    ),
    HeroBannerOption(
      id: 'midnightGold',
      nameFa: 'شب طلاکوب',
      nameEn: 'Midnight Gold',
      gradient: [Color(0xFF0B1020), Color(0xFF1A2B53)], // ['#0b1020','#1a2b53']
      archTint: Color(0xFFE2BD63), // ink '#e2bd63' glow '#4f5e83'
      icon: Icons.diamond_outlined,
    ),
    // ── Soft Modern (2) ──
    HeroBannerOption(
      id: 'blushBloom',
      nameFa: 'شکوفه صورتی',
      nameEn: 'Blush Bloom',
      gradient: [Color(0xFFF8DFE8), Color(0xFFE8B9CD)], // ['#f8dfe8','#e8b9cd']
      archTint: Color(0xFFB97A92), // ink '#b97a92' glow '#fdeff5'
      icon: Icons.local_florist_outlined,
    ),
    HeroBannerOption(
      id: 'sageWhisper',
      nameFa: 'نجوای مریم‌گلی',
      nameEn: 'Sage Whisper',
      gradient: [Color(0xFFE1ECE4), Color(0xFFB8CDBD)], // ['#e1ece4','#b8cdbd']
      archTint: Color(0xFF738B76), // ink '#738b76' glow '#f2fbf2'
      icon: Icons.spa_outlined,
    ),
    // ── Boho Garden (2) ──
    HeroBannerOption(
      id: 'terracottaDune',
      nameFa: 'تپه سفالی',
      nameEn: 'Terracotta Dune',
      gradient: [Color(0xFFC9805C), Color(0xFF985340)], // ['#c9805c','#985340']
      archTint: Color(0xFFF1DDBE), // ink '#f1ddbe' glow '#f9d7bf'
      icon: Icons.grass_rounded,
    ),
    HeroBannerOption(
      id: 'oliveLinen',
      nameFa: 'کتان زیتونی',
      nameEn: 'Olive Linen',
      gradient: [Color(0xFF8A8F67), Color(0xFF5B6647)], // ['#8a8f67','#5b6647']
      archTint: Color(0xFFF2E4C9), // ink '#f2e4c9' glow '#dce0bc'
      icon: Icons.eco_outlined,
    ),
    // ── Persian Classic (2) ──
    HeroBannerOption(
      id: 'persianCrimson',
      nameFa: 'زرشکی درباری',
      nameEn: 'Persian Crimson',
      gradient: [Color(0xFF701227), Color(0xFF3F0714)], // ['#701227','#3f0714']
      archTint: Color(0xFFD8AB4F), // ink '#d8ab4f' glow '#8f3450'
      icon: Icons.stars_rounded,
    ),
    HeroBannerOption(
      id: 'turquoiseCourt',
      nameFa: 'فیروزه درباری',
      nameEn: 'Turquoise Court',
      gradient: [Color(0xFF1FA9BB), Color(0xFF0D6882)], // ['#1fa9bb','#0d6882']
      archTint: Color(0xFFF5E8CD), // ink '#f5e8cd' glow '#84e2e8'
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
    // Luxury (2) — React HEARTS
    HeroHeartOption(
      id: 'pearlSatin',
      nameFa: 'صدفی ساتن',
      nameEn: 'Pearl Satin',
      base: Color(0xFFE6D8CA), // '#e6d8ca'
      accent: Color(0xFFD7AB50), // '#d7ab50'
      style: HeartStyle.pearlSatin,
    ),
    HeroHeartOption(
      id: 'noirVelvet',
      nameFa: 'مخمل شب',
      nameEn: 'Noir Velvet',
      base: Color(0xFF191D2A), // '#191d2a'
      accent: Color(0xFFE0BC65), // '#e0bc65'
      style: HeartStyle.noirVelvet,
    ),
    // Soft Modern (2)
    HeroHeartOption(
      id: 'blushSuede',
      nameFa: 'صورتی مخملی',
      nameEn: 'Blush Suede',
      base: Color(0xFFE8B6C5), // '#e8b6c5'
      accent: Color(0xFFBE7E97), // '#be7e97'
      style: HeartStyle.blushSuede,
    ),
    HeroHeartOption(
      id: 'skyWatercolor',
      nameFa: 'آبی آبرنگی',
      nameEn: 'Sky Watercolor',
      base: Color(0xFF89B4D8), // '#89b4d8'
      accent: Color(0xFFDCEEF8), // approximated '#dceefb'
      style: HeartStyle.skyWatercolor,
    ),
    // Boho (2)
    HeroHeartOption(
      id: 'terracottaRuffle',
      nameFa: 'سفالی چین‌دار',
      nameEn: 'Terracotta Ruffle',
      base: Color(0xFFC86F4F), // '#c86f4f'
      accent: Color(0xFFF3DFBF), // '#f3dfbf'
      style: HeartStyle.terracottaRuffle,
    ),
    HeroHeartOption(
      id: 'sageLinen',
      nameFa: 'کتان زیتونی',
      nameEn: 'Sage Linen',
      base: Color(0xFF75896A), // '#75896a'
      accent: Color(0xFFE7DBBE), // '#e7dbbe'
      style: HeartStyle.sageLinen,
    ),
    // Persian (2)
    HeroHeartOption(
      id: 'persianTurquoise',
      nameFa: 'فیروزه اسلیمی',
      nameEn: 'Persian Turquoise',
      base: Color(0xFF199BAD), // '#199bad'
      accent: Color(0xFFE4C069), // '#e4c069'
      style: HeartStyle.persianTurquoise,
    ),
    HeroHeartOption(
      id: 'crimsonGold',
      nameFa: 'زرشکی طلاکوب',
      nameEn: 'Crimson Gold',
      base: Color(0xFF6F162A), // '#6f162a'
      accent: Color(0xFFE1B35E), // '#e1b35e'
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
