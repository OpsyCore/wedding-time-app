import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_date_picker.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../main_navigation_screen.dart';
import '../services/wedding_service.dart';

class WeddingSetupScreen extends StatefulWidget {
  const WeddingSetupScreen({super.key});

  @override
  State<WeddingSetupScreen> createState() => _WeddingSetupScreenState();
}

class _WeddingSetupScreenState extends State<WeddingSetupScreen> {
  // 0 نقش | 1 ساخت | 2 کد دعوت | 3 پیوستن
  int _step = 0;
  String _role = ''; // bride | groom

  final _brideCtrl = TextEditingController();
  final _groomCtrl = TextEditingController();
  final _joinCodeCtrl = TextEditingController();

  final _auth = FirebaseAuth.instance;

  DateTime? _weddingDate;
  String? _inviteCode;
  String? _currentWeddingId;
  bool _loading = false;

  @override
  void dispose() {
    _brideCtrl.dispose();
    _groomCtrl.dispose();
    _joinCodeCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            error ? Colors.red.shade800 : AppTok.card(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _goHome() async {
    final weddingId = _currentWeddingId;
    if (!mounted) return;

    if (weddingId == null || weddingId.isEmpty) {
      _toast(AppLang.tr('wedding_not_found'), error: true);
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MainNavigationScreen(weddingId: weddingId),
      ),
      (_) => false,
    );
  }

  Future<void> _createWedding() async {
    if (_role.isEmpty) {
      _toast(AppLang.tr('select_role_first'), error: true);
      setState(() => _step = 0);
      return;
    }

    if (_brideCtrl.text.trim().isEmpty ||
        _groomCtrl.text.trim().isEmpty ||
        _weddingDate == null) {
      _toast(AppLang.tr('fill_couple_and_date'), error: true);
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      _toast(AppLang.tr('user_not_logged_in'), error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await WeddingService.createWedding(
        uid: user.uid,
        role: _role,
        brideName: _brideCtrl.text.trim(),
        groomName: _groomCtrl.text.trim(),
        weddingDate: _weddingDate!,
        email: user.email,
      );

      setState(() {
        _currentWeddingId = result.weddingId;
        _inviteCode = result.inviteCode;
        _step = 2;
      });
    } catch (e) {
      _toast('${AppLang.tr('create_wedding_error')}$e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinWedding() async {
    if (_role.isEmpty) {
      _toast(AppLang.tr('select_role_first'), error: true);
      return;
    }

    if (_joinCodeCtrl.text.trim().isEmpty) {
      _toast(AppLang.tr('enter_invite_code'), error: true);
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      _toast(AppLang.tr('user_not_logged_in'), error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final weddingId = await WeddingService.joinWedding(
        uid: user.uid,
        role: _role,
        code: _joinCodeCtrl.text,
        email: user.email,
      );

      _currentWeddingId = weddingId;
      await _goHome();
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _toast(msg, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickWeddingDate() async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context,
      initialDate: _weddingDate ?? now.add(const Duration(days: 30)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && mounted) {
      setState(() => _weddingDate = picked);
    }
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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Row(
                      children: [
                        if (_step > 0 && _step != 2)
                          IconButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    setState(() {
                                      if (_step == 3) {
                                        _step = 0;
                                      } else {
                                        _step = _step - 1;
                                      }
                                    });
                                  },
                            icon: Icon(
                              Icons.arrow_back,
                              color: AppTok.text(context),
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                        const Spacer(),
                        Text(
                          AppLang.tr('app_name'),
                          style: TextStyle(
                            color: AppTok.accent(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                            fontFamily: 'serif',
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
                      child: _buildStep(),
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

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _roleStep();
      case 1:
        return _createStep();
      case 2:
        return _inviteStep();
      case 3:
        return _joinStep();
      default:
        return _roleStep();
    }
  }

  Widget _roleStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          AppLang.tr('choose_your_role'),
          style: TextStyle(
            color: AppTok.text(context),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLang.tr('choose_role_subtitle'),
          style: TextStyle(color: AppTok.textSoft(context), fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        Row(
          children: [
            Expanded(
              child: _roleCard(
                title: AppLang.tr('groom'),
                subtitle: 'Groom',
                role: 'groom',
                child: Icon(
                  Icons.man_2_rounded,
                  size: 54,
                  color: AppTok.accent(context),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _roleCard(
                title: AppLang.tr('bride'),
                subtitle: 'Bride',
                role: 'bride',
                child: Icon(
                  Icons.woman_2_rounded,
                  size: 54,
                  color: AppTok.accent(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),
        _primaryBtn(AppLang.tr('continue'), () {
          if (_role.isEmpty) {
            _toast(AppLang.tr('select_a_role'), error: true);
            return;
          }
          setState(() => _step = 1);
        }),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _step = 3),
          child: Text(
            AppLang.tr('join_with_invite_code'),
            style: TextStyle(
              color: AppTok.accent(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _roleCard({
    required String title,
    required String subtitle,
    required String role,
    required Widget child,
  }) {
    final selected = _role == role;
    return GestureDetector(
      onTap: () => setState(() => _role = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 190,
        decoration: BoxDecoration(
          color: AppTok.card(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? AppTok.accent(context)
                : AppTok.border(context),
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTok.accent(context).withValues(alpha: 0.18),
                    blurRadius: 16,
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            if (selected)
              Positioned(
                top: 12,
                left: 12,
                child: Icon(
                  Icons.check_circle,
                  color: AppTok.accent(context),
                  size: 20,
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  child,
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: selected
                          ? AppTok.accent(context)
                          : AppTok.text(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
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
          ],
        ),
      ),
    );
  }

  Widget _createStep() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Text(
          AppLang.tr('create_wedding_title'),
          style: TextStyle(
            color: AppTok.text(context),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLang.tr('create_wedding_subtitle'),
          style: TextStyle(color: AppTok.textSoft(context), fontSize: 13),
        ),
        const SizedBox(height: 28),
        _field(_brideCtrl, AppLang.tr('bride_name'), Icons.person_outline),
        const SizedBox(height: 14),
        _field(_groomCtrl, AppLang.tr('groom_name'), Icons.person_outline),
        const SizedBox(height: 14),
        _dateField(),
        const SizedBox(height: 30),
        _loading
            ? CircularProgressIndicator(color: AppTok.accent(context))
            : _primaryBtn(AppLang.tr('create_wedding'), _createWedding),
      ],
    );
  }

  Widget _inviteStep() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Text(
          AppLang.tr('your_invite_code'),
          style: TextStyle(
            color: AppTok.text(context),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLang.tr('share_code_with_partner'),
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTok.textSoft(context), fontSize: 13),
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
          decoration: BoxDecoration(
            color: AppTok.card(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTok.accent(context).withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: [
              Text(
                AppLang.tr('ceremony_invite_code'),
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _inviteCode ?? '---',
                    style: TextStyle(
                      color: AppTok.accent(context),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: _inviteCode ?? ''),
                      );
                      _toast(AppLang.tr('code_copied'));
                    },
                    icon: Icon(
                      Icons.copy_rounded,
                      color: AppTok.textSoft(context),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Icon(Icons.favorite, color: AppTok.accent(context), size: 42),
              const SizedBox(height: 10),
              Text(
                AppLang.tr('invite_code_help'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _primaryBtn(AppLang.tr('share_code'), () {
          Share.share(
            '${AppLang.tr('share_invite_message')}${_inviteCode ?? ''}',
          );
        }),
        const SizedBox(height: 12),
        _primaryBtn(AppLang.tr('enter_app'), _goHome),
      ],
    );
  }

  Widget _joinStep() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Text(
          AppLang.tr('join_wedding_title'),
          style: TextStyle(
            color: AppTok.text(context),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLang.tr('join_wedding_subtitle'),
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTok.textSoft(context), fontSize: 13),
        ),
        const SizedBox(height: 28),
        _field(
          _joinCodeCtrl,
          AppLang.tr('enter_invite_code'),
          Icons.vpn_key_outlined,
          capitalize: true,
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            AppLang.tr('choose_your_role'),
            style: TextStyle(color: AppTok.textSoft(context), fontSize: 12),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _miniRole(AppLang.tr('bride'), 'bride')),
            const SizedBox(width: 10),
            Expanded(child: _miniRole(AppLang.tr('groom'), 'groom')),
          ],
        ),
        const SizedBox(height: 28),
        _loading
            ? CircularProgressIndicator(color: AppTok.accent(context))
            : _primaryBtn(AppLang.tr('join_wedding'), _joinWedding),
        const SizedBox(height: 12),
        Text(
          AppLang.tr('get_code_from_partner'),
          style: TextStyle(color: AppTok.textSoft(context), fontSize: 12),
        ),
      ],
    );
  }

  Widget _miniRole(String title, String role) {
    final selected = _role == role;
    return InkWell(
      onTap: () => setState(() => _role = role),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTok.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppTok.accent(context)
                : Colors.transparent,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected
                ? AppTok.accent(context)
                : AppTok.text(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    bool capitalize = false,
  }) {
    return TextField(
      controller: c,
      style: TextStyle(color: AppTok.text(context)),
      textCapitalization:
          capitalize ? TextCapitalization.characters : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTok.textSoft(context)),
        prefixIcon: Icon(icon, color: AppTok.accent(context)),
        filled: true,
        fillColor: AppTok.card(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dateField() {
    return InkWell(
      onTap: _pickWeddingDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: AppTok.card(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              color: AppTok.accent(context),
            ),
            const SizedBox(width: 12),
            Text(
              _weddingDate == null
                  ? AppLang.tr('wedding_date')
                  : '${_weddingDate!.year}/${_weddingDate!.month.toString().padLeft(2, '0')}/${_weddingDate!.day.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: _weddingDate == null
                    ? AppTok.textSoft(context)
                    : AppTok.text(context),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryBtn(String title, VoidCallback onTap) {
    final onAccent =
        AppTok.isDark(context) ? AppDarkPalette.background : Colors.white;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTok.accent(context),
          foregroundColor: onAccent,
          disabledBackgroundColor:
              AppTok.accent(context).withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}