import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../core/app_theme.dart';
import '../../core/app_theme_controller.dart';
import '../../models/invitation_model.dart';
import '../../services/invitation_service.dart';
import '../public_invite_screen.dart';
import 'guest_portal_shell.dart';

/// /invite/{slug}
///
/// فقط:
/// 1) کارت دعوت (می‌ماند تا کاربر خودش بخواهد)
/// 2) دکمه «ورود به پنل مهمان» → پنل مهمان
///
/// هیچ ریدایرکت خودکاری به لاگین/پنل زوج وجود ندارد.
class GuestAuthGate extends StatefulWidget {
  const GuestAuthGate({super.key, required this.slug});

  final String slug;

  @override
  State<GuestAuthGate> createState() => _GuestAuthGateState();
}

class _GuestAuthGateState extends State<GuestAuthGate> {
  bool _loading = true;
  String? _error;
  String? _weddingId;
  InvitationModel? _invitation;

  /// فقط با دکمه true می‌شود — هرگز خودکار
  bool _inGuestPanel = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? fa : en;
    return v;
  }

  Future<void> _load() async {
    final slug = widget.slug.trim();
    if (slug.isEmpty) {
      setState(() {
        _loading = false;
        _error = _t(
          'invalid_invite_link',
          'لینک دعوت نامعتبر است',
          'Invalid invite link',
        );
      });
      return;
    }

    try {
      final data = await InvitationService.getBySlug(slug);
      if (!mounted) return;
      if (data == null) {
        setState(() {
          _loading = false;
          _error = _t(
            'invite_not_found',
            'دعوت‌نامه پیدا نشد',
            'Invitation not found',
          );
        });
        return;
      }
      setState(() {
        _weddingId = data.weddingId;
        _invitation = data.invitation;
        _loading = false;
        _inGuestPanel = false; // فقط کارت
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _t(
          'invite_load_error',
          'خطا در بارگذاری دعوت‌نامه',
          'Failed to load invitation',
        );
      });
    }
  }

  void _openGuestPanel() {
    if (_weddingId == null || _invitation == null) return;
    setState(() => _inGuestPanel = true);
  }

  void _backToInviteCard() {
    setState(() => _inGuestPanel = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        return Directionality(
          textDirection: AppLang.I.direction,
          child: _buildBody(context),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTok.background(context),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTok.accent(context)),
              const SizedBox(height: 14),
              Text(
                _t(
                  'loading_invite',
                  'در حال بارگذاری دعوت‌نامه...',
                  'Loading invitation...',
                ),
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _weddingId == null || _invitation == null) {
      return Scaffold(
        backgroundColor: AppTok.background(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link_off, size: 40, color: AppTok.danger(context)),
                const SizedBox(height: 12),
                Text(
                  _error ??
                      _t(
                        'invite_unavailable',
                        'دعوت‌نامه در دسترس نیست',
                        'Invite unavailable',
                      ),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTok.text(context), height: 1.5),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _load();
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(_t('retry', 'تلاش دوباره', 'Retry')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // فقط با کلیک دکمه
    if (_inGuestPanel) {
      return GuestPortalShell(
        weddingId: _weddingId!,
        invitation: _invitation!,
        onLeavePortal: _backToInviteCard,
      );
    }

    // کارت دعوت — همین‌جا می‌ماند (بدون تایمر / بدون auth)
    return PublicInviteScreen(
      weddingId: _weddingId!,
      invitation: _invitation!,
      previewMode: false,
      showGuestPanelButton: true,
      onOpenGuestPanel: _openGuestPanel,
      // لینک عمومی: دکمه برگشت به اپ زوج نباشد
      allowPop: false,
    );
  }
}