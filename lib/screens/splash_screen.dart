import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_config.dart';
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

  /// مهلت پاسخ شبکه — بدون این، اسپلش روی اینترنت ضعیف بی‌نهایت می‌ماند.
  static const _networkTimeout = Duration(seconds: 20);

  bool _left = false;
  bool _skipHintHidden = false;
  bool _error = false;

  final Completer<void> _skipCover = Completer<void>();
  late final Future<void> _coverDone;

  @override
  void initState() {
    super.initState();
    // کاور و آماده‌سازی به‌صورت موازی اجرا می‌شوند؛ دیرترینشان ملاک است.
    _coverDone = Future.any<void>([
      Future<void>.delayed(_coverDuration),
      _skipCover.future,
    ]);
    _bootstrap();
  }

  void _skipCoverNow() {
    if (_skipCover.isCompleted) return;
    setState(() => _skipHintHidden = true);
    _skipCover.complete();
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

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (!mounted || _left) return;
      if (_leaveToGuestIfNeeded()) return;

      if (user == null) {
        await _coverDone;
        _replace(const LoginScreen());
        return;
      }

      final weddingId = await WeddingService.getUserWeddingId(user.uid)
          .timeout(_networkTimeout);
      if (!mounted || _left) return;
      if (_leaveToGuestIfNeeded()) return;

      if (weddingId == null || weddingId.isEmpty) {
        await _coverDone;
        _replace(const WeddingSetupScreen());
        return;
      }

      final wedding =
          await WeddingService.getWedding(weddingId).timeout(_networkTimeout);
      if (!mounted || _left) return;
      if (_leaveToGuestIfNeeded()) return;

      if (wedding == null) {
        await WeddingService.clearUserWedding(user.uid);
        if (!mounted || _left) return;
        await _coverDone;
        _replace(const WeddingSetupScreen());
        return;
      }

      // زوجِ عضو که با لینک پارتنر باز کرده → مستقیم پنل خودش
      AppConfig.pendingJoinCode = null;
      await _coverDone;
      _replace(MainNavigationScreen(weddingId: weddingId));
    } catch (_) {
      if (!mounted || _left) return;
      if (_leaveToGuestIfNeeded()) return;
      // خطای شبکه/سرور → به‌جای اسپینر بی‌پایان، پیام تلاش دوباره
      setState(() => _error = true);
    }
  }

  void _retry() {
    if (!mounted) return;
    setState(() => _error = false);
    _bootstrap();
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
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _error ? null : _skipCoverNow,
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
                    child: _error
                        ? _buildErrorCard(context)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: accent,
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                              if (!_skipHintHidden) ...[
                                const SizedBox(height: 12),
                                Text(
                                  AppLang.tr('tap_to_continue'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: AppTok.card(context).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTok.border(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, color: AppTok.danger(context), size: 26),
          const SizedBox(height: 8),
          Text(
            AppLang.tr('splash_network_error'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTok.text(context),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLang.tr('splash_network_hint'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTok.textSoft(context),
              fontSize: 12,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _retry,
              child: Text(AppLang.tr('retry')),
            ),
          ),
          TextButton(
            onPressed: () => _replace(const LoginScreen()),
            child: Text(
              AppLang.tr('go_to_login'),
              style: TextStyle(color: AppTok.textSoft(context), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}