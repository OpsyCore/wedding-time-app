import 'dart:async';
import 'dart:math' show pi;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_effect_controller.dart';
import '../core/app_effects.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../core/hero_styles.dart';
import '../widgets/app_drawer.dart';
import '../widgets/effect_background.dart';
import '../widgets/floral_decor.dart';
import '../widgets/page_glass.dart';
import '../widgets/wedding_progress_bar.dart';
import '../widgets/wedding_time_header.dart';
import 'couple_profile_screen.dart';
import 'vendors_screen.dart';

class HomeScreen extends StatefulWidget {
  final String weddingId;
  final void Function(int index)? onNavigateToTab;

  const HomeScreen({
    super.key,
    required this.weddingId,
    this.onNavigateToTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  DateTime? weddingDate;
  String? role;
  String? brideName;
  String? groomName;
  String? bridePhoto;
  String? groomPhoto;
  String? coverPhoto;
  String _nameOrder = 'groom_first';
  double? _profileComplete;

  late AnimationController _pulse;
  late Animation<double> _pulseScale;

  String _effectStyleId = AppEffectStyle.noneId;

  // ── هیروی قابل‌شخصی‌سازی (بنر + قلب) ──
  String _heroBannerId = kDefaultHeroBannerId; // none
  String _heroHeartId = kDefaultHeroHeartId; // crimson
  bool _heroHeartVisible = true;
  bool _heroBannerAnimated = true;

  Duration remaining = Duration.zero;

  Timer? _tickTimer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _weddingSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _musicSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  DocumentReference<Map<String, dynamic>> get _weddingDoc =>
      FirebaseFirestore.instance.collection('weddings').doc(widget.weddingId);

  DocumentReference<Map<String, dynamic>> get _profileDoc =>
      _weddingDoc.collection('profile').doc('main');

  DocumentReference<Map<String, dynamic>> get _musicSettingsDoc =>
      _weddingDoc.collection('musicSettings').doc('main');

  CollectionReference<Map<String, dynamic>> get _checklistRef =>
      _weddingDoc.collection('checklist');

  CollectionReference<Map<String, dynamic>> get _guestsRef =>
      _weddingDoc.collection('guests');

  CollectionReference<Map<String, dynamic>> get _budgetGroupsRef =>
      _weddingDoc.collection('budgetGroups');

  CollectionReference<Map<String, dynamic>> get _vendorsRef =>
      _weddingDoc.collection('vendors');

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _weddingDoc.collection('calendarEvents');

  // استریم‌ها فقط یک‌بار ساخته می‌شوند؛ اگر داخل build هر بار snapshots()
  // صدا زده شود، هر rebuild (مثل تیک‌تاک ثانیه‌ای شمارش معکوس) باعث
  // subscribe مجدد و خواندن دوبارهٔ همهٔ اسناد می‌شود و سهمیهٔ رایگان را می‌سوزاند.
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _checklistStream =
      _checklistRef.snapshots();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _guestsStream =
      _guestsRef.snapshots();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _budgetGroupsStream =
      _budgetGroupsRef.snapshots();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _vendorsStream =
      _vendorsRef.snapshots();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _eventsStream =
      _eventsRef.snapshots();

  bool get _dark => AppTok.isDark(context);

  Color get _brandGreenSoft =>
      _dark ? AppDarkPalette.brandGreenSoft : AppPalette.brandGreenSoft;
  Color get _brandBlushSoft =>
      _dark ? AppDarkPalette.brandBlushSoft : AppPalette.brandBlushSoft;
  Color get _brandBlush =>
      _dark ? AppDarkPalette.brandBlush : AppPalette.brandBlush;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    _pulse.repeat(reverse: true);

    _weddingSub = _weddingDoc.snapshots().listen((doc) {
      final data = doc.data() ?? {};
      final timestamp = data['weddingDate'] as Timestamp?;
      setState(() {
        weddingDate = timestamp?.toDate();

        if ((data['brideName']?.toString() ?? '').trim().isNotEmpty) {
          brideName = data['brideName']?.toString();
        }
        if ((data['groomName']?.toString() ?? '').trim().isNotEmpty) {
          groomName = data['groomName']?.toString();
        }

        bridePhoto ??= _firstUrl(data, [
          'bridePhoto',
          'bridePhotoUrl',
          'brideImage',
          'brideAvatar',
        ]);
        groomPhoto ??= _firstUrl(data, [
          'groomPhoto',
          'groomPhotoUrl',
          'groomImage',
          'groomAvatar',
        ]);
        coverPhoto ??= _firstUrl(data, [
          'coverPhoto',
          'coverUrl',
          'couplePhoto',
          'couplePhotoUrl',
          'heroImage',
        ]);

        final p = data['profileCompletePercent'];
        if (p is num) _profileComplete = p.toDouble().clamp(0.0, 1.0);

        final style = data['effectStyleId']?.toString().trim();
        if (style != null && style.isNotEmpty) {
          _effectStyleId = style;
        } else if (data['effectsParticles'] == true) {
          _effectStyleId = AppEffectStyle.goldId;
        }
      });
      _updateRemaining();
    });

    _profileSub = _profileDoc.snapshots().listen((doc) {
      final p = doc.data();
      if (p == null) return;
      final newBanner = (p[heroBannerField] ?? kDefaultHeroBannerId).toString();
      final newHeart = (p[heroHeartField] ?? kDefaultHeroHeartId).toString();
      final newVisible = p[heroHeartVisibleField] is bool ? p[heroHeartVisibleField] as bool : true;
      final newAnimated = p[heroBannerAnimatedField] is bool ? p[heroBannerAnimatedField] as bool : true;
      final changedAnimated = newAnimated != _heroBannerAnimated;
      setState(() {
        final bf = p['brideFullName']?.toString().trim();
        final gf = p['groomFullName']?.toString().trim();
        if (bf != null && bf.isNotEmpty) brideName = bf;
        if (gf != null && gf.isNotEmpty) groomName = gf;

        final bp = _emptyToNull(p['bridePhotoUrl']?.toString());
        final gp = _emptyToNull(p['groomPhotoUrl']?.toString());
        final cp = _emptyToNull(p['couplePhotoUrl']?.toString());
        if (bp != null) bridePhoto = bp;
        if (gp != null) groomPhoto = gp;
        if (cp != null) coverPhoto = cp;

        final order = p['nameOrder']?.toString();
        if (order == 'bride_first' || order == 'groom_first') {
          _nameOrder = order!;
        }

        final pct = p['completePercent'];
        if (pct is num) {
          _profileComplete = pct.toDouble().clamp(0.0, 1.0);
        } else {
          final pi = p['completePercentInt'];
          if (pi is num) {
            _profileComplete = (pi.toDouble() / 100).clamp(0.0, 1.0);
          }
        }

        _heroBannerId = newBanner.isEmpty ? kDefaultHeroBannerId : newBanner;
        _heroHeartId = newHeart.isEmpty ? kDefaultHeroHeartId : newHeart;
        _heroHeartVisible = newVisible;
        _heroBannerAnimated = newAnimated;
      });
      // کنترل انیمیشن قلب/بنر
      if (changedAnimated) {
        if (_heroBannerAnimated) {
          if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
        } else {
          _pulse.stop();
          _pulse.value = 0;
        }
      }
    });

    _musicSub = _musicSettingsDoc.snapshots().listen((doc) {
      final m = doc.data();
      if (m == null) return;
      setState(() {
        final effects = m['effects'];
        String? styleId;
        if (effects is Map) {
          styleId = effects['styleId']?.toString().trim();
          if ((styleId == null || styleId.isEmpty) &&
              effects['particles'] == true) {
            styleId = AppEffectStyle.goldId;
          }
        }
        styleId ??= m['effectStyleId']?.toString().trim();
        if (styleId != null && styleId.isNotEmpty) {
          _effectStyleId = styleId;
        }
      });
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userSub = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen((doc) {
        setState(() {
          role = doc.data()?['role']?.toString();
        });
      });
    }

    _tickTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemaining(),
    );
  }

  String? _emptyToNull(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  String? _firstUrl(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  void _updateRemaining() {
    if (weddingDate == null) {
      if (!mounted) return;
      setState(() => remaining = Duration.zero);
      return;
    }
    final diff = weddingDate!.difference(DateTime.now());
    if (!mounted) return;
    setState(() {
      remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _tickTimer?.cancel();
    _weddingSub?.cancel();
    _profileSub?.cancel();
    _musicSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }

  String get _greetingName {
    if (role == 'bride' && (brideName ?? '').isNotEmpty) {
      return brideName!.split(' ').first;
    }
    if (role == 'groom' && (groomName ?? '').isNotEmpty) {
      return groomName!.split(' ').first;
    }
    return '';
  }

  static const _persianDigits = [
    '۰',
    '۱',
    '۲',
    '۳',
    '۴',
    '۵',
    '۶',
    '۷',
    '۸',
    '۹',
  ];

  String _faDigits(String input) {
    return input.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? _persianDigits[i] : c;
    }).join();
  }

  String _displayNum(Object n) {
    final s = n.toString();
    return AppLang.I.isFa ? _faDigits(s) : s;
  }

  String _formatAmount(num amount) {
    final intPart = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i != 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return _displayNum(buffer.toString());
  }

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return _displayNum('${d.year}/$m/$day');
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _progressMessage(double p) {
    if (p <= 0) return AppLang.tr('progress_start');
    if (p < 0.25) return AppLang.tr('progress_good_start');
    if (p < 0.5) return AppLang.tr('progress_shaping');
    if (p < 0.75) return AppLang.tr('progress_great');
    if (p < 1) return AppLang.tr('progress_almost');
    return AppLang.tr('progress_ready');
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inNextDays(DateTime date, int days) {
    final now = _dateOnly(DateTime.now());
    final end = now.add(Duration(days: days));
    final d = _dateOnly(date);
    return !d.isBefore(now) && !d.isAfter(end);
  }

  bool _isOverdue(DateTime date) {
    final now = _dateOnly(DateTime.now());
    return _dateOnly(date).isBefore(now);
  }

  DateTime? _parseDocDate(Map<String, dynamic> data) {
    for (final k in [
      'date',
      'eventDate',
      'dueDate',
      'startAt',
      'startDate',
      'weddingDate',
      'nextPaymentDue',
    ]) {
      final v = data[k];
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
    }
    return null;
  }

  String _titleOf(Map<String, dynamic> data, {String? fallback}) {
    final fb = fallback ?? AppLang.tr('untitled');
    for (final k in ['title', 'name', 'text', 'label']) {
      final v = data[k]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return fb;
  }

  Future<Map<String, int>> _calculateBudgetTotals(List<String> groupIds) async {
    int estimated = 0;
    int actual = 0;
    for (final groupId in groupIds) {
      final expenses =
          await _budgetGroupsRef.doc(groupId).collection('expenses').get();
      for (final doc in expenses.docs) {
        final data = doc.data();
        estimated += ((data['estimatedAmount'] ?? 0) as num).toInt();
        actual += ((data['actualAmount'] ?? 0) as num).toInt();
      }
    }
    return {'estimated': estimated, 'actual': actual};
  }

  void _goTab(int index) => widget.onNavigateToTab?.call(index);

  void _openVendors() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VendorsScreen(weddingId: widget.weddingId),
      ),
    );
  }

  void _openCoupleProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoupleProfileScreen(weddingId: widget.weddingId),
      ),
    );
  }

  double _homeEffectIntensity(String id) {
    switch (id) {
      case AppEffectStyle.lavenderId:
      case AppEffectStyle.roseId:
        return 0.85;
      case AppEffectStyle.goldId:
      case AppEffectStyle.champagneId:
        return 0.8;
      case AppEffectStyle.midnightId:
        return 0.7;
      default:
        return 0.75;
    }
  }

  bool _isChecklistFocus(_FocusItem e) {
    return e.subtitle == AppLang.tr('checklist_due_today') ||
        e.subtitle == AppLang.tr('due_this_week') ||
        e.subtitle == AppLang.tr('remaining_checklist_task');
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
        return Directionality(
          textDirection: AppLang.I.direction,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            drawer: AppDrawer(weddingId: widget.weddingId),
            body: SafeArea(
              child: Column(
                children: [
                  Builder(
                    builder: (context) => WeddingTimeHeader(
                      weddingId: widget.weddingId,
                      onMenuPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: FloralDecor(intensity: 1.05),
                        ),
                        // new global light effect (very subtle)
                        const Positioned.fill(
                          child: EffectBackground(
                            opacity: 0.35,
                            enableBlur: false,
                            child: SizedBox.expand(),
                          ),
                        ),
                        Positioned.fill(
                          child: AppEffectOverlay(
                            effectId: _effectStyleId,
                            intensity: _homeEffectIntensity(_effectStyleId),
                          ),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildGreeting(),
                              const SizedBox(height: 14),
                              _buildCoupleHero(),
                              if (_profileComplete != null &&
                                  _profileComplete! < 1) ...[
                                const SizedBox(height: 12),
                                _buildProfileNudge(),
                              ],
                              const SizedBox(height: 14),
                              _buildTodayWeekSection(),
                              const SizedBox(height: 14),
                              _buildProgressCard(),
                            ],
                          ),
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

  Widget _buildProfileNudge() {
    // TASK 3 — dual profile nudge uses premium thin progress bar + live binding
    final progress = (_profileComplete ?? 0).clamp(0.0, 1.0);
    final pct = (progress * 100).round().clamp(0, 100);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);
    final accentSoft = AppTok.accentSoft(context);
    final isDark = AppTok.isDark(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openCoupleProfile,
        borderRadius: BorderRadius.circular(18),
        child: PageGlass(
          opacity: isDark ? 0.86 : 0.90,
          blurSigma: 14,
          borderRadius: 18,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _brandBlushSoft.withValues(alpha: 0.9),
                          AppTok.accent(context).withValues(alpha: 0.18),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTok.accent(context).withValues(alpha: 0.18),
                      ),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: accentSoft,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppLang.tr('couple_profile'),
                                style: TextStyle(
                                  color: text,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                AppLang.I.isFa
                                    ? '${_displayNum(pct)}${AppLang.tr('percent_unit')}'
                                    : '$pct${AppLang.tr('percent_unit')}',
                                style: TextStyle(
                                  color: AppTok.accentDeep(context),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _progressMessage(progress),
                          style: TextStyle(
                            color: textSoft,
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    AppLang.I.isFa ? Icons.chevron_left : Icons.chevron_right,
                    color: accent,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              WeddingProgressBar(
                value: progress,
                size: WeddingProgressSize.thin,
                animate: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoupleHero() {
    final brideRaw = (brideName ?? '').trim();
    final groomRaw = (groomName ?? '').trim();
    final bride = brideRaw.isEmpty ? AppLang.tr('bride') : brideRaw;
    final groom = groomRaw.isEmpty ? AppLang.tr('groom') : groomRaw;

    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    final isWeddingDay =
        weddingDate != null && _isSameDay(weddingDate!, DateTime.now());
    final isPast = weddingDate != null &&
        weddingDate!.isBefore(DateTime.now()) &&
        !isWeddingDay;

    String topText;
    if (AppLang.I.isFa) {
      if (groomRaw.isNotEmpty && brideRaw.isNotEmpty) {
        topText = 'تا روز جشن $groom با $bride';
      } else if (groomRaw.isNotEmpty || brideRaw.isNotEmpty) {
        final title = '$groom & $bride'.trim();
        topText = 'تا روز جشن $title';
      } else {
        topText = 'تا روز جشن';
      }
    } else {
      if (groomRaw.isNotEmpty && brideRaw.isNotEmpty) {
        topText = 'Until our special day — $groom & $bride';
      } else if (groomRaw.isNotEmpty || brideRaw.isNotEmpty) {
        final base = AppLang.tr('until_celebration');
        topText = '$base — $groom & $bride';
      } else {
        topText = AppLang.tr('until_celebration');
      }
    }

    final bgPhoto = (coverPhoto ?? '').trim();

    final accent = AppTok.accent(context);
    final cardSoft = AppTok.cardSoft(context);
    final textSoft = AppTok.textSoft(context);
    final accentDeep = AppTok.accentDeep(context);

    return GestureDetector(
      onTap: _openCoupleProfile,
      child: PageGlass(
        opacity: 0.86,
        blurSigma: 12,
        borderRadius: 24,
        padding: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: AppTok.heroGradient(context),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // ── بنر انتخابی یا عکس زوج به‌عنوان پس‌زمینه ──
                if (_heroBannerId != 'none')
                  Positioned.fill(child: _buildHeroBanner(_heroBannerId))
                else if (bgPhoto.isNotEmpty)
                  Positioned.fill(
                    child: Opacity(
                      opacity: _dark ? 0.18 : 0.12,
                      child: Image.network(
                        bgPhoto,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                  ),
                // دکور دایره‌ای نرم — فقط وقتی بنر نداریم
                if (_heroBannerId == 'none') ...[
                  Positioned(
                    top: -40,
                    left: -20,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _brandGreenSoft.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    right: -10,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _brandBlushSoft.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  child: Column(
                    children: [
                      Text(
                        isWeddingDay
                            ? AppLang.tr('today_is_your_day')
                            : isPast
                                ? AppLang.tr('married_life_congrats')
                                : topText,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _dark
                              ? Colors.white.withValues(alpha: 0.96)
                              : AppTok.text(context),
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // ── وسط: قلب (قابل مخفی‌سازی) — وقتی مخفی فقط بک‌گراند دیده می‌شود ──
                      if (_heroHeartVisible)
                        Center(
                          child: _buildBigPulsingHeart(
                            groom: groom,
                            bride: bride,
                            date: weddingDate,
                            heartId: _heroHeartId,
                            animated: _heroBannerAnimated,
                          ),
                        )
                      else
                        const SizedBox(height: 8),
                      const SizedBox(height: 28),
                      // پایین: شمارش معکوس
                      if (weddingDate == null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: cardSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            AppLang.tr('wedding_date_not_set'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textSoft, fontSize: 12),
                          ),
                        )
                      else if (isWeddingDay)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _brandGreenSoft,
                                _brandBlushSoft.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            AppLang.tr('wedding_day_banner'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: accentDeep,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        )
                      else if (isPast)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: cardSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '${AppLang.tr('days_since_wedding_prefix')}${_displayNum((-weddingDate!.difference(DateTime.now()).inDays).abs())} ${AppLang.tr('days_since_wedding')}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textSoft, fontSize: 12),
                          ),
                        )
                      else
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            children: [
                              Expanded(
                                child: _timeBox(
                                  _displayNum(days),
                                  AppLang.tr('day'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _timeBox(
                                  _displayNum(_two(hours)),
                                  AppLang.tr('hour'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _timeBox(
                                  _displayNum(_two(minutes)),
                                  AppLang.tr('minute'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _timeBox(
                                  _displayNum(_two(seconds)),
                                  AppLang.tr('second'),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ویجت بنر پشت هیرو — ۵ طرح گرادیانی شبیه اسکرین‌شات
  Widget _buildHeroBanner(String id) {
    final opt = HeroBannerOption.byId(id);
    if (id == 'none') return const SizedBox();
    // برای هر بنر یک گرادیان + یک قوس مرکزی ساده
    Widget arch;
    switch (id) {
      case 'skyHeart':
        arch = Center(
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2.5),
            ),
            child: Center(
              child: Icon(Icons.favorite_border, size: 56, color: Colors.white.withValues(alpha: 0.45)),
            ),
          ),
        );
        break;
      case 'royalBlue':
        arch = Stack(
          children: [
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(child: Container(color: const Color(0xFF1A4A7A).withValues(alpha: 0.35))),
                  Container(width: 1, color: Colors.white.withValues(alpha: 0.12)),
                  Expanded(child: Container(color: const Color(0xFF0F2F56).withValues(alpha: 0.18))),
                ],
              ),
            ),
            Center(
              child: Container(
                width: 140,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(70)),
                  border: Border.all(color: const Color(0xFF7EB8E8).withValues(alpha: 0.55), width: 1.4),
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
          ],
        );
        break;
      case 'iceGarden':
        arch = Center(
          child: Container(
            width: 150,
            height: 195,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(75)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.6),
              boxShadow: [BoxShadow(color: const Color(0xFF6FA8D8).withValues(alpha: 0.25), blurRadius: 18)],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(74)),
              child: Container(
                color: const Color(0xFF9CC6E8).withValues(alpha: 0.22),
                child: Center(child: Icon(Icons.ac_unit_rounded, size: 40, color: Colors.white.withValues(alpha: 0.55))),
              ),
            ),
          ),
        );
        break;
      case 'crimsonPetal':
        arch = Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.2, -0.3),
                    radius: 1.1,
                    colors: [Colors.white.withValues(alpha: 0.18), Colors.transparent],
                  ),
                ),
              ),
            ),
            Container(
              width: 148,
              height: 195,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(74)),
                border: Border.all(color: const Color(0xFFFFD1DC).withValues(alpha: 0.7), width: 1.5),
              ),
              child: Center(child: Icon(Icons.local_florist_rounded, size: 44, color: const Color(0xFFFFD1DC).withValues(alpha: 0.85))),
            ),
          ],
        );
        break;
      case 'classicIvory':
        arch = Center(
          child: Container(
            width: 152,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border.all(color: const Color(0xFFC2A981).withValues(alpha: 0.6), width: 1.2),
              color: Colors.white.withValues(alpha: 0.55),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_rounded, size: 34, color: const Color(0xFF9C8458).withValues(alpha: 0.9)),
                const SizedBox(height: 6),
                Container(width: 60, height: 1, color: const Color(0xFFC2A981).withValues(alpha: 0.5)),
              ],
            ),
          ),
        );
        break;
      default:
        arch = const SizedBox();
    }

    Widget banner = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: opt.gradient.length >= 2 ? opt.gradient : [opt.gradient.first, opt.gradient.first],
        ),
      ),
      child: arch,
    );

    // انیمیشن ملایم بنر — وقتی فعال باشد کمی برق می‌زند
    if (_heroBannerAnimated) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1.0),
        duration: const Duration(milliseconds: 1600),
        curve: Curves.easeInOut,
        builder: (context, v, child) => Opacity(opacity: v, child: child),
        child: banner,
        // برای لوپ از AnimatedBuilder استفاده نمی‌کنیم تا سبک بماند؛
        // همین فیدِ اولیه کافی است — پالسِ قلب جداست
      );
    }
    return banner;
  }

  /// وقتی قلب مخفی است — فقط عکس دو نفره + کادر شیشه‌ای
  Widget _buildCouplePhotoOnly(String bgPhoto) {
    final hasPhoto = bgPhoto.isNotEmpty;
    return Container(
      width: 210,
      height: 192,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppTok.card(context).withValues(alpha: 0.92),
        border: Border.all(color: AppTok.border(context), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
        image: hasPhoto
            ? DecorationImage(image: NetworkImage(bgPhoto), fit: BoxFit.cover, onError: (_, __) {})
            : null,
      ),
      child: hasPhoto
          ? null
          : Center(
              child: Icon(Icons.favorite_rounded, size: 64, color: AppTok.accent(context).withValues(alpha: 0.85)),
            ),
    );
  }

  /// قلب بزرگ تپنده — ۶ طرح دقیقاً مثل عکس ارسالی
  Widget _buildBigPulsingHeart({
    required String groom,
    required String bride,
    DateTime? date,
    String heartId = kDefaultHeroHeartId,
    bool animated = true,
  }) {
    final coupleLine = _nameOrder == 'bride_first' ? '$bride  &  $groom' : '$groom  &  $bride';
    final dateStr = date != null ? _formatDate(date) : '';
    final heart = HeroHearts.byId(heartId);

    // همه قلب‌ها متن سفید با هاله مشکی مات (خواسته کاربر)
    const textColor = Colors.white;
    const subColor = Colors.white;
    const dateColor = Colors.white;

    // سایه پشت هر قلب بر اساس همان رنگ پایه
    Widget heartStack = SizedBox(
      width: 210,
      height: 192,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 210,
            height: 192,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: heart.base.withValues(alpha: 0.30), blurRadius: 28, spreadRadius: 6)],
            ),
          ),
          // ── قلب پایه + بافت هر طرح ──
          Positioned.fill(
            child: ClipPath(
              clipper: _HeartClipper(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // رنگ پایه
                  Container(color: heart.base),
                  // بافت‌های اختصاصی
                  if (heart.style == HeartStyle.blueWatercolor)
                    // رگه‌های آبرنگی — چند لایه گرادیان + لکه
                    CustomPaint(painter: _WatercolorPainter()),
                  if (heart.style == HeartStyle.goldVelvet)
                    // مخمل طلایی — گرادیان عمودی تیره/روشن + هایلایت چپ
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFFD4A000), Color(0xFFF5C518), Color(0xFFE6B800), Color(0xFFC89A00)],
                          stops: [0.0, 0.35, 0.65, 1.0],
                        ),
                      ),
                    ),
                  if (heart.style == HeartStyle.goldVelvet)
                    // درز عمودی وسط — مثل دو تکه پارچه دوخته شده
                    Align(
                      alignment: Alignment.center,
                      child: Container(width: 1.2, color: const Color(0xFF8C6F00).withValues(alpha: 0.55)),
                    ),
                  if (heart.style == HeartStyle.purpleBow || heart.style == HeartStyle.greenRuffle || heart.style == HeartStyle.pinkRuffleBow)
                    // بافت نمدی خیلی ملایم (نویز نقطه‌ای)
                    Opacity(
                      opacity: 0.12,
                      child: CustomPaint(painter: _FeltNoisePainter(base: heart.base)),
                    ),
                ],
              ),
            ),
          ),

          // ── لایه تزئین قلب ──
          // 1) بنفش پاپیونی — دوخت سفید دَش + پاپیون یاسی
          if (heart.style == HeartStyle.purpleBow) ...[
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: ClipPath(
                  clipper: _HeartClipper(),
                  child: CustomPaint(painter: _DashedStitchPainter(color: Colors.white.withValues(alpha: 0.85), strokeWidth: 1.2, dash: 6, gap: 4)),
                ),
              ),
            ),
            Positioned(
              top: 10,
              child: _buildBow(width: 36, height: 22, color: const Color(0xFFD8C6F0), knotColor: const Color(0xFFB89EE8), shadow: true),
            ),
          ],

          // 2) صورتی ستاره‌ای — ستاره‌های رنگی پراکنده
          if (heart.style == HeartStyle.pinkStars) ...[
            for (final s in _pinkStarData)
              Positioned(
                left: s.dx * 210,
                top: s.dy * 192,
                child: Transform.rotate(
                  angle: s.angle,
                  child: Icon(Icons.star, size: s.size, color: s.color.withValues(alpha: 0.95)),
                ),
              ),
          ],

          // 3) آبی آبرنگی — هیچ تزئین اضافه، فقط بافت آبرنگی بالا

          // 5) صورتی چین‌دار — لبه چین‌دار (ruffled) + پاپیون قرمز کوچک
          if (heart.style == HeartStyle.pinkRuffleBow) ...[
            // لبه چین‌دار — دایره‌های کوچک صورتی تیره دور قلب
            Positioned.fill(child: CustomPaint(painter: _RufflePainter(ruffleColor: const Color(0xFFF8BBD0), stitchColor: Colors.white.withValues(alpha: 0.55)))),
            Positioned(
              top: 8,
              child: _buildBow(width: 22, height: 14, color: const Color(0xFFE53935), knotColor: const Color(0xFFB71C1C), shadow: true, small: true),
            ),
          ],

          // 6) سبز چین‌دار
          if (heart.style == HeartStyle.greenRuffle) ...[
            Positioned.fill(child: CustomPaint(painter: _RufflePainter(ruffleColor: const Color(0xFF7CB342), stitchColor: Colors.white.withValues(alpha: 0.70)))),
          ],

          // 4) طلایی و همه — ستاره‌های کوچک ظریف برای درخشش (اختیاری، خیلی کم)
          if (heart.style == HeartStyle.goldVelvet)
            Positioned(
              top: 22,
              right: 28,
              child: Icon(Icons.auto_awesome, size: 18, color: Colors.white.withValues(alpha: 0.55)),
            ),

          // برای همه قلب‌ها — ستاره سفید ظریف بالا راست و پایین چپ (مثل رفرنس قبلی) فقط برای عمق
          // ولی برای ۶ قلب جدید خیلی کم‌رنگ تا شبیه عکس بماند
          if (heart.style == HeartStyle.purpleBow || heart.style == HeartStyle.pinkStars)
            Positioned(top: 18, right: 22, child: Icon(Icons.auto_awesome, size: 14, color: Colors.white.withValues(alpha: 0.22))),

          // ── متن داخل — کاملاً وسط + هاله مشکی مات ──
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 42, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(coupleLine,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          height: 1.2,
                          shadows: [
                            Shadow(color: Color(0x8C000000), blurRadius: 6, offset: Offset(0, 1.2)),
                            Shadow(color: Color(0x59000000), blurRadius: 12),
                          ])),
                  const SizedBox(height: 7),
                  Text(AppLang.I.isFa ? 'ما ازدواج می‌کنیم' : 'We are getting married',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: subColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          shadows: [
                            Shadow(color: Color(0x80000000), blurRadius: 5, offset: Offset(0, 1)),
                            Shadow(color: Color(0x4D000000), blurRadius: 10),
                          ])),
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(dateStr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: dateColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(color: Color(0x80000000), blurRadius: 5, offset: Offset(0, 1)),
                              Shadow(color: Color(0x4D000000), blurRadius: 10),
                            ])),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!animated) return heartStack;
    return ScaleTransition(scale: _pulseScale, child: heartStack);
  }

  /// پاپیون کوچک — دو لوب + گره وسط
  Widget _buildBow({required double width, required double height, required Color color, required Color knotColor, bool shadow = false, bool small = false}) {
    final lobeW = width * 0.38;
    final lobeH = height * 0.75;
    return Container(
      width: width,
      height: height,
      decoration: shadow ? BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 4, offset: const Offset(0, 2))]) : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: lobeW, height: lobeH, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(small ? 4 : 6))),
              SizedBox(width: width * 0.12, height: height * 0.5),
              Container(width: lobeW, height: lobeH, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(small ? 4 : 6))),
            ],
          ),
          Container(width: width * 0.22, height: height * 0.62, decoration: BoxDecoration(color: knotColor, borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }

  /// ستاره چهارپر کوچک — شبیه ستاره‌های رفرنس
  Widget _sparkle({required double size, required Color color, double angle = 0}) {
    return Transform.rotate(
      angle: angle,
      child: Icon(
        Icons.auto_awesome,
        size: size,
        color: color,
      ),
    );
  }

  Widget _personAvatar({
    required String? photoUrl,
    required String name,
  }) {
    final initial =
        name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    final accent = AppTok.accent(context);
    final card = AppTok.card(context);
    final textSoft = AppTok.textSoft(context);

    return Column(
      children: [
        SizedBox(
          width: 116,
          height: 106,
          child: Stack(
            children: [
              // حاشیهٔ گرادیانیِ قلب
              Positioned.fill(
                child: ClipPath(
                  clipper: _HeartClipper(),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent,
                          _brandBlush,
                          _brandGreenSoft,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // داخل قلب: عکس یا حرف اول نام
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(3.5),
                  child: ClipPath(
                    clipper: _HeartClipper(),
                    child: Container(
                      color: card,
                      child: photoUrl != null && photoUrl.isNotEmpty
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _avatarFallback(initial),
                            )
                          : _avatarFallback(initial),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 110,
          child: Text(
            name.split(' ').first,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textSoft,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback(String initial) {
    return Container(
      color: _brandGreenSoft.withValues(alpha: 0.55),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: AppTok.accentDeep(context),
            fontSize: 34,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
          ),
        ),
      ),
    );
  }

  Widget _timeBox(String value, String label) {
    final accentDeep = AppTok.accentDeep(context);
    final textSoft = AppTok.textSoft(context);

    return PageGlass(
      opacity: 0.84,
      blurSigma: 10,
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: accentDeep,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: textSoft,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayWeekSection() {
    final accent = AppTok.accent(context);
    final accentSoft = AppTok.accentSoft(context);
    final accentDeep = AppTok.accentDeep(context);
    final danger = AppTok.danger(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _checklistStream,
      builder: (context, checkSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _guestsStream,
          builder: (context, guestSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _vendorsStream,
              builder: (context, vendorSnap) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _eventsStream,
                  builder: (context, eventSnap) {
                    final items = <_FocusItem>[];
                    final now = DateTime.now();
                    final today = _dateOnly(now);

                    if (weddingDate != null) {
                      final wd = _dateOnly(weddingDate!);
                      if (_isSameDay(wd, today)) {
                        items.add(
                          _FocusItem(
                            icon: Icons.favorite,
                            color: accentSoft,
                            title: AppLang.tr('wedding_day_focus_title'),
                            subtitle: AppLang.tr('wedding_day_focus_sub'),
                            badge: AppLang.tr('today'),
                            isToday: true,
                            priority: 0,
                            onTap: () => _goTab(5),
                          ),
                        );
                      } else if (_inNextDays(weddingDate!, 7) &&
                          wd.isAfter(today)) {
                        final days = wd.difference(today).inDays;
                        items.add(
                          _FocusItem(
                            icon: Icons.celebration_outlined,
                            color: accent,
                            title:
                                '${AppLang.tr('wedding_in_days_prefix')}${_displayNum(days)}${AppLang.tr('wedding_in_days_suffix')}',
                            subtitle: AppLang.tr('review_week_plan'),
                            badge: AppLang.tr('this_week'),
                            isToday: false,
                            priority: 1,
                            onTap: () => _goTab(5),
                          ),
                        );
                      }
                    }

                    if (vendorSnap.hasData) {
                      for (final doc in vendorSnap.data!.docs) {
                        final data = doc.data();
                        final name =
                            (data['name'] ?? AppLang.tr('vendor_default'))
                                .toString();
                        final unpaid =
                            ((data['unpaidCount'] ?? 0) as num).toInt();
                        final nextDue =
                            (data['nextPaymentDue'] as Timestamp?)?.toDate();
                        final paidTotal =
                            ((data['paidTotal'] ?? 0) as num).toDouble();
                        final cost = ((data['cost'] ?? 0) as num).toDouble();
                        if (unpaid <= 0 || nextDue == null) continue;

                        final due = _dateOnly(nextDue);
                        final remain = cost - paidTotal;
                        final remainText = cost > 0
                            ? '${AppLang.tr('remaining_amount')}${_formatAmount(remain < 0 ? 0 : remain)}${AppLang.tr('toman_short')}'
                            : '${_displayNum(unpaid)}${AppLang.tr('open_installments')}';

                        if (_isOverdue(due)) {
                          items.add(
                            _FocusItem(
                              icon: Icons.warning_amber_rounded,
                              color: danger,
                              title:
                                  '${AppLang.tr('overdue_installment')} · $name',
                              subtitle:
                                  '${AppLang.tr('due_date')} ${_formatDate(due)} · $remainText',
                              badge: AppLang.tr('overdue'),
                              isToday: true,
                              priority: 0,
                              onTap: _openVendors,
                            ),
                          );
                        } else if (_isSameDay(due, today)) {
                          items.add(
                            _FocusItem(
                              icon: Icons.payments_outlined,
                              color: const Color(0xFFC2A45D),
                              title:
                                  '${AppLang.tr('due_today_installment')} · $name',
                              subtitle: remainText,
                              badge: AppLang.tr('today'),
                              isToday: true,
                              priority: 0,
                              onTap: _openVendors,
                            ),
                          );
                        } else if (_inNextDays(due, 7)) {
                          items.add(
                            _FocusItem(
                              icon: Icons.account_balance_wallet_outlined,
                              color: const Color(0xFFC4A484),
                              title:
                                  '${AppLang.tr('week_installment')} · $name',
                              subtitle:
                                  '${AppLang.tr('due_date')} ${_formatDate(due)} · $remainText',
                              badge: AppLang.tr('this_week'),
                              isToday: false,
                              priority: 2,
                              onTap: _openVendors,
                            ),
                          );
                        }
                      }
                    }

                    if (eventSnap.hasData) {
                      for (final doc in eventSnap.data!.docs) {
                        final data = doc.data();
                        final date = _parseDocDate(data);
                        if (date == null) continue;
                        final title = _titleOf(
                          data,
                          fallback: AppLang.tr('event_default'),
                        );
                        if (_isSameDay(_dateOnly(date), today)) {
                          items.add(
                            _FocusItem(
                              icon: Icons.calendar_today_outlined,
                              color: const Color(0xFF7FAE82),
                              title: title,
                              subtitle: AppLang.tr('event_today'),
                              badge: AppLang.tr('today'),
                              isToday: true,
                              priority: 1,
                              onTap: () => _goTab(5),
                            ),
                          );
                        } else if (_inNextDays(date, 7) &&
                            _dateOnly(date).isAfter(today)) {
                          items.add(
                            _FocusItem(
                              icon: Icons.event_outlined,
                              color: const Color(0xFF7FAE82),
                              title: title,
                              subtitle: _formatDate(date),
                              badge: AppLang.tr('this_week'),
                              isToday: false,
                              priority: 2,
                              onTap: () => _goTab(5),
                            ),
                          );
                        }
                      }
                    }

                    final openTasks =
                        <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                    if (checkSnap.hasData) {
                      for (final doc in checkSnap.data!.docs) {
                        final data = doc.data();
                        if (data['done'] == true) continue;
                        openTasks.add(doc);
                        final due = _parseDocDate(data);
                        if (due == null) continue;
                        final title = _titleOf(
                          data,
                          fallback: AppLang.tr('checklist_task'),
                        );
                        if (_isSameDay(_dateOnly(due), today)) {
                          items.add(
                            _FocusItem(
                              icon: Icons.checklist_rtl_outlined,
                              color: const Color(0xFF8E9C6B),
                              title: title,
                              subtitle: AppLang.tr('checklist_due_today'),
                              badge: AppLang.tr('today'),
                              isToday: true,
                              priority: 1,
                              onTap: () => _goTab(1),
                            ),
                          );
                        } else if (_inNextDays(due, 7) &&
                            _dateOnly(due).isAfter(today)) {
                          items.add(
                            _FocusItem(
                              icon: Icons.checklist_rtl_outlined,
                              color: const Color(0xFF8E9C6B),
                              title: title,
                              subtitle: AppLang.tr('due_this_week'),
                              badge: AppLang.tr('this_week'),
                              isToday: false,
                              priority: 3,
                              onTap: () => _goTab(1),
                            ),
                          );
                        }
                      }
                      final hasTaskFocus = items.any(_isChecklistFocus);
                      if (!hasTaskFocus && openTasks.isNotEmpty) {
                        for (final doc in openTasks.take(2)) {
                          items.add(
                            _FocusItem(
                              icon: Icons.task_alt_outlined,
                              color: const Color(0xFF8E9C6B),
                              title: _titleOf(
                                doc.data(),
                                fallback: AppLang.tr('open_task'),
                              ),
                              subtitle: AppLang.tr('remaining_checklist_task'),
                              badge: AppLang.tr('do_it'),
                              isToday: true,
                              priority: 4,
                              onTap: () => _goTab(1),
                            ),
                          );
                        }
                      }
                    }

                    if (guestSnap.hasData) {
                      final pending = guestSnap.data!.docs.where((d) {
                        final s = (d.data()['status'] ?? '').toString();
                        return s == 'pending' || s == 'invited';
                      }).length;
                      if (pending > 0) {
                        items.add(
                          _FocusItem(
                            icon: Icons.groups_outlined,
                            color: const Color(0xFFD1A36B),
                            title:
                                '${_displayNum(pending)}${AppLang.tr('guests_awaiting_rsvp')}',
                            subtitle: AppLang.tr('follow_rsvp'),
                            badge: AppLang.tr('guest_badge'),
                            isToday: false,
                            priority: 4,
                            onTap: () => _goTab(4),
                          ),
                        );
                      }
                    }

                    items.sort((a, b) {
                      if (a.isToday != b.isToday) {
                        return a.isToday ? -1 : 1;
                      }
                      return a.priority.compareTo(b.priority);
                    });

                    final todayItems =
                        items.where((e) => e.isToday).take(6).toList();
                    final weekItems =
                        items.where((e) => !e.isToday).take(6).toList();

                    return PageGlass(
                      opacity: 0.84,
                      blurSigma: 12,
                      borderRadius: 22,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                color: accent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLang.tr('today_and_this_week'),
                                style: TextStyle(
                                  color: text,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(today),
                            style: TextStyle(
                              color: textSoft,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            AppLang.tr('today'),
                            style: TextStyle(
                              color: accentDeep,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (todayItems.isEmpty)
                            _emptyFocus(AppLang.tr('no_urgent_today'))
                          else
                            ...todayItems.map(_focusTile),
                          const SizedBox(height: 14),
                          Text(
                            AppLang.tr('this_week'),
                            style: TextStyle(
                              color: accentDeep,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (weekItems.isEmpty)
                            _emptyFocus(AppLang.tr('no_plans_this_week'))
                          else
                            ...weekItems.map(_focusTile),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _emptyFocus(String text) {
    return PageGlass(
      opacity: 0.78,
      blurSigma: 10,
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Text(
        text,
        style: TextStyle(color: AppTok.textSoft(context), fontSize: 12.5),
      ),
    );
  }

  Widget _focusTile(_FocusItem item) {
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PageGlass(
        opacity: 0.80,
        blurSigma: 10,
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textSoft,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.badge,
                    style: TextStyle(
                      color: item.color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  AppLang.I.isFa ? Icons.chevron_left : Icons.chevron_right,
                  color: textSoft,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildGreeting() {
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accentSoft = AppTok.accentSoft(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _greetingName.isEmpty
                  ? AppLang.tr('hello')
                  : '${AppLang.tr('hello_name')}$_greetingName',
              style: TextStyle(
                color: text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.favorite, color: accentSoft, size: 15),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          AppLang.tr('home_welcome_sub'),
          style: TextStyle(color: textSoft, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    // TASK 3 — premium wedding progress card with shared WeddingProgressBar
    final isDark = AppTok.isDark(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final border = AppTok.border(context);
    final accent = AppTok.accent(context);
    final ringTrack = AppTok.ringTrack(context);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _checklistStream,
      builder: (context, checkSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _guestsStream,
          builder: (context, guestSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _budgetGroupsStream,
              builder: (context, budgetSnap) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _vendorsStream,
                  builder: (context, vendorSnap) {
                    int checkTotal = 0;
                    int checkDone = 0;
                    if (checkSnap.hasData) {
                      checkTotal = checkSnap.data!.docs.length;
                      checkDone = checkSnap.data!.docs
                          .where((d) => d.data()['done'] == true)
                          .length;
                    }
                    final checkPercent =
                        checkTotal == 0 ? 0.0 : checkDone / checkTotal;

                    int guestTotal = 0;
                    int guestConfirmed = 0;
                    int guestPending = 0;
                    int guestDeclined = 0;
                    if (guestSnap.hasData) {
                      guestTotal = guestSnap.data!.docs.length;
                      guestConfirmed = guestSnap.data!.docs
                          .where((d) => d.data()['status'] == 'confirmed')
                          .length;
                      guestPending = guestSnap.data!.docs.where((d) {
                        final s = (d.data()['status'] ?? '').toString();
                        return s == 'pending' || s == 'invited';
                      }).length;
                      guestDeclined = guestSnap.data!.docs
                          .where((d) => d.data()['status'] == 'declined')
                          .length;
                    }
                    final guestPercent =
                        guestTotal == 0 ? 0.0 : guestConfirmed / guestTotal;

                    int vendorTotal = 0;
                    int vendorDone = 0;
                    if (vendorSnap.hasData) {
                      vendorTotal = vendorSnap.data!.docs.length;
                      vendorDone = vendorSnap.data!.docs.where((d) {
                        final m = d.data();
                        return m['done'] == true ||
                            m['status'] == 'confirmed' ||
                            m['status'] == 'booked';
                      }).length;
                    }
                    final vendorPercent =
                        vendorTotal == 0 ? 0.0 : vendorDone / vendorTotal;

                    final groupIds =
                        budgetSnap.data?.docs.map((d) => d.id).toList() ?? [];

                    return FutureBuilder<Map<String, int>>(
                      future: _calculateBudgetTotals(groupIds),
                      builder: (context, budgetTotalSnap) {
                        final totals = budgetTotalSnap.data ??
                            {'estimated': 0, 'actual': 0};
                        final estimated = totals['estimated'] ?? 0;
                        final actual = totals['actual'] ?? 0;
                        final budgetPercent = estimated == 0
                            ? 0.0
                            : (actual / estimated).clamp(0.0, 1.0);

                        final overall = (checkPercent +
                                budgetPercent +
                                vendorPercent +
                                guestPercent) /
                            4;

                        final statusKey = overall <= 0
                            ? 'progress_status_not_started'
                            : overall < 0.4
                                ? 'progress_status_in_progress'
                                : overall < 0.85
                                    ? 'progress_status_almost_done'
                                    : 'progress_status_completed';

                        return PageGlass(
                          opacity: isDark ? 0.88 : 0.92,
                          blurSigma: 16,
                          borderRadius: 22,
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 60,
                                          height: 60,
                                          child: CircularProgressIndicator(
                                            value: 1,
                                            strokeWidth: 5,
                                            color: ringTrack,
                                          ),
                                        ),
                                        TweenAnimationBuilder<double>(
                                          tween: Tween<double>(
                                              begin: 0, end: overall),
                                          duration:
                                              const Duration(milliseconds: 520),
                                          curve: Curves.easeOutCubic,
                                              builder: (context, anim, _) =>
                                                  SizedBox(
                                            width: 60,
                                            height: 60,
                                            child: CircularProgressIndicator(
                                              value: anim,
                                              strokeWidth: 5,
                                              strokeCap: StrokeCap.round,
                                              color: accent,
                                              backgroundColor:
                                                  Colors.transparent,
                                            ),
                                          ),
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TweenAnimationBuilder<double>(
                                              tween: Tween<double>(
                                                  begin: 0,
                                                  end: (overall * 100)),
                                              duration: const Duration(
                                                  milliseconds: 500),
                                              curve: Curves.easeOutCubic,
                                              builder: (context, animPct, _) =>
                                                  Text(
                                                AppLang.I.isFa
                                                    ? '${_displayNum(animPct.round())}${AppLang.tr('percent_unit')}'
                                                    : '${_displayNum(animPct.round())}${AppLang.tr('percent_unit')}',
                                                style: TextStyle(
                                                  color: text,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 1),
                                            Container(
                                              width: 4,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: accent.withValues(
                                                    alpha: 0.9),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                AppLang.tr(
                                                    'wedding_progress'),
                                                style: TextStyle(
                                                  color: text,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: accent.withValues(
                                                    alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: accent.withValues(
                                                      alpha: 0.18),
                                                ),
                                              ),
                                              child: Text(
                                                AppLang.tr(statusKey),
                                                style: TextStyle(
                                                  color:
                                                      AppTok.accentDeep(context),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _progressMessage(overall),
                                          style: TextStyle(
                                            color: textSoft,
                                            fontSize: 12,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        WeddingProgressBar(
                                          value: overall,
                                          size: WeddingProgressSize.thin,
                                          animate: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                height: 1,
                                color: border.withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 12),
                              IntrinsicHeight(
                                child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _statTile(
                                      icon: Icons.checklist_rtl_outlined,
                                      color: const Color(0xFF6F9B76),
                                      title: AppLang.tr('stat_checklist'),
                                      value:
                                          '${_displayNum(checkDone)}/${_displayNum(checkTotal)}',
                                      subtitle: checkTotal == 0
                                          ? AppLang.tr('no_tasks')
                                          : '${_displayNum((checkPercent * 100).round())}${AppLang.tr('percent_done')}',
                                      goLabel: AppLang.I.isFa
                                          ? 'رفتن به چک‌لیست'
                                          : 'Go to checklist',
                                      onTap: () => _goTab(1),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _budgetCard(
                                      estimated: estimated,
                                      actual: actual,
                                      percent: budgetPercent,
                                    ),
                                  ),
                                ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              IntrinsicHeight(
                                child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _statTile(
                                      icon: Icons.storefront_outlined,
                                      color: const Color(0xFF6F9BB5),
                                      title: AppLang.tr('stat_vendor'),
                                      value:
                                          '${_displayNum(vendorDone)}/${_displayNum(vendorTotal)}',
                                      subtitle: vendorTotal == 0
                                          ? AppLang.tr('not_recorded')
                                          : '${_displayNum((vendorPercent * 100).round())}${AppLang.tr('percent_booked')}',
                                      goLabel: AppLang.I.isFa
                                          ? 'رفتن به تأمین‌کننده‌ها'
                                          : 'Go to vendors',
                                      onTap: _openVendors,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _guestsCard(
                                      total: guestTotal,
                                      confirmed: guestConfirmed,
                                      pending: guestPending,
                                      declined: guestDeclined,
                                    ),
                                  ),
                                ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  /// کارت بودجه با گیج نیم‌دایره — مشابه طرح مرجع
  Widget _budgetCard({
    required int estimated,
    required int actual,
    required double percent,
  }) {
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    const color = Color(0xFFD1A36B);

    return PageGlass(
      opacity: 0.82,
      blurSigma: 10,
      borderRadius: 16,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: InkWell(
        onTap: () => _goTab(2),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pie_chart_outline, color: color, size: 17),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLang.tr('stat_budget'),
                    style: TextStyle(
                      color: text,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Center(
              child: CustomPaint(
                painter: _HalfGaugePainter(
                  value: percent,
                  track: AppTok.ringTrack(context),
                  fill: color,
                ),
                child: SizedBox(
                  width: 120,
                  height: 61,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatAmount(actual),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: text,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        AppLang.I.isFa
                            ? 'از ${_formatAmount(estimated)}'
                            : 'of ${_formatAmount(estimated)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textSoft, fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            const SizedBox(height: 8),
            _goLink(
              AppLang.I.isFa ? 'رفتن به بودجه' : 'Go to budget',
              () => _goTab(2),
            ),
          ],
        ),
      ),
    );
  }

  /// کارت مهمان‌ها با آمار چهارستونهٔ جمع‌وجور (کل / بله / انتظار / رد)
  Widget _guestsCard({
    required int total,
    required int confirmed,
    required int pending,
    required int declined,
  }) {
    final text = AppTok.text(context);
    final border = AppTok.border(context);
    const green = Color(0xFF3E9B4F);
    const orange = Color(0xFFD07C1F);
    const red = Color(0xFFC4554D);

    return PageGlass(
      opacity: 0.82,
      blurSigma: 10,
      borderRadius: 16,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: InkWell(
        onTap: () => _goTab(4),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTok.accentSoft(context).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.groups_outlined,
                    color: AppTok.accent(context),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLang.tr('stat_guest'),
                    style: TextStyle(
                      color: text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _gStat(_displayNum(total), AppLang.I.isFa ? 'کل' : 'all', text),
                Container(width: 1, height: 26, color: border),
                _gStat(_displayNum(confirmed),
                    AppLang.I.isFa ? 'بله' : 'yes', green),
                Container(width: 1, height: 26, color: border),
                _gStat(_displayNum(pending),
                    AppLang.I.isFa ? 'انتظار' : 'waiting', orange),
                Container(width: 1, height: 26, color: border),
                _gStat(_displayNum(declined), AppLang.I.isFa ? 'رد' : 'no', red),
              ],
            ),
            const Spacer(),
            const SizedBox(height: 8),
            _goLink(
              AppLang.I.isFa ? 'رفتن به مهمان‌ها' : 'Go to guests',
              () => _goTab(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTok.textSoft(context),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _goLink(String label, VoidCallback onTap) {
    final text = AppTok.text(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              AppLang.I.isFa
                  ? Icons.arrow_left_rounded
                  : Icons.arrow_right_rounded,
              size: 16,
              color: text,
            ),
          ],
        ),
      ),
    );
  }

  /// کاشی چک‌لیست / تأمین‌کننده — هم‌خانواده با کارت بودجه و مهمان:
  /// سربرگ آیکن+عنوان، عدد بزرگ، زیرنویس رنگی، لینک پایین (بدون فضای خالی).
  Widget _statTile({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
    required String goLabel,
    required VoidCallback onTap,
  }) {
    final text = AppTok.text(context);

    return PageGlass(
      opacity: 0.82,
      blurSigma: 10,
      borderRadius: 16,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 17),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: text,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: text,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color.withValues(alpha: 0.95),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const SizedBox(height: 8),
            _goLink(goLabel, onTap),
          ],
        ),
      ),
    );
  }
}

class _FocusItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String badge;
  final bool isToday;
  final int priority;
  final VoidCallback onTap;

  _FocusItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.isToday,
    this.priority = 5,
    required this.onTap,
  });
}

/// کلیپر شکل قلب برای آواتارهای صفحهٔ خانه
class _HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w / 2, h * 0.999);
    path.cubicTo(
      -w * 0.28,
      h * 0.60,
      w * 0.02,
      h * 0.02,
      w / 2,
      h * 0.30,
    );
    path.cubicTo(
      w * 0.98,
      h * 0.02,
      w * 1.28,
      h * 0.60,
      w / 2,
      h * 0.999,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DottedBorderPainter extends CustomPainter {
  final Color dotColor;
  const _DottedBorderPainter({required this.dotColor});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor..style = PaintingStyle.fill;
    // dotted rim — 28 dots evenly spaced around perimeter (approx)
    final pts = [
      Offset(size.width * 0.12, size.height * 0.18),
      Offset(size.width * 0.20, size.height * 0.09),
      Offset(size.width * 0.33, size.height * 0.05),
      Offset(size.width * 0.48, size.height * 0.11),
      Offset(size.width * 0.62, size.height * 0.05),
      Offset(size.width * 0.77, size.height * 0.08),
      Offset(size.width * 0.88, size.height * 0.16),
      Offset(size.width * 0.94, size.height * 0.28),
      Offset(size.width * 0.91, size.height * 0.42),
      Offset(size.width * 0.83, size.height * 0.56),
      Offset(size.width * 0.71, size.height * 0.71),
      Offset(size.width * 0.58, size.height * 0.84),
      Offset(size.width * 0.41, size.height * 0.84),
      Offset(size.width * 0.28, size.height * 0.71),
      Offset(size.width * 0.16, size.height * 0.56),
      Offset(size.width * 0.08, size.height * 0.42),
      Offset(size.width * 0.06, size.height * 0.28),
    ];
    for (final p in pts) {
      canvas.drawCircle(p, 2.4, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LaceBorderPainter extends CustomPainter {
  final Color color;
  const _LaceBorderPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 0.9;
    final path = _HeartClipper().getClip(size);
    canvas.drawPath(path, p);
    final dot = Paint()..color = color..style = PaintingStyle.fill;
    for (double t = 0.08; t < 0.92; t += 0.08) {
      final x = size.width * t;
      final y = size.height * (0.04 + 0.06 * (t < 0.5 ? t : 1 - t));
      canvas.drawCircle(Offset(x, y), 1.2, dot);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── بافت‌های ۶ قلب جدید ──
class _WatercolorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // لکه‌های آبرنگی آبی کم‌رنگ
    final p1 = Paint()..color = const Color(0xFFB8E0F2).withValues(alpha: 0.55)..style = PaintingStyle.fill;
    final p2 = Paint()..color = const Color(0xFF6FB8D8).withValues(alpha: 0.28)..style = PaintingStyle.fill;
    final p3 = Paint()..color = Colors.white.withValues(alpha: 0.45)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.35), 42, p1);
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.48), 36, p2);
    canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.62), 28, p3);
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.58), 22, p2);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FeltNoisePainter extends CustomPainter {
  final Color base;
  const _FeltNoisePainter({required this.base});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.22)..style = PaintingStyle.fill;
    // نویز خیلی ریز نمدی
    final rnd = [Offset(0.2, 0.25), Offset(0.7, 0.3), Offset(0.5, 0.7), Offset(0.8, 0.65), Offset(0.3, 0.55)];
    for (final o in rnd) {
      canvas.drawCircle(Offset(size.width * o.dx, size.height * o.dy), 1.0, p);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedStitchPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dash;
  final double gap;
  const _DashedStitchPainter({required this.color, this.strokeWidth = 1.2, this.dash = 6, this.gap = 4});
  @override
  void paint(Canvas canvas, Size size) {
    final path = _HeartClipper().getClip(size);
    final dashed = _dashPath(path, dashLength: dash, gapLength: gap);
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    canvas.drawPath(dashed, paint);
  }
  Path _dashPath(Path source, {required double dashLength, required double gapLength}) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final nextDash = (dist + dashLength).clamp(0.0, metric.length);
        dashed.addPath(metric.extractPath(dist, nextDash), Offset.zero);
        dist = nextDash + gapLength;
      }
    }
    return dashed;
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RufflePainter extends CustomPainter {
  final Color ruffleColor;
  final Color stitchColor;
  const _RufflePainter({required this.ruffleColor, required this.stitchColor});
  @override
  void paint(Canvas canvas, Size size) {
    // چین دور قلب — دایره‌های کوچک مماس بر لبه قلب
    final rufflePaint = Paint()..color = ruffleColor..style = PaintingStyle.fill;
    final stitchPaint = Paint()..color = stitchColor..style = PaintingStyle.stroke..strokeWidth = 0.9..strokeCap = StrokeCap.round;
    // تعداد ruffle ها
    final path = _HeartClipper().getClip(size);
    // outer ruffle circles along path
    final step = 10.0;
    for (final metric in path.computeMetrics()) {
      final len = metric.length;
      for (double d = 0; d < len; d += step) {
        final pos = metric.getTangentForOffset(d);
        if (pos == null) continue;
        canvas.drawCircle(pos.position, 4.2, rufflePaint);
      }
    }
    // inner dashed stitch inside ruffle
    final inner = Path();
    // approximate inner by slightly scaled clip
    final innerPath = _HeartClipper().getClip(Size(size.width - 10, size.height - 10));
    // shift to center
    inner.addPath(innerPath, const Offset(5, 5));
    final dashed = _dashPath(inner, dashLength: 4, gapLength: 4);
    canvas.drawPath(dashed, stitchPaint);
  }
  Path _dashPath(Path source, {required double dashLength, required double gapLength}) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final nextDash = (dist + dashLength).clamp(0.0, metric.length);
        dashed.addPath(metric.extractPath(dist, nextDash), Offset.zero);
        dist = nextDash + gapLength;
      }
    }
    return dashed;
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PinkStar {
  final double dx, dy, size, angle;
  final Color color;
  const _PinkStar(this.dx, this.dy, this.size, this.angle, this.color);
}

const _pinkStarData = [
  _PinkStar(0.18, 0.22, 10, 0.2, Color(0xFFFFEB3B)),
  _PinkStar(0.28, 0.38, 11, -0.15, Color(0xFF81D4FA)),
  _PinkStar(0.42, 0.28, 8, 0.3, Color(0xFFFFB74D)),
  _PinkStar(0.58, 0.32, 9, -0.2, Color(0xFFB39DDB)),
  _PinkStar(0.72, 0.26, 8, 0.15, Color(0xFF80CBC4)),
  _PinkStar(0.78, 0.45, 9, -0.25, Color(0xFFFFAB91)),
  _PinkStar(0.35, 0.62, 10, 0.1, Color(0xFFFFEB3B)),
  _PinkStar(0.52, 0.55, 7, -0.3, Color(0xFF81D4FA)),
  _PinkStar(0.64, 0.68, 8, 0.2, Color(0xFFFFB74D)),
  _PinkStar(0.22, 0.58, 7, -0.1, Color(0xFFB39DDB)),
];

/// گیج نیم‌دایره برای کارت بودجه
class _HalfGaugePainter extends CustomPainter {
  _HalfGaugePainter({
    required this.value,
    required this.track,
    required this.fill,
  });

  final double value;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final rect = Rect.fromLTRB(
      stroke / 2,
      stroke / 2,
      size.width - stroke / 2,
      (size.height - stroke / 2) * 2,
    );
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, pi, pi, false, trackPaint);

    final v = value.clamp(0.0, 1.0);
    if (v > 0.001) {
      final fillPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = fill;
      canvas.drawArc(rect, pi, pi * v, false, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HalfGaugePainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.track != track ||
      oldDelegate.fill != fill;
}
