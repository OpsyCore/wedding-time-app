import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_effect.dart';
import '../core/app_effect_controller.dart';
import '../core/app_effects.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../widgets/app_drawer.dart';
import '../widgets/effect_background.dart';
import '../widgets/floral_decor.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  DateTime? weddingDate;
  String? role;
  String? brideName;
  String? groomName;
  String? bridePhoto;
  String? groomPhoto;
  String? coverPhoto;
  String _nameOrder = 'groom_first';
  double? _profileComplete;

  String _effectStyleId = AppEffectStyle.noneId;

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
      });
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
        final bg = AppTok.background(context);

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
                        Positioned.fill(
                          child: EffectBackground(
                            opacity: 0.35,
                            enableBlur: false,
                            child: const SizedBox.expand(),
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
    final pct = ((_profileComplete ?? 0) * 100).round().clamp(0, 100);
    final card = AppTok.card(context);
    final border = AppTok.border(context);
    final shadow = AppTok.shadow(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);
    final accentSoft = AppTok.accentSoft(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openCoupleProfile,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _brandBlushSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.favorite_outline_rounded,
                  color: accentSoft,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLang.tr('couple_profile'),
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_displayNum(pct)}${AppLang.tr('percent_unit')} · ${_progressMessage(_profileComplete ?? 0)}',
                      style: TextStyle(
                        color: textSoft,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                AppLang.I.isFa ? Icons.chevron_left : Icons.chevron_right,
                color: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoupleHero() {
    final bride = (brideName ?? '').trim().isEmpty
        ? AppLang.tr('bride')
        : brideName!.trim();
    final groom = (groomName ?? '').trim().isEmpty
        ? AppLang.tr('groom')
        : groomName!.trim();

    final brideFirst = _nameOrder == 'bride_first';
    final leftName = brideFirst ? bride : groom;
    final rightName = brideFirst ? groom : bride;
    final leftPhoto = brideFirst ? bridePhoto : groomPhoto;
    final rightPhoto = brideFirst ? groomPhoto : bridePhoto;

    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    final isWeddingDay =
        weddingDate != null && _isSameDay(weddingDate!, DateTime.now());
    final isPast = weddingDate != null &&
        weddingDate!.isBefore(DateTime.now()) &&
        !isWeddingDay;

    final coupleLine = brideFirst ? '$bride  &  $groom' : '$groom  &  $bride';

    final border = AppTok.border(context);
    final shadow = AppTok.shadow(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);
    final accentDeep = AppTok.accentDeep(context);
    final accentSoft = AppTok.accentSoft(context);
    final cardSoft = AppTok.cardSoft(context);

    return GestureDetector(
      onTap: _openCoupleProfile,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: AppTok.heroGradient(context),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: shadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              if (coverPhoto != null && coverPhoto!.isNotEmpty)
                Positioned.fill(
                  child: Opacity(
                    opacity: _dark ? 0.18 : 0.12,
                    child: Image.network(
                      coverPhoto!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  children: [
                    Text(
                      isWeddingDay
                          ? AppLang.tr('today_is_your_day')
                          : isPast
                              ? AppLang.tr('married_life_congrats')
                              : AppLang.tr('until_celebration'),
                      style: TextStyle(
                        color: accentDeep,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _personAvatar(photoUrl: leftPhoto, name: leftName),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _brandBlushSoft,
                                  border: Border.all(
                                    color: accentSoft.withValues(alpha: 0.7),
                                  ),
                                ),
                                child: Icon(
                                  Icons.favorite,
                                  color: accentSoft,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '&',
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'serif',
                                ),
                              ),
                            ],
                          ),
                        ),
                        _personAvatar(photoUrl: rightPhoto, name: rightName),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      coupleLine,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: text,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (weddingDate != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(weddingDate!),
                        style: TextStyle(
                          color: textSoft,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
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
                          style: TextStyle(
                            color: textSoft,
                            fontSize: 12,
                          ),
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
                          style: TextStyle(
                            color: textSoft,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      Row(
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
                  ],
                ),
              ),
            ],
          ),
        ),
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
        Container(
          width: 78,
          height: 78,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                accent,
                _brandBlush,
                _brandGreenSoft,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: card,
              border: Border.all(color: card, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: photoUrl != null && photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(initial),
                  )
                : _avatarFallback(initial),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 88,
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
            fontSize: 26,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
          ),
        ),
      ),
    );
  }

  Widget _timeBox(String value, String label) {
    final card = AppTok.card(context);
    final border = AppTok.border(context);
    final accentDeep = AppTok.accentDeep(context);
    final textSoft = AppTok.textSoft(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
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
    final card = AppTok.card(context);
    final border = AppTok.border(context);
    final shadow = AppTok.shadow(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _checklistRef.snapshots(),
      builder: (context, checkSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _guestsRef.snapshots(),
          builder: (context, guestSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _vendorsRef.snapshots(),
              builder: (context, vendorSnap) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _eventsRef.snapshots(),
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

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: border),
                        boxShadow: [
                          BoxShadow(
                            color: shadow,
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTok.cardSoft(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(color: AppTok.textSoft(context), fontSize: 12.5),
      ),
    );
  }

  Widget _focusTile(_FocusItem item) {
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final cardSoft = AppTok.cardSoft(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cardSoft,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final border = AppTok.border(context);
    final shadow = AppTok.shadow(context);
    final accent = AppTok.accent(context);
    final ringTrack = AppTok.ringTrack(context);
    final accentSoft = AppTok.accentSoft(context);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _checklistRef.snapshots(),
      builder: (context, checkSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _guestsRef.snapshots(),
          builder: (context, guestSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _budgetGroupsRef.snapshots(),
              builder: (context, budgetSnap) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _vendorsRef.snapshots(),
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
                    if (guestSnap.hasData) {
                      guestTotal = guestSnap.data!.docs.length;
                      guestConfirmed = guestSnap.data!.docs
                          .where((d) => d.data()['status'] == 'confirmed')
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

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: AppTok.progressGradient(context),
                            border: Border.all(color: border),
                            boxShadow: [
                              BoxShadow(
                                color: shadow,
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 64,
                                          height: 64,
                                          child: CircularProgressIndicator(
                                            value: 1,
                                            strokeWidth: 5.5,
                                            color: ringTrack,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 64,
                                          height: 64,
                                          child: CircularProgressIndicator(
                                            value: overall,
                                            strokeWidth: 5.5,
                                            color: accent,
                                            strokeCap: StrokeCap.round,
                                          ),
                                        ),
                                        Text(
                                          '${_displayNum((overall * 100).round())}%',
                                          style: TextStyle(
                                            color: text,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLang.tr('wedding_progress'),
                                          style: TextStyle(
                                            color: text,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _progressMessage(overall),
                                          style: TextStyle(
                                            color: textSoft,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: overall,
                                            minHeight: 5,
                                            backgroundColor: ringTrack,
                                            color: accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                height: 1,
                                color: border,
                              ),
                              const SizedBox(height: 14),
                              Row(
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
                                      onTap: () => _goTab(1),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _statTile(
                                      icon: Icons.savings_outlined,
                                      color: const Color(0xFFD1A36B),
                                      title: AppLang.tr('stat_budget'),
                                      value: estimated == 0
                                          ? '—'
                                          : '${_displayNum((budgetPercent * 100).round())}%',
                                      subtitle: estimated == 0
                                          ? AppLang.tr('not_recorded')
                                          : '${_formatAmount(actual)}${AppLang.tr('toman_short')}',
                                      onTap: () => _goTab(2),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
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
                                      onTap: _openVendors,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _statTile(
                                      icon: Icons.groups_outlined,
                                      color: accentSoft,
                                      title: AppLang.tr('stat_guest'),
                                      value: _displayNum(guestTotal),
                                      subtitle: guestTotal == 0
                                          ? AppLang.tr('no_guests')
                                          : '${_displayNum(guestConfirmed)}${AppLang.tr('confirmed_count')}',
                                      onTap: () => _goTab(4),
                                    ),
                                  ),
                                ],
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

  Widget _statTile({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final card = AppTok.card(context);
    final border = AppTok.border(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);

    return Material(
      color: card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 17),
                  ),
                  const Spacer(),
                  Icon(
                    AppLang.I.isFa ? Icons.chevron_left : Icons.chevron_right,
                    size: 16,
                    color: textSoft.withValues(alpha: 0.8),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  color: textSoft,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color.withValues(alpha: 0.95),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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