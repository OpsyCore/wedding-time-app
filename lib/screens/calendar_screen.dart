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
import '../widgets/page_glass.dart';
import '../widgets/wedding_time_header.dart';

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

  String? _venueCity;
  double? _venueLat;
  double? _venueLng;

  WeatherSnapshot? _weather;
  bool _weatherLoading = false;
  String? _weatherError;

  StreamSubscription<DocumentSnapshot>? _weddingSub;
  StreamSubscription<DocumentSnapshot>? _invitationSub;

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
    _listenWedding();
    _listenInvitation();
  }

  void _listenWedding() {
    _weddingSub = _weddingDoc.snapshots().listen((doc) {
      final data = doc.data();
      final ts = data?['weddingDate'] as Timestamp?;
      if (!mounted) return;
      setState(() => weddingDate = ts?.toDate());
    });
  }

  void _listenInvitation() {
    _invitationSub = _invitationDoc.snapshots().listen((doc) {
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
    });
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
    super.dispose();
  }

  int get daysLeft {
    if (weddingDate == null) return 0;
    final diff = weddingDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  List<QueryDocumentSnapshot> _eventsForDay(
    List<QueryDocumentSnapshot> all,
    DateTime day,
  ) {
    final target = _dateOnly(day);
    return all.where((doc) {
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
    final now = DateTime.now();
    final list = all.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['date'] as Timestamp?;
      if (ts == null) return false;
      return ts.toDate().isAfter(now) || isSameDay(ts.toDate(), now);
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
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return _displayNum('$y/$m/$day');
  }

  String _formatMonthYear(DateTime d) {
    // Premium month header — use AppLang for month? For simplicity, English month + year with fa digits
    // We have weekday keys but not month keys; use numeric month/year with refined typography
    // If fa, show Persian month approximate via Gregorian month name translated? Keep simple: y/m with fa digits
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
      'December'
    ];
    const faMonths = [
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
      'دسامبر'
    ];
    final monthName = AppLang.I.isFa ? faMonths[d.month - 1] : enMonths[d.month - 1];
    final year = _displayNum(d.year);
    return '$monthName $year';
  }

  String _dayTitle(DateTime d, int index) {
    if (index == 0) return AppLang.tr('today');
    return _weekDayName(d.weekday);
  }

  IconData _weatherIcon(int code) {
    if (code == 0 || code == 1) return Icons.wb_sunny_outlined;
    if (code == 2) return Icons.wb_cloudy_outlined;
    if (code == 3) return Icons.cloud_outlined;
    if (code == 45 || code == 48) return Icons.cloud_queue_outlined;
    if (code >= 51 && code <= 67) return Icons.water_drop_outlined;
    if (code >= 71 && code <= 77) return Icons.ac_unit;
    if (code >= 80 && code <= 82) return Icons.grain;
    if (code >= 95) return Icons.thunderstorm_outlined;
    return Icons.wb_cloudy_outlined;
  }

  String _weatherLabel(int code) {
    return WeatherService.label(code);
  }

  String _weatherShort(int code) {
    return WeatherService.conditionShort(code);
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppTok.textSoft(context)),
      filled: true,
      fillColor: AppTok.background(context),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTok.accent(context)),
      ),
    );
  }

  void openAddEvent({DocumentSnapshot? eventDoc}) {
    final data = eventDoc?.data() as Map<String, dynamic>?;
    final titleC = TextEditingController(text: data?['title'] ?? '');
    final descC = TextEditingController(text: data?['desc'] ?? '');

    DateTime pickedDate = selectedDay;
    if (data?['date'] is Timestamp) {
      pickedDate = (data!['date'] as Timestamp).toDate();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTok.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ListenableBuilder(
              listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
              builder: (context, _) {
                return Directionality(
                  textDirection: AppLang.I.direction,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                      left: 20,
                      right: 20,
                      top: 20,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            eventDoc == null
                                ? AppLang.tr('add_event')
                                : AppLang.tr('edit_event'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTok.text(context),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: titleC,
                            style: TextStyle(color: AppTok.text(context)),
                            decoration: _fieldDecoration(
                              context,
                              AppLang.tr('title'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: descC,
                            style: TextStyle(color: AppTok.text(context)),
                            maxLines: 3,
                            decoration: _fieldDecoration(
                              context,
                              AppLang.tr('description'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
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
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppTok.background(context),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    color: AppTok.textSoft(context),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _formatDate(pickedDate),
                                    style: TextStyle(
                                      color: AppTok.text(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTok.accent(context),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () async {
                                if (titleC.text.trim().isEmpty) return;

                                final payload = {
                                  'title': titleC.text.trim(),
                                  'desc': descC.text.trim(),
                                  'date': Timestamp.fromDate(
                                    DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                    ),
                                  ),
                                };

                                if (eventDoc == null) {
                                  await eventsRef.add({
                                    ...payload,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                } else {
                                  await eventsRef
                                      .doc(eventDoc.id)
                                      .update(payload);
                                }

                                if (context.mounted) Navigator.pop(context);
                              },
                              child: Text(
                                AppLang.tr('save'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        return Directionality(
          textDirection: AppLang.I.direction,
          child: Scaffold(
            backgroundColor: AppTok.background(context),
            drawer: AppDrawer(weddingId: widget.weddingId),
            body: SafeArea(
              child: StreamBuilder<QuerySnapshot>(
                stream: eventsRef.orderBy('date').snapshots(),
                builder: (context, snapshot) {
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
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                          children: [
                            _buildWeddingBanner(context),
                            const SizedBox(height: 16),
                            _buildCalendar(context, allDocs),
                            const SizedBox(height: 16),
                            _buildWeatherCard(context),
                            const SizedBox(height: 20),
                            _buildSectionTitle(
                              context,
                              icon: Icons.event_note_rounded,
                              title: AppLang.tr('selected_day_events'),
                              subtitle: _formatDate(selectedDay),
                            ),
                            const SizedBox(height: 12),
                            if (dayEvents.isEmpty)
                              _buildEmptyState(
                                context,
                                message: AppLang.tr('no_events_this_day'),
                                icon: Icons.event_busy_outlined,
                              )
                            else
                              ...dayEvents
                                  .map((d) => _buildEventCard(context, d)),
                            const SizedBox(height: 24),
                            _buildSectionTitle(
                              context,
                              icon: Icons.upcoming_rounded,
                              title: AppLang.tr('upcoming_events'),
                            ),
                            const SizedBox(height: 12),
                            if (upcoming.isEmpty)
                              _buildEmptyState(
                                context,
                                message: AppLang.tr('no_upcoming_events'),
                                icon: Icons.calendar_today_outlined,
                              )
                            else
                              ...upcoming
                                  .map((d) => _buildEventCard(context, d)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'calendar_fab',
              backgroundColor: AppTok.accent(context),
              foregroundColor: Colors.white,
              onPressed: () => openAddEvent(),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTok.accent(context).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
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
      ],
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

  Widget _buildWeddingBanner(BuildContext context) {
    final isDark = AppTok.isDark(context);
    return PageGlass(
      opacity: isDark ? 0.86 : 0.90,
      blurSigma: 14,
      borderRadius: 22,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppDarkPalette.cardSoft.withValues(alpha: 0.9),
                    AppDarkPalette.card.withValues(alpha: 0.95),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.95),
                    AppPalette.cardSoft.withValues(alpha: 0.9),
                  ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTok.accent(context).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTok.accent(context).withValues(alpha: 0.18),
                ),
              ),
              child: Icon(
                Icons.favorite_rounded,
                color: AppTok.accent(context),
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
                      color: AppTok.textSoft(context),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weddingDate == null
                        ? AppLang.tr('loading_ellipsis')
                        : _formatDate(weddingDate!),
                    style: TextStyle(
                      color: AppTok.text(context),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTok.accent(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTok.accent(context).withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.hourglass_bottom_rounded,
                    size: 14,
                    color: AppTok.accentDeep(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_displayNum(daysLeft)}${AppLang.tr('days_remaining')}',
                    style: TextStyle(
                      color: AppTok.accentDeep(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
                width: 32,
                height: 32,
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
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8C29A).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _weatherIcon(w.weatherCode),
                      color: const Color(0xFFE8C29A),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$temp°',
                        style: TextStyle(
                          color: AppTok.text(context),
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _weatherLabel(w.weatherCode),
                        style: TextStyle(
                          color: AppTok.textSoft(context),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _metaRow(
                context,
                Icons.water_drop_outlined,
                '$humidity${AppLang.tr('percent_unit')}',
              ),
              const SizedBox(height: 6),
              _metaRow(
                context,
                Icons.umbrella_outlined,
                '$precip${AppLang.tr('percent_unit')}',
              ),
              const SizedBox(height: 6),
              _metaRow(
                context,
                Icons.air_rounded,
                '$wind${AppLang.tr('km_unit')}',
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLang.I.isFa ? '۷ روز آینده' : 'Next 7 days',
                style: TextStyle(
                  color: AppTok.textSoft(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < w.daily.length; i++)
                      _dayColumn(context, w.daily[i], i),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metaRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppTok.cardSoft(context),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 12, color: AppTok.textSoft(context)),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: AppTok.textSoft(context), fontSize: 11.5),
        ),
      ],
    );
  }

  Widget _dayColumn(BuildContext context, WeatherDay day, int index) {
    final isToday = index == 0;
    return Container(
      width: 62,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: isToday
            ? AppTok.accent(context).withValues(alpha: 0.10)
            : AppTok.cardSoft(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday
              ? AppTok.accent(context).withValues(alpha: 0.22)
              : AppTok.border(context).withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          Text(
            _dayTitle(day.date, index),
            style: TextStyle(
              color: isToday
                  ? AppTok.accentDeep(context)
                  : AppTok.textSoft(context),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            _weatherIcon(day.weatherCode),
            color: isToday
                ? AppTok.accent(context)
                : const Color(0xFFE8C29A),
            size: 22,
          ),
          const SizedBox(height: 6),
          Text(
            _weatherShort(day.weatherCode),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTok.text(context),
              fontSize: 9.5,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_displayNum(day.tempMax.round())}°',
            style: const TextStyle(
              color: Color(0xFFFF8A80),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_displayNum(day.tempMin.round())}°',
            style: const TextStyle(
              color: Color(0xFF80CBC4),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
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
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);
    final accentDeep = AppTok.accentDeep(context);
    final border = AppTok.border(context);
    final cardSoft = AppTok.cardSoft(context);
    final ringTrack = AppTok.ringTrack(context);

    // Precompute events per day for dot colors
    Map<DateTime, int> eventsCount = {};
    for (final doc in allDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['date'] as Timestamp?;
      if (ts == null) continue;
      final d = DateTime(ts.toDate().year, ts.toDate().month, ts.toDate().day);
      eventsCount[d] = (eventsCount[d] ?? 0) + 1;
    }

    return PageGlass(
      opacity: isDark ? 0.86 : 0.92,
      blurSigma: 16,
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          // ── Premium month header ──
          Row(
            children: [
              _GlassIconButton(
                icon: AppLang.I.isFa
                    ? Icons.chevron_right_rounded
                    : Icons.chevron_left_rounded,
                onTap: _goPrevMonth,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      AppLang.tr('calendar_month_title'),
                      style: TextStyle(
                        color: textSoft,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatMonthYear(focusedDay),
                      style: TextStyle(
                        color: text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              _GlassIconButton(
                icon: AppLang.I.isFa
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                onTap: _goNextMonth,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: border.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 8),
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2035),
            focusedDay: focusedDay,
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
            daysOfWeekHeight: 36,
            rowHeight: 56,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.all(4),
              cellPadding: EdgeInsets.zero,
              defaultTextStyle: TextStyle(
                color: text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              weekendTextStyle: TextStyle(
                color: textSoft,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              outsideTextStyle: TextStyle(
                color: textSoft.withValues(alpha: 0.35),
                fontSize: 13,
              ),
              todayDecoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              todayTextStyle: TextStyle(
                color: accentDeep,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              selectedDecoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              markerDecoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: textSoft,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
              weekendStyle: TextStyle(
                color: textSoft.withValues(alpha: 0.8),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              // Custom today with sage ring
              todayBuilder: (context, day, focused) {
                final count = eventsCount[DateTime(day.year, day.month, day.day)] ?? 0;
                return _DayCell(
                  day: day,
                  isToday: true,
                  isSelected: false,
                  eventsCount: count,
                );
              },
              selectedBuilder: (context, day, focused) {
                final count = eventsCount[DateTime(day.year, day.month, day.day)] ?? 0;
                return _DayCell(
                  day: day,
                  isToday: isSameDay(day, DateTime.now()),
                  isSelected: true,
                  eventsCount: count,
                );
              },
              defaultBuilder: (context, day, focused) {
                final count = eventsCount[DateTime(day.year, day.month, day.day)] ?? 0;
                final isWeekend = day.weekday == DateTime.friday;
                return _DayCell(
                  day: day,
                  isToday: false,
                  isSelected: false,
                  isWeekend: isWeekend,
                  eventsCount: count,
                );
              },
              outsideBuilder: (context, day, focused) {
                return Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: textSoft.withValues(alpha: 0.28),
                      fontSize: 13,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = (data['title'] ?? '').toString();
    final desc = (data['desc'] ?? '').toString();
    final ts = data['date'] as Timestamp?;
    final dateText = ts == null ? '--' : _formatDate(ts.toDate());
    final isDark = AppTok.isDark(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PageGlass(
        opacity: isDark ? 0.84 : 0.90,
        blurSigma: 12,
        borderRadius: 16,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => openAddEvent(eventDoc: doc),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTok.accent(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTok.accent(context).withValues(alpha: 0.18),
                      ),
                    ),
                    child: Icon(
                      Icons.event_rounded,
                      color: AppTok.accent(context),
                      size: 20,
                    ),
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
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTok.cardSoft(context),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                dateText,
                                style: TextStyle(
                                  color: AppTok.accentDeep(context),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (desc.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  desc,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppTok.textSoft(context),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_outlined,
                    color: AppTok.textSoft(context),
                    size: 16,
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
                color: Colors.black.withValues(alpha: AppTok.isDark(context) ? 0.14 : 0.04),
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
    this.isWeekend = false,
    required this.eventsCount,
  });

  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool isWeekend;
  final int eventsCount;

  @override
  Widget build(BuildContext context) {
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);
    final accentDeep = AppTok.accentDeep(context);
    final accentSoft = AppTok.accentSoft(context);
    final isDark = AppTok.isDark(context);

    Color bg;
    Color txt;
    Border? border;
    List<BoxShadow>? shadow;

    if (isSelected) {
      bg = accent;
      txt = Colors.white;
      shadow = [
        BoxShadow(
          color: accent.withValues(alpha: 0.32),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    } else if (isToday) {
      bg = accent.withValues(alpha: 0.14);
      txt = accentDeep;
      border = Border.all(color: accent.withValues(alpha: 0.38), width: 1.3);
    } else {
      bg = Colors.transparent;
      txt = isWeekend ? textSoft : text;
    }

    final dayNum = day.day.toString();

    return Center(
      child: Container(
        width: 40,
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(12),
          border: border,
          boxShadow: shadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLang.I.isFa
                  ? _toFa(day.day)
                  : dayNum,
              style: TextStyle(
                color: txt,
                fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            if (eventsCount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  eventsCount.clamp(1, 3),
                  (i) {
                    final colors = [
                      isSelected ? Colors.white : accent,
                      isSelected ? Colors.white.withValues(alpha: 0.8) : accentSoft,
                      isSelected ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF8E9C6B),
                    ];
                    return Container(
                      width: 4.5,
                      height: 4.5,
                      margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
                      decoration: BoxDecoration(
                        color: colors[i],
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
              )
            else
              const SizedBox(height: 4.5),
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
