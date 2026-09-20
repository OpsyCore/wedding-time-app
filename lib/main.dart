import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Conditional import: flutter_web_plugins depends on dart:ui_web, which
// only exists on web. Importing it unconditionally breaks Android/iOS
// builds with "Dart library 'dart:ui_web' is not available".
import 'core/web_url_strategy_stub.dart'
    if (dart.library.js_interop) 'core/web_url_strategy_web.dart';

import 'core/app_config.dart';
import 'core/app_effect_controller.dart';
import 'core/app_lang.dart';
import 'core/guest_slug.dart';
import 'core/app_theme.dart';
import 'core/app_theme_controller.dart';
import 'firebase_options.dart';
import 'screens/guest_portal/guest_auth_gate.dart';
import 'screens/splash_screen.dart';
import 'services/ambient_music_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    configureWebUrlStrategy();
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AppLang.I.load();
  await AppThemeController.I.load();
  await AppEffectController.I.load();
  try {
    await AmbientMusicService.I.init();
  } catch (_) {
    // missing-file safe — never crash app start
  }

  // مهم: slug مهمان را یک‌بار در استارت قفل کن
  // تا rebuild تم/زبان آن را گم نکند
  WeddingTimeApp.lockInitialGuestSlug();

  runApp(const WeddingTimeApp());
}

class WeddingTimeApp extends StatelessWidget {
  const WeddingTimeApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// فقط یک‌بار در main() ست می‌شود
  static String? _lockedGuestSlug;
  static bool _lockDone = false;

  /// true = این تب با لینک پارتنر (?join=) باز شده — هرگز سشن مهمان نشود
  static bool _joinMode = false;

  /// true = این سشن فقط مهمان است — Splash/Login/زوج ممنوع
  static bool get isGuestSession => _lockedGuestSlug != null;

  static String? get lockedGuestSlug => _lockedGuestSlug;

  static void lockInitialGuestSlug() {
    if (_lockDone) return;
    _lockDone = true;

    // لینک دعوت پارتنر: /join/CODE یا ?join=CODE → سشن مهمان قفل نشود؛
    // کد برای مرحلهٔ پیوستن در WeddingSetupScreen نگه داشته می‌شود.
    if (kIsWeb) {
      String join = Uri.base.queryParameters['join']?.trim() ?? '';
      if (join.isEmpty) {
        final segs = Uri.base.pathSegments;
        if (segs.length >= 2 && segs[0] == 'join') {
          join = Uri.decodeComponent(segs[1]).trim();
        }
      }
      if (join.isNotEmpty) {
        _joinMode = true;
        AppConfig.pendingJoinCode = join;
        _lockedGuestSlug = null;
        return;
      }
    }

    _lockedGuestSlug = extractGuestSlug();
  }

  static String? extractGuestSlug([String? raw]) {
    // حالت پیوستن پارتنر: هیچ مسیری نباید به پورتال مهمان برود
    if (_joinMode) return null;
    final tried = <String>[
      if (raw != null) raw,
      if (kIsWeb) Uri.base.path,
      if (kIsWeb) Uri.base.toString(),
      if (kIsWeb && Uri.base.fragment.isNotEmpty) Uri.base.fragment,
    ];
    for (final item in tried) {
      final s = _slugFrom(item);
      if (s != null) return s;
    }
    return null;
  }

  static String? _slugFrom(String? raw) => GuestSlug.from(raw);

  static Route<dynamic> _routeFor(RouteSettings settings) {
    // سشن مهمان قفل‌شده — هر routeی → فقط GuestAuthGate
    if (isGuestSession) {
      return MaterialPageRoute(
        settings: RouteSettings(name: '/invite/$_lockedGuestSlug'),
        builder: (_) => GuestAuthGate(slug: _lockedGuestSlug ?? ''),
      );
    }

    final slug = extractGuestSlug(settings.name);
    if (slug != null) {
      _lockedGuestSlug ??= slug;
      return MaterialPageRoute(
        settings: RouteSettings(name: '/invite/$slug'),
        builder: (_) => GuestAuthGate(slug: slug),
      );
    }

    return MaterialPageRoute(
      settings: const RouteSettings(name: '/'),
      builder: (_) => const SplashScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppLang.I,
        AppThemeController.I,
        AppEffectController.I,
      ]),
      builder: (context, _) {
        final lang = AppLang.I;

        return MaterialApp(
          // کلید ثابت — کمتر stack را می‌پرد
          key: const ValueKey('wedding_time_root'),
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          locale: lang.locale,
          supportedLocales: const [Locale('fa'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: AppThemeController.I.themeMode,
          builder: (context, child) {
            return Directionality(
              textDirection: lang.direction,
              child: child ?? const SizedBox.shrink(),
            );
          },
          // مهمان: فقط gate — Splash اصلاً mount نشود
          home: isGuestSession
              ? GuestAuthGate(slug: _lockedGuestSlug ?? '')
              : const SplashScreen(),
          onGenerateRoute: _routeFor,
          onUnknownRoute: (_) {
            if (isGuestSession) {
              return MaterialPageRoute(
                builder: (_) => GuestAuthGate(slug: _lockedGuestSlug ?? ''),
              );
            }
            return MaterialPageRoute(
              builder: (_) => const SplashScreen(),
            );
          },
        );
      },
    );
  }
}