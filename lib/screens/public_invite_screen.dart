import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/app_effects.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../core/map_launcher.dart';
import '../models/invitation_model.dart';
import '../services/guest_local_store.dart';
import '../services/invitation_service.dart';
import '../widgets/floral_decor.dart';

/// ──────────────────────────────────────────────────────────
///  کارت دعوت عمومی — LIGHT-ONLY (cream / sage / blush)
///  ساختار: Cover → Countdown → Place → RSVP → دکمه پنل مهمان
/// ──────────────────────────────────────────────────────────
class PublicInviteScreen extends StatefulWidget {
  final String? weddingId;
  final String? slug;
  final InvitationModel? invitation;
  final bool previewMode;

  /// کنترل نمایش دکمه «پنل مهمان» (فقط وقتی از لینک عمومی می‌آیند)
  final bool showGuestPanelButton;
  final VoidCallback? onOpenGuestPanel;

  /// اگر false باشد دکمه برگشت AppBar نشان داده نمی‌شود
  /// (لینک عمومی مهمان — نرود سراغ اپ زوج)
  final bool allowPop;

  const PublicInviteScreen({
    super.key,
    required String this.weddingId,
    required InvitationModel this.invitation,
    this.previewMode = false,
    this.showGuestPanelButton = false,
    this.onOpenGuestPanel,
    this.allowPop = true,
  }) : slug = null;

  const PublicInviteScreen.bySlug({
    super.key,
    required String this.slug,
    this.showGuestPanelButton = false,
    this.onOpenGuestPanel,
    this.allowPop = true,
  })  : weddingId = null,
        invitation = null,
        previewMode = false;

  @override
  State<PublicInviteScreen> createState() => _PublicInviteScreenState();
}

class _PublicInviteScreenState extends State<PublicInviteScreen> {
  // ── data ──
  String? _weddingId;
  InvitationModel? _invitation;
  bool _loading = true;
  String? _error;

  // ── RSVP ──
  String? _rsvp;
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  bool _sending = false;
  bool _submitted = false;

  // ── effects ──
  String _effectStyleId = AppEffectStyle.noneId;

  // ── countdown ──
  Timer? _cdTimer;
  Duration _remaining = Duration.zero;

  // ── palette (light only, AppTok cream / sage / blush) ──
  static const _bg = Color(0xFFF5F0E8); // brandCream
  static const _cardFill = Color(0xFFF7F1E6); // warm cream
  static const _innerFill = Color(0xFFFFFBF4); // near-white ivory
  static const _nameColor = Color(0xFF3A342E);
  static const _sage = Color(0xFF5F7F62); // accent
  static const _sageDeep = Color(0xFF3E5A43); // accentDeep
  static const _sageSoft = Color(0xFFD8E5D6); // brandGreenSoft
  static const _blush = Color(0xFFD9A39A); // accentSoft
  static const _blushSoft = Color(0xFFF0DDD7); // brandBlushSoft
  static const _textMain = Color(0xFF2F2B28);
  static const _textSoft = Color(0xFF7A736C);
  static const _border = Color(0xFFD9E3D6);
  static const _qrModule = Color(0xFF2F2B28);
  static const _danger = Color(0xFFC96B6B);

  static const _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  // ───────────────── helpers ─────────────────

  String fa(String input) {
    if (!AppLang.I.isFa) return input;
    return input.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? _faDigits[i] : c;
    }).join();
  }

  String _t(String key, String fallback) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return fallback;
    return v;
  }

  String _groomDisplay(InvitationModel inv) {
    final g = inv.groomName.trim();
    return g.isEmpty ? AppLang.tr('groom') : g;
  }

  String _brideDisplay(InvitationModel inv) {
    final b = inv.brideName.trim();
    return b.isEmpty ? AppLang.tr('bride') : b;
  }

  String _placeLine(InvitationModel inv) {
    final parts = <String>[];
    if (inv.venueName.trim().isNotEmpty) parts.add(inv.venueName.trim());
    if (inv.venueCity.trim().isNotEmpty) parts.add(inv.venueCity.trim());
    return parts.join(AppLang.I.isFa ? '، ' : ', ');
  }

  String _inviteQrData(InvitationModel inv) {
    final link = inv.shareLink.trim();
    if (link.isNotEmpty) return link;
    return inv.coupleTitle;
  }

  /// تاریخ به فرمت:  ۱۴۰۴ / ۰۵ / ۱۲  یا  OCT  25  2025
  String _formatDateCompact(DateTime? d) {
    if (d == null) return AppLang.tr('to_be_announced');
    const monthsEn = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    if (AppLang.I.isFa) {
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return fa('${d.year}  /  $m  /  $day');
    }
    return '${monthsEn[d.month - 1]}   ${d.day}   ${d.year}';
  }

  // ───────────────── countdown ─────────────────

  void _startCountdown() {
    _cdTimer?.cancel();
    _tickCountdown(); // initial
    _cdTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickCountdown());
  }

  void _tickCountdown() {
    final inv = _invitation;
    if (inv == null || inv.weddingDate == null) {
      if (mounted) setState(() => _remaining = Duration.zero);
      return;
    }
    // combine date + eventTime → target DateTime
    final date = inv.weddingDate!;
    final timeParts = inv.eventTime.trim().split(':');
    final h = timeParts.isNotEmpty ? (int.tryParse(timeParts[0]) ?? 19) : 19;
    final m = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
    final target = DateTime(date.year, date.month, date.day, h, m);
    final diff = target.difference(DateTime.now());
    if (mounted) {
      setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
    }
  }

  // ───────────────── lifecycle ─────────────────

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _cdTimer?.cancel();
    _nameC.dispose();
    _phoneC.dispose();
    super.dispose();
  }

  // ───────────────── bootstrap ─────────────────

  Future<void> _bootstrap() async {
    try {
      if (widget.invitation != null && widget.weddingId != null) {
        _weddingId = widget.weddingId;
        _invitation = widget.invitation;
        if (mounted) setState(() => _loading = false);
        await _restoreLocalRsvp();
        await _loadEffectStyle();
        _startCountdown();
        return;
      }

      final slug = widget.slug?.trim() ?? '';
      if (slug.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = AppLang.tr('invalid_invite_link');
        });
        return;
      }

      final data = await InvitationService.getBySlug(slug);
      if (!mounted) return;

      if (data == null) {
        setState(() {
          _loading = false;
          _error = AppLang.tr('invite_not_found');
        });
        return;
      }

      setState(() {
        _weddingId = data.weddingId;
        _invitation = data.invitation;
        _loading = false;
      });
      await _restoreLocalRsvp();
      await _loadEffectStyle();
      _startCountdown();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLang.tr('invite_load_error');
      });
    }
  }

  Future<void> _restoreLocalRsvp() async {
    final wid = _weddingId;
    if (wid == null || wid.trim().isEmpty || widget.previewMode) return;
    try {
      final saved = await GuestLocalStore.loadRsvp(wid);
      if (!mounted) return;

      if (saved.status == 'yes' || saved.status == 'no') {
        setState(() {
          _rsvp = saved.status;
          _submitted = true;
          if ((saved.name ?? '').trim().isNotEmpty) {
            _nameC.text = saved.name!.trim();
          }
        });
        return;
      }

      if ((saved.name ?? '').trim().isNotEmpty) {
        _nameC.text = saved.name!.trim();
        return;
      }

      final dn = await GuestLocalStore.loadDisplayName(wid);
      if (!mounted) return;
      if ((dn ?? '').trim().isNotEmpty) {
        _nameC.text = dn!.trim();
      }
    } catch (_) {}
  }

  Future<void> _loadEffectStyle() async {
    final wid = _weddingId;
    if (wid == null || wid.isEmpty) return;
    try {
      String style = AppEffectStyle.noneId;

      final settings = await FirebaseFirestore.instance
          .collection('weddings')
          .doc(wid)
          .collection('musicSettings')
          .doc('main')
          .get();
      final s = settings.data() ?? {};
      final fx = s['effects'];
      if (fx is Map) {
        final sid = (fx['styleId'] ?? fx['effectId'] ?? '').toString().trim();
        if (sid.isNotEmpty && sid != 'none') {
          style = sid;
        } else if (fx['inviteHearts'] == true) {
          style = AppEffectStyle.lavenderId;
        } else if (fx['particles'] == true) {
          style = AppEffectStyle.goldId;
        }
      }

      if (style == AppEffectStyle.noneId) {
        final wedding = await FirebaseFirestore.instance
            .collection('weddings')
            .doc(wid)
            .get();
        final w = wedding.data() ?? {};
        final sid = (w['effectStyleId'] ?? '').toString().trim();
        if (sid.isNotEmpty) {
          style = sid;
        } else if (w['effectsInviteHearts'] == true) {
          style = AppEffectStyle.lavenderId;
        } else if (w['effectsParticles'] == true) {
          style = AppEffectStyle.goldId;
        }
      }

      if (mounted) setState(() => _effectStyleId = style);
    } catch (_) {}
  }

  double get _inviteIntensity {
    switch (_effectStyleId) {
      case AppEffectStyle.lavenderId:
      case AppEffectStyle.roseId:
        return 0.95;
      case AppEffectStyle.goldId:
      case AppEffectStyle.champagneId:
        return 0.85;
      case AppEffectStyle.midnightId:
        return 0.75;
      default:
        return 0.7;
    }
  }

  // ───────────────── RSVP submit ─────────────────

  Future<void> _submitRsvp(String value) async {
    if (widget.previewMode) {
      setState(() => _rsvp = value);
      showAppSnack(context, AppLang.tr('rsvp_preview_mode'));
      return;
    }

    if (_weddingId == null) return;

    if (_submitted) {
      showAppSnack(context, AppLang.tr('rsvp_already_submitted'));
      return;
    }

    final name = _nameC.text.trim();
    if (name.isEmpty) {
      showAppSnack(context, AppLang.tr('please_enter_name'), error: true);
      return;
    }

    setState(() {
      _rsvp = value;
      _sending = true;
    });

    try {
      await InvitationService.submitRsvp(
        weddingId: _weddingId!,
        name: name,
        phone: _phoneC.text,
        attending: value == 'yes',
      );

      await GuestLocalStore.saveRsvp(
        weddingId: _weddingId!,
        name: name,
        status: value,
      );

      if (!mounted) return;
      setState(() => _submitted = true);
      showAppSnack(
        context,
        value == 'yes'
            ? AppLang.tr('rsvp_yes_saved')
            : AppLang.tr('rsvp_no_saved'),
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnack(
        context,
        '${AppLang.tr('rsvp_submit_error')}$e',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ───────────────── map ─────────────────

  Future<void> _openMap() async {
    final inv = _invitation;
    if (inv == null) return;

    final ok = await MapLauncher.openLocation(
      name: inv.venueName,
      address: [
        if (inv.venueAddress.trim().isNotEmpty) inv.venueAddress.trim(),
        if (inv.venueCity.trim().isNotEmpty) inv.venueCity.trim(),
      ].join(AppLang.I.isFa ? '، ' : ', '),
      lat: inv.lat,
      lng: inv.lng,
      mapUrl: inv.mapUrl,
    );

    if (!ok && mounted) {
      showAppSnack(context, AppLang.tr('map_open_failed'), error: true);
    }
  }

  // ═══════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        // ── loading ──
        if (_loading) {
          return Directionality(
            textDirection: AppLang.I.direction,
            child: Scaffold(
              backgroundColor: _bg,
              body: const Center(
                child: CircularProgressIndicator(color: _sage),
              ),
            ),
          );
        }

        // ── error ──
        if (_error != null || _invitation == null) {
          return Directionality(
            textDirection: AppLang.I.direction,
            child: Scaffold(
              backgroundColor: _bg,
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link_off, color: _textSoft, size: 42),
                        const SizedBox(height: 12),
                        Text(
                          _error ?? AppLang.tr('invite_unavailable'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _textMain,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (widget.allowPop && Navigator.of(context).canPop())
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'بازگشت',
                              style: TextStyle(color: _sage),
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

        final inv = _invitation!;

        return Directionality(
          textDirection: AppLang.I.direction,
          child: Scaffold(
            backgroundColor: _bg,
            body: SafeArea(
              child: Stack(
                children: [
                  // ── floral background ──
                  const Positioned.fill(
                    child: FloralDecor(intensity: 1.05),
                  ),
                  // ── effects overlay ──
                  Positioned.fill(
                    child: AppEffectOverlay(
                      effectId: _effectStyleId,
                      intensity: _inviteIntensity,
                    ),
                  ),
                  // ── content ──
                  Column(
                    children: [
                      // top bar
                      _buildTopBar(),
                      // scrollable sections
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          children: [
                            // ─── 1. COVER ───
                            _buildCover(inv),
                            const SizedBox(height: 20),

                            // ─── 2. COUNTDOWN ───
                            if (inv.weddingDate != null) ...[
                              _buildCountdown(),
                              const SizedBox(height: 20),
                            ],

                            // ─── 3. PLACE ───
                            _buildPlace(inv),
                            const SizedBox(height: 20),

                            // ─── 4. RSVP ───
                            if (inv.showRsvp) ...[
                              _buildRsvp(),
                              const SizedBox(height: 20),
                            ],

                            // ─── دکمه «ورود به پنل مهمان» ───
                            if (widget.showGuestPanelButton &&
                                widget.onOpenGuestPanel != null &&
                                !widget.previewMode) ...[
                              _buildGuestPanelButton(),
                              const SizedBox(height: 8),
                              Text(
                                AppLang.I.isFa
                                    ? 'تایم‌لاین · دوربین · صندلی · گالری · هدیه — بدون لاگین'
                                    : 'Timeline · Camera · Seats · Gallery · Gifts — no login',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _textSoft,
                                  fontSize: 11.5,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
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

  // ─────────────── top bar ───────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          if (widget.allowPop && Navigator.of(context).canPop())
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                AppLang.I.isFa ? Icons.arrow_forward : Icons.arrow_back,
                color: _textMain,
              ),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              _t('digital_invitation', AppLang.I.isFa ? 'دعوت‌نامه دیجیتال' : 'Digital Invitation'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _sageDeep,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  //  1 · COVER CARD
  // ═══════════════════════════════════════

  Widget _buildCover(InvitationModel inv) {
    final groom = _groomDisplay(inv);
    final bride = _brideDisplay(inv);
    final dateText = _formatDateCompact(inv.weddingDate);
    final timeText = inv.eventTime.trim();
    final place = _placeLine(inv);
    final qrData = _inviteQrData(inv);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardFill,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _sage.withValues(alpha: 0.22), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _sage.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          const BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // ── floral frame ──
            const Positioned.fill(
              child: FloralDecor(intensity: 1.25, frameMode: true),
            ),
            // ── inner soft layer for readability ──
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _innerFill.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _sage.withValues(alpha: 0.18)),
                ),
              ),
            ),
            // ── content ──
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
              child: Column(
                children: [
                  // header line
                  Text(
                    _t('you_are_invited', AppLang.I.isFa ? 'شما دعوتید به' : 'YOU ARE INVITED TO')
                        .toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xCC3E5A43),
                      fontSize: 10.5,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t('to_the_wedding_of', AppLang.I.isFa ? 'عروسی' : 'THE WEDDING OF')
                        .toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xE67A736C),
                      fontSize: 10.5,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── couple names ──
                  Text(
                    groom,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      color: _nameColor,
                      fontSize: 38,
                      height: 1.05,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '&',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      color: Color(0xCC3E5A43),
                      fontSize: 26,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bride,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      color: _nameColor,
                      fontSize: 38,
                      height: 1.05,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 18),
                  // ── divider with heart ──
                  Row(
                    children: [
                      Expanded(
                        child: Container(height: 1, color: _border),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          Icons.favorite,
                          size: 12,
                          color: _blush.withValues(alpha: 0.9),
                        ),
                      ),
                      Expanded(
                        child: Container(height: 1, color: _border),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── date ──
                  Text(
                    dateText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _sageDeep,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.4,
                    ),
                  ),
                  if (timeText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      fa(timeText),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _textSoft,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (place.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      place,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _textSoft,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  // ── QR ──
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(
                          color: _sage.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrData,
                      size: 128,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: _sageDeep,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: _qrModule,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _t('scan_to_rsvp', AppLang.I.isFa ? 'برای RSVP اسکن کنید' : 'Scan to RSVP'),
                    style: const TextStyle(
                      color: _textSoft,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
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

  // ═══════════════════════════════════════
  //  2 · COUNTDOWN
  // ═══════════════════════════════════════

  Widget _buildCountdown() {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    final daysLabel = AppLang.tr('days');
    final hoursLabel = AppLang.tr('hours');
    final minsLabel = _t('guest_home_mins', AppLang.I.isFa ? 'دقیقه' : 'MINS');
    final secsLabel = _t('guest_home_secs', AppLang.I.isFa ? 'ثانیه' : 'SECS');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: AppPalette.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _sage.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: _sage.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty, color: _sage, size: 18),
              const SizedBox(width: 8),
              Text(
                _t('guest_home_upcoming', AppLang.I.isFa ? 'جشن پیشِ رو' : 'Upcoming'),
                style: const TextStyle(
                  color: _sageDeep,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4 boxes
          Row(
            children: [
              _countdownBox(fa(days.toString()), daysLabel, _sage, _sageSoft),
              const SizedBox(width: 8),
              _countdownBox(fa(hours.toString()), hoursLabel, _sage, _sageSoft),
              const SizedBox(width: 8),
              _countdownBox(fa(minutes.toString()), minsLabel, _blush, _blushSoft),
              const SizedBox(width: 8),
              _countdownBox(fa(seconds.toString()), secsLabel, _blush, _blushSoft),
            ],
          ),

          if (_remaining == Duration.zero) ...[
            const SizedBox(height: 12),
            Text(
              _t('guest_home_today', AppLang.I.isFa ? 'امروز جشن ماست 🎉' : 'Today is the day! 🎉'),
              style: const TextStyle(
                color: _sageDeep,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _countdownBox(String value, String label, Color accent, Color soft) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: soft.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: accent.withValues(alpha: 0.85),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  //  3 · PLACE
  // ═══════════════════════════════════════

  Widget _buildPlace(InvitationModel inv) {
    final hasLocation = inv.venueName.trim().isNotEmpty ||
        inv.venueAddress.trim().isNotEmpty ||
        inv.mapUrl.trim().isNotEmpty ||
        inv.hasGeo;

    if (!hasLocation) {
      return _lightCard(
        child: Column(
          children: [
            Icon(Icons.location_on_outlined, color: _textSoft, size: 26),
            const SizedBox(height: 10),
            Text(
              AppLang.tr('to_be_announced'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSoft, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return _lightCard(
      child: Column(
        children: [
          // icon + title
          Icon(Icons.location_on, color: _sage, size: 24),
          const SizedBox(height: 8),
          Text(
            _t('location', AppLang.I.isFa ? 'مکان' : 'Venue'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textSoft, fontSize: 12),
          ),
          const SizedBox(height: 6),

          // venue name
          Text(
            inv.venueName.trim().isEmpty
                ? AppLang.tr('to_be_announced')
                : inv.venueName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textMain,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          // city
          if (inv.venueCity.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              inv.venueCity,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _sageDeep,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          // address
          if (inv.venueAddress.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              inv.venueAddress,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textSoft,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 16),
          // map button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _openMap,
              icon: const Icon(Icons.directions, size: 18),
              label: Text(AppLang.tr('open_in_google_maps')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _sage,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  //  4 · RSVP
  // ═══════════════════════════════════════

  Widget _buildRsvp() {
    if (_submitted) {
      return _lightCard(
        child: Column(
          children: [
            Icon(
              _rsvp == 'yes'
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              color: _sage,
              size: 30,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _sageSoft.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _rsvp == 'yes'
                    ? AppLang.tr('rsvp_recorded_yes')
                    : AppLang.tr('rsvp_recorded_no'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _sageDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                'rsvp_once_hint',
                AppLang.I.isFa
                    ? 'پاسخ شما ثبت شده — دیگر لازم نیست دوباره تأیید کنید.'
                    : 'Your reply is saved — no need to confirm again.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textSoft,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }

    return _lightCard(
      child: Column(
        children: [
          Text(
            AppLang.tr('rsvp_question'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textMain,
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 14),

          // name field
          TextField(
            controller: _nameC,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textMain),
            decoration: InputDecoration(
              hintText: AppLang.tr('your_name_required'),
              hintStyle: const TextStyle(color: _textSoft),
              filled: true,
              fillColor: AppPalette.cardSoft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // phone field
          TextField(
            controller: _phoneC,
            keyboardType: TextInputType.phone,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textMain),
            decoration: InputDecoration(
              hintText: AppLang.tr('phone_optional'),
              hintStyle: const TextStyle(color: _textSoft),
              filled: true,
              fillColor: AppPalette.cardSoft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // yes button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _sending ? null : () => _submitRsvp('yes'),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(AppLang.tr('rsvp_yes')),
              style: OutlinedButton.styleFrom(
                foregroundColor: _sageDeep,
                backgroundColor: _rsvp == 'yes'
                    ? _sageSoft.withValues(alpha: 0.65)
                    : Colors.transparent,
                side: BorderSide(color: _sage.withValues(alpha: 0.75)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // no button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _sending ? null : () => _submitRsvp('no'),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: Text(AppLang.tr('rsvp_no')),
              style: OutlinedButton.styleFrom(
                foregroundColor: _danger,
                backgroundColor: _rsvp == 'no'
                    ? _blushSoft.withValues(alpha: 0.75)
                    : Colors.transparent,
                side: BorderSide(color: _danger.withValues(alpha: 0.75)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  //  GUEST PANEL BUTTON
  // ═══════════════════════════════════════

  Widget _buildGuestPanelButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [_sage, _sageDeep],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _sage.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onOpenGuestPanel,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.groups_2_outlined, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  AppLang.I.isFa ? 'ورود به پنل مهمان' : 'Open guest panel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────── shared light card ───────────

  Widget _lightCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
