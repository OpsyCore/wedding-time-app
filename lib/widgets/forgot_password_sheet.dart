import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';

/// بازیابی رمز عبور — ارسال لینک تغییر رمز از طریق Firebase Auth
///
/// پیش‌نیاز در Firebase Console (بدون آن ایمیل ارسال نمی‌شود):
/// 1) Authentication → Sign-in method → Email/Password روشن باشد.
/// 2) Authentication → Settings → Authorized domains دامنهٔ اپ ثبت شده باشد.
/// 3) Authentication → Templates → Password reset قالب ایمیل فعال باشد
///    (قالب پیش‌فرض فایربیس کافی است).
///
/// روی وب/دسکتاپ لینک در مرورگر باز می‌شود؛ روی موبایل هم اگر
/// ActionCodeSettings تنظیم نشده باشد، کاربر در مرورگر رمز را عوض می‌کند.
class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({super.key, this.initialEmail});

  /// در صورت وجود، فیلد ایمیل از پیش پر می‌شود
  final String? initialEmail;

  /// نمایش شیت — خروجی `true` یعنی ایمیل بازیابی ارسال شد
  static Future<bool> show(
    BuildContext context, {
    String? initialEmail,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ForgotPasswordSheet(initialEmail: initialEmail),
    );
    return result ?? false;
  }

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  static final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;

  bool _isLoading = false;
  String? _errorText;

  /// وقتی پر شود، شیت به حالت «ارسال شد» می‌رود
  String? _sentTo;

  @override
  void initState() {
    super.initState();
    _emailCtrl =
        TextEditingController(text: (widget.initialEmail ?? '').trim());
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final email = _emailCtrl.text.trim();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _sentTo = email;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = _mapAuthError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = '${AppLang.tr('error_with_details')}$e';
      });
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
      case 'missing-email':
        return AppLang.tr('email_invalid');
      case 'user-not-found':
        return AppLang.tr('user_not_found');
      case 'too-many-requests':
        return AppLang.tr('reset_too_many_requests');
      case 'network-request-failed':
        return AppLang.tr('reset_network_error');
      default:
        final msg = e.message?.trim() ?? '';
        return msg.isNotEmpty ? msg : AppLang.tr('reset_error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLang.I,
      builder: (context, _) {
        return Directionality(
          textDirection: AppLang.I.direction,
          child: Padding(
            // کیبورد شیت را به بالا می‌راند
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppTok.card(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: _sentTo != null
                      ? _buildSuccess(context, _sentTo!)
                      : _buildForm(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────── فرم ─────────────────────────

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _handle(context),
          const SizedBox(height: 14),
          _buildHeader(context),
          const SizedBox(height: 12),
          Text(
            AppLang.tr('forgot_password_body'),
            style: TextStyle(
              color: AppTok.textSoft(context),
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _emailCtrl,
            enabled: !_isLoading,
            autofocus: _emailCtrl.text.isEmpty,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _send(),
            style: TextStyle(color: AppTok.text(context)),
            decoration: _inputDecoration(
              context,
              label: AppLang.tr('email'),
              icon: Icons.email_outlined,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final v = (value ?? '').trim();
              if (v.isEmpty) return AppLang.tr('email_required');
              if (!_emailRe.hasMatch(v)) return AppLang.tr('email_invalid');
              return null;
            },
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            _errorBox(context, _errorText!),
          ],
          const SizedBox(height: 20),
          _primaryButton(
            context,
            label: _isLoading
                ? AppLang.tr('sending')
                : AppLang.tr('send_reset_link'),
            onTap: _isLoading ? null : _send,
            showSpinner: _isLoading,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTok.cardSoft(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.lock_reset_rounded,
            color: AppTok.accent(context),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            AppLang.tr('forgot_password_title'),
            style: TextStyle(
              color: AppTok.text(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          tooltip: AppLang.tr('close'),
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          icon: Icon(Icons.close_rounded, color: AppTok.textSoft(context)),
        ),
      ],
    );
  }

  // ─────────────────────── موفقیت ───────────────────────

  Widget _buildSuccess(BuildContext context, String email) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _handle(context),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTok.cardSoft(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read_rounded,
              color: AppTok.accent(context),
              size: 38,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          AppLang.trArgs('reset_email_sent_to', {'email': email}),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTok.text(context),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          AppLang.tr('reset_email_hint'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTok.textSoft(context),
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 22),
        _primaryButton(
          context,
          label: AppLang.tr('reset_done_button'),
          onTap: () => Navigator.pop(context, true),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  // ─────────────────────── اجزای مشترک ───────────────────────

  Widget _handle(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: AppTok.border(context),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppTok.textSoft(context)),
      prefixIcon: Icon(icon, color: AppTok.accent(context)),
      filled: true,
      fillColor: AppTok.card(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTok.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTok.accent(context), width: 1.5),
      ),
    );
  }

  Widget _primaryButton(
    BuildContext context, {
    required String label,
    required VoidCallback? onTap,
    bool showSpinner = false,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTok.accent(context),
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            AppTok.accent(context).withValues(alpha: 0.45),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.85),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: showSpinner
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
    );
  }

  Widget _errorBox(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTok.danger(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTok.danger(context).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              color: AppTok.danger(context),
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppTok.danger(context),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
