import 'dart:async';

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

/// تب خانه مهمان — داشبورد کارت‌محور:
/// هدر خوش‌آمد + کارت Hero با شمارش معکوس + لیست «مسیر مهمان».
/// رنگ/فضا فقط از AppTok.* و پالت‌های static const؛ بدون هاردکد بیرونی.
class GuestHomeTab extends StatefulWidget {
  const GuestHomeTab({
    super.key,
    required this.weddingId,
    required this.invitation,
    this.onOpenTab,
  });

  final String weddingId;
  final InvitationModel invitation;

  /// سوییچ به تب‌های پایینِ شل (0 خانه، 1 دعوت‌نامه، 2 تایم‌لاین،
  /// 3 دوربین، 4 صندلی). از خود شل پاس داده می‌شود — بدون ترفند ناوبری.
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
      duration: const Duration(milliseconds: 420),
    );
    _fadeIn = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.045),
      end: Offset.zero,
    ).animate(_fadeIn);
    _intro.forward();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _loadLocal();
  }

  /// فقط داده‌های محلی موجود (بدون جعل وضعیت):
  /// نام نمایشی، وضعیت RSVP و تعداد عکس‌های ثبت‌شده دوربین.
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
    } catch (_) {
      // خانه نباید با خطای پریف خراب شود.
    }
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

  String _initialOf(String name) {
    final t = name.trim();
    if (t.isEmpty) return '';
    return String.fromCharCode(t.runes.first);
  }

  /// مونوگرام زوج برای آواتار هدر (از نام‌های واقعی، بدون عکس جعلی)
  String _monogram(String groom, String bride) {
    final g = _initialOf(groom);
    final b = _initialOf(bride);
    if (g.isEmpty && b.isEmpty) return '♥';
    if (g.isEmpty) return b;
    if (b.isEmpty) return g;
    return '$g & $b';
  }

  /// هدف شمارش معکوس: تاریخ مراسم + ساعت برنامه اگر قابل پارس باشد
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

  String _weekDay(DateTime d) {
    switch (d.weekday) {
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGreeting(context),
                          const SizedBox(height: 14),
                          _buildHero(context),
                          const SizedBox(height: 20),
                          _buildPlanHeader(context),
                          const SizedBox(height: 10),
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

  // ───────────────────────── هدر خوش‌آمد ─────────────────────────

  Widget _buildGreeting(BuildContext context) {
    final name = _guestName ?? '';
    final greeting = name.isEmpty
        ? _t(
            'guest_home_greeting_anon',
            'سلام، مهمان عزیز',
            'Hello, dear guest',
          )
        : _t('guest_home_greeting_name', 'سلام {name}', 'Hello, {name}')
            .replaceAll('{name}', name);

    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTok.accent(context).withValues(alpha: 0.85),
                AppTok.accentSoft(context).withValues(alpha: 0.75),
              ],
            ),
            border: Border.all(
              color: AppTok.card(context).withValues(alpha: 0.7),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTok.accentSoft(context).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _monogram(
                widget.invitation.groomName,
                widget.invitation.brideName,
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 15,
                fontWeight: FontWeight.w800,
                fontFamily: 'serif',
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTok.text(context),
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _t(
                  'guest_home_welcome_sub',
                  'حضور شما قاب خاطرات ما را کامل می‌کند',
                  'Your presence completes our story',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────── کارت Hero + شمارش معکوس ─────────────────────────

  Widget _buildHero(BuildContext context) {
    final dark = AppTok.isDark(context);
    final inv = widget.invitation;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTok.card(context),
            AppTok.cardSoft(context).withValues(alpha: 0.9),
            AppTok.accentSoft(context).withValues(alpha: dark ? 0.16 : 0.30),
          ],
        ),
        border: Border.all(
          color: AppTok.accent(context).withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTok.accentSoft(context).withValues(alpha: dark ? 0.14 : 0.30),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppTok.shadow(context),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          // نام‌های زنده از سند مراسم (همان استریم عمومی که خانه قبلاً داشت)
          stream: FirebaseFirestore.instance
              .collection('weddings')
              .doc(widget.weddingId)
              .snapshots(),
          builder: (context, snap) {
            final d = snap.data?.data() ?? {};
            final groom = (d['groomName'] ?? inv.groomName).toString().trim();
            final bride = (d['brideName'] ?? inv.brideName).toString().trim();
            final title = groom.isNotEmpty && bride.isNotEmpty
                ? '$groom  &  $bride'
                : inv.coupleTitle;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // لیبل نرم بالای کارت
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTok.accent(context).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: AppTok.accent(context).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      _t('guest_home_upcoming', 'جشن پیشِ رو', 'Upcoming'),
                      style: TextStyle(
                        color: AppTok.accentDeep(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTok.text(context),
                    fontSize: 26,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 18),
                _buildCountdown(context),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: AppTok.border(context).withValues(alpha: 0.8),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.weddingDate == null
                                ? AppLang.tr('to_be_announced')
                                : '${_weekDay(inv.weddingDate!)} · ${_dateLine(inv.weddingDate!)}',
                            style: TextStyle(
                              color: AppTok.text(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (inv.venueName.trim().isNotEmpty ||
                              inv.venueCity.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${AppLang.tr('location')}: '
                              '${[
                                if (inv.venueName.trim().isNotEmpty)
                                  inv.venueName.trim(),
                                if (inv.venueCity.trim().isNotEmpty)
                                  inv.venueCity.trim(),
                              ].join(AppLang.I.isFa ? '، ' : ', ')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTok.textSoft(context),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _detailsButton(context),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _detailsButton(BuildContext context) {
    final onAccent =
        AppTok.isDark(context) ? AppDarkPalette.background : Colors.white;
    return Material(
      color: AppTok.accent(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _goTab(1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mail_outline, color: onAccent, size: 15),
              const SizedBox(width: 6),
              Text(
                _t(
                  'guest_home_view_details',
                  'جزئیات دعوت‌نامه',
                  'View invitation',
                ),
                style: TextStyle(
                  color: onAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// شمارش معکوس: اعداد همیشه در چیدمان LTR؛ بدون عدد منفی.
  Widget _buildCountdown(BuildContext context) {
    final target = _target;

    if (target == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
        decoration: BoxDecoration(
          color: AppTok.cardSoft(context).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTok.border(context)),
        ),
        child: Text(
          AppLang.tr('to_be_announced'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTok.textSoft(context),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final diff = target.difference(_now);

    if (diff.isNegative || diff == Duration.zero) {
      // امروز یا بعد از مراسم — هرگز عدد منفی نشان نده
      final isToday = _now.year == target.year &&
          _now.month == target.month &&
          _now.day == target.day;
      final headline = isToday
          ? _t('guest_home_today', 'امروز جشن ماست', 'Today is the day')
          : _t(
              'guest_home_started',
              'جشن آغاز شد',
              'The celebration has begun',
            );
      final sub = _t(
        'guest_home_started_sub',
        'ممنون که این لحظه‌ها را با ما قسمت می‌کنید',
        'Thank you for sharing these moments with us',
      );

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
        decoration: BoxDecoration(
          color: AppTok.accent(context).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTok.accent(context).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.celebration_outlined,
              color: AppTok.accent(context),
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTok.text(context),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTok.textSoft(context),
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final mins = diff.inMinutes % 60;
    final secs = diff.inSeconds % 60;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          _segment(context, days.toString(), 'guest_home_days', 'روز', 'DAYS'),
          _colon(context),
          _segment(
            context,
            hours.toString().padLeft(2, '0'),
            'guest_home_hours',
            'ساعت',
            'HOURS',
          ),
          _colon(context),
          _segment(
            context,
            mins.toString().padLeft(2, '0'),
            'guest_home_mins',
            'دقیقه',
            'MINS',
          ),
          _colon(context),
          _segment(
            context,
            secs.toString().padLeft(2, '0'),
            'guest_home_secs',
            'ثانیه',
            'SECS',
          ),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, String value, String key, String fa,
      String en) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTok.cardSoft(context).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTok.border(context).withValues(alpha: 0.9),
          ),
        ),
        child: Column(
          children: [
            Text(
              _fa(value),
              style: TextStyle(
                color: AppTok.text(context),
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _t(key, fa, en),
              style: TextStyle(
                color: AppTok.textSoft(context),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colon(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: TextStyle(
          color: AppTok.accent(context).withValues(alpha: 0.75),
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ───────────────────────── مسیر مهمان ─────────────────────────

  Widget _buildPlanHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('guest_home_plan_title', 'مسیر مهمان', 'Your plan'),
          style: TextStyle(
            color: AppTok.text(context),
            fontSize: 15.5,
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
            fontSize: 11.5,
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
        // فقط اگر واقعاً عکسی روی این دستگاه ثبت شده (داده محلی موجود)
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

    // فاصله بین کارت‌ها
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
