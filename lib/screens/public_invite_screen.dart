import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_config.dart';
import '../core/app_effect_controller.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../core/map_launcher.dart';
import '../models/invitation_model.dart';
import '../services/guest_local_store.dart';
import '../services/invitation_service.dart';
import '../widgets/effect_background.dart';
import '../widgets/floral_decor.dart';
import '../widgets/page_glass.dart';
import 'guest_portal/guest_portal_shell.dart';

/// Public invite — 5 phones redesign FROM ZERO
/// Always light elegant (phone1 dark cinematic allowed over cover photo)
/// Glass chrome: cards, AppBar, bottom nav
/// Effect wash behind, glass above
class PublicInviteScreen extends StatefulWidget {
  final String weddingId;
  final InvitationModel? invitation;
  final bool previewMode;
  final bool showGuestPanelButton;
  final VoidCallback? onOpenGuestPanel;
  final bool allowPop;

  const PublicInviteScreen({
    super.key,
    required this.weddingId,
    this.invitation,
    this.previewMode = false,
    this.showGuestPanelButton = false,
    this.onOpenGuestPanel,
    this.allowPop = true,
  });

  @override
  State<PublicInviteScreen> createState() => _PublicInviteScreenState();
}

class _PublicInviteScreenState extends State<PublicInviteScreen> {
  InvitationModel? _inv;
  bool _loading = true;
  String? _error;

  // enriched
  String _couplePhotoUrl = '';
  String _coverImageUrl = '';
  String _message = '';

  // page view
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // countdown
  Timer? _timer;
  Duration _remaining = Duration.zero;
  DateTime? _targetDateTime;

  // rsvp
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  bool _submitting = false;
  String? _localRsvpStatus;
  String? _localRsvpName;
  bool _hasRsvp = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _nameC.dispose();
    _phoneC.dispose();
    super.dispose();
  }

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? fa : en;
    return v;
  }

  Future<void> _bootstrap() async {
    try {
      InvitationModel? inv = widget.invitation;

      // if no invitation passed, try to load by weddingId (should not happen in normal flow,
      // but for safety)
      if (inv == null) {
        // try to load from firestore directly (invitation/main)
        final snap = await FirebaseFirestore.instance
            .collection('weddings')
            .doc(widget.weddingId)
            .collection('invitation')
            .doc('main')
            .get();
        if (snap.exists) {
          inv = InvitationModel.fromMap(
              Map<String, dynamic>.from(snap.data() as Map? ?? {}));
        }
      }

      if (inv == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = _t('invite_not_found', 'دعوت‌نامه پیدا نشد',
              'Invitation not found');
        });
        return;
      }

      // enrich from wedding doc + profile
      String couplePhoto = inv.couplePhotoUrl.trim();
      String coverImage = inv.coverImageUrl.trim();
      String message = inv.message.trim();

      try {
        final weddingDoc = await FirebaseFirestore.instance
            .collection('weddings')
            .doc(widget.weddingId)
            .get();
        final wData = weddingDoc.data() as Map<String, dynamic>? ?? {};
        // cover image candidates
        final coverCandidates = [
          wData['coverImageUrl'],
          wData['coverPhotoUrl'],
          wData['coverImage'],
          wData['coverPhoto'],
          wData['bannerUrl'],
        ];
        for (final c in coverCandidates) {
          final s = (c ?? '').toString().trim();
          if (s.isNotEmpty && coverImage.isEmpty) coverImage = s;
        }
        // couple photo from wedding doc
        final coupleCandidates = [
          wData['couplePhotoUrl'],
          wData['couplePhoto'],
          wData['photoUrl'],
        ];
        for (final c in coupleCandidates) {
          final s = (c ?? '').toString().trim();
          if (s.isNotEmpty && couplePhoto.isEmpty) couplePhoto = s;
        }
        // message from wedding doc
        final msgCandidates = [
          wData['invitationMessage'],
          wData['message'],
          wData['inviteMessage'],
        ];
        for (final c in msgCandidates) {
          final s = (c ?? '').toString().trim();
          if (s.isNotEmpty && message.isEmpty) message = s;
        }
      } catch (_) {}

      try {
        final profileDoc = await FirebaseFirestore.instance
            .collection('weddings')
            .doc(widget.weddingId)
            .collection('profile')
            .doc('main')
            .get();
        final pData = profileDoc.data() as Map<String, dynamic>? ?? {};
        final candidates = [
          pData['couplePhotoUrl'],
          pData['couplePhoto'],
          pData['photoUrl'],
          pData['coverPhotoUrl'],
        ];
        for (final c in candidates) {
          final s = (c ?? '').toString().trim();
          if (s.isNotEmpty && couplePhoto.isEmpty) couplePhoto = s;
        }
        if (message.isEmpty) {
          final m = (pData['invitationMessage'] ?? pData['message'] ?? '')
              .toString()
              .trim();
          if (m.isNotEmpty) message = m;
        }
        if (coverImage.isEmpty) {
          final cv = (pData['coverImageUrl'] ?? pData['coverPhotoUrl'] ?? '')
              .toString()
              .trim();
          if (cv.isNotEmpty) coverImage = cv;
        }
      } catch (_) {}

      // local rsvp
      final rsvp = await GuestLocalStore.loadRsvp(widget.weddingId);
      final displayName =
          await GuestLocalStore.loadDisplayName(widget.weddingId);
      final hasRsvp = await GuestLocalStore.hasRsvp(widget.weddingId);

      if (!mounted) return;
      setState(() {
        _inv = inv;
        _couplePhotoUrl = couplePhoto;
        _coverImageUrl = coverImage;
        _message = message;
        _localRsvpStatus = rsvp.status;
        _localRsvpName = rsvp.name;
        _hasRsvp = hasRsvp;
        _loading = false;
      });

      // prefill name
      final prefill = displayName ?? rsvp.name ?? '';
      if (prefill.trim().isNotEmpty) {
        _nameC.text = prefill.trim();
      }

      _setupCountdown();
      _loadDisplayNameForPrefill();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _t('invite_load_error', 'خطا در بارگذاری دعوت‌نامه',
            'Failed to load invitation');
      });
    }
  }

  Future<void> _loadDisplayNameForPrefill() async {
    try {
      final name = await GuestLocalStore.loadDisplayName(widget.weddingId);
      if (name != null && name.trim().isNotEmpty && _nameC.text.trim().isEmpty) {
        if (mounted) {
          setState(() => _nameC.text = name.trim());
        }
      }
    } catch (_) {}
  }

  void _setupCountdown() {
    _timer?.cancel();
    final inv = _inv;
    if (inv == null || inv.weddingDate == null) {
      _remaining = Duration.zero;
      return;
    }
    // parse eventTime "19:00" or "19:30:00"
    int hour = 19;
    int minute = 0;
    try {
      final t = inv.eventTime.trim();
      if (t.isNotEmpty) {
        final parts = t.split(':');
        if (parts.isNotEmpty) {
          hour = int.tryParse(parts[0].trim()) ?? 19;
          if (parts.length > 1) {
            minute = int.tryParse(parts[1].trim()) ?? 0;
          }
        }
      }
    } catch (_) {}

    final d = inv.weddingDate!;
    _targetDateTime = DateTime(d.year, d.month, d.day, hour, minute);

    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final target = _targetDateTime;
    if (target == null) return;
    final now = DateTime.now();
    var diff = target.difference(now);
    if (diff.isNegative) diff = Duration.zero;
    if (!mounted) return;
    setState(() => _remaining = diff);
  }

  String _formatDate(DateTime? d) {
    if (d == null) return _t('invite_no_message', 'تاریخ به زودی', 'Date soon');
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    if (AppLang.I.isFa) {
      return '$y / $m / $day';
    }
    return '$day / $m / $y';
  }

  String _inviteLink() {
    final slug = _inv?.normalizedSlug ?? widget.weddingId;
    return AppConfig.inviteUrl(slug);
  }

  Future<void> _shareInvite() async {
    final link = _inviteLink();
    final inv = _inv;
    final title = inv?.coupleTitle ?? '';
    final text = inv?.shareText ?? '';
    final shareText = text.contains(link) ? text : '$title\n$link';
    try {
      await Share.share(shareText, subject: title);
    } catch (_) {
      if (!mounted) return;
      await Clipboard.setData(ClipboardData(text: link));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('invite_copy_link', 'لینک کپی شد', 'Link copied'))),
      );
    }
  }

  Future<void> _openMap() async {
    final inv = _inv;
    if (inv == null) return;
    final ok = await MapLauncher.openLocation(
      name: inv.venueName,
      address: [
        if (inv.venueAddress.trim().isNotEmpty) inv.venueAddress.trim(),
        if (inv.venueCity.trim().isNotEmpty) inv.venueCity.trim(),
      ].join(AppLang.I.isFa ? '، ' : ', '),
      lat: inv.lat,
      lng: inv.lng,
      mapUrl: inv.mapUrl.isEmpty ? null : inv.mapUrl,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLang.tr('map_open_failed'))),
      );
    }
  }

  Future<void> _submitRsvp(String status) async {
    final name = _nameC.text.trim();
    final phone = _phoneC.text.trim();
    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLang.tr('err_rsvp_name_required'))),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final isMaybe = status == 'maybe';
      final attending = status == 'yes' || isMaybe ? true : false;
      // For maybe we pass attending true but override
      // If maybe, we want pending; our service handles override
      await InvitationService.submitRsvp(
        weddingId: widget.weddingId,
        name: name,
        phone: phone,
        attending: status == 'yes' ? true : (status == 'maybe' ? true : false),
        rsvpStatusOverride: status,
      );
      await GuestLocalStore.saveRsvp(
        weddingId: widget.weddingId,
        name: name,
        status: status,
      );
      await GuestLocalStore.saveDisplayName(
        weddingId: widget.weddingId,
        name: name,
      );
      if (!mounted) return;
      setState(() {
        _localRsvpStatus = status;
        _localRsvpName = name;
        _hasRsvp = true;
        _submitting = false;
      });
      final msgKey = status == 'yes'
          ? 'invite_rsvp_success_yes'
          : status == 'maybe'
              ? 'invite_rsvp_success_maybe'
              : 'invite_rsvp_success_no';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLang.tr(msgKey))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLang.tr('save_error')}: $e')),
      );
    }
  }

  void _goToGuestPanel() {
    if (widget.onOpenGuestPanel != null) {
      widget.onOpenGuestPanel!.call();
      return;
    }
    final inv = _inv;
    if (inv == null) return;
    if (widget.previewMode) {
      // in preview, still open portal shell
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GuestPortalShell(
            weddingId: widget.weddingId,
            invitation: inv,
            onLeavePortal: () => Navigator.pop(context),
          ),
        ),
      );
      return;
    }
    // normal: push portal shell
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuestPortalShell(
          weddingId: widget.weddingId,
          invitation: inv,
          onLeavePortal: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppLang.I,
        AppThemeController.I,
        AppEffectController.I,
      ]),
      builder: (context, _) {
        // force light elegant even if dark mode, except effect wash
        // we use light palette tokens for card backgrounds
        return Directionality(
          textDirection: AppLang.I.direction,
          child: EffectBackgroundStack(
            opacity: 0.9,
            enableBlur: false,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: _buildAppBar(context),
              body: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppPalette.accent,
                      ),
                    )
                  : _error != null
                      ? _buildError(context)
                      : _buildBody(context),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = AppTok.isDark(context);
    // Glass AppBar: light glass even in dark for public invite elegance
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: widget.allowPop
          ? IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: Icon(
                AppLang.I.isFa ? Icons.arrow_forward : Icons.arrow_back,
                color: _currentPage == 0 ? Colors.white : AppPalette.text,
              ),
            )
          : null,
      title: PageGlass(
        opacity: 0.78,
        blurSigma: 12,
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded,
                size: 16, color: AppPalette.accent),
            const SizedBox(width: 6),
            Text(
              _inv?.coupleTitle ?? AppLang.tr('invite_5phone_title'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppPalette.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: AppLang.tr('invite_share'),
          onPressed: _shareInvite,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppPalette.legacyGold.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.ios_share,
                size: 18, color: AppPalette.text),
          ),
        ),
        const SizedBox(width: 6),
      ],
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: (isDark
                    ? Colors.black.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.68))
                .withValues(alpha: 0.72),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PageGlass(
          opacity: 0.88,
          borderRadius: 20,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off, size: 36, color: AppPalette.danger),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppPalette.text),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _bootstrap();
                },
                icon: const Icon(Icons.refresh),
                label: Text(AppLang.tr('retry')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final inv = _inv!;
    final link = _inviteLink();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          children: [
            // page indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  PageGlass(
                    opacity: 0.82,
                    borderRadius: 20,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLang.tr(
                              'invite_page_${_currentPage + 1}_of_5'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.textSoft,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(5, (i) {
                            final active = i == _currentPage;
                            return Container(
                              width: active ? 18 : 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppPalette.accent
                                    : AppPalette.ringTrack,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (_currentPage < 4)
                    PageGlass(
                      opacity: 0.78,
                      borderRadius: 20,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLang.tr('invite_swipe_hint'),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppPalette.textSoft,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            AppLang.I.isFa
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            size: 14,
                            color: AppPalette.textSoft,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildPhone1(context, inv),
                  _buildPhone2(context, inv),
                  _buildPhone3(context, inv),
                  _buildPhone4(context, inv),
                  _buildPhone5(context, inv, link),
                ],
              ),
            ),
            // bottom glass bar with guest panel button (single primary)
            if (widget.showGuestPanelButton || !widget.previewMode)
              _buildBottomGuestBar(context, link),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Phone 1: dark cinematic cover
  Widget _buildPhone1(BuildContext context, InvitationModel inv) {
    final hasCover = _coverImageUrl.trim().isNotEmpty;
    final groom = inv.groomName.trim().isEmpty
        ? AppLang.tr('groom')
        : inv.groomName.trim();
    final bride = inv.brideName.trim().isEmpty
        ? AppLang.tr('bride')
        : inv.brideName.trim();
    final dateStr = _formatDate(inv.weddingDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // background
            Positioned.fill(
              child: hasCover
                  ? Image.network(
                      _coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildCoverGradient(),
                    )
                  : _buildCoverGradient(),
            ),
            // dark cinematic overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: hasCover ? 0.18 : 0.05),
                      Colors.black.withValues(alpha: hasCover ? 0.55 : 0.25),
                      Colors.black.withValues(alpha: hasCover ? 0.78 : 0.35),
                    ],
                  ),
                ),
              ),
            ),
            if (!hasCover)
              const Positioned.fill(
                child: FloralDecor(intensity: 0.9, frameMode: false),
              ),
            // content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  children: [
                    // top share hint (optional)
                    Align(
                      alignment: Alignment.topRight,
                      child: PageGlass(
                        opacity: 0.72,
                        blurSigma: 10,
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.link_rounded,
                                size: 12, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              AppLang.tr('invite_share_link'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AppLang.tr('invite_you_are_invited'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 11,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLang.tr('invite_wedding_of'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 10,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      groom,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        color: Color(0xFFE8C9A8),
                        fontSize: 36,
                        height: 1.05,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '&',
                      style: TextStyle(
                        fontFamily: 'serif',
                        color: const Color(0xFFE8C9A8).withValues(alpha: 0.9),
                        fontSize: 22,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bride,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        color: Color(0xFFE8C9A8),
                        fontSize: 36,
                        height: 1.05,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 60,
                      height: 1,
                      color: const Color(0xFFE8C9A8).withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    PageGlass(
                      opacity: 0.18,
                      blurSigma: 12,
                      borderRadius: 14,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      borderColor:
                          const Color(0xFFE8C9A8).withValues(alpha: 0.35),
                      child: Text(
                        dateStr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // bottom pill ورود به دعوت
                    InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFD4AF8C)
                                .withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLang.tr('invite_enter_invite'),
                              style: const TextStyle(
                                color: Color(0xFF2F2B28),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5F7F62),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppLang.tr('invite_swipe_hint'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF7F1E6),
            Color(0xFFD8E5D6),
            Color(0xFFF0DDD7),
            Color(0xFF5F7F62),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: CustomPaint(
                painter: _OrnamentPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Phone 2: floral photo card
  Widget _buildPhone2(BuildContext context, InvitationModel inv) {
    final msg = _message.trim().isNotEmpty
        ? _message.trim()
        : inv.message.trim().isNotEmpty
            ? inv.message.trim()
            : AppLang.tr('invite_message_fallback');
    final hasCouplePhoto = _couplePhotoUrl.trim().isNotEmpty ||
        inv.couplePhotoUrl.trim().isNotEmpty;
    final photoUrl = _couplePhotoUrl.trim().isNotEmpty
        ? _couplePhotoUrl.trim()
        : inv.couplePhotoUrl.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: PageGlass(
        opacity: 0.86,
        blurSigma: 12,
        borderRadius: 28,
        padding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            const Positioned.fill(
              child: FloralDecor(intensity: 1.1, frameMode: true),
            ),
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF4).withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF5F7F62).withValues(alpha: 0.14),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
              child: Column(
                children: [
                  // floral frame hint
                  PageGlass(
                    opacity: 0.78,
                    borderRadius: 10,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_outlined,
                            size: 12, color: AppPalette.accent),
                        const SizedBox(width: 4),
                        Text(
                          AppLang.tr('invite_floral_frame_hint'),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppPalette.textSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // couple photo
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color:
                            const Color(0xFFD4AF8C).withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(23),
                      child: hasCouplePhoto
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildFloralPlaceholder(),
                            )
                          : _buildFloralPlaceholder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    inv.coupleTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      color: AppPalette.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 1,
                    color: AppPalette.accent.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        msg,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppPalette.text,
                          fontSize: 13.5,
                          height: 1.7,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                    ),
                    child: PageGlass(
                      opacity: 0.88,
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLang.tr('invite_until_special_day'),
                            style: const TextStyle(
                              color: AppPalette.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 16, color: AppPalette.accent),
                        ],
                      ),
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

  Widget _buildFloralPlaceholder() {
    return Container(
      color: const Color(0xFFF0DDD7),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const FloralDecor(intensity: 1.2, frameMode: false),
          Center(
            child: Icon(Icons.favorite,
                color: AppPalette.accent.withValues(alpha: 0.4), size: 48),
          ),
        ],
      ),
    );
  }

  // Phone 3: countdown + time & place
  Widget _buildPhone3(BuildContext context, InvitationModel inv) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: PageGlass(
        opacity: 0.88,
        blurSigma: 12,
        borderRadius: 28,
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          children: [
            Text(
              AppLang.tr('invite_until_special_day'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppPalette.accent,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 16),
            // countdown LTR digits
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  _countBox('$days', 'D'),
                  const SizedBox(width: 8),
                  _countBox('$hours', 'H'),
                  const SizedBox(width: 8),
                  _countBox('$minutes', 'M'),
                  const SizedBox(width: 8),
                  _countBox('$seconds', 'S'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 1,
              color: AppPalette.border.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                AppLang.tr('invite_time_place'),
                style: const TextStyle(
                  color: AppPalette.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _infoRow(
              icon: Icons.calendar_today_outlined,
              label: AppLang.tr('invite_date_label'),
              value: _formatDate(inv.weddingDate),
            ),
            const SizedBox(height: 10),
            _infoRow(
              icon: Icons.access_time_rounded,
              label: AppLang.tr('invite_time_label'),
              value: inv.eventTime,
            ),
            const SizedBox(height: 10),
            _infoRow(
              icon: Icons.location_on_outlined,
              label: AppLang.tr('invite_venue_label'),
              value: inv.venueName.trim().isEmpty
                  ? AppLang.tr('invite_no_venue')
                  : inv.venueName.trim(),
            ),
            if (inv.venueCity.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _infoRow(
                icon: Icons.location_city_outlined,
                label: AppLang.tr('invite_city_label'),
                value: inv.venueCity,
              ),
            ],
            if (inv.venueAddress.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _infoRow(
                icon: Icons.map_outlined,
                label: AppLang.tr('invite_address_label'),
                value: inv.venueAddress,
                maxLines: 3,
              ),
            ],
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
              ),
              child: PageGlass(
                opacity: 0.84,
                borderRadius: 16,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLang.tr('invite_navigate_map'),
                      style: const TextStyle(
                        color: AppPalette.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 16, color: AppPalette.accent),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countBox(String value, String unit) {
    return Expanded(
      child: PageGlass(
        opacity: 0.92,
        blurSigma: 10,
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppPalette.text,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                fontFeatures: [ui.FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              unit,
              style: const TextStyle(
                color: AppPalette.textSoft,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppPalette.cardSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppPalette.border),
          ),
          child: Icon(icon, size: 18, color: AppPalette.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppPalette.textSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppPalette.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Phone 4: map
  Widget _buildPhone4(BuildContext context, InvitationModel inv) {
    final hasVenue = inv.venueName.trim().isNotEmpty ||
        inv.venueAddress.trim().isNotEmpty ||
        inv.hasGeo;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: PageGlass(
        opacity: 0.88,
        blurSigma: 12,
        borderRadius: 28,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppPalette.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.map_outlined,
                      color: AppPalette.accent, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLang.tr('invite_time_place'),
                        style: const TextStyle(
                          color: AppPalette.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        hasVenue
                            ? (inv.venueName.trim().isEmpty
                                ? inv.venueCity
                                : inv.venueName)
                            : AppLang.tr('invite_no_venue'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppPalette.textSoft,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // large map preview
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // map placeholder gradient
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFEEF3EA),
                              Color(0xFFF7F1E6),
                              Color(0xFFD8E5D6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // grid lines
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _MapGridPainter(),
                      ),
                    ),
                    // pin
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppPalette.accent
                                    .withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.location_on,
                                color: AppPalette.accent, size: 28),
                          ),
                          const SizedBox(height: 8),
                          PageGlass(
                            opacity: 0.92,
                            borderRadius: 12,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Text(
                              inv.venueName.trim().isEmpty
                                  ? AppLang.tr('invite_no_venue')
                                  : inv.venueName.trim(),
                              style: const TextStyle(
                                color: AppPalette.text,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (inv.venueAddress.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            PageGlass(
                              opacity: 0.86,
                              borderRadius: 10,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              child: Text(
                                inv.venueAddress.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppPalette.textSoft,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // lat/lng badge
                    if (inv.hasGeo)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: PageGlass(
                          opacity: 0.84,
                          borderRadius: 10,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                            child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              '${inv.lat!.toStringAsFixed(4)}, ${inv.lng!.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppPalette.textSoft,
                                fontFeatures: [
                                  ui.FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _openMap,
                icon: const Icon(Icons.navigation_rounded, size: 20),
                label: Text(
                  AppLang.tr('invite_navigate_map'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
              ),
              child: PageGlass(
                opacity: 0.82,
                borderRadius: 14,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLang.tr('invite_rsvp_honor_title'),
                      style: const TextStyle(
                        color: AppPalette.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 16, color: AppPalette.accent),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Phone 5: RSVP + share + QR + guest button
  Widget _buildPhone5(
      BuildContext context, InvitationModel inv, String link) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: PageGlass(
        opacity: 0.88,
        blurSigma: 12,
        borderRadius: 28,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // honor title
              Text(
                AppLang.tr('invite_rsvp_honor_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppPalette.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLang.tr('invite_rsvp_honor_sub'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppPalette.textSoft,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              // name + phone
              TextField(
                controller: _nameC,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppPalette.text),
                decoration: InputDecoration(
                  hintText: AppLang.tr('invite_rsvp_name_hint'),
                  hintStyle:
                      const TextStyle(color: AppPalette.textSoft),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppPalette.border.withValues(alpha: 0.9),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppPalette.border.withValues(alpha: 0.9),
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneC,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppPalette.text),
                decoration: InputDecoration(
                  hintText: AppLang.tr('invite_rsvp_phone_hint'),
                  hintStyle:
                      const TextStyle(color: AppPalette.textSoft),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppPalette.border.withValues(alpha: 0.9),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppPalette.border.withValues(alpha: 0.9),
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 14),
              if (_hasRsvp && _localRsvpStatus != null)
                PageGlass(
                  opacity: 0.92,
                  borderRadius: 14,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        _localRsvpStatus == 'yes'
                            ? Icons.check_circle_rounded
                            : _localRsvpStatus == 'maybe'
                                ? Icons.help_rounded
                                : Icons.cancel_rounded,
                        color: _localRsvpStatus == 'yes'
                            ? AppPalette.accent
                            : _localRsvpStatus == 'maybe'
                                ? const Color(0xFFD4AF8C)
                                : AppPalette.textSoft,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${AppLang.tr('invite_rsvp_already')}: ${_localRsvpName ?? ''} (${_localRsvpStatus})',
                          style: const TextStyle(
                            color: AppPalette.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_hasRsvp && _localRsvpStatus != null)
                const SizedBox(height: 12),
              // 3 pills
              Row(
                children: [
                  Expanded(
                    child: _rsvpPill(
                      label: AppLang.tr('invite_rsvp_yes'),
                      icon: Icons.favorite_rounded,
                      color: AppPalette.accent,
                      status: 'yes',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _rsvpPill(
                      label: AppLang.tr('invite_rsvp_no'),
                      icon: Icons.close_rounded,
                      color: AppPalette.textSoft,
                      status: 'no',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _rsvpPill(
                      label: AppLang.tr('invite_rsvp_maybe'),
                      icon: Icons.help_outline_rounded,
                      color: const Color(0xFFD4AF8C),
                      status: 'maybe',
                    ),
                  ),
                ],
              ),
              if (_localRsvpStatus == 'maybe' || true)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    AppLang.tr('invite_rsvp_maybe_hint'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppPalette.textSoft,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Container(
                height: 1,
                color: AppPalette.border.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              // share + qr
              Text(
                AppLang.tr('invite_share_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppPalette.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              PageGlass(
                opacity: 0.92,
                borderRadius: 14,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              link,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppPalette.textSoft,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            await Clipboard.setData(
                                ClipboardData(text: link));
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text(AppLang.tr('invite_copy_link')),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppPalette.cardSoft,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppPalette.border),
                            ),
                            child: const Icon(Icons.copy_rounded,
                                size: 16, color: AppPalette.textSoft),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                  ClipboardData(text: link));
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text(AppLang.tr('invite_copy_link')),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: Text(AppLang.tr('invite_copy_link')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppPalette.accent,
                              side: BorderSide(color: AppPalette.accent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size.fromHeight(42),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _shareInvite,
                            icon: const Icon(Icons.ios_share, size: 16),
                            label: Text(AppLang.tr('invite_share')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPalette.accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size.fromHeight(42),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // QR
              Center(
                child: PageGlass(
                  opacity: 0.96,
                  borderRadius: 18,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      QrImageView(
                        data: link,
                        version: QrVersions.auto,
                        size: 132,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF3E5A43),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF2F2B28),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLang.tr('invite_qr_hint'),
                        style: const TextStyle(
                          color: AppPalette.textSoft,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // SINGLE primary guest panel button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _goToGuestPanel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.groups_2_rounded, size: 20),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLang.tr('invite_enter_guest_panel'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            AppLang.tr('invite_enter_guest_panel_sub'),
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLang.tr('invite_scan_to_rsvp'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppPalette.textSoft,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rsvpPill({
    required String label,
    required IconData icon,
    required Color color,
    required String status,
  }) {
    final selected = _localRsvpStatus == status;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _submitting ? null : () => _submitRsvp(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppPalette.border,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppPalette.text,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
            if (_submitting && _localRsvpStatus == null)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomGuestBar(BuildContext context, String link) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: PageGlass(
        opacity: 0.82,
        blurSigma: 14,
        borderRadius: 18,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppPalette.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.groups_2_rounded,
                  color: AppPalette.accent, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLang.tr('invite_enter_guest_panel'),
                    style: const TextStyle(
                      color: AppPalette.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  Text(
                    AppLang.tr('invite_enter_guest_panel_sub'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppPalette.textSoft,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: _goToGuestPanel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: Text(
                  AppLang.tr('invite_enter_guest_panel'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrnamentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF5F7F62).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.2);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.25,
    );
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.4,
      size.width * 0.9,
      size.height * 0.3,
    );
    canvas.drawPath(path, p);

    final p2 = Paint()
      ..color = const Color(0xFFD4AF8C).withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path2 = Path();
    path2.moveTo(size.width * 0.15, size.height * 0.75);
    path2.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.65,
      size.width * 0.55,
      size.height * 0.78,
    );
    path2.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.9,
      size.width * 0.85,
      size.height * 0.8,
    );
    canvas.drawPath(path2, p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF5F7F62).withValues(alpha: 0.10)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }

    final road = Paint()
      ..color = const Color(0xFFF0DDD7).withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height * 0.55);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.5,
      size.width * 0.6,
      size.height * 0.58,
    );
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.62,
      size.width,
      size.height * 0.55,
    );
    canvas.drawPath(path, road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
