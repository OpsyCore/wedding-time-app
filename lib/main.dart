import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'core/app_lang.dart';
import 'core/app_theme.dart';
import 'core/app_theme_controller.dart';
import 'firebase_options.dart';
import 'screens/guest_portal/guest_auth_gate.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AppLang.I.load();
  await AppThemeController.I.load();

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

  /// true = این سشن فقط مهمان است — Splash/Login/زوج ممنوع
  static bool get isGuestSession => _lockedGuestSlug != null;

  static String? get lockedGuestSlug => _lockedGuestSlug;

  static void lockInitialGuestSlug() {
    if (_lockDone) return;
    _lockDone = true;
    _lockedGuestSlug = extractGuestSlug();
  }

  static String? extractGuestSlug([String? raw]) {
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

  static String? _slugFrom(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;

    final asUri = Uri.tryParse(s);
    if (asUri != null && (asUri.hasScheme || s.contains('://'))) {
      s = asUri.path;
      if ((s.isEmpty || s == '/') && asUri.fragment.isNotEmpty) {
        s = asUri.fragment;
      }
    }

    if (s.startsWith('#')) s = s.substring(1);
    if (!s.startsWith('/')) s = '/$s';

    final qi = s.indexOf('?');
    if (qi >= 0) s = s.substring(0, qi);
    final hi = s.indexOf('#');
    if (hi >= 0) s = s.substring(0, hi);

    final parts = s.split('/').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return null;

    final root = parts.first.toLowerCase();
    if (root == 'invite' ||
        root == 'portal' ||
        root == 'guest' ||
        root == 'g') {
      if (parts.length >= 2) {
        return Uri.decodeComponent(parts[1]).trim();
      }
      return '';
    }
    return null;
  }

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
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
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