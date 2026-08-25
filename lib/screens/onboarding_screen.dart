import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../main_navigation_screen.dart';
import '../services/wedding_service.dart';
import 'login_screen.dart';
import 'wedding_setup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late String selectedLanguage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedLanguage = AppLang.I.code;
  }

  /// پیش‌نمایش با زبان انتخاب‌شده — قبل از setLanguage
  String _pt(String key) => AppLang.trIn(selectedLanguage, key);

  Future<void> _continue() async {
    setState(() => isLoading = true);

    await AppLang.I.setLanguage(selectedLanguage);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final weddingId = await WeddingService.getUserWeddingId(user.uid);
    if (!mounted) return;

    if (weddingId == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WeddingSetupScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainNavigationScreen(weddingId: weddingId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewFa = selectedLanguage == 'fa';
    final onAccent =
        AppTok.isDark(context) ? AppDarkPalette.background : Colors.white;

    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        return Directionality(
          textDirection: previewFa ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: AppTok.background(context),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Wedding Time',
                      style: TextStyle(
                        fontSize: 28,
                        color: AppTok.accent(context),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _pt('onboarding_tagline'),
                      style: TextStyle(
                        color: AppTok.textSoft(context),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    Text(
                      _pt('choose_language'),
                      style: TextStyle(
                        color: AppTok.text(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _pt('onboarding_can_change_later'),
                      style: TextStyle(
                        color: AppTok.textSoft(context),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _langCard(
                      code: 'fa',
                      title: _pt('lang_fa'),
                      subtitle: _pt('lang_fa_sub_rtl'),
                    ),
                    const SizedBox(height: 12),
                    _langCard(
                      code: 'en',
                      title: _pt('lang_en'),
                      subtitle: _pt('lang_en_sub_ltr'),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTok.accent(context),
                          foregroundColor: onAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: isLoading ? null : _continue,
                        child: isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: onAccent,
                                ),
                              )
                            : Text(
                                _pt('continue'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _langCard({
    required String code,
    required String title,
    required String subtitle,
  }) {
    final isSelected = selectedLanguage == code;

    return GestureDetector(
      onTap: () => setState(() => selectedLanguage = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppTok.card(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppTok.accent(context)
                : AppTok.border(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected
                  ? AppTok.accent(context)
                  : AppTok.textSoft(context),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? AppTok.text(context)
                          : AppTok.textSoft(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTok.textSoft(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTok.accent(context), size: 20),
          ],
        ),
      ),
    );
  }
}