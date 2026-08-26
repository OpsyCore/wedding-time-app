import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Global visual effects — very light, readable, works with light & dark
/// ids: none, blush_rose, sage_garden, champagne_gold, lavender_dusk, ocean_mist
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

  // Legacy compatibility ids mapping (old app_effects.dart used gold/lavender etc)
  static const Map<String, String> legacyMap = {
    'gold': champagneGold,
    'lavender': lavenderDusk,
    'rose': blushRose,
    'champagne': champagneGold,
    'midnight': oceanMist,
  };

  static const List<String> ids = [
    none,
    blushRose,
    sageGarden,
    champagneGold,
    lavenderDusk,
    oceanMist,
  ];

  static String normalizeId(String? raw) {
    var v = (raw ?? none).trim().toLowerCase();
    if (v.isEmpty) return none;
    if (legacyMap.containsKey(v)) return legacyMap[v]!;
    // allow direct legacy ids without mapping? already mapped
    if (ids.contains(v)) return v;
    // also accept with dash or old naming
    v = v.replaceAll('-', '_');
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
    AppEffect(
      id: blushRose,
      nameKey: 'fx_blush_rose',
      subtitleKey: 'fx_blush_rose_sub',
      primary: Color(0xFFD9A39A), // brandBlush
      secondary: Color(0xFFF0DDD7), // brandBlushSoft
      icon: Icons.favorite_rounded,
      gradientLight: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF0DDD7), // blush soft
          Color(0xFFFFFDF9), // ivory
          Color(0xFFF5F0E8), // cream
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
      primary: Color(0xFF5F7F62), // brandGreen
      secondary: Color(0xFFD8E5D6), // brandGreenSoft
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
      primary: Color(0xFFD4AF8C), // legacyGold
      secondary: Color(0xFFEFC4A8), // legacyGoldSoft
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
      primary: Color(0xFFD9A39A), // use blush as base to avoid random purple, but hint lavender via secondary
      secondary: Color(0xFFE8D5E0), // very light mauve-blush (still within cream/blush family)
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
      primary: Color(0xFF5F7F62), // sage
      secondary: Color(0xFFD4E5E0), // misty sage-blue (still sage family)
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
  ];

  static AppEffect byId(String? id) {
    final norm = normalizeId(id);
    return all.firstWhere((e) => e.id == norm, orElse: () => all.first);
  }

  LinearGradient gradientForBrightness(Brightness b) {
    return b == Brightness.dark ? gradientDark : gradientLight;
  }
}

/// Optional: alias for legacy code that used AppEffectStyle
/// Keep AppEffectStyle defined in app_effects.dart for backward compat,
/// but we expose helper to convert.
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
      default:
        return 'none';
    }
  }
}
