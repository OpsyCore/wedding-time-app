import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_config.dart';
import '../core/app_date_picker.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../core/map_launcher.dart';
import '../models/invitation_model.dart';
import '../services/invitation_service.dart';
import '../services/weather_service.dart';
import '../widgets/city_picker_sheet.dart';
import '../widgets/floral_decor.dart';
import 'guest_portal/guest_auth_gate.dart';
import 'public_invite_screen.dart';
import 'rsvp_inbox_screen.dart';

class InvitationScreen extends StatefulWidget {
  final String weddingId;

  const InvitationScreen({super.key, required this.weddingId});

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _saving = false;
  bool _savingRsvpToggle = false;
  bool _loaded = false;

  final _coverTitleC = TextEditingController();
  final _brideC = TextEditingController();
  final _groomC = TextEditingController();
  final _timeC = TextEditingController();
  final _venueNameC = TextEditingController();
  final _venueAddressC = TextEditingController();
  final _mapUrlC = TextEditingController();
  final _slugC = TextEditingController();

  DateTime? _weddingDate;
  bool _showRsvp = true;
  List<ScheduleItem> _schedule = [];

  String _venueCity = '';
  double? _lat;
  double? _lng;

  WeatherSnapshot? _weather;
  bool _weatherLoading = false;

  DocumentReference get inviteRef => FirebaseFirestore.instance
      .collection('weddings')
      .doc(widget.weddingId)
      .collection('invitation')
      .doc('main');

  DocumentReference get weddingRef =>
      FirebaseFirestore.instance.collection('weddings').doc(widget.weddingId);

  static const _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  String fa(String input) {
    if (!AppLang.I.isFa) return input;
    return input.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? _faDigits[i] : c;
    }).join();
  }

  String _t(String key, String faTxt, String enTxt) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? faTxt : enTxt;
    return v;
  }

  /// همیشه لینک پورتال مهمان همان عروسی — نه ریشه سایت
  String get _guestPortalUrl {
    final raw = _slugC.text.trim().isEmpty
        ? (_buildSlug(_groomC.text, _brideC.text))
        : _slugC.text.trim();
    final slug = raw.trim().toLowerCase().isEmpty
        ? widget.weddingId.trim().toLowerCase()
        : raw.trim().toLowerCase();
    return AppConfig.inviteUrl(slug);
  }

  String get _guestPortalSlug {
    final raw = _slugC.text.trim().isEmpty
        ? (_buildSlug(_groomC.text, _brideC.text))
        : _slugC.text.trim();
    final slug = raw.trim().toLowerCase().isEmpty
        ? widget.weddingId.trim().toLowerCase()
        : raw.trim().toLowerCase();
    return slug;
  }

  /// متن اشتراک با لینک پورتال مهمان
  String _guestShareText(InvitationModel model) {
    final date = model.weddingDate == null
        ? ''
        : '${model.weddingDate!.year}/${model.weddingDate!.month.toString().padLeft(2, '0')}/${model.weddingDate!.day.toString().padLeft(2, '0')}';

    final portal = AppConfig.inviteUrl(model.normalizedSlug);
    final buf = StringBuffer();
    buf.writeln(
      _t(
        'share_guest_portal_header',
        'لینک پورتال مهمان عروسی',
        'Wedding guest portal link',
      ),
    );
    buf.writeln(model.coupleTitle);
    if (date.isNotEmpty) {
      buf.writeln('${AppLang.tr('share_date_line')}$date');
    }
    if (model.eventTime.trim().isNotEmpty) {
      buf.writeln('${AppLang.tr('share_time_line')}${model.eventTime.trim()}');
    }
    if (model.venueName.trim().isNotEmpty) {
      buf.writeln('📍 ${model.venueName.trim()}');
    }
    if (model.venueCity.trim().isNotEmpty) {
      buf.writeln('🏙 ${model.venueCity.trim()}');
    }
    if (model.venueAddress.trim().isNotEmpty) {
      buf.writeln(model.venueAddress.trim());
    }
    if (model.googleMapsLink.isNotEmpty) {
      buf.writeln();
      buf.writeln(AppLang.tr('share_directions_label'));
      buf.writeln(model.googleMapsLink);
    }
    buf.writeln();
    buf.writeln(
      _t(
        'share_guest_portal_link_label',
        'ورود به پورتال مهمان:',
        'Open guest portal:',
      ),
    );
    buf.writeln(portal);
    return buf.toString();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bootstrap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _coverTitleC.dispose();
    _brideC.dispose();
    _groomC.dispose();
    _timeC.dispose();
    _venueNameC.dispose();
    _venueAddressC.dispose();
    _mapUrlC.dispose();
    _slugC.dispose();
    super.dispose();
  }

  bool _parseShowRsvp(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final s = raw.trim().toLowerCase();
      if (s == 'false' || s == '0' || s == 'no') return false;
      if (s == 'true' || s == '1' || s == 'yes') return true;
    }
    return true;
  }

  Future<void> _bootstrap() async {
    final weddingSnap = await weddingRef.get();
    final wedding = weddingSnap.data() as Map<String, dynamic>? ?? {};

    final inviteSnap = await inviteRef.get();
    Map<String, dynamic> data = {};

    if (inviteSnap.exists) {
      data = Map<String, dynamic>.from(
        inviteSnap.data() as Map<String, dynamic>? ?? {},
      );
    } else {
      final bride = (wedding['brideName'] ?? '').toString();
      final groom = (wedding['groomName'] ?? '').toString();

      data = {
        'coverTitle': AppLang.tr('default_cover_title'),
        'brideName': bride,
        'groomName': groom,
        'weddingDate': wedding['weddingDate'],
        'eventTime': '19:00',
        'venueName': '',
        'venueAddress': '',
        'venueCity': '',
        'lat': null,
        'lng': null,
        'mapUrl': '',
        'slug': _buildSlug(groom, bride),
        'showRsvp': true,
        'schedule': [
          {
            'time': '18:00',
            'title': AppLang.tr('schedule_guests_arrive'),
            'icon': 'guests',
          },
          {
            'time': '18:30',
            'title': AppLang.tr('schedule_ceremony'),
            'icon': 'ring',
          },
          {
            'time': '19:30',
            'title': AppLang.tr('schedule_dinner'),
            'icon': 'dinner',
          },
          {
            'time': '20:30',
            'title': AppLang.tr('schedule_first_dance'),
            'icon': 'dance',
          },
          {
            'time': '21:30',
            'title': AppLang.tr('schedule_cake_cutting'),
            'icon': 'cake',
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await InvitationService.saveInvitation(
        weddingId: widget.weddingId,
        model: InvitationModel.fromMap(data),
      );
    }

    final model = InvitationModel.fromMap(data);

    _coverTitleC.text = model.coverTitle;
    _brideC.text = model.brideName;
    _groomC.text = model.groomName;
    _timeC.text = model.eventTime;
    _venueNameC.text = model.venueName;
    _venueAddressC.text = model.venueAddress;
    _mapUrlC.text = model.mapUrl;
    _slugC.text = model.slug.trim().isEmpty
        ? _buildSlug(model.groomName, model.brideName)
        : model.slug;
    _weddingDate = model.weddingDate;

    if (data.containsKey('showRsvp')) {
      _showRsvp = _parseShowRsvp(data['showRsvp']);
    } else if (wedding.containsKey('showRsvp')) {
      _showRsvp = _parseShowRsvp(wedding['showRsvp']);
    } else {
      _showRsvp = model.showRsvp;
    }

    _schedule = List<ScheduleItem>.from(model.schedule);
    _venueCity = model.venueCity;
    _lat = model.lat;
    _lng = model.lng;

    // ایندکس slug برای /invite/:slug
    final slug = _guestPortalSlug;
    await weddingRef.set({
      'inviteSlug': slug,
      'showRsvp': _showRsvp,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await FirebaseFirestore.instance.collection('public_slugs').doc(slug).set({
        'weddingId': widget.weddingId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}

    if (!mounted) return;
    setState(() => _loaded = true);
    await _loadWeather();
  }

  Future<void> _loadWeather() async {
    if (_lat == null || _lng == null) {
      if (!mounted) return;
      setState(() {
        _weather = null;
        _weatherLoading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _weatherLoading = true);
    try {
      final w = await WeatherService.fetch(lat: _lat!, lng: _lng!);
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
      });
    }
  }

  String _buildSlug(String groom, String bride) {
    String clean(String s) => s
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF\-]+'), '');

    final g = clean(groom);
    final b = clean(bride);

    if (g.isEmpty && b.isEmpty) return widget.weddingId.toLowerCase();
    if (g.isEmpty) return b;
    if (b.isEmpty) return g;
    return '$g-$b';
  }

  InvitationModel get _currentModel {
    final slug = _guestPortalSlug;
    return InvitationModel(
      coverTitle: _coverTitleC.text.trim().isEmpty
          ? AppLang.tr('default_cover_title')
          : _coverTitleC.text.trim(),
      brideName: _brideC.text.trim(),
      groomName: _groomC.text.trim(),
      weddingDate: _weddingDate,
      eventTime: _timeC.text.trim().isEmpty ? '19:00' : _timeC.text.trim(),
      venueName: _venueNameC.text.trim(),
      venueAddress: _venueAddressC.text.trim(),
      venueCity: _venueCity.trim(),
      lat: _lat,
      lng: _lng,
      mapUrl: _mapUrlC.text.trim(),
      slug: slug,
      showRsvp: _showRsvp,
      schedule: _schedule,
    );
  }

  Future<void> _onShowRsvpChanged(bool value) async {
    final previous = _showRsvp;
    setState(() {
      _showRsvp = value;
      _savingRsvpToggle = true;
    });

    try {
      await InvitationService.saveShowRsvp(
        weddingId: widget.weddingId,
        showRsvp: value,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? AppLang.tr('rsvp_shown_saved')
                : AppLang.tr('rsvp_hidden_saved'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _showRsvp = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLang.tr('rsvp_toggle_save_failed')}: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingRsvpToggle = false);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    _applyCoordsFromText();

    // اگر slug خالی بود از اسم‌ها بساز
    if (_slugC.text.trim().isEmpty) {
      _slugC.text = _buildSlug(_groomC.text, _brideC.text);
    }

    setState(() => _saving = true);
    try {
      await InvitationService.saveInvitation(
        weddingId: widget.weddingId,
        model: _currentModel,
      );
      await _loadWeather();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLang.tr('invitation_saved'))),
      );
      setState(() {});
      _tabController.animateTo(0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLang.tr('save_error')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return AppLang.tr('date_not_set');

    final weekdays = AppLang.I.isFa
        ? [
            'دوشنبه',
            'سه‌شنبه',
            'چهارشنبه',
            'پنجشنبه',
            'جمعه',
            'شنبه',
            'یکشنبه',
          ]
        : [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ];

    final wd = weekdays[d.weekday - 1];
    final text =
        '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';
    return '$wd\n${fa(text)}';
  }

  String _formatDateMockup(DateTime? d) {
    if (d == null) return AppLang.tr('date_not_set');
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context,
      initialDate: _weddingDate ?? DateTime(now.year, now.month + 1, now.day),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null || !mounted) return;
    setState(() => _weddingDate = picked);
  }

  Future<void> _pickVenueCity() async {
    final picked = await CityPickerSheet.show(
      context,
      selectedCity: _venueCity.isEmpty ? null : _venueCity,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _venueCity = picked.name;
      _lat = picked.lat;
      _lng = picked.lng;
    });
    await _loadWeather();
  }

  void _applyCoordsFromText() {
    final raw = _mapUrlC.text.trim();
    if (raw.isEmpty) return;

    final direct = RegExp(r'^\s*(-?\d+(\.\d+)?)\s*,\s*(-?\d+(\.\d+)?)\s*$')
        .firstMatch(raw);
    if (direct != null) {
      _lat = double.tryParse(direct.group(1)!);
      _lng = double.tryParse(direct.group(3)!);
      return;
    }

    final at = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(raw);
    if (at != null) {
      _lat = double.tryParse(at.group(1)!);
      _lng = double.tryParse(at.group(2)!);
      return;
    }

    final q = RegExp(r'[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(raw);
    if (q != null) {
      _lat = double.tryParse(q.group(1)!);
      _lng = double.tryParse(q.group(2)!);
      return;
    }

    final query = RegExp(r'query=(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(raw);
    if (query != null) {
      _lat = double.tryParse(query.group(1)!);
      _lng = double.tryParse(query.group(2)!);
    }
  }

  Future<void> _openMaps() async {
    _applyCoordsFromText();

    final m = _currentModel;
    final ok = await MapLauncher.openLocation(
      name: m.venueName,
      address: [
        if (m.venueAddress.isNotEmpty) m.venueAddress,
        if (m.venueCity.isNotEmpty) m.venueCity,
      ].join(AppLang.I.isFa ? '، ' : ', '),
      lat: m.lat,
      lng: m.lng,
      mapUrl: m.mapUrl.isEmpty ? null : m.mapUrl,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLang.tr('map_open_failed'))),
      );
    }
  }

  void _openPublicPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicInviteScreen(
          weddingId: widget.weddingId,
          invitation: _currentModel,
          previewMode: true,
        ),
      ),
    );
  }

  void _openLivePublicPage() {
    final slug = _guestPortalSlug;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuestAuthGate(slug: slug),
      ),
    );
  }

  Future<void> _openSharePage() async {
    // قبل از اشتراک، slug را در Firestore ثبت کن تا لینک برای مهمان resolve شود
    if (_slugC.text.trim().isEmpty) {
      _slugC.text = _buildSlug(_groomC.text, _brideC.text);
    }
    try {
      await InvitationService.saveInvitation(
        weddingId: widget.weddingId,
        model: _currentModel,
      );
    } catch (_) {
      // حتی اگر save خطا داد، صفحه share با لینک محلی باز می‌شود
    }
    if (!mounted) return;

    final model = _currentModel;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ShareInvitePage(
          invitation: model,
          portalUrl: AppConfig.inviteUrl(model.normalizedSlug),
          shareText: _guestShareText(model),
          onOpenLive: _openLivePublicPage,
        ),
      ),
    );
  }

  void _openRsvpInbox() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RsvpInboxScreen(weddingId: widget.weddingId),
      ),
    );
  }

  Future<void> _onSavePin() async {
    setState(_applyCoordsFromText);
    await _loadWeather();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _lat == null ? AppLang.tr('pin_need_city') : AppLang.tr('pin_saved'),
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
              child: !_loaded
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppTok.accent(context),
                      ),
                    )
                  : Column(
                      children: [
                        _header(context),
                        TabBar(
                          controller: _tabController,
                          indicatorColor: AppTok.accent(context),
                          labelColor: AppTok.accent(context),
                          unselectedLabelColor: AppTok.textSoft(context),
                          tabs: [
                            Tab(text: AppLang.tr('preview')),
                            Tab(text: AppLang.tr('settings')),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _previewTab(context),
                              _settingsTab(context),
                            ],
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

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              AppLang.I.isFa ? Icons.arrow_forward : Icons.arrow_back,
              color: AppTok.text(context),
            ),
          ),
          Expanded(
            child: Text(
              AppLang.tr('digital_invitation'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTok.text(context),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            tooltip: _t(
              'share_guest_link',
              'اشتراک لینک مهمان',
              'Share guest link',
            ),
            onPressed: _openSharePage,
            icon: Icon(Icons.ios_share, color: AppTok.accent(context)),
          ),
        ],
      ),
    );
  }

  Widget _previewTab(BuildContext context) {
    final m = _currentModel;
    final portalUrl = AppConfig.inviteUrl(m.normalizedSlug);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        _InvitationCard(
          model: m,
          portalUrl: portalUrl,
          formatDate: _formatDate,
          formatDateMockup: _formatDateMockup,
          fa: fa,
          weather: _weather,
          weatherLoading: _weatherLoading,
          onOpenMap: _openMaps,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(AppLang.tr('edit')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTok.accentSoft(context),
                  foregroundColor: AppTok.text(context),
                  minimumSize: const Size.fromHeight(48),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openPublicPreview,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: Text(
                  _t('card_preview', 'پیش‌نمایش کارت', 'Card preview'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTok.accent(context),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _openLivePublicPage,
            icon: const Icon(Icons.groups_2_outlined),
            label: Text(
              _t(
                'open_guest_portal',
                'باز کردن پورتال مهمان',
                'Open guest portal',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTok.accentDeep(context),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _openSharePage,
            icon: const Icon(Icons.qr_code_2),
            label: Text(
              _t(
                'share_guest_qr',
                'اشتراک‌گذاری لینک و QR مهمان',
                'Share guest link & QR',
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTok.accentDeep(context),
              side: BorderSide(color: AppTok.accent(context)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _openRsvpInbox,
            icon: const Icon(Icons.mark_email_read_outlined),
            label: Text(AppLang.tr('view_rsvp_responses')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTok.accentDeep(context),
              side: BorderSide(color: AppTok.accent(context)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTok.card(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTok.border(context)),
          ),
          child: Column(
            children: [
              Text(
                _t(
                  'guest_link_explain',
                  'لینک و QR زیر، مهمان را به پورتال مهمان می‌برد (نه فقط کارت):\nخانه · دعوت‌نامه · تایم‌لاین · دوربین · صندلی\nو از منو: داستان عشق، آرزو، گالری، حمایت، هدیه',
                  'The link/QR opens the full Guest Portal (not only the card):\nHome · Invite · Timeline · Camera · Seats\nMenu: love story, wishes, gallery, supports, gifts',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                portalUrl,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: AppTok.accent(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsTab(BuildContext context) {
    final portalUrl = _guestPortalUrl;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        _sectionTitle(context, AppLang.tr('card_texts')),
        _field(
          context,
          _coverTitleC,
          AppLang.tr('cover_title_label'),
          maxLines: 2,
          alignCenter: true,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(
                context,
                _groomC,
                AppLang.tr('groom_name'),
                alignCenter: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(
                context,
                _brideC,
                AppLang.tr('bride_name'),
                alignCenter: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionTitle(context, AppLang.tr('ceremony_time')),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppTok.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTok.border(context)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: AppTok.accent(context),
                  size: 18,
                ),
                const SizedBox(height: 8),
                Text(
                  _weddingDate == null
                      ? AppLang.tr('select_ceremony_date')
                      : fa(
                          '${_weddingDate!.year}/${_weddingDate!.month.toString().padLeft(2, '0')}/${_weddingDate!.day.toString().padLeft(2, '0')}',
                        ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _weddingDate == null
                        ? AppTok.textSoft(context)
                        : AppTok.text(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _field(
          context,
          _timeC,
          AppLang.tr('start_time_hint'),
          keyboard: TextInputType.datetime,
          alignCenter: true,
          ltr: true,
        ),
        const SizedBox(height: 20),
        _sectionTitle(context, AppLang.tr('location_and_weather')),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTok.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTok.accent(context).withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.location_on, color: AppTok.accent(context), size: 24),
              const SizedBox(height: 8),
              Text(
                AppLang.tr('venue_fields_hint'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              _field(
                context,
                _venueNameC,
                AppLang.tr('venue_name_label'),
                alignCenter: true,
                filledColor: AppTok.background(context),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickVenueCity,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppTok.background(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTok.border(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_city_outlined,
                        color: AppTok.accent(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _venueCity.isEmpty
                              ? AppLang.tr('venue_city_label')
                              : _venueCity,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _venueCity.isEmpty
                                ? AppTok.textSoft(context)
                                : AppTok.text(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.expand_more, color: AppTok.textSoft(context)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLang.tr('venue_city_weather_hint'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 11,
                ),
              ),
              if (_weatherLoading) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  color: AppTok.accent(context),
                  backgroundColor: AppTok.ringTrack(context),
                ),
              ] else if (_weather != null) ...[
                const SizedBox(height: 10),
                Text(
                  '${AppLang.tr('now')}: ${fa(_weather!.temperature.toStringAsFixed(0))}° — ${WeatherService.label(_weather!.weatherCode)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTok.accent(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _field(
                context,
                _venueAddressC,
                AppLang.tr('full_address'),
                maxLines: 3,
                alignCenter: true,
                filledColor: AppTok.background(context),
              ),
              const SizedBox(height: 10),
              _field(
                context,
                _mapUrlC,
                AppLang.tr('map_link_or_coords_hint'),
                maxLines: 2,
                alignCenter: true,
                ltr: true,
                filledColor: AppTok.background(context),
              ),
              const SizedBox(height: 10),
              if (_lat != null && _lng != null)
                Text(
                  _venueCity.isEmpty
                      ? '${AppLang.tr('coordinates')}: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}'
                      : '$_venueCity · ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTok.accent(context),
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openMaps,
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: Text(AppLang.tr('open_map')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTok.accentDeep(context),
                        side: BorderSide(color: AppTok.accent(context)),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _onSavePin,
                      icon: const Icon(Icons.push_pin_outlined, size: 18),
                      label: Text(AppLang.tr('save_pin')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTok.accent(context),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _openMaps,
                  icon: const Icon(Icons.directions_outlined, size: 18),
                  label: Text(AppLang.tr('directions_view_pin')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTok.text(context),
                    side: BorderSide(color: AppTok.border(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle(
          context,
          _t('guest_portal_link', 'لینک پورتال مهمان', 'Guest portal link'),
        ),
        _field(
          context,
          _slugC,
          AppLang.tr('slug_hint'),
          keyboard: TextInputType.url,
          ltr: true,
          alignCenter: true,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTok.card(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTok.border(context)),
          ),
          child: Column(
            children: [
              Text(
                _t(
                  'guest_portal_url_label',
                  'آدرس پورتال مهمان:',
                  'Guest portal URL:',
                ),
                style: TextStyle(
                  color: AppTok.accent(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                portalUrl,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 11.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _t(
                  'guest_portal_url_must',
                  'باید شبیه این باشد:\nhttps://wedding-time-app2.netlify.app/invite/zaza-sara',
                  'Must look like:\nhttps://wedding-time-app2.netlify.app/invite/zaza-sara',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 10.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: AppTok.card(context),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: Text(
              AppLang.tr('show_rsvp_for_guest'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTok.text(context)),
            ),
            subtitle: Text(
              _savingRsvpToggle
                  ? AppLang.tr('saving')
                  : (_showRsvp
                      ? AppLang.tr('rsvp_guest_can_respond')
                      : AppLang.tr('rsvp_form_hidden')),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTok.textSoft(context),
                fontSize: 11,
              ),
            ),
            value: _showRsvp,
            activeTrackColor: AppTok.accent(context).withValues(alpha: 0.45),
            activeThumbColor: AppTok.accent(context),
            onChanged:
                (_saving || _savingRsvpToggle) ? null : _onShowRsvpChanged,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                AppLang.tr('wedding_day_schedule'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _schedule.add(
                    ScheduleItem(
                      time: '20:00',
                      title: AppLang.tr('new_item'),
                      icon: 'custom',
                    ),
                  );
                });
              },
              icon: Icon(Icons.add, color: AppTok.accent(context), size: 18),
              label: Text(
                AppLang.tr('add'),
                style: TextStyle(color: AppTok.accent(context)),
              ),
            ),
          ],
        ),
        ..._schedule.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTok.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTok.border(context)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: TextFormField(
                    initialValue: item.time,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTok.text(context),
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '18:00',
                      hintStyle: TextStyle(color: AppTok.textSoft(context)),
                    ),
                    onChanged: (v) {
                      _schedule[i] = ScheduleItem(
                        time: v.trim(),
                        title: _schedule[i].title,
                        icon: _schedule[i].icon,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: item.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTok.text(context),
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: AppLang.tr('title'),
                      hintStyle: TextStyle(color: AppTok.textSoft(context)),
                    ),
                    onChanged: (v) {
                      _schedule[i] = ScheduleItem(
                        time: _schedule[i].time,
                        title: v.trim(),
                        icon: _schedule[i].icon,
                      );
                    },
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _schedule.removeAt(i)),
                  icon: Icon(
                    Icons.close,
                    color: AppTok.textSoft(context),
                    size: 18,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTok.accent(context),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    AppLang.tr('save_digital_invitation'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppTok.accent(context),
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context,
    TextEditingController c,
    String label, {
    TextInputType? keyboard,
    bool ltr = false,
    bool alignCenter = false,
    int maxLines = 1,
    Color? filledColor,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      textAlign: alignCenter ? TextAlign.center : TextAlign.start,
      textDirection: ltr ? TextDirection.ltr : AppLang.I.direction,
      style: TextStyle(color: AppTok.text(context)),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTok.textSoft(context)),
        alignLabelWithHint: true,
        filled: true,
        fillColor: filledColor ?? AppTok.card(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// کارت پیش‌نمایش = light mockup عمدی + FloralDecor
class _InvitationCard extends StatelessWidget {
  final InvitationModel model;
  final String portalUrl;
  final String Function(DateTime?) formatDate;
  final String Function(DateTime?) formatDateMockup;
  final String Function(String) fa;
  final WeatherSnapshot? weather;
  final bool weatherLoading;
  final VoidCallback onOpenMap;

  const _InvitationCard({
    required this.model,
    required this.portalUrl,
    required this.formatDate,
    required this.formatDateMockup,
    required this.fa,
    required this.weather,
    required this.weatherLoading,
    required this.onOpenMap,
  });

  static const _brandGreen = AppPalette.brandGreen;
  static const _brandBlush = AppPalette.brandBlush;
  static const _ink = Color(0xFF3A342E);
  static const _softInk = AppPalette.textSoft;
  static const _deep = AppPalette.accentDeep;
  static const _accent = AppPalette.accent;
  static const _border = AppPalette.border;
  static const _cream = Color(0xFFF7F1E6);
  static const _inner = Color(0xFFFFFBF4);

  String _t(String key, String fallback) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return fallback;
    return v;
  }

  String get _groom {
    final g = model.groomName.trim();
    return g.isEmpty ? AppLang.tr('groom') : g;
  }

  String get _bride {
    final b = model.brideName.trim();
    return b.isEmpty ? AppLang.tr('bride') : b;
  }

  String get _place {
    final parts = <String>[];
    if (model.venueName.trim().isNotEmpty) parts.add(model.venueName.trim());
    if (model.venueCity.trim().isNotEmpty) parts.add(model.venueCity.trim());
    return parts.join(AppLang.I.isFa ? '، ' : ', ');
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = model.venueName.trim().isNotEmpty ||
        model.venueAddress.trim().isNotEmpty ||
        model.googleMapsLink.isNotEmpty ||
        model.hasGeo;

    // QR = فقط لینک پورتال مهمان
    final qrData = portalUrl.trim().isNotEmpty ? portalUrl : model.coupleTitle;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _brandGreen.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _brandGreen.withValues(alpha: 0.10),
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
            const Positioned.fill(
              child: FloralDecor(intensity: 1.2, frameMode: true),
            ),
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _inner.withValues(alpha: 0.84),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _brandGreen.withValues(alpha: 0.16),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 26),
              child: Column(
                children: [
                  Text(
                    _t(
                      'you_are_invited',
                      AppLang.I.isFa
                          ? 'شما دعوتید به'
                          : 'YOU ARE INVITED TO',
                    ).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _deep.withValues(alpha: 0.88),
                      fontSize: 10.5,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t(
                      'to_the_wedding_of',
                      AppLang.I.isFa ? 'عروسی' : 'THE WEDDING OF',
                    ).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _softInk,
                      fontSize: 10.5,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _groom,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      color: _ink,
                      fontSize: 36,
                      height: 1.05,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '&',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      color: _deep.withValues(alpha: 0.9),
                      fontSize: 24,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _bride,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      color: _ink,
                      fontSize: 36,
                      height: 1.05,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: _border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          Icons.favorite,
                          size: 12,
                          color: _brandBlush.withValues(alpha: 0.95),
                        ),
                      ),
                      Expanded(child: Container(height: 1, color: _border)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    formatDateMockup(model.weddingDate),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _deep,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppLang.tr('time_label')} ${fa(model.eventTime)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _softInk,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_place.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _place,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _softInk,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                  if (weatherLoading) ...[
                    const SizedBox(height: 14),
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _accent,
                      ),
                    ),
                  ] else if (weather != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.cardSoft.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wb_sunny_outlined,
                            color: _accent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${fa(weather!.temperature.toStringAsFixed(0))}°',
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              WeatherService.label(weather!.weatherCode),
                              style: const TextStyle(
                                color: _softInk,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (model.venueCity.isEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      AppLang.tr('weather_pick_city_hint'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _softInk,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: QrImageView(
                      data: qrData,
                      size: 120,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: _deep,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF2F2B28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t(
                      'scan_to_rsvp',
                      AppLang.I.isFa
                          ? 'اسکن = ورود به پورتال مهمان'
                          : 'Scan = open guest portal',
                    ),
                    style: const TextStyle(
                      color: _softInk,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (model.venueAddress.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      model.venueAddress,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _softInk,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (hasLocation) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: onOpenMap,
                      icon: const Icon(
                        Icons.map_outlined,
                        color: _accent,
                        size: 18,
                      ),
                      label: Text(
                        AppLang.tr('view_on_google_maps'),
                        style: const TextStyle(
                          color: _deep,
                          fontWeight: FontWeight.bold,
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
    );
  }
}

class _ShareInvitePage extends StatelessWidget {
  final InvitationModel invitation;
  final String portalUrl;
  final String shareText;
  final VoidCallback onOpenLive;

  const _ShareInvitePage({
    required this.invitation,
    required this.portalUrl,
    required this.shareText,
    required this.onOpenLive,
  });

  String _t(String key, String faTxt, String enTxt) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? faTxt : enTxt;
    return v;
  }

  @override
  Widget build(BuildContext context) {
    // فقط لینک پورتال — هرگز ریشه سایت
    final link = portalUrl.trim().isNotEmpty
        ? portalUrl.trim()
        : AppConfig.inviteUrl(invitation.normalizedSlug);
    final text = shareText.trim().isNotEmpty ? shareText : invitation.shareText;

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
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            AppLang.I.isFa
                                ? Icons.arrow_forward
                                : Icons.arrow_back,
                            color: AppTok.text(context),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _t(
                              'share_guest_portal',
                              'اشتراک پورتال مهمان',
                              'Share guest portal',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTok.text(context),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8F1),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color:
                                    AppPalette.accent.withValues(alpha: 0.45),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTok.shadow(context),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                QrImageView(
                                  data: link,
                                  version: QrVersions.auto,
                                  size: 220,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: AppPalette.accentDeep,
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Color(0xFF2F2B28),
                                  ),
                                ),
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8F1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: AppPalette.accentSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _t(
                            'qr_guest_portal_hint',
                            'این QR و لینک، مهمان را به پورتال مهمان می‌برد:\nخانه · دعوت‌نامه · تایم‌لاین · دوربین · صندلی\n(+ منو: داستان عشق، آرزو، گالری، حمایت، هدیه)',
                            'This QR/link opens the Guest Portal:\nHome · Invite · Timeline · Camera · Seats\n(+ menu: love story, wishes, gallery, supports, gifts)',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTok.textSoft(context),
                            fontSize: 11.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTok.card(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTok.border(context)),
                          ),
                          child: Text(
                            text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTok.text(context),
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTok.card(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTok.border(context)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  link,
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(
                                    color: AppTok.textSoft(context),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: link));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _t(
                                          'guest_link_copied',
                                          'لینک پورتال مهمان کپی شد',
                                          'Guest portal link copied',
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.copy,
                                  color: AppTok.textSoft(context),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: onOpenLive,
                            icon: const Icon(Icons.groups_2_outlined),
                            label: Text(
                              _t(
                                'preview_guest_portal',
                                'پیش‌نمایش پورتال مهمان',
                                'Preview guest portal',
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTok.accent(context),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: text));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLang.tr('invite_text_copied'),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy, size: 18),
                                label: Text(AppLang.tr('copy_text')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTok.cardSoft(context),
                                  foregroundColor: AppTok.accentDeep(context),
                                  elevation: 0,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Share فقط متنی که لینک پورتال داخلش است
                                  Share.share(
                                    text.contains(link) ? text : '$text\n\n$link',
                                    subject: _t(
                                      'guest_portal_share_subject',
                                      'پورتال مهمان عروسی',
                                      'Wedding guest portal',
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.share_outlined,
                                  size: 18,
                                ),
                                label: Text(AppLang.tr('share')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTok.accent(context),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}