// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../core/app_date_picker.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../services/weather_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/async_state_views.dart';
import '../widgets/page_glass.dart';
import '../widgets/wedding_time_header.dart';

/// تبدیل دقیق تاریخ میلادی به شمسی (جلالی) بدون وابستگی به پکیج خارجی
class _JalaliDate {
  final int year;
  final int month;
  final int day;

  const _JalaliDate(this.year, this.month, this.day);

  static const List<String> monthNamesFa = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static _JalaliDate fromDateTime(DateTime d) {
    final gy = d.year;
    final gm = d.month;
    final gd = d.day;
    const gDayMonth = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    final gy2 = (gm > 2) ? (gy + 1) : gy;
    var days = 355666 +
        (365 * gy) +
        ((gy2 + 3) ~/ 4) -
        ((gy2 + 99) ~/ 100) +
        ((gy2 + 399) ~/ 400) +
        gd +
        gDayMonth[gm - 1];
    var jy = -1595 + (33 * (days ~/ 12053));
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    final int jm = (days < 186) ? 1 + (days ~/ 31) : 7 + ((days - 186) ~/ 30);
    final int jd = 1 + ((days < 186) ? (days % 31) : ((days - 186) % 30));
    return _JalaliDate(jy, jm, jd);
  }

  String get monthNameFa => monthNamesFa[(month - 1).clamp(0, 11)];
}

/// دسته‌بندی رویدادهای تقویم عروسی
class _EventCategory {
  final String id;
  final String titleFa;
  final String titleEn;
  final IconData icon;
  final Color color;

  const _EventCategory({
    required this.id,
    required this.titleFa,
    required this.titleEn,
    required this.icon,
    required this.color,
  });

  String label(bool isFa) => isFa ? titleFa : titleEn;

  static const List<_EventCategory> all = [
    _EventCategory(
      id: 'venue',
      titleFa: 'تالار و تشریفات',
      titleEn: 'Venue & Catering',
      icon: Icons.castle_rounded,
      color: Color(0xFFD4AF37),
    ),
    _EventCategory(
      id: 'photo',
      titleFa: 'آتلیه و عکاسی',
      titleEn: 'Photo & Video',
      icon: Icons.camera_alt_rounded,
      color: Color(0xFFC9B6E4),
    ),
    _EventCategory(
      id: 'beauty',
      titleFa: 'لباس و زیبایی',
      titleEn: 'Dress & Beauty',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFF8B8C0),
    ),
    _EventCategory(
      id: 'shopping',
      titleFa: 'خرید و حلقه',
      titleEn: 'Shopping & Rings',
      icon: Icons.diamond_rounded,
      color: Color(0xFF6B8E5A),
    ),
    _EventCategory(
      id: 'payment',
      titleFa: 'قسط و پرداخت',
      titleEn: 'Payment & Deposit',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFFFF9A3C),
    ),
    _EventCategory(
      id: 'guests',
      titleFa: 'مهمانان و دعوت',
      titleEn: 'Guests & Invites',
      icon: Icons.mail_rounded,
      color: Color(0xFF4A7C9B),
    ),
    _EventCategory(
      id: 'general',
      titleFa: 'یادآوری عمومی',
      titleEn: 'General Reminder',
      icon: Icons.event_note_rounded,
      color: Color(0xFFDCA3A3),
    ),
  ];

  static _EventCategory byId(String? id) {
    final norm = (id ?? 'general').trim();
    return all.firstWhere((c) => c.id == norm, orElse: () => all.last);
  }
}

/// قالب‌های آماده برای ثبت سریع رویداد عروسی
class _EventTemplate {
  final String titleFa;
  final String titleEn;
  final String categoryId;
  final String time;

  const _EventTemplate({
    required this.titleFa,
    required this.titleEn,
    required this.categoryId,
    required this.time,
  });

  static const List<_EventTemplate> presets = [
    _EventTemplate(
      titleFa: 'پرو لباس عروس / داماد',
      titleEn: 'Wedding Dress / Suit Fitting',
      categoryId: 'beauty',
      time: '17:00',
    ),
    _EventTemplate(
      titleFa: 'جلسه هماهنگی با آتلیه',
      titleEn: 'Photography Studio Meeting',
      categoryId: 'photo',
      time: '16:00',
    ),
    _EventTemplate(
      titleFa: 'تست منوی شام و شیرینی تالار',
      titleEn: 'Venue Menu & Cake Tasting',
      categoryId: 'venue',
      time: '19:00',
    ),
    _EventTemplate(
      titleFa: 'رزرو آرایشگاه و میکاپ',
      titleEn: 'Beauty Salon Appointment',
      categoryId: 'beauty',
      time: '15:00',
    ),
    _EventTemplate(
      titleFa: 'خرید حلقه و سرویس طلا',
      titleEn: 'Wedding Rings Shopping',
      categoryId: 'shopping',
      time: '18:00',
    ),
    _EventTemplate(
      titleFa: 'پرداخت قسط تالار / تشریفات',
      titleEn: 'Venue Installment Payment',
      categoryId: 'payment',
      time: '11:00',
    ),
    _EventTemplate(
      titleFa: 'ارسال کارت دعوت به مهمانان',
      titleEn: 'Send Wedding Invitations',
      categoryId: 'guests',
      time: '20:00',
    ),
  ];
}

class CalendarScreen extends StatefulWidget {
  final String weddingId;

  const CalendarScreen({super.key, required this.weddingId});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();
  DateTime? weddingDate;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _showJalaliNumbers = true;
  String _selectedCategoryFilter = 'all';

  String? _venueCity;
  double? _venueLat;
  double? _venueLng;

  WeatherSnapshot? _weather;
  bool _weatherLoading = false;
  String? _weatherError;

  StreamSubscription<DocumentSnapshot>? _weddingSub;
  StreamSubscription<DocumentSnapshot>? _invitationSub;
  late final Stream<QuerySnapshot> _eventsStream;
  late final ScrollController _pageScrollController;

  CollectionReference get eventsRef => FirebaseFirestore.instance
      .collection('weddings')
      .doc(widget.weddingId)
      .collection('calendarEvents');

  DocumentReference<Map<String, dynamic>> get _weddingDoc =>
      FirebaseFirestore.instance.collection('weddings').doc(widget.weddingId);

  DocumentReference<Map<String, dynamic>> get _invitationDoc =>
      _weddingDoc.collection('invitation').doc('main');

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

  @override
  void initState() {
    super.initState();
    // Keep one stream instance across rebuilds; recreating it resets the
    // StreamBuilder subscription and can make the page jump back to the top.
    _eventsStream = eventsRef.orderBy('date').snapshots();
    _pageScrollController = ScrollController();
    _listenWedding();
    _listenInvitation();
  }

  void _listenWedding() {
    _weddingSub = _weddingDoc.snapshots().listen(
      (doc) {
        final data = doc.data();
        final ts = data?['weddingDate'] as Timestamp?;
        if (!mounted) return;
        setState(() => weddingDate = ts?.toDate());
      },
      onError: (_) {},
    );
  }

  void _listenInvitation() {
    _invitationSub = _invitationDoc.snapshots().listen(
      (doc) {
        final data = doc.data() ?? {};
        final city = data['venueCity']?.toString();
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();

        if (!mounted) return;
        setState(() {
          _venueCity =
              (city != null && city.trim().isNotEmpty) ? city.trim() : null;
          _venueLat = lat;
          _venueLng = lng;
        });
        _loadWeather();
      },
      onError: (_) {},
    );
  }

  Future<void> _loadWeather() async {
    if (_venueLat == null || _venueLng == null) {
      setState(() {
        _weather = null;
        _weatherError = null;
        _weatherLoading = false;
      });
      return;
    }

    setState(() {
      _weatherLoading = true;
      _weatherError = null;
    });

    try {
      final snap = await WeatherService.fetch(
        lat: _venueLat!,
        lng: _venueLng!,
      );
      if (!mounted) return;
      setState(() {
        _weather = snap;
        _weatherLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _weatherError = AppLang.tr('weather_fetch_failed');
        _weatherLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _weddingSub?.cancel();
    _invitationSub?.cancel();
    _pageScrollController.dispose();
    super.dispose();
  }

  int get daysLeft {
    if (weddingDate == null) return 0;
    final diff = _dateOnly(weddingDate!).difference(_dateOnly(DateTime.now())).inDays;
    return diff < 0 ? 0 : diff;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _matchesCategory(QueryDocumentSnapshot doc) {
    if (_selectedCategoryFilter == 'all') return true;
    final data = doc.data() as Map<String, dynamic>;
    final cat = (data['category'] ?? 'general').toString();
    return cat == _selectedCategoryFilter;
  }

  List<QueryDocumentSnapshot> _eventsForDay(
    List<QueryDocumentSnapshot> all,
    DateTime day, {
    bool applyFilter = true,
  }) {
    final target = _dateOnly(day);
    return all.where((doc) {
      if (applyFilter && !_matchesCategory(doc)) return false;
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['date'] as Timestamp?;
      if (ts == null) return false;
      final d = _dateOnly(ts.toDate());
      return d.year == target.year &&
          d.month == target.month &&
          d.day == target.day;
    }).toList();
  }

  List<QueryDocumentSnapshot> _futureEvents(List<QueryDocumentSnapshot> all) {
    final now = _dateOnly(DateTime.now());
    final list = all.where((doc) {
      if (!_matchesCategory(doc)) return false;
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['date'] as Timestamp?;
      if (ts == null) return false;
      final d = _dateOnly(ts.toDate());
      return d.isAfter(now) || isSameDay(d, now);
    }).toList();

    list.sort((a, b) {
      final da = (a.data() as Map)['date'] as Timestamp?;
      final db = (b.data() as Map)['date'] as Timestamp?;
      if (da == null || db == null) return 0;
      return da.compareTo(db);
    });
    return list;
  }

  String _formatDate(DateTime d) {
    if (AppLang.I.isFa && _showJalaliNumbers) {
      final j = _JalaliDate.fromDateTime(d);
      final jy = _faDigits(j.year.toString());
      final jm = _faDigits(j.month.toString().padLeft(2, '0'));
      final jd = _faDigits(j.day.toString().padLeft(2, '0'));
      return '$jy/$jm/$jd (${j.day != 0 ? _faDigits('${j.day}') : ''} ${j.monthNameFa})';
    }
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return _displayNum('$y/$m/$day');
  }

  String _formatGregorianShort(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y/$m/$day';
  }

  String _formatMonthYear(DateTime d) {
    const enMonths = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const faGregorianMonths = [
      'ژانویه',
      'فوریه',
      'مارس',
      'آوریل',
      'مه',
      'ژوئن',
      'ژوئیه',
      'اوت',
      'سپتامبر',
      'اکتبر',
      'نوامبر',
      'دسامبر',
    ];
    if (!AppLang.I.isFa) {
      return '${enMonths[d.month - 1]} ${d.year}';
    }
    final jStart = _JalaliDate.fromDateTime(DateTime(d.year, d.month, 1));
    final jEnd = _JalaliDate.fromDateTime(DateTime(d.year, d.month + 1, 0));
    final jalaliTitle = jStart.month == jEnd.month
        ? '${jStart.monthNameFa} ${_faDigits('${jStart.year}')}'
        : '${jStart.monthNameFa} – ${jEnd.monthNameFa} ${_faDigits('${jEnd.year}')}';
    final gregTitle = '${faGregorianMonths[d.month - 1]} ${_faDigits('${d.year}')}';
    return _showJalaliNumbers ? jalaliTitle : gregTitle;
  }

  String _formatMonthYearSecondary(DateTime d) {
    const faGregorianMonths = [
      'ژانویه',
      'فوریه',
      'مارس',
      'آوریل',
      'مه',
      'ژوئن',
      'ژوئیه',
      'اوت',
      'سپتامبر',
      'اکتبر',
      'نوامبر',
      'دسامبر',
    ];
    if (!AppLang.I.isFa) return '';
    final jMid = _JalaliDate.fromDateTime(DateTime(d.year, d.month, 15));
    return _showJalaliNumbers
        ? '${faGregorianMonths[d.month - 1]} ${_faDigits('${d.year}')}'
        : '${jMid.monthNameFa} ${_faDigits('${jMid.year}')}';
  }

  String _dayTitle(DateTime d, int index) {
    if (index == 0) return AppLang.tr('today');
    return _weekDayName(d.weekday);
  }

  IconData _weatherIcon(int code) {
    if (code == 0 || code == 1) return Icons.wb_sunny_rounded;
    if (code == 2) return Icons.wb_cloudy_rounded;
    if (code == 3) return Icons.cloud_rounded;
    if (code == 45 || code == 48) return Icons.cloud_queue_rounded;
    if (code >= 51 && code <= 67) return Icons.water_drop_rounded;
    if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
    if (code >= 80 && code <= 82) return Icons.grain_rounded;
    if (code >= 95) return Icons.thunderstorm_rounded;
    return Icons.wb_cloudy_rounded;
  }

  String _weatherLabel(int code) => WeatherService.label(code);

  String _weatherShort(int code) => WeatherService.conditionShort(code);

  InputDecoration _fieldDecoration(BuildContext context, String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null
          ? Icon(icon, color: AppTok.textSoft(context), size: 19)
          : null,
      labelStyle: TextStyle(color: AppTok.textSoft(context)),
      filled: true,
      fillColor: AppTok.background(context),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTok.border(context).withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTok.accent(context), width: 1.4),
      ),
    );
  }

  Future<void> _toggleEventDone(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final current = data['done'] == true;
    await eventsRef.doc(doc.id).update({
      'done': !current,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _quickAddTemplate(_EventTemplate tpl) async {
    final isFa = AppLang.I.isFa;
    await eventsRef.add({
      'title': isFa ? tpl.titleFa : tpl.titleEn,
      'desc': '',
      'category': tpl.categoryId,
      'time': tpl.time,
      'done': false,
      'date': Timestamp.fromDate(
        DateTime(selectedDay.year, selectedDay.month, selectedDay.day),
      ),
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFa
              ? '«${tpl.titleFa}» برای ${_formatDate(selectedDay)} ثبت شد'
              : '"${tpl.titleEn}" added for ${_formatDate(selectedDay)}',
        ),
        backgroundColor: AppTok.accent(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void openAddEvent({DocumentSnapshot? eventDoc, _EventTemplate? preset}) {
    final data = eventDoc?.data() as Map<String, dynamic>?;
    final isFa = AppLang.I.isFa;
    final titleC = TextEditingController(
      text: data?['title']?.toString() ??
          (preset != null ? (isFa ? preset.titleFa : preset.titleEn) : ''),
    );
    final descC = TextEditingController(text: data?['desc']?.toString() ?? '');
    final timeC = TextEditingController(
      text: data?['time']?.toString() ?? (preset?.time ?? ''),
    );
    String selectedCat =
        (data?['category'] ?? preset?.categoryId ?? 'general').toString();

    DateTime pickedDate = selectedDay;
    if (data?['date'] is Timestamp) {
      pickedDate = (data!['date'] as Timestamp).toDate();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTok.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ListenableBuilder(
              listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
              builder: (context, _) {
                final text = AppTok.text(context);
                final textSoft = AppTok.textSoft(context);
                final accent = AppTok.accent(context);

                return Directionality(
                  textDirection: AppLang.I.direction,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                      left: 20,
                      right: 20,
                      top: 16,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 42,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppTok.border(context),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  eventDoc == null
                                      ? Icons.add_task_rounded
                                      : Icons.edit_calendar_rounded,
                                  color: accent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  eventDoc == null
                                      ? AppLang.tr('add_event')
                                      : AppLang.tr('edit_event'),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: text,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(Icons.close_rounded, color: textSoft),
                              ),
                            ],
                          ),
                          if (eventDoc == null) ...[
                            const SizedBox(height: 10),
                            Text(
                              isFa ? 'قالب‌های آماده (با یک لمس پر کنید):' : 'Quick templates:',
                              style: TextStyle(
                                color: textSoft,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 34,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _EventTemplate.presets.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 6),
                                itemBuilder: (context, idx) {
                                  final t = _EventTemplate.presets[idx];
                                  final cat = _EventCategory.byId(t.categoryId);
                                  return ActionChip(
                                    avatar: Icon(cat.icon, size: 15, color: cat.color),
                                    label: Text(
                                      isFa ? t.titleFa : t.titleEn,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: text,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    backgroundColor: AppTok.cardSoft(context),
                                    side: BorderSide(color: cat.color.withValues(alpha: 0.35)),
                                    onPressed: () {
                                      setModalState(() {
                                        titleC.text = isFa ? t.titleFa : t.titleEn;
                                        selectedCat = t.categoryId;
                                        timeC.text = t.time;
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Text(
                            isFa ? 'دسته‌بندی رویداد' : 'Category',
                            style: TextStyle(
                              color: textSoft,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _EventCategory.all.map((cat) {
                              final isSel = selectedCat == cat.id;
                              return ChoiceChip(
                                avatar: Icon(
                                  cat.icon,
                                  size: 15,
                                  color: isSel ? Colors.white : cat.color,
                                ),
                                label: Text(
                                  cat.label(isFa),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isSel ? Colors.white : text,
                                  ),
                                ),
                                selected: isSel,
                                selectedColor: cat.color,
                                backgroundColor: AppTok.cardSoft(context),
                                side: BorderSide(
                                  color: isSel
                                      ? cat.color
                                      : cat.color.withValues(alpha: 0.30),
                                ),
                                showCheckmark: false,
                                onSelected: (_) =>
                                    setModalState(() => selectedCat = cat.id),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: titleC,
                            style: TextStyle(color: text),
                            decoration: _fieldDecoration(
                              context,
                              AppLang.tr('title'),
                              icon: Icons.title_rounded,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await showAppDatePicker(
                                      context,
                                      initialDate: pickedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null) {
                                      setModalState(() => pickedDate = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 15,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTok.background(context),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppTok.border(context).withValues(alpha: 0.6),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          color: accent,
                                          size: 17,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _formatDate(pickedDate),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: text,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: timeC,
                                  readOnly: true,
                                  onTap: () async {
                                    final nowTime = TimeOfDay.now();
                                    final pickedTime = await showTimePicker(
                                      context: context,
                                      initialTime: nowTime,
                                    );
                                    if (pickedTime != null) {
                                      final hh = pickedTime.hour
                                          .toString()
                                          .padLeft(2, '0');
                                      final mm = pickedTime.minute
                                          .toString()
                                          .padLeft(2, '0');
                                      setModalState(() => timeC.text = '$hh:$mm');
                                    }
                                  },
                                  style: TextStyle(color: text, fontSize: 13),
                                  decoration: _fieldDecoration(
                                    context,
                                    isFa ? 'ساعت (اختیاری)' : 'Time',
                                    icon: Icons.access_time_rounded,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: descC,
                            style: TextStyle(color: text),
                            maxLines: 2,
                            decoration: _fieldDecoration(
                              context,
                              AppLang.tr('description'),
                              icon: Icons.notes_rounded,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 19),
                              label: Text(
                                AppLang.tr('save'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              onPressed: () async {
                                if (titleC.text.trim().isEmpty) return;

                                final payload = {
                                  'title': titleC.text.trim(),
                                  'desc': descC.text.trim(),
                                  'category': selectedCat,
                                  'time': timeC.text.trim(),
                                  'date': Timestamp.fromDate(
                                    DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                    ),
                                  ),
                                  'updatedAt': FieldValue.serverTimestamp(),
                                };

                                if (eventDoc == null) {
                                  await eventsRef.add({
                                    ...payload,
                                    'done': false,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                } else {
                                  await eventsRef
                                      .doc(eventDoc.id)
                                      .update(payload);
                                }

                                if (context.mounted) Navigator.pop(context);
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> deleteEvent(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final title = (data['title'] ?? '').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTok.card(context),
        title: Text(
          AppLang.tr('delete_event'),
          style: TextStyle(color: AppTok.text(context)),
        ),
        content: Text(
          AppLang.tr('delete_event_confirm').replaceAll('{title}', title),
          style: TextStyle(color: AppTok.textSoft(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLang.tr('cancel'),
              style: TextStyle(color: AppTok.textSoft(context)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLang.tr('delete'),
              style: TextStyle(color: AppTok.danger(context)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await eventsRef.doc(doc.id).delete();
    }
  }

  void _goPrevMonth() {
    setState(() {
      focusedDay = DateTime(focusedDay.year, focusedDay.month - 1, 1);
    });
  }

  void _goNextMonth() {
    setState(() {
      focusedDay = DateTime(focusedDay.year, focusedDay.month + 1, 1);
    });
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      focusedDay = now;
      selectedDay = now;
    });
  }

  void _jumpToWeddingDay() {
    if (weddingDate == null) return;
    setState(() {
      focusedDay = weddingDate!;
      selectedDay = weddingDate!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        return Directionality(
          textDirection: AppLang.I.direction,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            drawer: AppDrawer(weddingId: widget.weddingId),
            body: SafeArea(
              child: StreamBuilder<QuerySnapshot>(
                stream: _eventsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError && !snapshot.hasData) {
                    return Column(
                      children: [
                        Builder(
                          builder: (context) => WeddingTimeHeader(
                            weddingId: widget.weddingId,
                            onMenuPressed: () =>
                                Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        Expanded(
                          child: AsyncErrorView(
                            error: snapshot.error,
                            onRetry: () => setState(() {}),
                          ),
                        ),
                      ],
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Column(
                      children: [
                        Builder(
                          builder: (context) => WeddingTimeHeader(
                            weddingId: widget.weddingId,
                            onMenuPressed: () =>
                                Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTok.accent(context),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final allDocs = snapshot.data?.docs ?? [];
                  final dayEvents = _eventsForDay(allDocs, selectedDay);
                  final upcoming = _futureEvents(allDocs);

                  return Column(
                    children: [
                      Builder(
                        builder: (context) => WeddingTimeHeader(
                          weddingId: widget.weddingId,
                          onMenuPressed: () =>
                              Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          key: PageStorageKey<String>(
                            'calendar-page-${widget.weddingId}',
                          ),
                          controller: _pageScrollController,
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
                          children: [
                            _buildWeddingBanner(context, allDocs),
                            const SizedBox(height: 14),
                            _buildCalendar(context, allDocs),
                            const SizedBox(height: 14),
                            _buildCategoryFilterBar(context),
                            const SizedBox(height: 16),
                            _buildSectionTitle(
                              context,
                              icon: Icons.event_note_rounded,
                              title: AppLang.tr('selected_day_events'),
                              subtitle: _formatDate(selectedDay),
                              trailing: TextButton.icon(
                                onPressed: () => openAddEvent(),
                                icon: Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 16,
                                  color: AppTok.accent(context),
                                ),
                                label: Text(
                                  AppLang.I.isFa ? 'افزودن در این روز' : 'Add on this day',
                                  style: TextStyle(
                                    color: AppTok.accent(context),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (dayEvents.isEmpty)
                              _buildSelectedDayEmptyState(context)
                            else
                              ...dayEvents
                                  .map((d) => _buildEventCard(context, d)),
                            const SizedBox(height: 20),
                            _buildSectionTitle(
                              context,
                              icon: Icons.upcoming_rounded,
                              title: AppLang.tr('upcoming_events'),
                              subtitle: AppLang.I.isFa
                                  ? '${_displayNum(upcoming.length)} رویداد پیش رو'
                                  : '${upcoming.length} upcoming',
                            ),
                            const SizedBox(height: 10),
                            if (upcoming.isEmpty)
                              _buildEmptyState(
                                context,
                                message: AppLang.tr('no_upcoming_events'),
                                icon: Icons.calendar_today_outlined,
                              )
                            else
                              ...upcoming
                                  .map((d) => _buildEventCard(context, d)),
                            const SizedBox(height: 20),
                            _buildWeatherCard(context),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'calendar_fab',
              backgroundColor: AppTok.accent(context),
              foregroundColor: Colors.white,
              onPressed: () => openAddEvent(),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                AppLang.I.isFa ? 'رویداد جدید' : 'New Event',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilterBar(BuildContext context) {
    final isFa = AppLang.I.isFa;
    final text = AppTok.text(context);
    final accent = AppTok.accent(context);

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: ChoiceChip(
              label: Text(
                isFa ? 'همهٔ رویدادها' : 'All Events',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _selectedCategoryFilter == 'all' ? Colors.white : text,
                ),
              ),
              selected: _selectedCategoryFilter == 'all',
              selectedColor: accent,
              backgroundColor: AppTok.card(context),
              showCheckmark: false,
              onSelected: (_) => setState(() => _selectedCategoryFilter = 'all'),
            ),
          ),
          for (final cat in _EventCategory.all)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: ChoiceChip(
                avatar: Icon(
                  cat.icon,
                  size: 15,
                  color: _selectedCategoryFilter == cat.id
                      ? Colors.white
                      : cat.color,
                ),
                label: Text(
                  cat.label(isFa),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _selectedCategoryFilter == cat.id
                        ? Colors.white
                        : text,
                  ),
                ),
                selected: _selectedCategoryFilter == cat.id,
                selectedColor: cat.color,
                backgroundColor: AppTok.card(context),
                side: BorderSide(
                  color: _selectedCategoryFilter == cat.id
                      ? cat.color
                      : cat.color.withValues(alpha: 0.28),
                ),
                showCheckmark: false,
                onSelected: (_) =>
                    setState(() => _selectedCategoryFilter = cat.id),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTok.accent(context).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppTok.accent(context), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTok.text(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTok.textSoft(context),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildSelectedDayEmptyState(BuildContext context) {
    final isFa = AppLang.I.isFa;
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);

    return PageGlass(
      opacity: 0.86,
      blurSigma: 12,
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTok.cardSoft(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.event_available_rounded,
                  color: textSoft,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLang.tr('no_events_this_day'),
                      style: TextStyle(
                        color: text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFa
                          ? 'با یک لمس یکی از قرارهای پرتکرار عروسی را در این روز ثبت کنید:'
                          : 'Tap a wedding milestone below to add it to this date:',
                      style: TextStyle(color: textSoft, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _EventTemplate.presets.take(5).map((tpl) {
              final cat = _EventCategory.byId(tpl.categoryId);
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _quickAddTemplate(tpl),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cat.color.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon, size: 14, color: cat.color),
                      const SizedBox(width: 6),
                      Text(
                        '+ ${isFa ? tpl.titleFa : tpl.titleEn}',
                        style: TextStyle(
                          color: text,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String message,
    required IconData icon,
  }) {
    return PageGlass(
      opacity: 0.82,
      blurSigma: 10,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTok.cardSoft(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTok.textSoft(context), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppTok.textSoft(context),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeddingBanner(
    BuildContext context,
    List<QueryDocumentSnapshot> allDocs,
  ) {
    final isDark = AppTok.isDark(context);
    final isFa = AppLang.I.isFa;
    final accent = AppTok.accent(context);
    final accentDeep = AppTok.accentDeep(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);

    final totalEvents = allDocs.length;
    final doneEvents = allDocs.where((d) => (d.data() as Map)['done'] == true).length;

    String primaryWeddingDate = AppLang.tr('loading_ellipsis');
    String secondaryWeddingDate = '';
    if (weddingDate != null) {
      if (isFa) {
        final j = _JalaliDate.fromDateTime(weddingDate!);
        primaryWeddingDate =
            '${_weekDayName(weddingDate!.weekday)}، ${_faDigits('${j.day}')} ${j.monthNameFa} ${_faDigits('${j.year}')}';
        secondaryWeddingDate = _formatGregorianShort(weddingDate!);
      } else {
        primaryWeddingDate = _formatGregorianShort(weddingDate!);
      }
    }

    return PageGlass(
      opacity: isDark ? 0.88 : 0.92,
      blurSigma: 14,
      borderRadius: 22,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isDark
                ? [
                    accent.withValues(alpha: 0.16),
                    AppDarkPalette.cardSoft.withValues(alpha: 0.92),
                    AppDarkPalette.card.withValues(alpha: 0.96),
                  ]
                : [
                    accent.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.96),
                    AppPalette.cardSoft.withValues(alpha: 0.92),
                  ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.26)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLang.tr('your_wedding_date'),
                        style: TextStyle(
                          color: textSoft,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        primaryWeddingDate,
                        style: TextStyle(
                          color: text,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (secondaryWeddingDate.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          isFa
                              ? 'میلادی: $secondaryWeddingDate'
                              : secondaryWeddingDate,
                          style: TextStyle(
                            color: textSoft,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: weddingDate == null ? null : _jumpToWeddingDay,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.hourglass_bottom_rounded,
                          size: 14,
                          color: accentDeep,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${_displayNum(daysLeft)}${AppLang.tr('days_remaining')}',
                          style: TextStyle(
                            color: accentDeep,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _bannerChip(
                    context,
                    icon: Icons.today_rounded,
                    label: isFa ? 'امروز' : 'Today',
                    onTap: _jumpToToday,
                  ),
                ),
                const SizedBox(width: 8),
                if (weddingDate != null) ...[
                  Expanded(
                    child: _bannerChip(
                      context,
                      icon: Icons.celebration_rounded,
                      label: isFa ? 'رفتن به ماه عروسی' : 'Jump to Wedding',
                      onTap: _jumpToWeddingDay,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: _bannerChip(
                    context,
                    icon: Icons.checklist_rtl_rounded,
                    label: isFa
                        ? '${_displayNum(doneEvents)}/${_displayNum(totalEvents)} انجام‌شده'
                        : '$doneEvents/$totalEvents Done',
                    onTap: () => openAddEvent(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: AppTok.cardSoft(context).withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: AppTok.border(context).withValues(alpha: 0.65),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppTok.accent(context)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTok.text(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(BuildContext context) {
    final hasLocation = _venueLat != null && _venueLng != null;
    final isDark = AppTok.isDark(context);

    return PageGlass(
      opacity: isDark ? 0.86 : 0.90,
      blurSigma: 14,
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTok.accent(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.wb_cloudy_outlined,
                  color: AppTok.accent(context),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLang.tr('venue_weather'),
                      style: TextStyle(
                        color: AppTok.text(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                    if (_venueCity != null)
                      Text(
                        _venueCity!,
                        style: TextStyle(
                          color: AppTok.textSoft(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (hasLocation)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _weatherLoading ? null : _loadWeather,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTok.cardSoft(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTok.border(context)),
                      ),
                      child: _weatherLoading
                          ? Padding(
                              padding: const EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTok.accent(context),
                              ),
                            )
                          : Icon(
                              Icons.refresh_rounded,
                              color: AppTok.textSoft(context),
                              size: 18,
                            ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (!hasLocation)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTok.cardSoft(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                AppLang.tr('venue_city_not_set'),
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
                child: CircularProgressIndicator(color: AppTok.accent(context)),
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
            _buildWeatherContent(context, _weather!),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(BuildContext context, WeatherSnapshot w) {
    final temp = _displayNum(w.temperature.toStringAsFixed(1));
    final humidity =
        w.humidity != null ? _displayNum(w.humidity.toString()) : '—';
    final precip = w.precipProbability != null
        ? _displayNum(w.precipProbability.toString())
        : '—';
    final wind = w.windSpeedKmh != null
        ? _displayNum(w.windSpeedKmh!.round().toString())
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTok.cardSoft(context).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTok.border(context).withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8C29A).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _weatherIcon(w.weatherCode),
                  color: const Color(0xFFE8C29A),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLang.tr('current_conditions'),
                      style: TextStyle(
                        color: AppTok.textSoft(context),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '$temp°',
                          style: TextStyle(
                            color: AppTok.text(context),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _weatherLabel(w.weatherCode),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTok.textSoft(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _weatherPill(
                context,
                Icons.water_drop_outlined,
                '$humidity${AppLang.tr('percent_unit')}',
              ),
              const SizedBox(width: 6),
              _weatherPill(
                context,
                Icons.umbrella_outlined,
                '$precip${AppLang.tr('percent_unit')}',
              ),
              const SizedBox(width: 6),
              _weatherPill(
                context,
                Icons.air_rounded,
                '$wind${AppLang.tr('km_unit')}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppLang.I.isFa ? 'پیش‌بینی ۷ روز آینده' : '7-Day Forecast',
          style: TextStyle(
            color: AppTok.textSoft(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < w.daily.length; i++)
                _dayColumn(context, w.daily[i], i),
            ],
          ),
        ),
      ],
    );
  }

  Widget _weatherPill(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTok.border(context).withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTok.accent(context)),
          const SizedBox(height: 2),
          Text(
            text,
            style: TextStyle(
              color: AppTok.text(context),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayColumn(BuildContext context, WeatherDay day, int index) {
    final isToday = index == 0;
    final j = _JalaliDate.fromDateTime(day.date);
    return Container(
      width: 68,
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: isToday
            ? AppTok.accent(context).withValues(alpha: 0.14)
            : AppTok.cardSoft(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday
              ? AppTok.accent(context).withValues(alpha: 0.35)
              : AppTok.border(context).withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          Text(
            _dayTitle(day.date, index),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isToday
                  ? AppTok.accentDeep(context)
                  : AppTok.textSoft(context),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (AppLang.I.isFa)
            Text(
              '${_faDigits('${j.day}')} ${j.monthNameFa}',
              style: TextStyle(
                color: AppTok.textSoft(context).withValues(alpha: 0.75),
                fontSize: 8.5,
              ),
            ),
          const SizedBox(height: 6),
          Icon(
            _weatherIcon(day.weatherCode),
            color: isToday
                ? AppTok.accent(context)
                : const Color(0xFFE8C29A),
            size: 22,
          ),
          const SizedBox(height: 5),
          Text(
            _weatherShort(day.weatherCode),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTok.text(context),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_displayNum(day.tempMax.round())}°',
                style: const TextStyle(
                  color: Color(0xFFFF8A80),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${_displayNum(day.tempMin.round())}°',
                style: const TextStyle(
                  color: Color(0xFF80CBC4),
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

  Widget _buildCalendar(
    BuildContext context,
    List<QueryDocumentSnapshot> allDocs,
  ) {
    final isDark = AppTok.isDark(context);
    final isFa = AppLang.I.isFa;
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);
    final border = AppTok.border(context);

    final Map<DateTime, List<Color>> dayEventColors = {};
    for (final doc in allDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['date'] as Timestamp?;
      if (ts == null) continue;
      final d = DateTime(ts.toDate().year, ts.toDate().month, ts.toDate().day);
      final cat = _EventCategory.byId(data['category']?.toString());
      dayEventColors.putIfAbsent(d, () => <Color>[]).add(cat.color);
    }

    final secondaryTitle = _formatMonthYearSecondary(focusedDay);

    return PageGlass(
      opacity: isDark ? 0.88 : 0.94,
      blurSigma: 16,
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          // ── هدر حرفه‌ای تقویم (با جهت صحیح فلش‌ها در RTL و سوییچ شمسی/میلادی) ──
          Row(
            children: [
              // در حالت RTL، chevron_left خودکار به > (ماه قبل) تبدیل می‌شود
              _GlassIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: _goPrevMonth,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatMonthYear(focusedDay),
                      style: TextStyle(
                        color: text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (secondaryTitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        secondaryTitle,
                        style: TextStyle(
                          color: textSoft,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _GlassIconButton(
                icon: Icons.chevron_right_rounded,
                onTap: _goNextMonth,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // نوار ابزار تقویم در عرض کم به دو ردیف می‌رود تا سرریز نکند.
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 430;
              final calendarModeToggle = InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () =>
                    setState(() => _showJalaliNumbers = !_showJalaliNumbers),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 14,
                        color: accent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        compact
                            ? (_showJalaliNumbers ? 'نمایش: شمسی' : 'نمایش: میلادی')
                            : (_showJalaliNumbers
                                ? 'نمایش: تقویم شمسی (با زیرنویس میلادی)'
                                : 'نمایش: تقویم میلادی'),
                        style: TextStyle(
                          color: text,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
              final formatControls = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _formatToggleChip(
                    context,
                    label: isFa ? 'ماهانه' : 'Month',
                    selected: _calendarFormat == CalendarFormat.month,
                    onTap: () =>
                        setState(() => _calendarFormat = CalendarFormat.month),
                  ),
                  const SizedBox(width: 4),
                  _formatToggleChip(
                    context,
                    label: isFa ? '۲ هفته' : '2W',
                    selected: _calendarFormat == CalendarFormat.twoWeeks,
                    onTap: () => setState(
                      () => _calendarFormat = CalendarFormat.twoWeeks,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _formatToggleChip(
                    context,
                    label: isFa ? 'هفتگی' : 'Week',
                    selected: _calendarFormat == CalendarFormat.week,
                    onTap: () =>
                        setState(() => _calendarFormat = CalendarFormat.week),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isFa)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: calendarModeToggle,
                      ),
                    if (isFa) const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: formatControls,
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isFa) calendarModeToggle,
                  formatControls,
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Container(
            height: 1,
            color: border.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 8),
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2035),
            focusedDay: focusedDay,
            calendarFormat: _calendarFormat,
            onFormatChanged: (fmt) => setState(() => _calendarFormat = fmt),
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                selectedDay = selected;
                focusedDay = focused;
              });
            },
            onPageChanged: (focused) {
              setState(() => focusedDay = focused);
            },
            headerVisible: false,
            locale: AppLang.I.code,
            startingDayOfWeek: StartingDayOfWeek.saturday,
            daysOfWeekHeight: 34,
            rowHeight: 58,
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: EdgeInsets.all(2),
              cellPadding: EdgeInsets.zero,
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: textSoft,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
              weekendStyle: TextStyle(
                color: const Color(0xFFF8B8C0),
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              todayBuilder: (context, day, focused) {
                final colors =
                    dayEventColors[DateTime(day.year, day.month, day.day)] ??
                        const <Color>[];
                return _DayCell(
                  day: day,
                  isToday: true,
                  isSelected: false,
                  isWeddingDay:
                      weddingDate != null && isSameDay(day, weddingDate!),
                  isWeekend: day.weekday == DateTime.friday,
                  showJalali: isFa && _showJalaliNumbers,
                  eventColors: colors,
                );
              },
              selectedBuilder: (context, day, focused) {
                final colors =
                    dayEventColors[DateTime(day.year, day.month, day.day)] ??
                        const <Color>[];
                return _DayCell(
                  day: day,
                  isToday: isSameDay(day, DateTime.now()),
                  isSelected: true,
                  isWeddingDay:
                      weddingDate != null && isSameDay(day, weddingDate!),
                  isWeekend: day.weekday == DateTime.friday,
                  showJalali: isFa && _showJalaliNumbers,
                  eventColors: colors,
                );
              },
              defaultBuilder: (context, day, focused) {
                final colors =
                    dayEventColors[DateTime(day.year, day.month, day.day)] ??
                        const <Color>[];
                return _DayCell(
                  day: day,
                  isToday: false,
                  isSelected: false,
                  isWeddingDay:
                      weddingDate != null && isSameDay(day, weddingDate!),
                  isWeekend: day.weekday == DateTime.friday,
                  showJalali: isFa && _showJalaliNumbers,
                  eventColors: colors,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _formatToggleChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final accent = AppTok.accent(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? accent : AppTok.cardSoft(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTok.textSoft(context),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = (data['title'] ?? '').toString();
    final desc = (data['desc'] ?? '').toString();
    final time = (data['time'] ?? '').toString();
    final done = data['done'] == true;
    final cat = _EventCategory.byId(data['category']?.toString());
    final ts = data['date'] as Timestamp?;
    final eventDate = ts?.toDate();
    final dateText = eventDate == null ? '--' : _formatDate(eventDate);
    final isDark = AppTok.isDark(context);
    final isFa = AppLang.I.isFa;

    String? diffBadge;
    if (eventDate != null) {
      final dDiff = _dateOnly(eventDate).difference(_dateOnly(DateTime.now())).inDays;
      if (dDiff == 0) {
        diffBadge = isFa ? 'امروز' : 'Today';
      } else if (dDiff == 1) {
        diffBadge = isFa ? 'فردا' : 'Tomorrow';
      } else if (dDiff > 1) {
        diffBadge = isFa ? '${_faDigits('$dDiff')} روز دیگر' : 'In $dDiff days';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PageGlass(
        opacity: isDark ? 0.86 : 0.92,
        blurSigma: 12,
        borderRadius: 18,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => openAddEvent(eventDoc: doc),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: done
                      ? AppTok.border(context).withValues(alpha: 0.4)
                      : cat.color.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _toggleEventDone(doc),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: done
                            ? const Color(0xFF6B8E5A).withValues(alpha: 0.18)
                            : cat.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: done
                              ? const Color(0xFF6B8E5A)
                              : cat.color.withValues(alpha: 0.40),
                        ),
                      ),
                      child: Icon(
                        done ? Icons.check_circle_rounded : cat.icon,
                        color: done ? const Color(0xFF6B8E5A) : cat.color,
                        size: 21,
                      ),
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
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: done
                                      ? AppTok.textSoft(context)
                                      : AppTok.text(context),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (diffBadge != null && !done)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: cat.color.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  diffBadge,
                                  style: TextStyle(
                                    color: cat.color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTok.cardSoft(context),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                dateText,
                                style: TextStyle(
                                  color: AppTok.accentDeep(context),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (time.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTok.cardSoft(context),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 11,
                                      color: AppTok.textSoft(context),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _displayNum(time),
                                      style: TextStyle(
                                        color: AppTok.textSoft(context),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Text(
                              cat.label(isFa),
                              style: TextStyle(
                                color: cat.color,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            desc,
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
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: AppLang.tr('delete_event'),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 30,
                      height: 30,
                    ),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: AppTok.danger(context),
                      size: 18,
                    ),
                    onPressed: () => deleteEvent(doc),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTok.cardSoft(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTok.border(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: AppTok.isDark(context) ? 0.14 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppTok.textSoft(context),
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    this.isWeddingDay = false,
    this.isWeekend = false,
    this.showJalali = true,
    required this.eventColors,
  });

  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool isWeddingDay;
  final bool isWeekend;
  final bool showJalali;
  final List<Color> eventColors;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTok.isDark(context);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);
    final accentDeep = AppTok.accentDeep(context);

    final jalali = _JalaliDate.fromDateTime(day);
    final primaryNum = showJalali ? _toFa(jalali.day) : _toFa(day.day);
    final secondaryNum = showJalali ? '${day.day}' : _toFa(jalali.day);

    Color bg;
    Color txt;
    Border? border;
    List<BoxShadow>? shadow;

    if (isSelected) {
      bg = accent;
      txt = Colors.white;
      shadow = [
        BoxShadow(
          color: accent.withValues(alpha: 0.35),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    } else if (isWeddingDay) {
      bg = const Color(0xFFF8B8C0).withValues(alpha: 0.22);
      txt = const Color(0xFFF8B8C0);
      border = Border.all(color: const Color(0xFFF8B8C0), width: 1.5);
    } else if (isToday) {
      bg = accent.withValues(alpha: 0.16);
      txt = accentDeep;
      border = Border.all(color: accent.withValues(alpha: 0.45), width: 1.3);
    } else {
      bg = AppTok.cardSoft(context).withValues(alpha: isDark ? 0.36 : 0.45);
      txt = isWeekend ? const Color(0xFFF8B8C0) : text;
      border = Border.all(
        color: AppTok.border(context).withValues(alpha: 0.32),
        width: 0.8,
      );
    }

    return Center(
      child: Container(
        width: 44,
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(13),
          border: border,
          boxShadow: shadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isWeddingDay)
              Positioned(
                top: 2,
                left: 3,
                child: Icon(
                  Icons.favorite_rounded,
                  size: 9,
                  color: isSelected ? Colors.white : const Color(0xFFF8B8C0),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  primaryNum,
                  style: TextStyle(
                    color: txt,
                    fontWeight: isSelected || isToday || isWeddingDay
                        ? FontWeight.w800
                        : FontWeight.w700,
                    fontSize: 13,
                    height: 1.05,
                  ),
                ),
                if (AppLang.I.isFa)
                  Text(
                    secondaryNum,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.75)
                          : textSoft.withValues(alpha: 0.55),
                      fontSize: 8.5,
                      height: 1.05,
                    ),
                  ),
                const SizedBox(height: 2),
                if (eventColors.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      eventColors.length.clamp(1, 3),
                      (i) => Container(
                        width: 4.5,
                        height: 4.5,
                        margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : eventColors[i],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 4.5),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const _fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  static String _toFa(int n) {
    final s = n.toString();
    if (!AppLang.I.isFa) return s;
    return s.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? _fa[i] : c;
    }).join();
  }
}
