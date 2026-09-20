import 'package:flutter/material.dart';

/// فیلدهای Firestore برای ظاهر هیروی خانه (بنر + قلب)
const heroBannerField = 'heroBannerId';
const heroHeartField = 'heroHeartId';
const heroHeartVisibleField = 'heroHeartVisible';
const heroBannerAnimatedField = 'heroBannerAnimated';

const kDefaultHeroBannerId = 'none';
const kDefaultHeroHeartId = 'crimson'; // قرمز آجری فعلی

/// ── بنرهای پشت هیرو — ۵ طرح + حالت «بدون بنر» ──
class HeroBannerOption {
  final String id;
  final String nameFa;
  final String nameEn;
  final List<Color> gradient; // top → bottom
  final Color archTint; // رنگ قوس / هایلایت
  final IconData icon; // آیکن کوچک برای پریویو

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

class HeroHearts {
  static const List<HeroHeartOption> all = [
    HeroHeartOption(
      id: 'pinkDotted',
      nameFa: 'صورتی خال‌دار',
      nameEn: 'Pink Dotted',
      base: Color(0xFFE8A0B2),
      accent: Color(0xFF8E3A4A),
      hasBow: false,
      hasDots: true,
    ),
    HeroHeartOption(
      id: 'bowLace',
      nameFa: 'پاپیون توری',
      nameEn: 'Bow Lace',
      base: Color(0xFFF6D6DC),
      accent: Color(0xFF5A2A35),
      hasBow: true,
      hasDots: false,
      lace: true,
    ),
    HeroHeartOption(
      id: 'mochaBow',
      nameFa: 'موکا پاپیونی',
      nameEn: 'Mocha Bow',
      base: Color(0xFF9E8E8A),
      accent: Color(0xFF3E2E2B),
      hasBow: true,
      hasDots: false,
    ),
    HeroHeartOption(
      id: 'watercolor',
      nameFa: 'آبرنگی',
      nameEn: 'Watercolor',
      base: Color(0xFFFFEFF3),
      accent: Color(0xFFE8A0B2),
      hasBow: false,
      hasDots: false,
      watercolor: true,
    ),
    HeroHeartOption(
      id: 'crimson',
      nameFa: 'آجری کلاسیک',
      nameEn: 'Crimson Classic',
      base: Color(0xFFD75445),
      accent: Color(0xFF4A2520),
      hasBow: false,
      hasDots: false,
    ),
  ];

  static HeroHeartOption byId(String id) {
    final v = id.trim();
    for (final o in all) {
      if (o.id == v) return o;
    }
    // default crimson
    return all.last;
  }
}

class HeroHeartOption {
  final String id;
  final String nameFa;
  final String nameEn;
  final Color base;
  final Color accent; // for sparkle/bow
  final bool hasBow;
  final bool hasDots;
  final bool lace;
  final bool watercolor;

  const HeroHeartOption({
    required this.id,
    required this.nameFa,
    required this.nameEn,
    required this.base,
    required this.accent,
    this.hasBow = false,
    this.hasDots = false,
    this.lace = false,
    this.watercolor = false,
  });

  String name(bool isFa) => isFa ? nameFa : nameEn;
}
