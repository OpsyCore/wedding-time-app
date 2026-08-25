import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../main_navigation_screen.dart';
import '../services/wedding_service.dart';
import 'wedding_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _setLang(String code) async {
    await AppLang.I.setLanguage(code);

    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
          'language': code,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<void> _setDark(bool value) async {
    await AppThemeController.I.setDark(value);
    if (mounted) setState(() {});
  }

  Future<void> _routeAfterAuth(User user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'language': AppLang.I.isFa ? 'fa' : 'en',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}

    final weddingId = await WeddingService.getUserWeddingId(user.uid);

    if (!mounted) return;

    if (weddingId == null || weddingId.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WeddingSetupScreen()),
      );
      return;
    }

    final wedding = await WeddingService.getWedding(weddingId);
    if (!mounted) return;

    if (wedding == null) {
      await WeddingService.clearUserWedding(user.uid);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WeddingSetupScreen()),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainNavigationScreen(weddingId: weddingId),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text.trim();
      late final UserCredential credential;

      if (_isLogin) {
        credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
      } else {
        credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'email': email,
          'plan': 'free',
          'language': AppLang.I.isFa ? 'fa' : 'en',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      final user = credential.user;
      if (user == null) {
        throw Exception(AppLang.tr('user_create_failed'));
      }

      await _routeAfterAuth(user);
    } on FirebaseAuthException catch (e) {
      String message = AppLang.tr('login_error');
      if (e.code == 'user-not-found') {
        message = AppLang.tr('user_not_found');
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = AppLang.tr('wrong_credentials');
      } else if (e.code == 'email-already-in-use') {
        message = AppLang.tr('email_already_in_use');
      } else if (e.code == 'weak-password') {
        message = AppLang.tr('weak_password');
      } else if (e.code == 'invalid-email') {
        message = AppLang.tr('email_invalid');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTok.danger(context),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLang.tr('error_with_details')}${e.toString()}'),
            backgroundColor: AppTok.danger(context),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v == key || v.isEmpty) {
      return AppLang.I.isFa ? fa : en;
    }
    return v;
  }

  Widget _langSwitch(BuildContext context) {
    final isFa = AppLang.I.isFa;
    final dark = AppTok.isDark(context);
    final brandGreenSoft =
        dark ? AppDarkPalette.brandGreenSoft : AppPalette.brandGreenSoft;

    return Column(
      children: [
        Text(
          AppLang.tr('language'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTok.textSoft(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTok.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTok.border(context)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _langChip(
                  context,
                  label: 'فارسی',
                  selected: isFa,
                  brandGreenSoft: brandGreenSoft,
                  onTap: () => _setLang('fa'),
                ),
              ),
              Expanded(
                child: _langChip(
                  context,
                  label: 'English',
                  selected: !isFa,
                  brandGreenSoft: brandGreenSoft,
                  onTap: () => _setLang('en'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _themeSwitch(BuildContext context) {
    final isDark = AppThemeController.I.isDark;
    final dark = AppTok.isDark(context);
    final brandGreenSoft =
        dark ? AppDarkPalette.brandGreenSoft : AppPalette.brandGreenSoft;
    final brandBlushSoft =
        dark ? AppDarkPalette.brandBlushSoft : AppPalette.brandBlushSoft;

    return Column(
      children: [
        Text(
          _t('appearance', 'ظاهر', 'Appearance'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTok.textSoft(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTok.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTok.border(context)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _themeChip(
                  context,
                  label: _t('light_mode', 'روز', 'Light'),
                  icon: Icons.light_mode_outlined,
                  selected: !isDark,
                  selectedBg: brandGreenSoft,
                  onTap: () => _setDark(false),
                ),
              ),
              Expanded(
                child: _themeChip(
                  context,
                  label: _t('dark_mode', 'شب', 'Dark'),
                  icon: Icons.dark_mode_outlined,
                  selected: isDark,
                  selectedBg: brandBlushSoft,
                  onTap: () => _setDark(true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _langChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required Color brandGreenSoft,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? brandGreenSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? AppTok.accentDeep(context)
                  : AppTok.textSoft(context),
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _themeChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required Color selectedBg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? selectedBg : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? AppTok.accentDeep(context)
                    : AppTok.textSoft(context),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppTok.accentDeep(context)
                      : AppTok.textSoft(context),
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        return Directionality(
          textDirection: AppLang.I.direction,
          child: Scaffold(
            backgroundColor: AppTok.background(context),
            body: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      Icons.favorite,
                      color: AppTok.accent(context),
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isLogin
                          ? AppLang.tr('login_title')
                          : AppLang.tr('signup_title'),
                      style: TextStyle(
                        color: AppTok.text(context),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin
                          ? AppLang.tr('login_subtitle')
                          : AppLang.tr('signup_subtitle'),
                      style: TextStyle(
                        color: AppTok.textSoft(context),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailCtrl,
                            style: TextStyle(color: AppTok.text(context)),
                            decoration: InputDecoration(
                              labelText: AppLang.tr('email'),
                              labelStyle: TextStyle(
                                color: AppTok.textSoft(context),
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppTok.accent(context),
                              ),
                              filled: true,
                              fillColor: AppTok.card(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppLang.tr('email_required');
                              }
                              if (!value.contains('@')) {
                                return AppLang.tr('email_invalid');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: AppTok.text(context)),
                            decoration: InputDecoration(
                              labelText: AppLang.tr('password'),
                              labelStyle: TextStyle(
                                color: AppTok.textSoft(context),
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppTok.accent(context),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppTok.textSoft(context),
                                ),
                              ),
                              filled: true,
                              fillColor: AppTok.card(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppLang.tr('password_required');
                              }
                              if (value.length < 6) {
                                return AppLang.tr('password_min_length');
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTok.accent(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isLogin
                                  ? AppLang.tr('login')
                                  : AppLang.tr('signup'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin
                              ? AppLang.tr('no_account')
                              : AppLang.tr('have_account'),
                          style: TextStyle(
                            color: AppTok.textSoft(context),
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _isLogin = !_isLogin);
                          },
                          child: Text(
                            _isLogin
                                ? AppLang.tr('signup')
                                : AppLang.tr('login'),
                            style: TextStyle(
                              color: AppTok.accent(context),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── زبان + تم قبل ورود ──
                    const SizedBox(height: 28),
                    Container(
                      height: 1,
                      color: AppTok.border(context),
                    ),
                    const SizedBox(height: 20),
                    _langSwitch(context),
                    const SizedBox(height: 18),
                    _themeSwitch(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}