import 'package:flutter/material.dart';

/// Light mockup tokens — همیشه static const
class AppPalette {
  AppPalette._();

  static const Color background = Color(0xFFF5F0E8);
  static const Color card = Color(0xFFFFFDF9);
  static const Color cardSoft = Color(0xFFEEF3EA);
  static const Color accent = Color(0xFF5F7F62);
  static const Color accentSoft = Color(0xFFD9A39A);
  static const Color accentDeep = Color(0xFF3E5A43);
  static const Color text = Color(0xFF2F2B28);
  static const Color textSoft = Color(0xFF7A736C);
  static const Color danger = Color(0xFFC96B6B);
  static const Color ringTrack = Color(0xFFE7E0D6);
  static const Color border = Color(0xFFD9E3D6);
  static const Color shadow = Color(0x14000000);

  static const Color brandGreen = Color(0xFF5F7F62);
  static const Color brandGreenDeep = Color(0xFF3E5A43);
  static const Color brandGreenSoft = Color(0xFFD8E5D6);
  static const Color brandBlush = Color(0xFFD9A39A);
  static const Color brandBlushSoft = Color(0xFFF0DDD7);
  static const Color brandCream = Color(0xFFF5F0E8);
  static const Color brandIvory = Color(0xFFFFFDF9);
  static const Color legacyGold = Color(0xFFD4AF8C);
  static const Color legacyGoldSoft = Color(0xFFEFC4A8);

  static const String fontFamily = 'Estedad';

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFDF9), Color(0xFFEEF3EA), Color(0xFFF5F0E8)],
  );

  static const LinearGradient drawerHeaderGradient = LinearGradient(
    colors: [brandIvory, brandGreenSoft],
  );

  static const LinearGradient progressGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFFFFFDF9), Color(0xFFEEF3EA)],
  );

  static const LinearGradient inviteCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFDF9), Color(0xFFF7F1E8), Color(0xFFEEF3EA)],
  );
}

/// Dark classic gold-on-smoky-purple — همیشه static const
class AppDarkPalette {
  AppDarkPalette._();

  static const Color background = Color(0xFF14131C);
  static const Color card = Color(0xFF211F2B);
  static const Color cardSoft = Color(0xFF2A2735);
  static const Color accent = Color(0xFFD4AF8C);
  static const Color accentSoft = Color(0xFFEFC4A8);
  static const Color accentDeep = Color(0xFFE8C9A8);
  static const Color text = Color(0xFFF5EAF0);
  static const Color textSoft = Color(0xFFB9AAB0);
  static const Color danger = Color(0xFFE68585);
  static const Color ringTrack = Color(0xFF3A3545);
  static const Color border = Color(0xFF3A3545);
  static const Color shadow = Color(0x66000000);

  static const Color brandGreen = Color(0xFFD4AF8C);
  static const Color brandGreenDeep = Color(0xFFE8C9A8);
  static const Color brandGreenSoft = Color(0xFF3A3545);
  static const Color brandBlush = Color(0xFFEFC4A8);
  static const Color brandBlushSoft = Color(0xFF3A2F35);
  static const Color brandCream = Color(0xFF14131C);
  static const Color brandIvory = Color(0xFF211F2B);
  static const Color legacyGold = Color(0xFFD4AF8C);
  static const Color legacyGoldSoft = Color(0xFFEFC4A8);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF211F2B), Color(0xFF1A1520), Color(0xFF14131C)],
  );

  static const LinearGradient drawerHeaderGradient = LinearGradient(
    colors: [Color(0xFF2A2735), Color(0xFF211F2B)],
  );

  static const LinearGradient progressGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF2A2735), Color(0xFF211F2B)],
  );

  static const LinearGradient inviteCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF211F2B), Color(0xFF1A1520), Color(0xFF18141E)],
  );
}

/// Helper اختیاری برای مهاجرت تدریجی (بدون mutable کردن AppPalette)
class AppTok {
  AppTok._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext c) =>
      isDark(c) ? AppDarkPalette.background : AppPalette.background;
  static Color card(BuildContext c) =>
      isDark(c) ? AppDarkPalette.card : AppPalette.card;
  static Color cardSoft(BuildContext c) =>
      isDark(c) ? AppDarkPalette.cardSoft : AppPalette.cardSoft;
  static Color accent(BuildContext c) =>
      isDark(c) ? AppDarkPalette.accent : AppPalette.accent;
  static Color accentSoft(BuildContext c) =>
      isDark(c) ? AppDarkPalette.accentSoft : AppPalette.accentSoft;
  static Color accentDeep(BuildContext c) =>
      isDark(c) ? AppDarkPalette.accentDeep : AppPalette.accentDeep;
  static Color text(BuildContext c) =>
      isDark(c) ? AppDarkPalette.text : AppPalette.text;
  static Color textSoft(BuildContext c) =>
      isDark(c) ? AppDarkPalette.textSoft : AppPalette.textSoft;
  static Color danger(BuildContext c) =>
      isDark(c) ? AppDarkPalette.danger : AppPalette.danger;
  static Color border(BuildContext c) =>
      isDark(c) ? AppDarkPalette.border : AppPalette.border;
  static Color ringTrack(BuildContext c) =>
      isDark(c) ? AppDarkPalette.ringTrack : AppPalette.ringTrack;
  static Color shadow(BuildContext c) =>
      isDark(c) ? AppDarkPalette.shadow : AppPalette.shadow;

  static LinearGradient heroGradient(BuildContext c) =>
      isDark(c) ? AppDarkPalette.heroGradient : AppPalette.heroGradient;
  static LinearGradient drawerHeaderGradient(BuildContext c) => isDark(c)
      ? AppDarkPalette.drawerHeaderGradient
      : AppPalette.drawerHeaderGradient;
  static LinearGradient progressGradient(BuildContext c) =>
      isDark(c) ? AppDarkPalette.progressGradient : AppPalette.progressGradient;
  static LinearGradient inviteCardGradient(BuildContext c) => isDark(c)
      ? AppDarkPalette.inviteCardGradient
      : AppPalette.inviteCardGradient;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppPalette.fontFamily,
      scaffoldBackgroundColor: AppPalette.background,
      cardColor: AppPalette.card,
      dividerColor: AppPalette.border,
      textTheme: base.textTheme.apply(
        fontFamily: AppPalette.fontFamily,
        bodyColor: AppPalette.text,
        displayColor: AppPalette.text,
      ),
      colorScheme: const ColorScheme.light(
        primary: AppPalette.accent,
        onPrimary: Colors.white,
        secondary: AppPalette.accentSoft,
        onSecondary: AppPalette.text,
        surface: AppPalette.card,
        onSurface: AppPalette.text,
        error: AppPalette.danger,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppPalette.background,
        foregroundColor: AppPalette.text,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppPalette.accent,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppPalette.card,
        selectedItemColor: AppPalette.accent,
        unselectedItemColor: AppPalette.textSoft,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppPalette.background,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppPalette.accent,
        linearTrackColor: AppPalette.ringTrack,
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.border,
        thickness: 1,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppPalette.fontFamily,
      scaffoldBackgroundColor: AppDarkPalette.background,
      cardColor: AppDarkPalette.card,
      dividerColor: AppDarkPalette.border,
      textTheme: base.textTheme.apply(
        fontFamily: AppPalette.fontFamily,
        bodyColor: AppDarkPalette.text,
        displayColor: AppDarkPalette.text,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppDarkPalette.accent,
        onPrimary: AppDarkPalette.background,
        secondary: AppDarkPalette.accentSoft,
        onSecondary: AppDarkPalette.text,
        surface: AppDarkPalette.card,
        onSurface: AppDarkPalette.text,
        error: AppDarkPalette.danger,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppDarkPalette.background,
        foregroundColor: AppDarkPalette.text,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppDarkPalette.accent,
        foregroundColor: AppDarkPalette.background,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppDarkPalette.accent,
          foregroundColor: AppDarkPalette.background,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppDarkPalette.card,
        selectedItemColor: AppDarkPalette.accent,
        unselectedItemColor: AppDarkPalette.textSoft,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppDarkPalette.background,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppDarkPalette.accent,
        linearTrackColor: AppDarkPalette.ringTrack,
      ),
      dividerTheme: const DividerThemeData(
        color: AppDarkPalette.border,
        thickness: 1,
      ),
    );
  }

  /// Theme overlay برای DatePicker (برای استفاده داخل `showAppDatePicker`)
  /// - بسته به `base.brightness` خودکار Light/Dark می‌شود.
  static ThemeData datePickerOverlay([ThemeData? base]) {
    final parent = base ?? light();
    final isDark = parent.brightness == Brightness.dark;

    final accent = isDark ? AppDarkPalette.accent : AppPalette.accent;
    final accentDeep =
        isDark ? AppDarkPalette.accentDeep : AppPalette.accentDeep;
    final text = isDark ? AppDarkPalette.text : AppPalette.text;
    final textSoft = isDark ? AppDarkPalette.textSoft : AppPalette.textSoft;
    final surface = isDark ? AppDarkPalette.card : Colors.white;
    final onAccent = isDark ? AppDarkPalette.background : Colors.white;

    return parent.copyWith(
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: accent,
              onPrimary: onAccent,
              surface: surface,
              onSurface: text,
              onSurfaceVariant: textSoft,
            )
          : ColorScheme.light(
              primary: accent,
              onPrimary: onAccent,
              surface: surface,
              onSurface: text,
              onSurfaceVariant: textSoft,
            ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        headerBackgroundColor: accent,
        headerForegroundColor: onAccent,
        dayForegroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return onAccent;
          if (s.contains(WidgetState.disabled)) {
            return textSoft.withValues(alpha: 0.35);
          }
          return text;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return accent;
          return Colors.transparent;
        }),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: textSoft,
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: accentDeep,
        ),
      ),
    );
  }
}