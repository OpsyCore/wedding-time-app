import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show FlutterError, debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Conditional import: flutter_web_plugins depends on dart:ui_web, which
// only exists on web. Importing it unconditionally breaks Android/iOS
// builds with "Dart library 'dart:ui_web' is not available".
import 'core/web_url_strategy_stub.dart'
    if (dart.library.js_interop) 'core/web_url_strategy_web.dart';

import 'core/app_config.dart';
import 'core/app_effect_controller.dart';
import 'core/app_font_controller.dart';
import 'core/app_lang.dart';
import 'core/guest_slug.dart';
import 'core/app_theme.dart';
import 'core/app_theme_controller.dart';
import 'firebase_options.dart';
import 'screens/guest_portal/guest_auth_gate.dart';
import 'screens/splash_screen.dart';
import 'services/ambient_music_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    configureWebUrlStrategy();
  }

  _installGlobalErrorHandlers();

  await _bootstrap();
}

/// پایداری: هیچ خطای تکی نباید کلِ اپ را سفید/قرمز کند.
void _installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  // خطاهای asyncِ مدیریت‌نشده (قطعی شبکه، Timestamp نامعتبر و …)
  // به‌جای terminate شدن اپ، لاگ می‌شوند.
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint('Uncaught async error: $error\n$stack');
    return true;
  };

  // جایگزین صفحهٔ قرمز/خاکستری خطا با یک پیام آرام هم‌خوان با تم
  ErrorWidget.builder = (_) => const _AppErrorFallback();
}

Future<void> _bootstrap() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await AppLang.I.load();
    await AppThemeController.I.load();
    await AppEffectController.I.load();
    await AppFontController.I.load();
    try {
      await AmbientMusicService.I.init();
    } catch (_) {
      // missing-file safe — never crash app start
    }

    // مهم: slug مهمان را یک‌بار در استارت قفل کن
    // تا rebuild تم/زبان آن را گم نکند
    WeddingTimeApp.lockInitialGuestSlug();

    runApp(const WeddingTimeApp());
  } catch (e, stack) {
    // Firebase/SharedPreferences در دسترس نیست (آفلاین، پروژهٔ اشتباه، …)
    // به‌جای صفحهٔ سفید، پیام قابل‌فهم + تلاش دوباره نشان بده.
    debugPrint('Startup failed: $e\n$stack');
    WeddingTimeApp.lockInitialGuestSlug();
    runApp(StartupErrorApp(message: e.toString(), onRetry: _bootstrap));
  }
}

/// نمای جایگزین ویجت خراب — به‌جای صفحهٔ خاکستری/قرمز
class _AppErrorFallback extends StatelessWidget {
  const _AppErrorFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF5F0E8),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'مشکلی در نمایش این بخش پیش آمد\nThis section could not be shown',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7A736C),
              fontSize: 12,
              height: 1.7,
            ),
          ),
        ),
      ),
    );
  }
}

/// صفحهٔ خطای استارت — وقتی Firebase بالا نیامده است
class StartupErrorApp extends StatefulWidget {
  const StartupErrorApp({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  State<StartupErrorApp> createState() => _StartupErrorAppState();
}

class _StartupErrorAppState extends State<StartupErrorApp> {
  bool _retrying = false;
  bool _isFa = true;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    await widget.onRetry();
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(AppFontController.defaultFamily),
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: _isFa ? TextDirection.rtl : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        backgroundColor: AppPalette.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 52,
                    color: AppPalette.brandBlush,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isFa
                        ? 'اتصال برقرار نشد'
                        : 'Could not connect',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppPalette.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isFa
                        ? 'اینترنت را بررسی کن و دوباره تلاش کن.'
                        : 'Check your internet connection and try again.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppPalette.textSoft,
                      fontSize: 13,
                      height: 1.9,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _retrying ? null : _retry,
                      child: _retrying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isFa ? 'تلاش دوباره' : 'Retry'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => setState(() => _isFa = !_isFa),
                    child: Text(_isFa ? 'English' : 'فارسی'),
                  ),
                  const SizedBox(height: 12),
                  if (!_isFa)
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: AppPalette.textSoft,
                        fontSize: 10,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
        AppFontController.I,
      ]),
      builder: (context, _) {
        final lang = AppLang.I;

        final font = AppFontController.I.family;
        return MaterialApp(
          // ⚠️ هیچ key وابسته به فونت/تم اینجا نگذار:
          // key جدید یعنی دور ریختن کل Element tree و از دست رفتن
          // Navigator state. تغییر فونت فقط از طریق theme اعمال می‌شود.
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          locale: lang.locale,
          supportedLocales: const [Locale('fa'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(font),
          darkTheme: AppTheme.dark(font),
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