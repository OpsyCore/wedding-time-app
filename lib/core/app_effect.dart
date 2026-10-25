import 'package:flutter/material.dart';

/// Global visual effects — 10 distinct identities + none
/// Each effect has its own real color palette, icon, and particle/pattern style:
/// 1. gold (ذرات رزگلد): #DCA3A3 / #E8B4B8 — fine rose-gold dust
/// 2. lavender (قلب لوندر شیشه‌ای): #C9B6E4 / #E8DDF5 — blurred glassy hearts
/// 3. rose (باران رز): #F8B8C0 / #FFD6DE — falling pink hearts
/// 4. champagne (شامپاینی و درخشش): #D4AF37 / #F7E7CE — golden sparkles
/// 5. midnight (شب آبی ستاره‌ای): #4A7C9B / #1A2A4A — navy sky & white stars
/// 6. misty_rose (رز مه‌آلود): #E8C4C4 / #F5E0E0 — dusty rose mist & soft petals
/// 7. olive_grove (بیشه زیتون): #6B8E5A / #8FA68E — olive leaves
/// 8. candlelight (نور شمع): #FF9A3C / #FFC857 — warm flickering candle flame
/// 9. midnight_orchid (ارکیده نیمه‌شب): #8E7CC3 / #2D1B4E — deep violet orchid
/// 10. pearl_sand (شب مرواریدی): #D4CFC4 / #F5F5F0 — pearlescent shimmer
class AppEffect {
  const AppEffect({
    required this.id,
    required this.nameKey,
    required this.subtitleKey,
    required this.primary,
    required this.secondary,
    required this.icon,
    required this.gradientLight,
    required this.gradientDark,
  });

  final String id;
  final String nameKey;
  final String subtitleKey;
  final Color primary;
  final Color secondary;
  final IconData icon;
  final LinearGradient gradientLight;
  final LinearGradient gradientDark;

  static const String none = 'none';
  static const String gold = 'gold';
  static const String lavender = 'lavender';
  static const String rose = 'rose';
  static const String champagne = 'champagne';
  static const String midnight = 'midnight';
  static const String mistyRose = 'misty_rose';
  static const String oliveGrove = 'olive_grove';
  static const String candlelight = 'candlelight';
  static const String midnightOrchid = 'midnight_orchid';
  static const String pearlSand = 'pearl_sand';

  // Aliases kept for compatibility with callers referencing old constant names
  static const String blushRose = rose;
  static const String sageGarden = gold;
  static const String champagneGold = champagne;
  static const String lavenderDusk = lavender;
  static const String oceanMist = midnight;

  static const Map<String, String> legacyMap = {
    'gold': gold,
    'rose_gold': gold,
    'sage_garden': gold,
    'sage-garden': gold,
    'lavender': lavender,
    'lavender_dusk': lavender,
    'lavender-dusk': lavender,
    'rose': rose,
    'blush_rose': rose,
    'blush-rose': rose,
    'champagne': champagne,
    'champagne_gold': champagne,
    'champagne-gold': champagne,
    'midnight': midnight,
    'ocean_mist': midnight,
    'ocean-mist': midnight,
    'misty_rose': mistyRose,
    'misty-rose': mistyRose,
    'olive_grove': oliveGrove,
    'olive-grove': oliveGrove,
    'candlelight': candlelight,
    'midnight_orchid': midnightOrchid,
    'midnight-orchid': midnightOrchid,
    'pearl_sand': pearlSand,
    'pearl-sand': pearlSand,
  };

  static const List<String> ids = [
    none,
    gold,
    lavender,
    rose,
    champagne,
    midnight,
    mistyRose,
    oliveGrove,
    candlelight,
    midnightOrchid,
    pearlSand,
  ];

  static String normalizeId(String? raw) {
    var v = (raw ?? none).trim().toLowerCase();
    if (v.isEmpty) return none;
    if (legacyMap.containsKey(v)) return legacyMap[v]!;
    if (ids.contains(v)) return v;
    v = v.replaceAll('-', '_');
    if (legacyMap.containsKey(v)) return legacyMap[v]!;
    if (ids.contains(v)) return v;
    return none;
  }

  bool get isNone => id == none;

  static const List<AppEffect> all = [
    AppEffect(
      id: none,
      nameKey: 'fx_none',
      subtitleKey: 'fx_none_sub',
      primary: Color(0xFF7A736C),
      secondary: Color(0xFFEEF3EA),
      icon: Icons.block_flipped,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x00FFFFFF), Color(0x00FFFFFF)],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x00FFFFFF), Color(0x00FFFFFF)],
      ),
    ),
    // ۱. ذرات رزگلد — رزگلد واقعی #DCA3A3 / #E8B4B8 + ذره ریز پخش
    AppEffect(
      id: gold,
      nameKey: 'fx_gold',
      subtitleKey: 'fx_gold_sub',
      primary: Color(0xFFDCA3A3),
      secondary: Color(0xFFE8B4B8),
      icon: Icons.grain_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF7E4E6),
          Color(0xFFE8B4B8),
          Color(0xFFFFF9F9),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF3B2628),
          Color(0xFF2B1D20),
          Color(0xFF1A1416),
        ],
      ),
    ),
    // ۲. قلب لوندر شیشه‌ای — بنفش شیشه‌ای #C9B6E4 / #E8DDF5 + قلب blur
    AppEffect(
      id: lavender,
      nameKey: 'fx_lavender',
      subtitleKey: 'fx_lavender_sub',
      primary: Color(0xFFC9B6E4),
      secondary: Color(0xFFE8DDF5),
      icon: Icons.blur_on_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE8DDF5),
          Color(0xFFF3EEFA),
          Color(0xFFFFFDFF),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2D243B),
          Color(0xFF211C2C),
          Color(0xFF16131E),
        ],
      ),
    ),
    // ۳. باران رز — صورتی باران #F8B8C0 / #FFD6DE + قلب ریزان
    AppEffect(
      id: rose,
      nameKey: 'fx_rose',
      subtitleKey: 'fx_rose_sub',
      primary: Color(0xFFF8B8C0),
      secondary: Color(0xFFFFD6DE),
      icon: Icons.favorite_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFD6DE),
          Color(0xFFFFECF0),
          Color(0xFFFFFBFC),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF3D2229),
          Color(0xFF2A181D),
          Color(0xFF1B1215),
        ],
      ),
    ),
    // ۴. شامپاینی و درخشش — طلایی شامپاین #D4AF37 / #F7E7CE + جرقه‌ها
    AppEffect(
      id: champagne,
      nameKey: 'fx_champagne',
      subtitleKey: 'fx_champagne_sub',
      primary: Color(0xFFD4AF37),
      secondary: Color(0xFFF7E7CE),
      icon: Icons.auto_awesome_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF7E7CE),
          Color(0xFFFFF6E5),
          Color(0xFFFFFEFA),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF3A3014),
          Color(0xFF282210),
          Color(0xFF19160D),
        ],
      ),
    ),
    // ۵. شب آبی ستاره‌ای — سرمه‌ای #1A2A4A / #4A7C9B + ستاره سفید
    AppEffect(
      id: midnight,
      nameKey: 'fx_midnight',
      subtitleKey: 'fx_midnight_sub',
      primary: Color(0xFF4A7C9B),
      secondary: Color(0xFF1A2A4A),
      icon: Icons.nights_stay_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFD6E6F2),
          Color(0xFFEBF3F9),
          Color(0xFFF8FBFF),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1A2A4A),
          Color(0xFF132038),
          Color(0xFF0D1626),
        ],
      ),
    ),
    // ۶. رز مه‌آلود — صورتی غبار #E8C4C4 / #F5E0E0 مه‌آلود
    AppEffect(
      id: mistyRose,
      nameKey: 'fx_misty_rose',
      subtitleKey: 'fx_misty_rose_sub',
      primary: Color(0xFFE8C4C4),
      secondary: Color(0xFFF5E0E0),
      icon: Icons.cloud_queue_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF5E0E0),
          Color(0xFFFAF0F0),
          Color(0xFFFFFCFC),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF362828),
          Color(0xFF261E1E),
          Color(0xFF1A1515),
        ],
      ),
    ),
    // ۷. بیشه زیتون — سبز زیتونی #6B8E5A / #8FA68E + برگ
    AppEffect(
      id: oliveGrove,
      nameKey: 'fx_olive_grove',
      subtitleKey: 'fx_olive_grove_sub',
      primary: Color(0xFF6B8E5A),
      secondary: Color(0xFF8FA68E),
      icon: Icons.eco_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFDCE8D6),
          Color(0xFFEEF4EB),
          Color(0xFFFAFDF9),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF22301E),
          Color(0xFF192316),
          Color(0xFF121810),
        ],
      ),
    ),
    // ۸. نور شمع — نارنجی گرم #FF9A3C / #FFC857 + فلیکر شعله
    AppEffect(
      id: candlelight,
      nameKey: 'fx_candlelight',
      subtitleKey: 'fx_candlelight_sub',
      primary: Color(0xFFFF9A3C),
      secondary: Color(0xFFFFC857),
      icon: Icons.local_fire_department_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFECD2),
          Color(0xFFFFF5E4),
          Color(0xFFFFFDFA),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF3D2410),
          Color(0xFF2B1A0C),
          Color(0xFF1C1208),
        ],
      ),
    ),
    // ۹. ارکیده نیمه‌شب — بنفش تیره #2D1B4E / #8E7CC3
    AppEffect(
      id: midnightOrchid,
      nameKey: 'fx_midnight_orchid',
      subtitleKey: 'fx_midnight_orchid_sub',
      primary: Color(0xFF8E7CC3),
      secondary: Color(0xFF2D1B4E),
      icon: Icons.local_florist_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE4DDF2),
          Color(0xFFF1EDF9),
          Color(0xFFFCFAFF),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2D1B4E),
          Color(0xFF21143A),
          Color(0xFF150D26),
        ],
      ),
    ),
    // ۱۰. شب مرواریدی — سفید مرواریدی #F5F5F0 / #D4CFC4
    AppEffect(
      id: pearlSand,
      nameKey: 'fx_pearl_sand',
      subtitleKey: 'fx_pearl_sand_sub',
      primary: Color(0xFFD4CFC4),
      secondary: Color(0xFFF5F5F0),
      icon: Icons.lens_blur_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF5F5F0),
          Color(0xFFFAF9F6),
          Color(0xFFFFFFFF),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2E2C28),
          Color(0xFF22201D),
          Color(0xFF171614),
        ],
      ),
    ),
  ];

  static AppEffect byId(String? id) {
    final norm = normalizeId(id);
    return all.firstWhere((e) => e.id == norm, orElse: () => all.first);
  }

  /// Maps a global effect id onto the particle overlay styles in `app_effects.dart`.
  static String particleStyleId(String? id) {
    final norm = normalizeId(id);
    if (norm == none) return none;
    return norm;
  }

  LinearGradient gradientForBrightness(Brightness b) {
    return b == Brightness.dark ? gradientDark : gradientLight;
  }
}

/// Alias for legacy code that used AppEffectStyle
class AppEffectCompat {
  AppEffectCompat._();
  static String toLegacy(String newId) => AppEffect.normalizeId(newId);
}
