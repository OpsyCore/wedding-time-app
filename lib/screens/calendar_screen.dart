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
                            const SizedBox(height: 14),
                            _buildCalendar(context, allDocs),
                            const SizedBox(height: 16),
                            _buildWeatherCard(context),
                            const SizedBox(height: 18),
                            Text(
                              AppLang.tr('selected_day_events'),
                              style: TextStyle(
                                color: AppTok.text(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (dayEvents.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  AppLang.tr('no_events_this_day'),
                                  style: TextStyle(
                                    color: AppTok.textSoft(context),
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              ...dayEvents
                                  .map((d) => _buildEventCard(context, d)),
                            const SizedBox(height: 22),
                            Text(
                              AppLang.tr('upcoming_events'),
                              style: TextStyle(
                                color: AppTok.text(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (upcoming.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  AppLang.tr('no_upcoming_events'),
                                  style: TextStyle(
                                    color: AppTok.textSoft(context),
                                    fontSize: 13,
                                  ),
                                ),
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

  Widget _buildWeddingBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTok.accent(context).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: AppTok.accent(context), size: 16),
              const SizedBox(width: 8),
              Text(
                AppLang.tr('your_wedding_date'),
                style: TextStyle(
                  color: AppTok.text(context),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            weddingDate == null
                ? AppLang.tr('loading_ellipsis')
                : _formatDate(weddingDate!),
            style: TextStyle(
              color: AppTok.accent(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_displayNum(daysLeft)}${AppLang.tr('days_remaining')}',
            style: TextStyle(color: AppTok.textSoft(context), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(BuildContext context) {
    final hasLocation = _venueLat != null && _venueLng != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTok.border(context).withValues(alpha: 0.5),
        ),
      ),
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
              if (hasLocation)
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
          if (_venueCity != null) ...[
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
                  _venueCity!,
                  style: TextStyle(
                    color: AppTok.accent(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (!hasLocation)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTok.background(context),
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
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    _weatherIcon(w.weatherCode),
                    color: const Color(0xFFE8C29A),
                    size: 40,
                  ),
                  const SizedBox(width: 10),
                  Column(
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
                        _weatherLabel(w.weatherCode),
                        style: TextStyle(
                          color: AppTok.textSoft(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                Icons.air,
                '$wind${AppLang.tr('km_unit')}',
              ),
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
                  _dayColumn(context, w.daily[i], i),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaRow(BuildContext context, IconData icon, String text) {
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

  Widget _dayColumn(BuildContext context, WeatherDay day, int index) {
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
            color: const Color(0xFFE8C29A),
            size: 26,
          ),
          const SizedBox(height: 6),
          Text(
            _weatherShort(day.weatherCode),
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
            '${_displayNum(day.tempMax.round())}°',
            style: const TextStyle(
              color: Color(0xFFFF8A80),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_displayNum(day.tempMin.round())}°',
            style: const TextStyle(
              color: Color(0xFF80CBC4),
              fontSize: 12,
              fontWeight: FontWeight.bold,
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: TableCalendar(
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
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(color: AppTok.text(context)),
          weekendTextStyle: TextStyle(color: AppTok.textSoft(context)),
          todayDecoration: BoxDecoration(
            color: AppTok.accent(context).withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: AppTok.accent(context),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: AppTok.text(context),
            fontWeight: FontWeight.bold,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          markerDecoration: BoxDecoration(
            color: AppTok.accent(context),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: AppTok.text(context),
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: AppTok.textSoft(context),
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: AppTok.textSoft(context),
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: AppTok.textSoft(context),
            fontSize: 12,
          ),
          weekendStyle: TextStyle(
            color: AppTok.textSoft(context),
            fontSize: 12,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            final has = allDocs.any((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final ts = data['date'] as Timestamp?;
              if (ts == null) return false;
              final d = ts.toDate();
              return d.year == date.year &&
                  d.month == date.month &&
                  d.day == date.day;
            });

            if (!has) return null;

            return Positioned(
              bottom: 1,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTok.accent(context),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = (data['title'] ?? '').toString();
    final desc = (data['desc'] ?? '').toString();
    final ts = data['date'] as Timestamp?;
    final dateText = ts == null ? '--' : _formatDate(ts.toDate());

    return Dismissible(
      key: ValueKey(doc.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await deleteEvent(doc);
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(Icons.delete_outline, color: AppTok.danger(context)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTok.card(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          onTap: () => openAddEvent(eventDoc: doc),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTok.accent(context).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.event_outlined,
              color: AppTok.accent(context),
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: AppTok.text(context),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                dateText,
                style: TextStyle(
                  color: AppTok.accent(context),
                  fontSize: 12,
                ),
              ),
              if (desc.isNotEmpty)
                Text(
                  desc,
                  style: TextStyle(
                    color: AppTok.textSoft(context),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          trailing: Icon(
            Icons.edit_outlined,
            color: AppTok.textSoft(context),
            size: 18,
          ),
        ),
      ),
    );
  }
}