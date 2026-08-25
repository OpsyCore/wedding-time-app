import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../main.dart';
import '../main_navigation_screen.dart';
import '../services/wedding_service.dart';
import 'guest_portal/guest_auth_gate.dart';
import 'login_screen.dart';
import 'wedding_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _coverAsset = 'assets/images/og-cover.png';
  static const _coverDuration = Duration(seconds: 10);

  bool _left = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  bool _leaveToGuestIfNeeded() {
    if (WeddingTimeApp.isGuestSession) {
      final slug = WeddingTimeApp.lockedGuestSlug ?? '';
      _replace(GuestAuthGate(slug: slug));
      return true;
    }
    final slug = WeddingTimeApp.extractGuestSlug();
    if (slug != null) {
      _replace(GuestAuthGate(slug: slug));
      return true;
    }
    return false;
  }

  Future<void> _bootstrap() async {
    // لینک مهمان → هرگز کاور/لاگین/پنل زوج
    if (_leaveToGuestIfNeeded()) return;

    await Future<void>.delayed(_coverDuration);
    if (!mounted || _left) return;

    if (_leaveToGuestIfNeeded()) return;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (!mounted || _left) return;
      if (_leaveToGuestIfNeeded()) return;

      if (user == null) {
        _replace(const LoginScreen());
        return;
      }

      final weddingId = await WeddingService.getUserWeddingId(user.uid);
      if (!mounted || _left) return;
      if (_leaveToGuestIfNeeded()) return;

      if (weddingId == null || weddingId.isEmpty) {
        _replace(const WeddingSetupScreen());
        return;
      }

      final wedding = await WeddingService.getWedding(weddingId);
      if (!mounted || _left) return;
      if (_leaveToGuestIfNeeded()) return;

      if (wedding == null) {
        await WeddingService.clearUserWedding(user.uid);
        if (!mounted || _left) return;
        _replace(const WeddingSetupScreen());
        return;
      }

      _replace(MainNavigationScreen(weddingId: weddingId));
    } catch (_) {
      if (!mounted || _left) return;
      if (_leaveToGuestIfNeeded()) return;
      _replace(const LoginScreen());
    }
  }

  void _replace(Widget page) {
    if (!mounted || _left) return;
    // سشن مهمان: مطلقاً نرو سراغ زوج
    if (WeddingTimeApp.isGuestSession && page is! GuestAuthGate) {
      return;
    }
    _left = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    // اگر به هر دلیل splash روی لینک مهمان آمد، فوری gate
    if (WeddingTimeApp.isGuestSession) {
      return GuestAuthGate(slug: WeddingTimeApp.lockedGuestSlug ?? '');
    }

    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        final bg = AppTok.background(context);
        final accent = AppTok.accent(context);

        return Scaffold(
          backgroundColor: bg,
          body: Directionality(
            textDirection: AppLang.I.direction,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _coverAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return ColoredBox(
                      color: bg,
                      child: Center(
                        child: Icon(Icons.favorite, color: accent, size: 64),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 160,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0),
                          Colors.black.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 48,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLang.tr('app_name'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          fontFamily: 'serif',
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: accent,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}