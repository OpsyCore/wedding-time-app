import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'guest_portal/guest_portal_shell.dart';

/// Public invite — one light floral glass card.
/// Background effects show through the frosted card.
/// RSVP stays on the card; guest panel is a manual CTA only.
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
  static const Color _rsvpYes = Color(0xFF2E7D32);
  static const Color _rsvpMaybe = Color(0xFFF9A825);
  static const Color _rsvpNo = Color(0xFFC62828);

  InvitationModel? _inv;
  bool _loading = true;
  String? _error;

  String _bridePhotoUrl = '';
  String _groomPhotoUrl = '';
  String _message = '';

  Timer? _timer;
  Duration _remaining = Duration.zero;
  DateTime? _targetDateTime;

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

      if (inv == null) {
        final snap = await FirebaseFirestore.instance
            .collection('weddings')
            .doc(widget.weddingId)
            .collection('invitation')
            .doc('main')
            .get();
        final data = snap.data();
        if (data != null) {
          inv = InvitationModel.fromMap(Map<String, dynamic>.from(data));
        }
      }

      if (inv == null) {
        if (!mounted) return;
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

      String bridePhoto = '';
      String groomPhoto = '';
      String message = inv.message.trim();

      try {
        final weddingDoc = await FirebaseFirestore.instance
            .collection('weddings')
            .doc(widget.weddingId)
            .get();
        final wData = weddingDoc.data() ?? {};
        final brideCandidates = [
          wData['bridePhotoUrl'],
          wData['bridePhoto'],
          wData['brideImage'],
          wData['brideAvatar'],
        ];
        for (final c in brideCandidates) {
          final s = (c ?? '').toString().trim();
          if (s.isNotEmpty && bridePhoto.isEmpty) bridePhoto = s;
        }
        final groomCandidates = [
          wData['groomPhotoUrl'],
          wData['groomPhoto'],
          wData['groomImage'],
          wData['groomAvatar'],
        ];
        for (final c in groomCandidates) {
          final s = (c ?? '').toString().trim();
          if (s.isNotEmpty && groomPhoto.isEmpty) groomPhoto = s;
        }
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
        final pData = profileDoc.data() ?? {};
        if (message.isEmpty) {
          final m = (pData['invitationMessage'] ?? pData['message'] ?? '')
              .toString()
              .trim();
          if (m.isNotEmpty) message = m;
        }
        if (bridePhoto.isEmpty) {
          final bp = (pData['bridePhotoUrl'] ?? pData['bridePhoto'] ?? '')
              .toString()
              .trim();
          if (bp.isNotEmpty) bridePhoto = bp;
        }
        if (groomPhoto.isEmpty) {
          final gp = (pData['groomPhotoUrl'] ?? pData['groomPhoto'] ?? '')
              .toString()
              .trim();
          if (gp.isNotEmpty) groomPhoto = gp;
        }
      } catch (_) {}

      final rsvp = await GuestLocalStore.loadRsvp(widget.weddingId);
      final displayName =
          await GuestLocalStore.loadDisplayName(widget.weddingId);
      final hasRsvp = await GuestLocalStore.hasRsvp(widget.weddingId);

      if (!mounted) return;
      setState(() {
        _inv = inv;
        _bridePhotoUrl = bridePhoto;
        _groomPhotoUrl = groomPhoto;
        _message = message;
        _localRsvpStatus = rsvp.status;
        _localRsvpName = rsvp.name;
        _hasRsvp = hasRsvp;
        _loading = false;
      });

      final prefill = displayName ?? rsvp.name ?? '';
      if (prefill.trim().isNotEmpty) {
        _nameC.text = prefill.trim();
      }

      _setupCountdown();
      _loadDisplayNameForPrefill();
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

  Future<void> _loadDisplayNameForPrefill() async {
    try {
      final name = await GuestLocalStore.loadDisplayName(widget.weddingId);
      if (name != null &&
          name.trim().isNotEmpty &&
          _nameC.text.trim().isEmpty) {
        if (!mounted) return;
        setState(() => _nameC.text = name.trim());
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
    if (d == null) {
      return _t('invite_no_message', 'تاریخ به زودی', 'Date soon');
    }
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    if (AppLang.I.isFa) return '$y / $m / $day';
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('invite_copy_link', 'لینک کپی شد', 'Link copied')),
        ),
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
      await InvitationService.submitRsvp(
        weddingId: widget.weddingId,
        name: name,
        phone: phone,
        attending: status == 'yes' || status == 'maybe',
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

  bool get _showGuestCta =>
      widget.showGuestPanelButton || widget.previewMode;

  bool get _hasDualPortraits =>
      _bridePhotoUrl.trim().isNotEmpty && _groomPhotoUrl.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppLang.I,
        AppThemeController.I,
        AppEffectController.I,
      ]),
      builder: (context, _) {
        return Directionality(
          textDirection: AppLang.I.direction,
          child: EffectBackgroundStack(
            opacity: 0.95,
            enableBlur: false,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true,
              appBar: _buildAppBar(),
              body: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppPalette.accent,
                      ),
                    )
                  : _error != null
                      ? _buildError()
                      : _buildBody(),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: widget.allowPop
          ? IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: Icon(
                AppLang.I.isFa ? Icons.arrow_forward : Icons.arrow_back,
                color: AppPalette.text,
              ),
            )
          : null,
      title: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: _InviteGlass(
          opacity: 0.72,
          borderRadius: 12,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            _inv?.coupleTitle ?? AppLang.tr('digital_invitation'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppPalette.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: AppLang.tr('invite_share'),
          onPressed: _shareInvite,
          icon: _InviteGlass(
            opacity: 0.78,
            borderRadius: 10,
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.ios_share,
              size: 18,
              color: AppPalette.text,
            ),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _InviteGlass(
          opacity: 0.82,
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

  Widget _buildBody() {
    final inv = _inv!;
    final groom = inv.groomName.trim().isEmpty
        ? AppLang.tr('groom')
        : inv.groomName.trim();
    final bride = inv.brideName.trim().isEmpty
        ? AppLang.tr('bride')
        : inv.brideName.trim();
    final msg = _message.trim().isNotEmpty
        ? _message.trim()
        : inv.message.trim().isNotEmpty
            ? inv.message.trim()
            : AppLang.tr('invite_message_fallback');
    final venue = inv.venueName.trim();
    final city = inv.venueCity.trim();
    final address = inv.venueAddress.trim();
    final hasVenue = venue.isNotEmpty || city.isNotEmpty || address.isNotEmpty;
    final tagline = msg.trim();

    return LayoutBuilder(
      builder: (context, viewport) {
        final isMobile = viewport.maxWidth < 600;
        final pagePadding = EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 20,
          vertical: isMobile ? 0 : 16,
        );
        final panelMinHeight = isMobile
            ? viewport.maxHeight
            : (viewport.maxHeight - pagePadding.vertical)
                .clamp(0.0, double.infinity)
                .toDouble();
        final contentTop =
            MediaQuery.of(context).padding.top + kToolbarHeight + 14;
        final widthConstraint = isMobile
            ? const BoxConstraints()
            : const BoxConstraints(maxWidth: 640);

        return SingleChildScrollView(
          padding: pagePadding,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: widthConstraint,
              child: SizedBox(
                width: double.infinity,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: panelMinHeight),
                  child: Theme(
                    data: AppTheme.light(),
                    child: _InviteGlass(
                      opacity: 0.86,
                      blurSigma: 16,
                      borderRadius: isMobile ? 18 : 28,
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: FloralDecor(
                              intensity: 0.85,
                              frameMode: true,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              isMobile ? 14 : 20,
                              contentTop,
                              isMobile ? 14 : 20,
                              20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeroPhoto(groom: groom, bride: bride),
                                const SizedBox(height: 10),
                                _buildCoupleNames(groom, bride),
                                if (tagline.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    tagline,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppPalette.textSoft,
                                      fontSize: 13.5,
                                      height: 1.6,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 18),
                                _buildCountdownOrDate(inv),
                                const SizedBox(height: 16),
                                _buildPlaceBlock(
                                  inv,
                                  hasVenue,
                                  venue,
                                  city,
                                  address,
                                ),
                                if (inv.showRsvp) ...[
                                  const SizedBox(height: 20),
                                  _buildRsvpBlock(),
                                ],
                                if (_showGuestCta) ...[
                                  const SizedBox(height: 20),
                                  _buildGuestCta(),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoupleNames(String groom, String bride) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '$groom${AppLang.tr('couple_name_joiner')}$bride',
        maxLines: 1,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'serif',
          color: AppPalette.text,
          fontSize: 27,
          height: 1.15,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildHeroPhoto({required String groom, required String bride}) {
    if (_hasDualPortraits) return _dualPortraits(groom, bride);
    return _initialsPair(groom, bride);
  }

  Widget _dualPortraits(String groom, String bride) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _portraitTile(_groomPhotoUrl, _initialOf(groom)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.brandBlushSoft.withValues(alpha: 0.85),
              border: Border.all(
                color: AppPalette.legacyGold.withValues(alpha: 0.55),
              ),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 16,
              color: AppPalette.accentSoft,
            ),
          ),
        ),
        _portraitTile(_bridePhotoUrl, _initialOf(bride)),
      ],
    );
  }

  Widget _portraitTile(String url, String initial) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 118,
        height: 148,
        child: url.trim().isEmpty
            ? _initialsBox(initial)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsBox(initial),
              ),
      ),
    );
  }

  Widget _initialsPair(String groom, String bride) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _initialsCircle(_initialOf(groom)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.favorite_rounded,
            size: 18,
            color: AppPalette.accentSoft.withValues(alpha: 0.9),
          ),
        ),
        _initialsCircle(_initialOf(bride)),
      ],
    );
  }

  Widget _initialsCircle(String initial) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppPalette.brandIvory,
            AppPalette.brandGreenSoft,
            AppPalette.brandBlushSoft,
          ],
        ),
        border: Border.all(
          color: AppPalette.legacyGold.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontFamily: 'serif',
            color: AppPalette.text,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _initialsBox(String initial) {
    return Container(
      color: AppPalette.brandBlushSoft.withValues(alpha: 0.7),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontFamily: 'serif',
            color: AppPalette.text,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _initialOf(String name) {
    final t = name.trim();
    if (t.isEmpty) return '♥';
    return String.fromCharCode(t.runes.first);
  }

  Widget _buildCountdownOrDate(InvitationModel inv) {
    final hasDate = inv.weddingDate != null;
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;
    final isPast = hasDate && _remaining == Duration.zero;

    return Column(
      children: [
        Text(
          AppLang.tr('invite_until_special_day'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppPalette.accent,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 12),
        if (hasDate && !isPast)
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                _countBox('$days', AppLang.tr('day')),
                const SizedBox(width: 8),
                _countBox('$hours', AppLang.tr('hour')),
                const SizedBox(width: 8),
                _countBox('$minutes', AppLang.tr('minute')),
                const SizedBox(width: 8),
                _countBox('$seconds', AppLang.tr('second')),
              ],
            ),
          )
        else
          Text(
            hasDate
                ? AppLang.tr('guest_home_today')
                : AppLang.tr('date_not_set'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.text,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        const SizedBox(height: 12),
        Text(
          [
            _formatDate(inv.weddingDate),
            if (inv.eventTime.trim().isNotEmpty) inv.eventTime.trim(),
          ].join('  ·  '),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppPalette.textSoft,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _countBox(String value, String unit) {
    return Expanded(
      child: _InviteGlass(
        opacity: 0.78,
        blurSigma: 10,
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppPalette.text,
                fontWeight: FontWeight.w900,
                fontSize: 18,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceBlock(
    InvitationModel inv,
    bool hasVenue,
    String venue,
    String city,
    String address,
  ) {
    return Column(
      children: [
        Text(
          AppLang.tr('invite_time_place'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppPalette.text,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        _infoLine(
          Icons.location_on_outlined,
          hasVenue
              ? (venue.isEmpty ? AppLang.tr('invite_no_venue') : venue)
              : AppLang.tr('invite_no_venue'),
        ),
        if (city.isNotEmpty) ...[
          const SizedBox(height: 6),
          _infoLine(Icons.location_city_outlined, city),
        ],
        if (address.isNotEmpty) ...[
          const SizedBox(height: 6),
          _infoLine(Icons.map_outlined, address),
        ],
        if (hasVenue || inv.hasGeo || inv.mapUrl.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _openMap,
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: Text(AppLang.tr('invite_navigate_map')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.accentDeep,
                side: BorderSide(
                  color: AppPalette.accent.withValues(alpha: 0.45),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoLine(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppPalette.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: AppPalette.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRsvpBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLang.tr('invite_rsvp_honor_title'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppPalette.text,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLang.tr('invite_rsvp_honor_sub'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppPalette.textSoft,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _nameC,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppPalette.text),
          decoration: _fieldDecoration(AppLang.tr('invite_rsvp_name_hint')),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneC,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: AppPalette.text),
          decoration: _fieldDecoration(AppLang.tr('invite_rsvp_phone_hint')),
        ),
        if (_hasRsvp && _localRsvpStatus != null) ...[
          const SizedBox(height: 12),
          _InviteGlass(
            opacity: 0.80,
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
                      ? _rsvpYes
                      : _localRsvpStatus == 'maybe'
                          ? _rsvpMaybe
                          : _rsvpNo,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppLang.tr('invite_rsvp_already')}: ${_localRsvpName ?? ''}',
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
        ],
        const SizedBox(height: 14),
        _rsvpButton(
          status: 'yes',
          label: AppLang.tr('invite_rsvp_yes'),
          color: _rsvpYes,
        ),
        const SizedBox(height: 8),
        _rsvpButton(
          status: 'maybe',
          label: AppLang.tr('invite_rsvp_maybe'),
          color: _rsvpMaybe,
        ),
        const SizedBox(height: 8),
        _rsvpButton(
          status: 'no',
          label: AppLang.tr('invite_rsvp_no'),
          color: _rsvpNo,
        ),
        if (_submitting) ...[
          const SizedBox(height: 10),
          const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppPalette.accent,
              ),
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppPalette.textSoft),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.72),
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppPalette.accent, width: 1.3),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _rsvpButton({
    required String status,
    required String label,
    required Color color,
  }) {
    final selected = _localRsvpStatus == status;
    final background = selected
        ? Color.lerp(color, Colors.black, 0.18)!
        : color;
    final borderColor = Color.lerp(
      color,
      Colors.black,
      selected ? 0.42 : 0.24,
    )!;
    final foreground = status == 'maybe'
        ? const Color(0xFF332400)
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _submitting ? null : () => _submitRsvp(status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1.25,
            ),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestCta() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _goToGuestPanel,
        child: _InviteGlass(
          opacity: 0.78,
          blurSigma: 12,
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          tint: AppPalette.brandGreenSoft,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLang.tr('invite_enter_guest_panel'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppPalette.accentDeep,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                Text(
                  AppLang.tr('invite_enter_guest_panel_sub'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: AppPalette.textSoft.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Always-light cream/sage/blush glass so floral invite stays on-brand.
class _InviteGlass extends StatelessWidget {
  const _InviteGlass({
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.blurSigma = 14,
    this.opacity = 0.72,
    this.tint,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final double opacity;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final cream = Color.lerp(
      AppPalette.brandIvory,
      AppPalette.brandCream,
      0.28,
    )!;
    final base = tint == null ? cream : Color.lerp(cream, tint, 0.22)!;
    final fill = base.withValues(alpha: opacity.clamp(0.52, 0.86));
    final border = Color.lerp(
      AppPalette.brandGreenSoft,
      AppPalette.legacyGold,
      0.38,
    )!.withValues(alpha: 0.72);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppPalette.brandGreenDeep.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppPalette.legacyGold.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (!kIsWeb) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: content,
        ),
      );
    }

    return content;
  }
}
