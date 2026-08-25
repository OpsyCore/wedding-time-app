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
import '../services/weather_service.dart';
import '../widgets/floral_decor.dart';

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
  String? _weddingId;
  InvitationModel? _invitation;
  bool _loading = true;
  String? _error;

  String? _rsvp;
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  bool _sending = false;
  bool _submitted = false;

  WeatherSnapshot? _weather;
  bool _weatherLoading = false;
  String? _weatherError;

  String _effectStyleId = AppEffectStyle.noneId;

  static const _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  // Light mockup palette for floral invite card only (do not darken).
  static const _inviteCreamBg = Color(0xFFF3EDE3);
  static const _inviteCardFill = Color(0xFFF7F1E6);
  static const _inviteInnerFill = Color(0xFFFFFBF4);
  static const _inviteNameColor = Color(0xFF3A342E);
  static const _inviteQrModule = Color(0xFF2F2B28);

  String fa(String input) {
    if (!AppLang.I.isFa) return input;
    return input.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? _faDigits[i] : c;
    }).join();
  }

  String _weekDayName(int weekday) {
    switch (weekday) {
      case 1:
        return AppLang.tr('weekday_mon');
      case 2:
        return AppLang.tr('weekday_tue');
      case 3:
        return AppLang.tr('weekday_wed');
      case 4:
        return AppLang.tr('weekday_thu');
      case 5:
        return AppLang.tr('weekday_fri');
      case 6:
        return AppLang.tr('weekday_sat');
      case 7:
        return AppLang.tr('weekday_sun');
      default:
        return '';
    }
  }

  String _t(String key, String fallback) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return fallback;
    return v;
  }

  /// مثل موکاپ: OCT  25  2025
  String _formatInviteDateMockup(DateTime? d) {
    if (d == null) return AppLang.tr('to_be_announced');
    const monthsEn = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    if (AppLang.I.isFa) {
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return fa('${d.year}  /  $m  /  $day');
    }
    return '${monthsEn[d.month - 1]}   ${d.day}   ${d.year}';
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

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      if (widget.invitation != null && widget.weddingId != null) {
        _weddingId = widget.weddingId;
        _invitation = widget.invitation;
        if (mounted) setState(() => _loading = false);
        await _restoreLocalRsvp();
        await Future.wait([_loadWeather(), _loadEffectStyle()]);
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
      await Future.wait([_loadWeather(), _loadEffectStyle()]);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLang.tr('invite_load_error');
      });
    }
  }

  /// RSVP فقط یک‌بار — اگر روی این دستگاه ثبت شده باشد دوباره نپرس
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

  Future<void> _loadWeather() async {
    final inv = _invitation;
    if (inv == null || !inv.hasGeo) {
      if (!mounted) return;
      setState(() {
        _weather = null;
        _weatherLoading = false;
        _weatherError = null;
      });
      return;
    }

    setState(() {
      _weatherLoading = true;
      _weatherError = null;
    });

    try {
      final w = await WeatherService.fetch(lat: inv.lat!, lng: inv.lng!);
      if (!mounted) return;
      setState(() {
        _weather = w;
        _weatherLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _weather = null;
        _weatherLoading = false;
        _weatherError = AppLang.tr('weather_fetch_failed');
      });
    }
  }

  IconData _iconOf(String key) {
    switch (key) {
      case 'guests':
        return Icons.groups_outlined;
      case 'ring':
        return Icons.favorite_border;
      case 'dinner':
        return Icons.restaurant_outlined;
      case 'dance':
        return Icons.music_note_outlined;
      case 'cake':
        return Icons.cake_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  IconData _weatherIcon(int code) {
    if (code == 0 || code == 1) return Icons.wb_sunny_outlined;
    if (code == 2) return Icons.wb_cloudy_outlined;
    if (code == 3) return Icons.cloud_outlined;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 51 && code <= 67) return Icons.water_drop_outlined;
    if (code >= 71 && code <= 77) return Icons.ac_unit;
    if (code >= 80 && code <= 82) return Icons.grain;
    if (code >= 95) return Icons.thunderstorm_outlined;
    return Icons.wb_cloudy_outlined;
  }

  String _dayTitle(DateTime d, int index) {
    if (index == 0) return AppLang.tr('today');
    return _weekDayName(d.weekday);
  }

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

      // یک‌بار برای همیشه روی این دستگاه
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

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        final dark = AppTok.isDark(context);
        final brandGreenSoft =
            dark ? AppDarkPalette.brandGreenSoft : AppPalette.brandGreenSoft;
        final brandBlushSoft =
            dark ? AppDarkPalette.brandBlushSoft : AppPalette.brandBlushSoft;

        if (_loading) {
          return Directionality(
            textDirection: AppLang.I.direction,
            child: Scaffold(
              backgroundColor: AppTok.background(context),
              body: Center(
                child: CircularProgressIndicator(
                  color: AppTok.accent(context),
                ),
              ),
            ),
          );
        }

        if (_error != null || _invitation == null) {
          return Directionality(
            textDirection: AppLang.I.direction,
            child: Scaffold(
              backgroundColor: AppTok.background(context),
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.link_off,
                          color: AppTok.textSoft(context),
                          size: 42,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error ?? AppLang.tr('invite_unavailable'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTok.text(context),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (widget.allowPop && Navigator.of(context).canPop())
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              AppLang.tr('back'),
                              style: TextStyle(color: AppTok.accent(context)),
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

        final hasLocation = inv.venueName.trim().isNotEmpty ||
            inv.venueAddress.trim().isNotEmpty ||
            inv.mapUrl.trim().isNotEmpty ||
            inv.hasGeo;

        // پس‌زمینه اصلی صفحه
        final pageBg = dark ? AppTok.background(context) : _inviteCreamBg;

        return Directionality(
          textDirection: AppLang.I.direction,
          child: Scaffold(
            backgroundColor: pageBg,
            body: SafeArea(
              child: Stack(
                children: [
                  if (!dark)
                    const Positioned.fill(
                      child: FloralDecor(intensity: 1.05),
                    ),
                  Positioned.fill(
                    child: AppEffectOverlay(
                      effectId: _effectStyleId,
                      intensity: _inviteIntensity,
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: Row(
                          children: [
                            if (widget.allowPop &&
                                Navigator.of(context).canPop())
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(
                                  AppLang.I.isFa
                                      ? Icons.arrow_forward
                                      : Icons.arrow_back,
                                  color: AppTok.text(context),
                                ),
                              )
                            else
                              const SizedBox(width: 48),
                            Expanded(
                              child: Text(
                                AppLang.tr('digital_invitation'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTok.accentDeep(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                          children: [
                            _buildFloralInviteCard(inv),

                            // ─── دکمه پنل مهمان (بدون ثبت‌نام) ───
                            if (widget.showGuestPanelButton &&
                                widget.onOpenGuestPanel != null &&
                                !widget.previewMode) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: widget.onOpenGuestPanel,
                                  icon: const Icon(Icons.groups_2_outlined),
                                  label: Text(
                                    AppLang.I.isFa
                                        ? 'ورود به پنل مهمان'
                                        : 'Open guest panel',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTok.accent(context),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLang.I.isFa
                                    ? 'تایم‌لاین · دوربین · صندلی · گالری · هدیه — بدون لاگین'
                                    : 'Timeline · Camera · Seats · Gallery · Gifts — no login',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTok.textSoft(context),
                                  fontSize: 11.5,
                                  height: 1.4,
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // ─── RSVP فقط یک‌بار ───
                            if (inv.showRsvp) ...[
                              _softCard(
                                child: _submitted
                                    ? Column(
                                        children: [
                                          Icon(
                                            _rsvp == 'yes'
                                                ? Icons.check_circle_outline
                                                : Icons.info_outline,
                                            color: AppTok.accent(context),
                                            size: 28,
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: brandGreenSoft.withValues(
                                                alpha: 0.55,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _rsvp == 'yes'
                                                  ? AppLang.tr(
                                                      'rsvp_recorded_yes')
                                                  : AppLang.tr(
                                                      'rsvp_recorded_no'),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color:
                                                    AppTok.accentDeep(context),
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
                                            style: TextStyle(
                                              color: AppTok.textSoft(context),
                                              fontSize: 11.5,
                                              height: 1.45,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          Text(
                                            AppLang.tr('rsvp_question'),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppTok.text(context),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          TextField(
                                            controller: _nameC,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppTok.text(context),
                                            ),
                                            decoration: InputDecoration(
                                              hintText: AppLang.tr(
                                                'your_name_required',
                                              ),
                                              hintStyle: TextStyle(
                                                color:
                                                    AppTok.textSoft(context),
                                              ),
                                              filled: true,
                                              fillColor:
                                                  AppTok.cardSoft(context),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          TextField(
                                            controller: _phoneC,
                                            keyboardType: TextInputType.phone,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppTok.text(context),
                                            ),
                                            decoration: InputDecoration(
                                              hintText:
                                                  AppLang.tr('phone_optional'),
                                              hintStyle: TextStyle(
                                                color:
                                                    AppTok.textSoft(context),
                                              ),
                                              filled: true,
                                              fillColor:
                                                  AppTok.cardSoft(context),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          _rsvpButton(
                                            label: AppLang.tr('rsvp_yes'),
                                            icon: Icons.check_circle_outline,
                                            selected: _rsvp == 'yes',
                                            positive: true,
                                            brandGreenSoft: brandGreenSoft,
                                            brandBlushSoft: brandBlushSoft,
                                            onTap: _sending
                                                ? null
                                                : () => _submitRsvp('yes'),
                                          ),
                                          const SizedBox(height: 10),
                                          _rsvpButton(
                                            label: AppLang.tr('rsvp_no'),
                                            icon: Icons.cancel_outlined,
                                            selected: _rsvp == 'no',
                                            positive: false,
                                            brandGreenSoft: brandGreenSoft,
                                            brandBlushSoft: brandBlushSoft,
                                            onTap: _sending
                                                ? null
                                                : () => _submitRsvp('no'),
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            _softCard(
                              child: Column(
                                children: [
                                  Text(
                                    AppLang.tr('wedding_day_schedule'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTok.text(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (inv.schedule.isEmpty)
                                    Text(
                                      AppLang.tr('no_schedule_yet'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppTok.textSoft(context),
                                      ),
                                    )
                                  else
                                    ...inv.schedule.asMap().entries.map((e) {
                                      final item = e.value;
                                      final isLast =
                                          e.key == inv.schedule.length - 1;
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 54,
                                            child: Text(
                                              fa(item.time),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color:
                                                    AppTok.accentDeep(context),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Column(
                                            children: [
                                              Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color:
                                                        AppTok.accent(context),
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                              if (!isLast)
                                                Container(
                                                  width: 2,
                                                  height: 42,
                                                  color: AppTok.accent(context)
                                                      .withValues(alpha: 0.35),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 18,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    _iconOf(item.icon),
                                                    color:
                                                        AppTok.accent(context),
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      item.title,
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: TextStyle(
                                                        color: AppTok.text(
                                                          context,
                                                        ),
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildWeatherCard(inv),
                            const SizedBox(height: 16),
                            _softCard(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: AppTok.accent(context),
                                    size: 22,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    AppLang.tr('location'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTok.textSoft(context),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    inv.venueName.trim().isEmpty
                                        ? AppLang.tr('to_be_announced')
                                        : inv.venueName,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTok.text(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (inv.venueCity.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      inv.venueCity,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppTok.accentDeep(context),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  if (inv.venueAddress.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      inv.venueAddress,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppTok.textSoft(context),
                                        fontSize: 12,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                  if (hasLocation) ...[
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 46,
                                      child: ElevatedButton.icon(
                                        onPressed: _openMap,
                                        icon: const Icon(
                                          Icons.directions,
                                          size: 18,
                                        ),
                                        label: Text(
                                          AppLang.tr('open_in_google_maps'),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTok.accent(context),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
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

  /// کارت اصلی — شبیه موکاپ light: کرم + قاب گل + اسامی + تاریخ + QR
  /// (عمداً dark نمی‌شود تا FloralDecor نشکند)
  Widget _buildFloralInviteCard(InvitationModel inv) {
    final dateText = _formatInviteDateMockup(inv.weddingDate);
    final timeText = inv.eventTime.trim();
    final place = _placeLine(inv);
    final qrData = _inviteQrData(inv);
    final groom = _groomDisplay(inv);
    final bride = _brideDisplay(inv);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _inviteCardFill,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppPalette.brandGreen.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.brandGreen.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          const BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // لایه گل دور قاب
            const Positioned.fill(
              child: FloralDecor(intensity: 1.25, frameMode: true),
            ),
            // لایه نرم وسط برای خوانایی متن
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _inviteInnerFill.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppPalette.brandGreen.withValues(alpha: 0.18),
                  ),
                ),
              ),
            ),
            // محتوا
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
              child: Column(
                children: [
                  Text(
                    _t(
                      'you_are_invited',
                      AppLang.I.isFa ? 'شما دعوتید به' : 'YOU ARE INVITED TO',
                    ).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppPalette.accentDeep.withValues(alpha: 0.85),
                      fontSize: 10.5,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t(
                      'to_the_wedding_of',
                      AppLang.I.isFa ? 'عروسی' : 'THE WEDDING OF',
                    ).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppPalette.textSoft.withValues(alpha: 0.95),
                      fontSize: 10.5,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // داماد
                  Text(
                    groom,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      color: _inviteNameColor,
                      fontSize: 38,
                      height: 1.05,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '&',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      color: AppPalette.accentDeep.withValues(alpha: 0.85),
                      fontSize: 26,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // عروس
                  Text(
                    bride,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      color: _inviteNameColor,
                      fontSize: 38,
                      height: 1.05,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // خط ظریف
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppPalette.border.withValues(alpha: 0.9),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          Icons.favorite,
                          size: 12,
                          color: AppPalette.brandBlush.withValues(alpha: 0.9),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppPalette.border.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // تاریخ — فاصله‌دار مثل موکاپ
                  Text(
                    dateText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppPalette.accentDeep,
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
                        color: AppPalette.textSoft,
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
                        color: AppPalette.textSoft,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // QR
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppPalette.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppPalette.brandGreen.withValues(alpha: 0.08),
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
                        color: AppPalette.accentDeep,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: _inviteQrModule,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _t(
                      'scan_to_rsvp',
                      AppLang.I.isFa ? 'برای RSVP اسکن کنید' : 'Scan to RSVP',
                    ),
                    style: const TextStyle(
                      color: AppPalette.textSoft,
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

  Widget _softCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTok.card(context).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTok.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppTok.shadow(context),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildWeatherCard(InvitationModel inv) {
    return _softCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.wb_cloudy_outlined,
                color: AppTok.accent(context),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLang.tr('venue_weather'),
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (inv.hasGeo)
                IconButton(
                  tooltip: AppLang.tr('refresh'),
                  onPressed: _weatherLoading ? null : _loadWeather,
                  icon: Icon(
                    Icons.refresh,
                    color: AppTok.textSoft(context),
                    size: 20,
                  ),
                ),
            ],
          ),
          if (inv.venueCity.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppTok.accent(context),
                ),
                const SizedBox(width: 4),
                Text(
                  inv.venueCity,
                  style: TextStyle(
                    color: AppTok.accentDeep(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (!inv.hasGeo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTok.cardSoft(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                AppLang.tr('venue_city_not_set_invite'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 12.5,
                  height: 1.55,
                ),
              ),
            )
          else if (_weatherLoading && _weather == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTok.accent(context),
                ),
              ),
            )
          else if (_weatherError != null && _weather == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _weatherError!,
                      style: TextStyle(
                        color: AppTok.textSoft(context),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadWeather,
                    child: Text(
                      AppLang.tr('retry'),
                      style: TextStyle(color: AppTok.accent(context)),
                    ),
                  ),
                ],
              ),
            )
          else if (_weather != null)
            _buildWeatherContent(_weather!),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(WeatherSnapshot w) {
    final temp = fa(w.temperature.toStringAsFixed(1));
    final humidity = w.humidity != null ? fa(w.humidity.toString()) : '—';
    final precip = w.precipProbability != null
        ? fa(w.precipProbability.toString())
        : '—';
    final wind =
        w.windSpeedKmh != null ? fa(w.windSpeedKmh!.round().toString()) : '—';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLang.tr('current_conditions'),
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    _weatherIcon(w.weatherCode),
                    color: AppTok.accentSoft(context),
                    size: 40,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$temp°',
                          style: TextStyle(
                            color: AppTok.text(context),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          WeatherService.label(w.weatherCode),
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
              const SizedBox(height: 12),
              _metaRow(
                Icons.water_drop_outlined,
                '$humidity${AppLang.tr('percent_unit')}',
              ),
              const SizedBox(height: 6),
              _metaRow(
                Icons.umbrella_outlined,
                '$precip${AppLang.tr('percent_unit')}',
              ),
              const SizedBox(height: 6),
              _metaRow(Icons.air, '$wind${AppLang.tr('km_unit')}'),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < w.daily.length; i++)
                  _dayColumn(w.daily[i], i),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTok.textSoft(context)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(color: AppTok.textSoft(context), fontSize: 12),
        ),
      ],
    );
  }

  Widget _dayColumn(WeatherDay day, int index) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Text(
            _dayTitle(day.date, index),
            style: TextStyle(
              color: AppTok.textSoft(context),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            _weatherIcon(day.weatherCode),
            color: AppTok.accentSoft(context),
            size: 26,
          ),
          const SizedBox(height: 6),
          Text(
            WeatherService.conditionShort(day.weatherCode),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTok.text(context),
              fontSize: 10,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${fa(day.tempMax.round().toString())}°',
            style: TextStyle(
              color: AppTok.danger(context),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${fa(day.tempMin.round().toString())}°',
            style: TextStyle(
              color: AppTok.accentDeep(context),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rsvpButton({
    required String label,
    required IconData icon,
    required bool selected,
    required bool positive,
    required Color brandGreenSoft,
    required Color brandBlushSoft,
    required VoidCallback? onTap,
  }) {
    final color = positive ? AppTok.accent(context) : AppTok.danger(context);
    final bg = positive
        ? brandGreenSoft.withValues(alpha: 0.65)
        : brandBlushSoft.withValues(alpha: 0.75);
    final fg = positive ? AppTok.accentDeep(context) : AppTok.danger(context);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          backgroundColor: selected ? bg : Colors.transparent,
          side: BorderSide(color: color.withValues(alpha: 0.75)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}