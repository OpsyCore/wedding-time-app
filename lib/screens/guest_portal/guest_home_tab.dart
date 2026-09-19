import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../core/app_theme.dart';
import '../../core/app_theme_controller.dart';
import '../../models/invitation_model.dart';
import '../../services/guest_local_store.dart';
import 'guest_gallery_tab.dart';
import 'guest_gifts_tab.dart';
import 'guest_love_story_tab.dart';
import '../supports_guest_screen.dart';
import 'guest_wishes_tab.dart';

/// تب خانه مهمان — داشبورد کارت‌محور با بازطراحی کامل بخش Hero مطابق طرح مرجع:
/// ۱) هدر خوش‌آمد بالا با متن سلام و آیکون قلب (راست‌چین و تمیز)
/// ۲) کارت هیرو با قاب قوسی رمانتیک (عکس زوج / آرت شب ستاره‌ای)، اسامی خط نستعلیق، تاریخ، و ۴ کارت شمارش معکوس شیشه‌ای با آیکون‌های ویژه
/// ۳) مسیر مهمان و دسترسی به بخش‌های پورتال
class GuestHomeTab extends StatefulWidget {
  const GuestHomeTab({
    super.key,
    required this.weddingId,
    required this.invitation,
    this.onOpenTab,
  });

  final String weddingId;
  final InvitationModel invitation;

  /// سوییچ به تب‌های پایینِ شل (0 خانه، 1 دعوت‌نامه، 2 تایم‌لاین، 3 دوربین، 4 صندلی)
  final ValueChanged<int>? onOpenTab;

  @override
  State<GuestHomeTab> createState() => _GuestHomeTabState();
}

class _GuestHomeTabState extends State<GuestHomeTab>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  String? _guestName;
  String? _rsvpStatus; // yes | no | null
  int _cameraShots = 0;

  late final AnimationController _intro;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  static const _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  static const _monthsEn = [
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

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeIn = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_fadeIn);
    _intro.forward();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _loadLocal();
  }

  Future<void> _loadLocal() async {
    try {
      final wid = widget.weddingId;
      final results = await Future.wait([
        GuestLocalStore.loadDisplayName(wid),
        GuestLocalStore.loadRsvp(wid),
        GuestLocalStore.loadCameraUsage(wid),
      ]);
      if (!mounted) return;
      setState(() {
        _guestName = (results[0] as String?)?.trim();
        _rsvpStatus = (results[1] as ({String? status, String? name})).status;
        _cameraShots = results[2] as int;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _intro.dispose();
    super.dispose();
  }

  String _t(String key, String fa, String en) {
    final v = AppLang.tr(key);
    if (v.isEmpty || v == key) return AppLang.I.isFa ? fa : en;
    return v;
  }

  String _fa(String input) {
    if (!AppLang.I.isFa) return input;
    return input.split('').map((p) {
      final i = int.tryParse(p);
      return i != null ? _faDigits[i] : p;
    }).join();
  }

  DateTime? get _target {
    final d = widget.invitation.weddingDate;
    if (d == null) return null;
    final t = widget.invitation.eventTime.trim();
    final parts = t.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0].trim());
      final m = int.tryParse(parts[1].trim());
      if (h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
        return DateTime(d.year, d.month, d.day, h, m);
      }
    }
    return DateTime(d.year, d.month, d.day);
  }

  String _dateLine(DateTime d) {
    if (AppLang.I.isFa) {
      final mm = d.month.toString().padLeft(2, '0');
      final dd = d.day.toString().padLeft(2, '0');
      return _fa('${d.year}/$mm/$dd');
    }
    return '${_monthsEn[d.month - 1]} ${d.day}, ${d.year}';
  }

  void _push(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _goTab(int index) {
    widget.onOpenTab?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        return Directionality(
          textDirection: AppLang.I.direction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildGreeting(context),
                          const SizedBox(height: 14),
                          _buildHero(context),
                          const SizedBox(height: 24),
                          _buildPlanHeader(context),
                          const SizedBox(height: 12),
                          ..._buildActions(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────── ۱) هدر خوش‌آمد (مشابه عکس ۲) ─────────────────────────

  Widget _buildGreeting(BuildContext context) {
    final name = _guestName ?? '';
    final nameTitle = name.isEmpty
        ? _t('guest_home_greeting_anon', 'سلام، مهمان عزیز', 'Hello, Dear Guest')
        : (AppLang.I.isFa ? 'سلام $name' : 'Hello $name');

    final accent = AppTok.accent(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                nameTitle,
                style: TextStyle(
                  color: AppTok.text(context),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.favorite_rounded,
                size: 20,
                color: accent.withValues(alpha: 0.95),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _t(
              'guest_home_welcome_dream',
              'به برنامه‌ی رویایی‌تون خوش اومدید',
              'Welcome to your dream wedding app',
            ),
            style: TextStyle(
              color: AppTok.textSoft(context).withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── ۲) کارت Hero اصلی (مشابه عکس ۲) ─────────────────────────

  Widget _buildHero(BuildContext context) {
    final dark = AppTok.isDark(context);
    final inv = widget.invitation;
    final accent = AppTok.accent(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            dark ? const Color(0xFF1B1724) : AppTok.card(context),
            dark ? const Color(0xFF15111B) : AppTok.cardSoft(context),
            accent.withValues(alpha: dark ? 0.12 : 0.25),
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: dark ? 0.18 : 0.24),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTok.shadow(context),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('weddings')
                .doc(widget.weddingId)
                .snapshots(),
            builder: (context, snap) {
              final d = snap.data?.data() ?? {};
              final groom = (d['groomName'] ?? inv.groomName).toString().trim();
              final bride = (d['brideName'] ?? inv.brideName).toString().trim();
              final couplePhoto = (d['couplePhotoUrl'] ??
                      d['coverImageUrl'] ??
                      inv.couplePhotoUrl ??
                      inv.coverImageUrl ??
                      '')
                  .toString()
                  .trim();

              final title = groom.isNotEmpty && bride.isNotEmpty
                  ? '$groom & $bride'
                  : (inv.coupleTitle.isNotEmpty ? inv.coupleTitle : 'علی & دارا');

              final dateStr = inv.weddingDate != null
                  ? _dateLine(inv.weddingDate!)
                  : (AppLang.I.isFa ? '۲۰۲۶/۰۸/۰۱' : '2026/08/01');

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── بخش بالایی: قاب قوسی عکس زوج در یک سمت + متن و اسامی در سمت دیگر ──
                  SizedBox(
                    height: 200,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ۱) قاب قوسی رمانتیک (عکس زوج یا آرت شب ستاره‌ای با ماه و سیلوئت)
                        _buildArchedWindow(context, couplePhoto),

                        const SizedBox(width: 16),

                        // ۲) اسامی زوج، تاریخ و برچسب «تا روز جشن»
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 27,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'serif',
                                  fontFamilyFallback: const [
                                    'Nastaliq',
                                    'IranNastaliq',
                                    'Vazirmatn',
                                    'serif',
                                  ],
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: accent.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                dateStr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTok.textSoft(context).withValues(alpha: 0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _t(
                                  'guest_home_until_celebration',
                                  'تا روز جشن',
                                  'Until the celebration',
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTok.textSoft(context).withValues(alpha: 0.75),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── بخش پایینی: ۴ کارت شمارش معکوس شیشه‌ای با آیکون‌های اختصاصی ──
                  _buildCountdownCards(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// قاب قوسی رمانتیک با گوشه‌های گرد گنبدی در بالا و شاخه‌های طلایی در اطراف
  Widget _buildArchedWindow(BuildContext context, String photoUrl) {
    final accent = AppTok.accent(context);

    return SizedBox(
      width: 155,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // پترن گل و بوته طلایی اطراف قاب قوسی
          Positioned.fill(
            child: CustomPaint(
              painter: _FloralArchPainter(accentColor: accent),
            ),
          ),

          // محفظه قوسی با کادر درخشان
          Container(
            width: 140,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(75),
                bottom: Radius.circular(16),
              ),
              border: Border.all(
                color: accent.withValues(alpha: 0.55),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(74),
                bottom: Radius.circular(15),
              ),
              child: photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (c, _) => Container(
                        color: const Color(0xFF1B1423),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accent,
                          ),
                        ),
                      ),
                      errorWidget: (c, _, __) => _RomanticSilhouetteWidget(
                        accentColor: accent,
                      ),
                    )
                  : _RomanticSilhouetteWidget(accentColor: accent),
            ),
          ),
        ],
      ),
    );
  }

  /// ۴ کارت شمارش معکوس شیشه‌ای (روز، ساعت، دقیقه، ثانیه) مطابق عکس ۲
  Widget _buildCountdownCards(BuildContext context) {
    final target = _target ?? DateTime.now().add(const Duration(days: 4, hours: 21, minutes: 32, seconds: 46));
    final diff = target.difference(_now);

    final isPast = diff.isNegative || diff == Duration.zero;
    final days = isPast ? 0 : diff.inDays;
    final hours = isPast ? 0 : diff.inHours % 24;
    final mins = isPast ? 0 : diff.inMinutes % 60;
    final secs = isPast ? 0 : diff.inSeconds % 60;

    // ۴ کارت مطابق عکس ۲:
    // ۱) روز (Sparkle / ستاره ۴ پر)
    // ۲) ساعت (Heart / قلب)
    // ۳) دقیقه (Clock / ساعت)
    // ۴) ثانیه (Calendar / تقویم)
    return Row(
      children: [
        // روز
        Expanded(
          child: _countdownItemBox(
            context,
            icon: Icons.auto_awesome_rounded,
            value: days.toString(),
            label: _t('guest_home_days', 'روز', 'DAYS'),
            highlight: false,
          ),
        ),
        const SizedBox(width: 8),

        // ساعت
        Expanded(
          child: _countdownItemBox(
            context,
            icon: Icons.favorite_border_rounded,
            value: hours.toString().padLeft(2, '0'),
            label: _t('guest_home_hours', 'ساعت', 'HOURS'),
            highlight: false,
          ),
        ),
        const SizedBox(width: 8),

        // دقیقه (با هایلایت شیشه‌ای برجسته ۳D)
        Expanded(
          child: _countdownItemBox(
            context,
            icon: Icons.access_time_rounded,
            value: mins.toString().padLeft(2, '0'),
            label: _t('guest_home_mins', 'دقیقه', 'MINS'),
            highlight: true,
          ),
        ),
        const SizedBox(width: 8),

        // ثانیه
        Expanded(
          child: _countdownItemBox(
            context,
            icon: Icons.calendar_today_rounded,
            value: secs.toString().padLeft(2, '0'),
            label: _t('guest_home_secs', 'ثانیه', 'SECS'),
            highlight: false,
          ),
        ),
      ],
    );
  }

  Widget _countdownItemBox(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required bool highlight,
  }) {
    final accent = AppTok.accent(context);
    final dark = AppTok.isDark(context);

    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? accent.withValues(alpha: dark ? 0.22 : 0.32)
            : (dark ? const Color(0xFF221D2B).withValues(alpha: 0.85) : AppTok.cardSoft(context)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? accent.withValues(alpha: 0.75)
              : accent.withValues(alpha: 0.26),
          width: highlight ? 1.4 : 1.0,
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: accent.withValues(alpha: 0.95),
            size: 21,
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _fa(value),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.98),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: AppTok.textSoft(context).withValues(alpha: 0.85),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────── ۳) مسیر مهمان ─────────────────────────

  Widget _buildPlanHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('guest_home_plan_title', 'مسیر مهمان', 'Your plan'),
          style: TextStyle(
            color: AppTok.text(context),
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _t(
            'guest_home_plan_sub',
            'هر آنچه برای روز جشن لازم دارید، یک‌جا',
            'Everything you need for the big day, in one place',
          ),
          style: TextStyle(
            color: AppTok.textSoft(context),
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final items = <Widget>[];

    // 1) دعوت‌نامه / RSVP
    items.add(
      _actionTile(
        context,
        icon: Icons.mail_outline,
        title: _t('guest_home_act_invite', 'دعوت‌نامه و RSVP', 'Invitation & RSVP'),
        subtitle: _t(
          'guest_home_act_invite_sub',
          'جزئیات مراسم و ثبت پاسخ',
          'Event details & your reply',
        ),
        chip: widget.invitation.showRsvp
            ? (_rsvpStatus == 'yes' || _rsvpStatus == 'no'
                ? _doneChip(context)
                : _todoChip(
                    context,
                    _t(
                      'guest_home_rsvp_left',
                      'پاسخ داده نشده',
                      'Not answered yet',
                    ),
                  ))
            : null,
        onTap: () => _goTab(1),
      ),
    );

    // 2) تایم‌لاین
    items.add(
      _actionTile(
        context,
        icon: Icons.view_timeline_outlined,
        title: _t('guest_home_act_timeline', 'برنامه روز', 'Day schedule'),
        subtitle: _t(
          'guest_home_act_timeline_sub',
          'ترتیب لحظه‌های جشن',
          'How the celebration flows',
        ),
        onTap: () => _goTab(2),
      ),
    );

    // 3) میز من / صندلی
    items.add(
      _actionTile(
        context,
        icon: Icons.event_seat_outlined,
        title: _t('guest_home_act_seat', 'میز من', 'Find my seat'),
        subtitle: _t(
          'guest_home_act_seat_sub',
          'پیدا کردن صندلی با نام شما',
          'Find your table by name',
        ),
        onTap: () => _goTab(4),
      ),
    );

    // 4) دوربین یک‌بارمصرف
    items.add(
      _actionTile(
        context,
        icon: Icons.photo_camera_outlined,
        title: _t(
          'guest_home_act_camera',
          'دوربین یک‌بارمصرف',
          'Disposable camera',
        ),
        subtitle: _t(
          'guest_home_act_camera_sub',
          'ثبت لحظه‌ها از نگاه شما',
          'Capture moments your way',
        ),
        chip: _cameraShots > 0 ? _doneChip(context) : null,
        onTap: () => _goTab(3),
      ),
    );

    // 5) داستان عشق
    items.add(
      _actionTile(
        context,
        icon: Icons.auto_stories_outlined,
        title: _t('guest_home_act_story', 'داستان عشق', 'Love story'),
        subtitle: _t(
          'guest_home_act_story_sub',
          'روایت آشنایی ما',
          'How our story began',
        ),
        onTap: () => _push(GuestLoveStoryTab(weddingId: widget.weddingId)),
      ),
    );

    // 6) ارسال آرزو
    items.add(
      _actionTile(
        context,
        icon: Icons.favorite_border,
        title: _t('guest_home_act_wish', 'ارسال آرزو', 'Send a wish'),
        subtitle: _t(
          'guest_home_act_wish_sub',
          'پیام شما برای عروس و داماد',
          'Your message to the couple',
        ),
        onTap: () => _push(GuestWishesTab(weddingId: widget.weddingId)),
      ),
    );

    // 7) گالری
    items.add(
      _actionTile(
        context,
        icon: Icons.photo_library_outlined,
        title: _t('guest_home_act_gallery', 'گالری', 'Gallery'),
        subtitle: _t(
          'guest_home_act_gallery_sub',
          'عکس‌های تأییدشده مهمان‌ها',
          'Approved guest photos',
        ),
        onTap: () => _push(
          Scaffold(
            backgroundColor: AppTok.background(context),
            appBar: AppBar(
              backgroundColor: AppTok.background(context),
              elevation: 0,
              title: Text(
                _t('guest_home_act_gallery', 'گالری', 'Gallery'),
                style: TextStyle(color: AppTok.text(context)),
              ),
              iconTheme: IconThemeData(color: AppTok.text(context)),
            ),
            body: GuestGalleryTab(weddingId: widget.weddingId),
          ),
        ),
      ),
    );

    // 8) هدایا
    items.add(
      _actionTile(
        context,
        icon: Icons.card_giftcard_outlined,
        title: _t('guest_home_act_gifts', 'هدایا', 'Gifts'),
        subtitle: _t(
          'guest_home_act_gifts_sub',
          'لیست هدایا و رزرو',
          'Registry & reservation',
        ),
        onTap: () => _push(
          Scaffold(
            backgroundColor: AppTok.background(context),
            appBar: AppBar(
              backgroundColor: AppTok.background(context),
              elevation: 0,
              title: Text(
                _t('guest_home_act_gifts', 'هدایا', 'Gifts'),
                style: TextStyle(color: AppTok.text(context)),
              ),
              iconTheme: IconThemeData(color: AppTok.text(context)),
            ),
            body: GuestGiftsTab(weddingId: widget.weddingId),
          ),
        ),
      ),
    );

    // 9) حمایت‌ها
    items.add(
      _actionTile(
        context,
        icon: Icons.volunteer_activism_outlined,
        title: _t('guest_home_act_supports', 'حمایت‌ها', 'Supports'),
        subtitle: _t(
          'guest_home_act_supports_sub',
          'همراهی شما با ما',
          'Stand with us',
        ),
        onTap: () => _push(SupportsGuestScreen(weddingId: widget.weddingId)),
      ),
    );

    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i != items.length - 1) out.add(const SizedBox(height: 10));
    }
    return out;
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? chip,
  }) {
    final chevron = AppLang.I.isRtl ? Icons.chevron_left : Icons.chevron_right;

    return Material(
      color: AppTok.card(context).withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTok.border(context)),
            boxShadow: [
              BoxShadow(
                color: AppTok.shadow(context),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTok.accent(context).withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTok.accent(context).withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(icon, color: AppTok.accent(context), size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTok.text(context),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTok.textSoft(context),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (chip != null) ...[
                const SizedBox(width: 8),
                chip,
              ],
              const SizedBox(width: 6),
              Icon(chevron, color: AppTok.textSoft(context), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _doneChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTok.accent(context).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: AppTok.accent(context).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 11,
            color: AppTok.accentDeep(context),
          ),
          const SizedBox(width: 4),
          Text(
            _t('guest_home_done', 'انجام شد', 'Done'),
            style: TextStyle(
              color: AppTok.accentDeep(context),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _todoChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTok.cardSoft(context).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppTok.border(context)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTok.textSoft(context),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ───────────────────────── ویجت‌ها و نقاش‌های گرافیکی آرت‌ورک ─────────────────────────

class _RomanticSilhouetteWidget extends StatelessWidget {
  const _RomanticSilhouetteWidget({required this.accentColor});
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(140, 190),
      painter: _RomanticSilhouettePainter(accentColor: accentColor),
    );
  }
}

class _RomanticSilhouettePainter extends CustomPainter {
  const _RomanticSilhouettePainter({required this.accentColor});
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ۱) گرادینت گرگ‌ومیش و آسمان شبانه
    final skyRect = Rect.fromLTWH(0, 0, w, h);
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0E0C17),
        const Color(0xFF1D152A),
        const Color(0xFF332038),
        const Color(0xFF563446),
        const Color(0xFF1C1222),
      ],
      stops: const [0.0, 0.35, 0.65, 0.82, 1.0],
    );
    final skyPaint = Paint()..shader = skyGradient.createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // ۲) هاله گرم نور ماه/غروب در پشت زوج
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.35),
        radius: 0.65,
        colors: [
          accentColor.withValues(alpha: 0.38),
          const Color(0xFFFFB290).withValues(alpha: 0.20),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.5, h * 0.65), radius: w * 0.6));
    canvas.drawCircle(Offset(w * 0.5, h * 0.65), w * 0.6, glowPaint);

    // ۳) ستاره‌های درخشان در آسمان
    final starPaint = Paint()..color = Colors.white;
    final stars = [
      Offset(w * 0.15, h * 0.12),
      Offset(w * 0.28, h * 0.22),
      Offset(w * 0.42, h * 0.08),
      Offset(w * 0.75, h * 0.16),
      Offset(w * 0.85, h * 0.25),
      Offset(w * 0.20, h * 0.35),
      Offset(w * 0.65, h * 0.30),
      Offset(w * 0.88, h * 0.10),
      Offset(w * 0.10, h * 0.25),
      Offset(w * 0.55, h * 0.15),
    ];
    for (var i = 0; i < stars.length; i++) {
      final s = stars[i];
      final r = (i % 3 == 0) ? 1.4 : ((i % 2 == 0) ? 1.0 : 0.7);
      starPaint.color = Colors.white.withValues(alpha: (i % 2 == 0) ? 0.85 : 0.5);
      canvas.drawCircle(s, r, starPaint);
    }

    // ۴) هلال ماه نقره‌ای-طلایی
    final moonCenter = Offset(w * 0.54, h * 0.22);
    final moonRadius = w * 0.09;
    final moonGlow = Paint()
      ..color = const Color(0xFFFFECCC).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(moonCenter, moonRadius * 1.5, moonGlow);

    final moonPath = Path()
      ..addArc(Rect.fromCircle(center: moonCenter, radius: moonRadius), -0.9, 3.2);
    moonPath.arcTo(
      Rect.fromCircle(
        center: Offset(moonCenter.dx + moonRadius * 0.35, moonCenter.dy - moonRadius * 0.1),
        radius: moonRadius * 0.88,
      ),
      2.1,
      -2.8,
      false,
    );
    moonPath.close();
    canvas.drawPath(moonPath, Paint()..color = const Color(0xFFFFF7E8));

    // ۵) سایه‌نمای جنگل درختان کاج در پایین
    final forestPaint = Paint()..color = const Color(0xFF0D0A15);
    final forestPath = Path()..moveTo(0, h);
    forestPath.lineTo(0, h * 0.72);
    forestPath.lineTo(w * 0.12, h * 0.68);
    forestPath.lineTo(w * 0.25, h * 0.74);
    forestPath.lineTo(w * 0.40, h * 0.70);
    forestPath.lineTo(w * 0.60, h * 0.73);
    forestPath.lineTo(w * 0.78, h * 0.67);
    forestPath.lineTo(w * 0.90, h * 0.72);
    forestPath.lineTo(w * 0.69, h * 0.69);
    forestPath.lineTo(w, h * 0.69);
    forestPath.lineTo(w, h);
    forestPath.close();
    canvas.drawPath(forestPath, forestPaint);

    // ۶) سیلوئت رمانتیک زوج (داماد در سمت چپ، عروس در سمت راست روبروی هم)
    final silhouettePaint = Paint()..color = const Color(0xFF07040B);

    // داماد
    final groomPath = Path();
    groomPath.addOval(Rect.fromCenter(center: Offset(w * 0.38, h * 0.45), width: w * 0.13, height: h * 0.085));
    groomPath.moveTo(w * 0.32, h * 0.52);
    groomPath.quadraticBezierTo(w * 0.38, h * 0.49, w * 0.44, h * 0.52);
    groomPath.lineTo(w * 0.46, h * 0.78);
    groomPath.lineTo(w * 0.29, h * 0.78);
    groomPath.close();
    canvas.drawPath(groomPath, silhouettePaint);

    // عروس با لباس بلند
    final bridePath = Path();
    bridePath.addOval(Rect.fromCenter(center: Offset(w * 0.58, h * 0.47), width: w * 0.12, height: h * 0.08));
    bridePath.moveTo(w * 0.52, h * 0.53);
    bridePath.quadraticBezierTo(w * 0.58, h * 0.51, w * 0.64, h * 0.54);
    bridePath.quadraticBezierTo(w * 0.60, h * 0.65, w * 0.78, h * 0.95);
    bridePath.lineTo(w * 0.40, h * 0.95);
    bridePath.quadraticBezierTo(w * 0.50, h * 0.65, w * 0.52, h * 0.53);
    bridePath.close();
    canvas.drawPath(bridePath, silhouettePaint);

    // خط نور رمانتیک مهتاب روی لبه پیکرها
    final rimPaint = Paint()
      ..color = const Color(0xFFFFDFD0).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    canvas.drawPath(groomPath, rimPaint);
    canvas.drawPath(bridePath, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FloralArchPainter extends CustomPainter {
  const _FloralArchPainter({required this.accentColor});
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final vinePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final leafPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.60)
      ..style = PaintingStyle.fill;

    // پیچک و ساقه سمت چپ
    final leftVine = Path();
    leftVine.moveTo(10, h * 0.85);
    leftVine.quadraticBezierTo(-4, h * 0.55, 12, h * 0.28);
    leftVine.quadraticBezierTo(w * 0.20, 2, w * 0.5, 6);
    canvas.drawPath(leftVine, vinePaint);

    // پیچک و ساقه سمت راست
    final rightVine = Path();
    rightVine.moveTo(w - 10, h * 0.85);
    rightVine.quadraticBezierTo(w + 4, h * 0.55, w - 12, h * 0.28);
    rightVine.quadraticBezierTo(w * 0.80, 2, w * 0.5, 6);
    canvas.drawPath(rightVine, vinePaint);

    // برگ‌های ظریف طلایی در طول قوس
    final leafPoints = [
      Offset(7, h * 0.70),
      Offset(4, h * 0.56),
      Offset(9, h * 0.42),
      Offset(16, h * 0.28),
      Offset(w * 0.25, h * 0.12),
      Offset(w * 0.38, 8),
      Offset(w - 7, h * 0.70),
      Offset(w - 4, h * 0.56),
      Offset(w - 9, h * 0.42),
      Offset(w - 16, h * 0.28),
      Offset(w - w * 0.25, h * 0.12),
      Offset(w - w * 0.38, 8),
    ];

    for (final p in leafPoints) {
      canvas.drawOval(
        Rect.fromCenter(center: p, width: 4.5, height: 8),
        leafPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
