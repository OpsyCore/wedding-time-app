import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../core/app_theme.dart';
import '../../core/app_theme_controller.dart';

class GuestLoginScreen extends StatefulWidget {
  const GuestLoginScreen({super.key, required this.coupleTitle});

  final String coupleTitle;

  @override
  State<GuestLoginScreen> createState() => _GuestLoginScreenState();
}

class _GuestLoginScreenState extends State<GuestLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? fa : en;
    return v;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text.trim();

      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
      } else {
        final cred =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          'email': email,
          'role': 'guest',
          'language': AppLang.I.isFa ? 'fa' : 'en',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
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
            content: Text('${AppLang.tr('error_with_details')}$e'),
            backgroundColor: AppTok.danger(context),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        final isDark = AppThemeController.I.isDark;

        return Scaffold(
          backgroundColor: AppTok.background(context),
          appBar: AppBar(
            backgroundColor: AppTok.background(context),
            elevation: 0,
            actions: [
              IconButton(
                tooltip: isDark
                    ? _t('light_mode', 'روز', 'Light')
                    : _t('dark_mode', 'شب', 'Dark'),
                onPressed: () => AppThemeController.I.setDark(!isDark),
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: AppTok.accent(context),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  Icon(Icons.favorite, color: AppTok.accent(context), size: 56),
                  const SizedBox(height: 16),
                  Text(
                    _t('guest_portal_login_title', 'ورود مهمان', 'Guest sign in'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTok.text(context),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.coupleTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTok.accent(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t(
                      'guest_portal_login_sub',
                      'برای مشاهده دعوت‌نامه، گالری و هدایا وارد شوید',
                      'Sign in to view invitation, gallery and gifts',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTok.textSoft(context),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: AppTok.text(context)),
                          decoration: _dec(
                            context,
                            AppLang.tr('email'),
                            Icons.email_outlined,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return AppLang.tr('email_required');
                            }
                            if (!v.contains('@')) {
                              return AppLang.tr('email_invalid');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          style: TextStyle(color: AppTok.text(context)),
                          decoration: _dec(
                            context,
                            AppLang.tr('password'),
                            Icons.lock_outline,
                            suffix: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppTok.textSoft(context),
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return AppLang.tr('password_required');
                            }
                            if (v.length < 6) {
                              return AppLang.tr('password_min_length');
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTok.accent(context),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
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
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? _t(
                              'guest_need_account',
                              'حساب ندارید؟ ثبت‌نام',
                              'No account? Sign up',
                            )
                          : _t(
                              'guest_have_account',
                              'حساب دارید؟ ورود',
                              'Have an account? Login',
                            ),
                      style: TextStyle(color: AppTok.accent(context)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => AppLang.I.setLanguage('fa'),
                        child: Text(
                          'فارسی',
                          style: TextStyle(color: AppTok.textSoft(context)),
                        ),
                      ),
                      Text('|', style: TextStyle(color: AppTok.border(context))),
                      TextButton(
                        onPressed: () => AppLang.I.setLanguage('en'),
                        child: Text(
                          'English',
                          style: TextStyle(color: AppTok.textSoft(context)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _dec(
    BuildContext context,
    String label,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppTok.textSoft(context)),
      prefixIcon: Icon(icon, color: AppTok.accent(context)),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppTok.card(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}