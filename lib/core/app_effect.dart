import 'package:flutter/material.dart';

/// Global visual effects — very light, readable, works with light & dark
/// ids: none + 10 distinct effects (5 existing + 5 new)
/// - blush_rose, sage_garden, champagne_gold, lavender_dusk, ocean_mist
/// - misty_rose, olive_grove, candlelight, midnight_orchid, pearl_sand
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
  static const String blushRose = 'blush_rose';
  static const String sageGarden = 'sage_garden';
  static const String champagneGold = 'champagne_gold';
  static const String lavenderDusk = 'lavender_dusk';
  static const String oceanMist = 'ocean_mist';
  // new 5
  static const String mistyRose = 'misty_rose';
  static const String oliveGrove = 'olive_grove';
  static const String candlelight = 'candlelight';
  static const String midnightOrchid = 'midnight_orchid';
  static const String pearlSand = 'pearl_sand';

  // Legacy compatibility ids mapping (old app_effects.dart used gold/lavender etc)
  static const Map<String, String> legacyMap = {
    'gold': champagneGold,
    'lavender': lavenderDusk,
    'rose': blushRose,
    'champagne': champagneGold,
    'midnight': oceanMist,
    // also allow old new names with dash
    'blush-rose': blushRose,
    'sage-garden': sageGarden,
    'champagne-gold': champagneGold,
    'lavender-dusk': lavenderDusk,
    'ocean-mist': oceanMist,
    'misty-rose': mistyRose,
    'olive-grove': oliveGrove,
    'midnight-orchid': midnightOrchid,
    'pearl-sand': pearlSand,
  };

  static const List<String> ids = [
    none,
    blushRose,
    sageGarden,
    champagneGold,
    lavenderDusk,
    oceanMist,
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
    // existing 5
    AppEffect(
      id: blushRose,
      nameKey: 'fx_blush_rose',
      subtitleKey: 'fx_blush_rose_sub',
      primary: Color(0xFFD9A39A),
      secondary: Color(0xFFF0DDD7),
      icon: Icons.favorite_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF0DDD7),
          Color(0xFFFFFDF9),
          Color(0xFFF5F0E8),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF3A2F35),
          Color(0xFF2A2735),
          Color(0xFF211F2B),
        ],
      ),
    ),
    AppEffect(
      id: sageGarden,
      nameKey: 'fx_sage_garden',
      subtitleKey: 'fx_sage_garden_sub',
      primary: Color(0xFF5F7F62),
      secondary: Color(0xFFD8E5D6),
      icon: Icons.local_florist_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFD8E5D6),
          Color(0xFFEEF3EA),
          Color(0xFFF5F0E8),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2A332A),
          Color(0xFF211F2B),
          Color(0xFF14131C),
        ],
      ),
    ),
    AppEffect(
      id: champagneGold,
      nameKey: 'fx_champagne_gold',
      subtitleKey: 'fx_champagne_gold_sub',
      primary: Color(0xFFD4AF8C),
      secondary: Color(0xFFEFC4A8),
      icon: Icons.auto_awesome_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFEFC4A8),
          Color(0xFFFFFDF9),
          Color(0xFFF7F1E8),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF3A3328),
          Color(0xFF2A2735),
          Color(0xFF211F2B),
        ],
      ),
    ),
    AppEffect(
      id: lavenderDusk,
      nameKey: 'fx_lavender_dusk',
      subtitleKey: 'fx_lavender_dusk_sub',
      primary: Color(0xFFD9A39A),
      secondary: Color(0xFFE8D5E0),
      icon: Icons.blur_on_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE8D5E0),
          Color(0xFFF0DDD7),
          Color(0xFFFFFDF9),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2F2832),
          Color(0xFF211F2B),
          Color(0xFF14131C),
        ],
      ),
    ),
    AppEffect(
      id: oceanMist,
      nameKey: 'fx_ocean_mist',
      subtitleKey: 'fx_ocean_mist_sub',
      primary: Color(0xFF5F7F62),
      secondary: Color(0xFFD4E5E0),
      icon: Icons.water_drop_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFD4E5E0),
          Color(0xFFEEF3EA),
          Color(0xFFF5F0E8),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF24302E),
          Color(0xFF211F2B),
          Color(0xFF14131C),
        ],
      ),
    ),
    // new 5
    AppEffect(
      id: mistyRose,
      nameKey: 'fx_misty_rose',
      subtitleKey: 'fx_misty_rose_sub',
      primary: Color(0xFFC98A83),
      secondary: Color(0xFFF2D6D0),
      icon: Icons.spa_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF2D6D0),
          Color(0xFFF9E8E3),
          Color(0xFFFFFDF9),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF3A2A28),
          Color(0xFF2A2428),
          Color(0xFF1E1C22),
        ],
      ),
    ),
    AppEffect(
      id: oliveGrove,
      nameKey: 'fx_olive_grove',
      subtitleKey: 'fx_olive_grove_sub',
      primary: Color(0xFF6B7A4F),
      secondary: Color(0xFFDDE3D0),
      icon: Icons.park_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFDDE3D0),
          Color(0xFFE8EDDD),
          Color(0xFFF5F0E8),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2D3322),
          Color(0xFF22261E),
          Color(0xFF181C16),
        ],
      ),
    ),
    AppEffect(
      id: candlelight,
      nameKey: 'fx_candlelight',
      subtitleKey: 'fx_candlelight_sub',
      primary: Color(0xFFC9A86A),
      secondary: Color(0xFFF5E6C8),
      icon: Icons.local_fire_department_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF5E6C8),
          Color(0xFFFFF6E0),
          Color(0xFFFFFDF9),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF3A2E1E),
          Color(0xFF2B2518),
          Color(0xFF1E1C14),
        ],
      ),
    ),
    AppEffect(
      id: midnightOrchid,
      nameKey: 'fx_midnight_orchid',
      subtitleKey: 'fx_midnight_orchid_sub',
      primary: Color(0xFF8E7A8E),
      secondary: Color(0xFFE9DDE6),
      icon: Icons.nights_stay_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE9DDE6),
          Color(0xFFF0DDD7),
          Color(0xFFFFFDF9),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2E2630),
          Color(0xFF241E26),
          Color(0xFF1C181E),
        ],
      ),
    ),
    AppEffect(
      id: pearlSand,
      nameKey: 'fx_pearl_sand',
      subtitleKey: 'fx_pearl_sand_sub',
      primary: Color(0xFFD8CFC2),
      secondary: Color(0xFFF2EEE6),
      icon: Icons.beach_access_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF2EEE6),
          Color(0xFFF9F5ED),
          Color(0xFFFFFDF9),
        ],
      ),
      gradientDark: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2F2C28),
          Color(0xFF24211E),
          Color(0xFF1A1816),
        ],
      ),
    ),
  ];

  static AppEffect byId(String? id) {
    final norm = normalizeId(id);
    return all.firstWhere((e) => e.id == norm, orElse: () => all.first);
  }

  LinearGradient gradientForBrightness(Brightness b) {
    return b == Brightness.dark ? gradientDark : gradientLight;
  }
}

/// Alias for legacy code that used AppEffectStyle
class AppEffectCompat {
  AppEffectCompat._();
  static String toLegacy(String newId) {
    switch (newId) {
      case AppEffect.blushRose:
        return 'rose';
      case AppEffect.sageGarden:
        return 'gold';
      case AppEffect.champagneGold:
        return 'champagne';
      case AppEffect.lavenderDusk:
        return 'lavender';
      case AppEffect.oceanMist:
        return 'midnight';
      case AppEffect.mistyRose:
        return 'rose';
      case AppEffect.oliveGrove:
        return 'gold';
      case AppEffect.candlelight:
        return 'champagne';
      case AppEffect.midnightOrchid:
        return 'midnight';
      case AppEffect.pearlSand:
        return 'gold';
      default:
        return 'none';
    }
  }
}
