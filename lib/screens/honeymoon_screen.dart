import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../services/media_upload_service.dart';
import '../widgets/image_crop_screen.dart';

/// برنامه‌ریز ماه عسل — preferenze، مقصدها، علاقه‌مندی‌ها، رزرو و مکان‌های شخصی.
/// ذخیره در: weddings/{weddingId}/honeymoon/{prefs|destinations}
class HoneymoonScreen extends StatefulWidget {
  const HoneymoonScreen({super.key, required this.weddingId});

  final String weddingId;

  @override
  State<HoneymoonScreen> createState() => _HoneymoonScreenState();
}

class _Option {
  const _Option(this.id, this.fa, this.en, this.icon);
  final String id;
  final String fa;
  final String en;
  final IconData icon;
}

const _seasons = [
  _Option('spring', 'بهار', 'Spring', Icons.local_florist_outlined),
  _Option('summer', 'تابستان', 'Summer', Icons.wb_sunny_outlined),
  _Option('fall', 'پاییز', 'Fall', Icons.forest_outlined),
  _Option('winter', 'زمستان', 'Winter', Icons.ac_unit_outlined),
];

const _styles = [
  _Option('beach', 'ساحلی', 'Beach', Icons.beach_access_outlined),
  _Option('city', 'شهرگردی', 'City', Icons.location_city_outlined),
  _Option('adventure', 'ماجراجویی', 'Adventure', Icons.hiking_outlined),
  _Option('wellness', 'آرامش و اسپا', 'Wellness', Icons.spa_outlined),
  _Option('roadtrip', 'جاده و طبیعت', 'Road trip', Icons.directions_car_outlined),
  _Option('allinclusive', 'هتل همه‌چیزتمام', 'All-inclusive', Icons.all_inclusive),
];

const _regions = [
  _Option('iran', 'ایران', 'Iran', Icons.location_on_outlined),
  _Option('europe', 'اروپا', 'Europe', Icons.public_outlined),
  _Option('asia', 'آسیا', 'Asia', Icons.language_outlined),
  _Option('africa', 'آفریقا', 'Africa', Icons.travel_explore_outlined),
  _Option('america', 'آمریکا', 'America', Icons.map_outlined),
  _Option('oceania', 'اقیانوسیه', 'Oceania', Icons.waves_outlined),
];

const _climates = [
  _Option('warm', 'گرم', 'Warmer', Icons.whatshot_outlined),
  _Option('mild', 'معتدل', 'Mild', Icons.filter_none_outlined),
  _Option('cool', 'خنک', 'Cooler', Icons.ac_unit_outlined),
];

/// کاتالوگ اولیهٔ مقصدها (seed)
const _catalog = <Map<String, Object>>[
  {
    'nameFa': 'آنتالیا',
    'nameEn': 'Antalya',
    'countryFa': 'ترکیه',
    'countryEn': 'Turkey',
    'region': 'asia',
    'price': 9000000,
    'styles': ['beach', 'allinclusive', 'city'],
    'seasons': ['spring', 'summer', 'fall'],
    'climates': ['warm', 'mild'],
    'prosFa': ['هتل‌های همه‌چیزتمام عالی', 'پرواز مستقیم و کوتاه', 'تنوع ساحل و خرید'],
    'consFa': ['تابستان‌های شرجی', 'مناطق توریستی شلوغ'],
  },
  {
    'nameFa': 'کیش',
    'nameEn': 'Kish',
    'countryFa': 'ایران',
    'countryEn': 'Iran',
    'region': 'iran',
    'price': 6000000,
    'styles': ['beach', 'wellness', 'allinclusive'],
    'seasons': ['winter', 'fall', 'spring'],
    'climates': ['warm'],
    'prosFa': ['بدون ویزا و پرواز خارجی', 'هتل‌های لوکس', 'تفریحات دریایی'],
    'consFa': ['تابستان بسیار گرم', 'قیمت بالای هتل‌ها در پیک'],
  },
  {
    'nameFa': 'سانتورینی',
    'nameEn': 'Santorini',
    'countryFa': 'یونان',
    'countryEn': 'Greece',
    'region': 'europe',
    'price': 18000000,
    'styles': ['beach', 'city', 'wellness'],
    'seasons': ['spring', 'summer'],
    'climates': ['mild', 'warm'],
    'prosFa': ['منظره‌های رویایی', 'غروب‌های معروف', 'عکاسی بی‌نظیر'],
    'consFa': ['نیاز به ویزای شنگن', 'هزینهٔ بالا در پیک'],
  },
  {
    'nameFa': 'دبی',
    'nameEn': 'Dubai',
    'countryFa': 'امارات',
    'countryEn': 'UAE',
    'region': 'asia',
    'price': 12000000,
    'styles': ['city', 'allinclusive', 'adventure'],
    'seasons': ['winter', 'fall', 'spring'],
    'climates': ['warm'],
    'prosFa': ['ویزای آسان', 'هتل‌های لوکس', 'خرید و تفریح'],
    'consFa': ['تابستان بسیار داغ', 'هزینهٔ تفریحات بالا'],
  },
  {
    'nameFa': 'تفلیس',
    'nameEn': 'Tbilisi',
    'countryFa': 'گرجستان',
    'countryEn': 'Georgia',
    'region': 'europe',
    'price': 7000000,
    'styles': ['city', 'roadtrip', 'adventure'],
    'seasons': ['spring', 'summer', 'fall'],
    'climates': ['mild', 'cool'],
    'prosFa': ['بدون ویزا', 'طبیعت و کافه‌های دنج', 'هزینهٔ مناسب'],
    'consFa': ['زمستان سرد', 'پروازهای محدود در پیک'],
  },
  {
    'nameFa': 'بالی',
    'nameEn': 'Bali',
    'countryFa': 'اندونزی',
    'countryEn': 'Indonesia',
    'region': 'asia',
    'price': 15000000,
    'styles': ['beach', 'wellness', 'adventure'],
    'seasons': ['spring', 'summer', 'fall'],
    'climates': ['warm'],
    'prosFa': ['ویلاهای خصوصی', 'اسپا و یوگا', 'طبیعت بکر'],
    'consFa': ['پرواز طولانی', 'ترافیک محلی'],
  },
  {
    'nameFa': 'پاریس',
    'nameEn': 'Paris',
    'countryFa': 'فرانسه',
    'countryEn': 'France',
    'region': 'europe',
    'price': 22000000,
    'styles': ['city', 'wellness'],
    'seasons': ['spring', 'summer', 'fall'],
    'climates': ['mild', 'cool'],
    'prosFa': ['شهر عشاق', 'موزه‌ها و کافه‌ها', 'رستوران‌های عالی'],
    'consFa': ['ویزای شنگن سخت', 'هزینهٔ بالا'],
  },
  {
    'nameFa': 'مالدیو',
    'nameEn': 'Maldives',
    'countryFa': 'مالدیو',
    'countryEn': 'Maldives',
    'region': 'asia',
    'price': 35000000,
    'styles': ['beach', 'wellness', 'allinclusive'],
    'seasons': ['winter', 'spring'],
    'climates': ['warm'],
    'prosFa': ['ویلای روی آب', 'خصوصی و آرام', 'غواصی و دریا'],
    'consFa': ['گران‌ترین مقصد', 'خارج از هتل تفریحی نیست'],
  },
];

class _HoneymoonScreenState extends State<HoneymoonScreen> {
  final _budgetC = TextEditingController();

  int _nights = 5;
  int _budget = 0;
  bool _prefsLoaded = false;
  bool _filterOn = true;

  final Set<String> _selSeasons = {};
  final Set<String> _selStyles = {};
  final Set<String> _selRegions = {};
  final Set<String> _selClimates = {};

  CollectionReference<Map<String, dynamic>> get _dests => FirebaseFirestore
      .instance
      .collection('weddings')
      .doc(widget.weddingId)
      .collection('honeymoon')
      .collection('destinations');

  DocumentReference<Map<String, dynamic>> get _prefsDoc => FirebaseFirestore
      .instance
      .collection('weddings')
      .doc(widget.weddingId)
      .collection('honeymoon')
      .doc('prefs');

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _budgetC.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    try {
      final s = await _prefsDoc.get();
      final d = s.data() ?? {};
      _nights = (d['nights'] is int ? d['nights'] as int : 5);
      _budget = (d['budget'] is int ? d['budget'] as int : 0);
      _budgetC.text = _budget == 0 ? '' : '$_budget';
      _selSeasons
          .addAll((d['seasons'] as List? ?? []).map((e) => e.toString()));
      _selStyles.addAll((d['styles'] as List? ?? []).map((e) => e.toString()));
      _selRegions
          .addAll((d['regions'] as List? ?? []).map((e) => e.toString()));
      _selClimates
          .addAll((d['climates'] as List? ?? []).map((e) => e.toString()));

      if (d['catalogSeeded'] != true) {
        final batch = FirebaseFirestore.instance.batch();
        for (final c in _catalog) {
          final ref = _dests.doc();
          batch.set(ref, {
            ...c,
            'source': 'catalog',
            'fav': false,
            'finalPick': false,
            'status': 'none',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
        await _prefsDoc.set(
            {'catalogSeeded': true, 'updatedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
      }
    } catch (_) {}
    if (mounted) setState(() => _prefsLoaded = true);
  }

  Future<void> _savePrefs() async {
    await _prefsDoc.set({
      'nights': _nights,
      'budget': _budget,
      'seasons': _selSeasons.toList(),
      'styles': _selStyles.toList(),
      'regions': _selRegions.toList(),
      'climates': _selClimates.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _faNum(Object v) {
    if (!AppLang.I.isFa) return '$v';
    const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return '$v'.split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? fa[i] : c;
    }).join();
  }

  String _money(num v) => '${_faNum(v.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      ))}';

  bool _matches(Map<String, dynamic> d) {
    if (!_filterOn) return true;
    bool hit(Set<String> sel, String field) {
      if (sel.isEmpty) return true;
      final v = d[field];
      if (v is List) {
        return v.any((e) => sel.contains(e.toString()));
      }
      return sel.contains(v.toString());
    }

    if (!hit(_selSeasons, 'seasons')) return false;
    if (!hit(_selStyles, 'styles')) return false;
    if (!hit(_selRegions, 'region')) return false;
    if (!hit(_selClimates, 'climates')) return false;
    if (_budget > 0) {
      final price = (d['price'] is num ? d['price'] as num : 0) * _nights;
      if (price > _budget) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        final isFa = AppLang.I.isFa;
        final bg = AppTok.background(context);
        final text = AppTok.text(context);
        final accent = AppTok.accent(context);

        return Directionality(
          textDirection: AppLang.I.direction,
          child: Scaffold(
            backgroundColor: bg,
            appBar: AppBar(
              backgroundColor: bg,
              surfaceTintColor: Colors.transparent,
              title: Text(
                isFa ? 'ماه عسل' : 'Honeymoon',
                style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              iconTheme: IconThemeData(color: text),
              actions: [
                IconButton(
                  tooltip: isFa ? 'فیلتر هوشمند' : 'Smart filter',
                  icon: Icon(
                    _filterOn
                        ? Icons.tune_rounded
                        : Icons.tune_outlined,
                    color: _filterOn ? accent : AppTok.textSoft(context),
                  ),
                  onPressed: () => setState(() => _filterOn = !_filterOn),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.add_circle_outline, color: text),
                  onSelected: (v) {
                    if (v == 'custom') {
                      _openEditor(null, 'custom');
                    } else {
                      _openEditor(null, 'vendor');
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'custom',
                      child: Text(isFa
                          ? 'افزودن مکان شخصی'
                          : 'Add personal place'),
                    ),
                    PopupMenuItem(
                      value: 'vendor',
                      child: Text(isFa
                          ? 'افزودن پیشنهاد هتل/تفریح'
                          : 'Add hotel/venue offer'),
                    ),
                  ],
                ),
              ],
            ),
            body: !_prefsLoaded
                ? Center(child: CircularProgressIndicator(color: accent))
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _dests.snapshots(),
                    builder: (context, snap) {
                      final docs = (snap.data?.docs ?? []).toList();
                      docs.sort((a, b) {
                        final fa = a.data()['finalPick'] == true ? 0 : 1;
                        final fb = b.data()['finalPick'] == true ? 0 : 1;
                        if (fa != fb) return fa.compareTo(fb);
                        final av = a.data()['fav'] == true ? 0 : 1;
                        final bv = b.data()['fav'] == true ? 0 : 1;
                        if (av != bv) return av.compareTo(bv);
                        return 0;
                      });
                      final visible = docs.where((d) => _matches(d.data())).toList();
                      final finalDoc =
                          docs.where((d) => d.data()['finalPick'] == true).toList();

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        children: [
                          _prefsCard(),
                          const SizedBox(height: 14),
                          if (finalDoc.isNotEmpty) ...[
                            _finalBanner(finalDoc.first),
                            const SizedBox(height: 14),
                          ],
                          Row(
                            children: [
                              Icon(Icons.explore_outlined,
                                  color: accent, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                isFa
                                    ? 'مقصدها (${_faNum(visible.length)})'
                                    : 'Destinations (${visible.length})',
                                style: TextStyle(
                                  color: text,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                isFa
                                    ? (_filterOn ? 'فیلتر روشن' : 'فیلتر خاموش')
                                    : (_filterOn ? 'Filter on' : 'Filter off'),
                                style: TextStyle(
                                  color: AppTok.textSoft(context),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...visible.map(_destCard),
                          if (visible.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                isFa
                                    ? 'مقصدی با این فیلترها پیدا نشد — فیلتر را خاموش کن یا بودجه/فصل را تغییر بده.'
                                    : 'No destination matches — turn the filter off or adjust budget/season.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTok.textSoft(context),
                                  height: 1.7,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  // ─────────────────────────── فرم ترجیحات ───────────────────────────

  Widget _prefsCard() {
    final isFa = AppLang.I.isFa;
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTok.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flight_takeoff_outlined,
                  color: AppTok.accent(context), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFa
                      ? 'ترجیح‌های سفر ماه عسل'
                      : 'Honeymoon preferences',
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  isFa ? 'چند شب؟' : 'How many nights?',
                  style: TextStyle(color: textSoft, fontSize: 12),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: () => setState(() {
                  if (_nights > 1) _nights--;
                  _savePrefs();
                }),
              ),
              Text(
                isFa
                    ? '${_faNum(_nights)} شب'
                    : '$_nights nights',
                style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () => setState(() {
                  if (_nights < 30) _nights++;
                  _savePrefs();
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _budgetC,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {
              _budget = int.tryParse(v) ?? 0;
              _savePrefs();
            },
            style: TextStyle(color: text, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppTok.cardSoft(context),
              labelText: isFa
                  ? 'بودجهٔ کل (تومان)'
                  : 'Total budget (Toman)',
              labelStyle: TextStyle(color: textSoft, fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _chipRow(
            isFa ? 'فصل سفر' : 'Season',
            _seasons,
            _selSeasons,
          ),
          const SizedBox(height: 10),
          _chipRow(isFa ? 'سبک سفر' : 'Style', _styles, _selStyles),
          const SizedBox(height: 10),
          _chipRow(isFa ? 'منطقه' : 'Region', _regions, _selRegions),
          const SizedBox(height: 10),
          _chipRow(isFa ? 'آب‌وهوا' : 'Climate', _climates, _selClimates),
        ],
      ),
    );
  }

  Widget _chipRow(
    String label,
    List<_Option> options,
    Set<String> sel,
  ) {
    final isFa = AppLang.I.isFa;
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textSoft, fontSize: 11.5)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((o) {
            final on = sel.contains(o.id);
            return FilterChip(
              selected: on,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    sel.add(o.id);
                  } else {
                    sel.remove(o.id);
                  }
                  _savePrefs();
                });
              },
              selectedColor: accent.withValues(alpha: 0.18),
              checkmarkColor: accent,
              labelPadding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              label: Text(
                isFa ? o.fa : o.en,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: on ? accent : textSoft,
                ),
              ),
              avatar: Icon(o.icon, size: 14, color: on ? accent : textSoft),
              side: BorderSide(
                color: on
                    ? accent.withValues(alpha: 0.5)
                    : AppTok.border(context),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─────────────────────────── کارت مقصد ───────────────────────────

  Widget _destCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final isFa = AppLang.I.isFa;
    final name = (isFa ? d['nameFa'] ?? d['nameEn'] : d['nameEn'] ?? d['nameFa'])
        .toString();
    final country =
        (isFa ? d['countryFa'] ?? d['countryEn'] : d['countryEn'] ?? d['countryFa'])
            .toString();
    final img = (d['imageUrl'] ?? '').toString();
    final fav = d['fav'] == true;
    final isFinal = d['finalPick'] == true;
    final price = d['price'] is num ? d['price'] as num : 0;
    final source = (d['source'] ?? 'catalog').toString();
    final status = (d['status'] ?? 'none').toString();

    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFinal
              ? accent.withValues(alpha: 0.65)
              : AppTok.border(context),
          width: isFinal ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openDetails(doc),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(17),
                  ),
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: img.isNotEmpty
                        ? Image.network(
                            img,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _photoPlaceholder(),
                          )
                        : _photoPlaceholder(),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _badge(
                    source == 'vendor'
                        ? (isFa ? 'پیشنهاد هتل' : 'Hotel offer')
                        : source == 'custom'
                            ? (isFa ? 'انتخاب ما' : 'Our pick')
                            : (isFa ? 'پیشنهاد ما' : 'Suggested'),
                  ),
                ),
                if (status == 'requested')
                  Positioned(
                    top: 8,
                    right: 52,
                    child: _badge(isFa ? 'درخواست رزرو' : 'Requested'),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: isFa ? 'انتخاب نهایی' : 'Final pick',
                        icon: Icon(
                          isFinal
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: isFinal ? Colors.amber : Colors.white,
                          size: 24,
                        ),
                        onPressed: () => _setFinal(doc, !isFinal),
                      ),
                      IconButton(
                        tooltip: isFa ? 'علاقه‌مندی' : 'Favorite',
                        icon: Icon(
                          fav
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          color: fav
                              ? const Color(0xFFE5484D)
                              : Colors.white,
                          size: 24,
                        ),
                        onPressed: () => _dests.doc(doc.id).set({
                          'fav': !fav,
                        }, SetOptions(merge: true)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$name، $country',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                      Text(
                        isFa
                            ? '${_money(price * _nights)} ت'
                            : '${_money(price * _nights)} T',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isFa
                        ? 'تقریبی ${_faNum(_nights)} شب • هر شب ${_money(price)} تومان'
                        : 'About $_nights nights • ${_money(price)}/night',
                    style: TextStyle(color: textSoft, fontSize: 10.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      ...((d['styles'] as List? ?? [])
                          .map((e) => _tag(_labelOf(_styles, e.toString())))),
                      ...((d['seasons'] as List? ?? [])
                          .map((e) => _tag(_labelOf(_seasons, e.toString())))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: AppTok.accentSoft(context).withValues(alpha: 0.35),
      child: Center(
        child: Icon(
          Icons.beach_access_outlined,
          size: 46,
          color: AppTok.accentDeep(context),
        ),
      ),
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTok.accent(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTok.accentDeep(context),
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _labelOf(List<_Option> opts, String id) {
    for (final o in opts) {
      if (o.id == id) return AppLang.I.isFa ? o.fa : o.en;
    }
    return id;
  }

  Widget _finalBanner(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final isFa = AppLang.I.isFa;
    final name = (isFa ? d['nameFa'] ?? d['nameEn'] : d['nameEn'] ?? d['nameFa'])
        .toString();
    final accent = AppTok.accent(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.22),
            accent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.celebration_outlined, color: accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isFa
                  ? 'مقصد نهایی ماه عسل: $name 🎉'
                  : 'Final honeymoon destination: $name 🎉',
              style: TextStyle(
                color: AppTok.text(context),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── عملیات ───────────────────────────

  Future<void> _setFinal(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    bool on,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    if (on) {
      final all = await _dests.get();
      for (final x in all.docs) {
        if (x.data()['finalPick'] == true) {
          batch.update(x.reference, {'finalPick': false});
        }
      }
    }
    batch.set(doc.reference, {'finalPick': on}, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> _openDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final d = doc.data();
    final isFa = AppLang.I.isFa;
    final name = (isFa ? d['nameFa'] ?? d['nameEn'] : d['nameEn'] ?? d['nameFa'])
        .toString();
    final country = (isFa
            ? d['countryFa'] ?? d['countryEn']
            : d['countryEn'] ?? d['countryFa'])
        .toString();
    final price = d['price'] is num ? d['price'] as num : 0;
    final img = (d['imageUrl'] ?? '').toString();
    final source = (d['source'] ?? 'catalog').toString();
    final vendorName = (d['vendorName'] ?? '').toString();
    final vendorPhone = (d['vendorPhone'] ?? '').toString();
    final status = (d['status'] ?? 'none').toString();
    final pros = (d['prosFa'] as List? ?? []).map((e) => e.toString()).toList();
    final cons = (d['consFa'] as List? ?? []).map((e) => e.toString()).toList();
    final note = (d['note'] ?? '').toString();

    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTok.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: AppLang.I.direction,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            14,
            18,
            MediaQuery.of(ctx).viewInsets.bottom + 18,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTok.border(ctx),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (img.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      img,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  '$name، $country',
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isFa
                      ? 'برآورد ${_faNum(_nights)} شب: ${_money(price * _nights)} تومان'
                      : 'Estimate for $_nights nights: ${_money(price * _nights)} Toman',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                if (pros.isNotEmpty) ...[
                  Text(
                    isFa ? 'چرا بریم؟' : 'Why go?',
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...pros.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.add_circle_outline,
                                size: 14, color: Color(0xFF3E9B4F)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                p,
                                style: TextStyle(
                                  color: textSoft,
                                  fontSize: 12,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 10),
                ],
                if (cons.isNotEmpty) ...[
                  Text(
                    isFa ? 'چرا نه؟' : 'Why not?',
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...cons.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.remove_circle_outline,
                                size: 14, color: Color(0xFFD07C1F)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                p,
                                style: TextStyle(
                                  color: textSoft,
                                  fontSize: 12,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 10),
                ],
                if (note.isNotEmpty)
                  Text(
                    note,
                    style: TextStyle(
                      color: textSoft,
                      fontSize: 12,
                      height: 1.7,
                    ),
                  ),
                if (source == 'vendor' && vendorName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTok.cardSoft(ctx),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFa
                              ? 'ارائه‌دهنده: $vendorName'
                              : 'Provider: $vendorName',
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        if (vendorPhone.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.phone_outlined,
                                  size: 15, color: accent),
                              const SizedBox(width: 6),
                              Text(
                                vendorPhone,
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () async {
                                  await launchUrl(
                                    Uri.parse('tel:$vendorPhone'),
                                  );
                                },
                                child: Text(
                                  isFa ? 'تماس' : 'Call',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                if (source == 'vendor')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _dests.doc(doc.id).set({
                        'status': status == 'requested' ? 'none' : 'requested',
                        'requestedAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                    },
                    icon: Icon(
                      status == 'requested'
                          ? Icons.cancel_outlined
                          : Icons.event_available_outlined,
                      size: 18,
                    ),
                    label: Text(
                      status == 'requested'
                          ? (isFa ? 'لغو درخواست رزرو' : 'Cancel request')
                          : (isFa ? 'انتخاب و درخواست رزرو' : 'Select & request'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openEditor(doc, null);
                        },
                        child: Text(isFa ? 'ویرایش' : 'Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTok.danger(ctx),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _dests.doc(doc.id).delete();
                        },
                        child: Text(isFa ? 'حذف' : 'Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── افزودن/ویرایش ───────────────────────────

  Future<void> _openEditor(
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
    String? sourceDefault,
  ) async {
    final isFa = AppLang.I.isFa;
    final existing = doc?.data();
    final nameC =
        TextEditingController(text: (existing?['nameFa'] ?? '').toString());
    final countryC =
        TextEditingController(text: (existing?['countryFa'] ?? '').toString());
    final priceC = TextEditingController(
      text: existing?['price'] is num ? '${existing!['price']}' : '',
    );
    final phoneC =
        TextEditingController(text: (existing?['vendorPhone'] ?? '').toString());
    final vendorC =
        TextEditingController(text: (existing?['vendorName'] ?? '').toString());
    final noteC = TextEditingController(text: (existing?['note'] ?? '').toString());
    final prosC = TextEditingController(
      text: ((existing?['prosFa'] as List? ?? [])).join('\n'),
    );
    final consC = TextEditingController(
      text: ((existing?['consFa'] as List? ?? [])).join('\n'),
    );

    var source = existing?['source']?.toString() ?? sourceDefault ?? 'custom';
    var region = existing?['region']?.toString() ?? 'iran';
    String? imageUrl = existing?['imageUrl']?.toString();
    if (imageUrl == '') imageUrl = null;
    final styles = Set<String>.from(
        (existing?['styles'] as List? ?? []).map((e) => e.toString()));
    final seasons = Set<String>.from(
        (existing?['seasons'] as List? ?? []).map((e) => e.toString()));
    final climates = Set<String>.from(
        (existing?['climates'] as List? ?? []).map((e) => e.toString()));
    var uploading = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTok.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: AppLang.I.direction,
        child: StatefulBuilder(
          builder: (sheetCtx, setSheet) => Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              14,
              18,
              MediaQuery.of(sheetCtx).viewInsets.bottom + 18,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    source == 'vendor'
                        ? (isFa
                            ? 'پیشنهاد هتل / مکان تفریحی'
                            : 'Hotel / venue offer')
                        : (isFa ? 'مکان انتخابی خودمان' : 'Our own place'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTok.text(sheetCtx),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          selected: source == 'custom',
                          onSelected: (_) =>
                              setSheet(() => source = 'custom'),
                          label: Text(isFa ? 'شخصی' : 'Personal'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          selected: source == 'vendor',
                          onSelected: (_) =>
                              setSheet(() => source = 'vendor'),
                          label: Text(isFa ? 'هتل/تفریح' : 'Hotel/venue'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameC,
                    style: TextStyle(color: AppTok.text(sheetCtx)),
                    decoration: InputDecoration(
                      labelText: isFa ? 'نام مقصد' : 'Destination name',
                      filled: true,
                      fillColor: AppTok.cardSoft(sheetCtx),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: countryC,
                          style: TextStyle(color: AppTok.text(sheetCtx)),
                          decoration: InputDecoration(
                            labelText: isFa ? 'کشور' : 'Country',
                            filled: true,
                            fillColor: AppTok.cardSoft(sheetCtx),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: priceC,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(color: AppTok.text(sheetCtx)),
                          decoration: InputDecoration(
                            labelText:
                                isFa ? 'هر شب (تومان)' : 'Per night (Toman)',
                            filled: true,
                            fillColor: AppTok.cardSoft(sheetCtx),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: uploading
                              ? null
                              : () async {
                                  final picker = ImagePicker();
                                  final img = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 85,
                                    maxWidth: 1600,
                                  );
                                  if (img == null) return;
                                  final raw = await img.readAsBytes();
                                  if (!sheetCtx.mounted) return;
                                  final cropped = await ImageCropScreen.crop(
                                    sheetCtx,
                                    bytes: Uint8List.fromList(raw),
                                    initialAspectRatio: 16 / 9,
                                    title: AppLang.tr('crop_image'),
                                  );
                                  if (cropped == null ||
                                      !sheetCtx.mounted) {
                                    return;
                                  }
                                  setSheet(() => uploading = true);
                                  try {
                                    final res = await MediaUploadService
                                        .uploadImageBytes(
                                      bytes: cropped,
                                      fileName:
                                          'honeymoon_${DateTime.now().millisecondsSinceEpoch}.jpg',
                                    );
                                    setSheet(() => imageUrl = res.url);
                                  } catch (_) {}
                                  if (sheetCtx.mounted) {
                                    setSheet(() => uploading = false);
                                  }
                                },
                          icon: uploading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.photo_outlined, size: 16),
                          label: Text(
                            imageUrl != null
                                ? (isFa ? 'تغییر عکس' : 'Change photo')
                                : (isFa ? 'افزودن عکس' : 'Add photo'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      if (imageUrl != null) ...[
                        const SizedBox(width: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageUrl!,
                            width: 56,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  _editChips(sheetCtx, _styles, styles, setSheet),
                  const SizedBox(height: 8),
                  _editChips(sheetCtx, _seasons, seasons, setSheet),
                  const SizedBox(height: 8),
                  _editChips(sheetCtx, _climates, climates, setSheet),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _regions.map((r) {
                      final on = region == r.id;
                      return ChoiceChip(
                        selected: on,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => setSheet(() => region = r.id),
                        label: Text(
                          isFa ? r.fa : r.en,
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  if (source == 'vendor') ...[
                    TextField(
                      controller: vendorC,
                      style: TextStyle(color: AppTok.text(sheetCtx)),
                      decoration: InputDecoration(
                        labelText: isFa ? 'نام هتل/مجموعه' : 'Hotel/venue name',
                        filled: true,
                        fillColor: AppTok.cardSoft(sheetCtx),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneC,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: AppTok.text(sheetCtx)),
                      decoration: InputDecoration(
                        labelText: isFa ? 'شماره تماس' : 'Phone',
                        filled: true,
                        fillColor: AppTok.cardSoft(sheetCtx),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: prosC,
                    maxLines: 3,
                    style: TextStyle(color: AppTok.text(sheetCtx)),
                    decoration: InputDecoration(
                      labelText:
                          isFa ? 'مزایا (هر خط یک مورد)' : 'Pros (one per line)',
                      filled: true,
                      fillColor: AppTok.cardSoft(sheetCtx),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: consC,
                    maxLines: 2,
                    style: TextStyle(color: AppTok.text(sheetCtx)),
                    decoration: InputDecoration(
                      labelText:
                          isFa ? 'معایب (هر خط یک مورد)' : 'Cons (one per line)',
                      filled: true,
                      fillColor: AppTok.cardSoft(sheetCtx),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteC,
                    maxLines: 2,
                    style: TextStyle(color: AppTok.text(sheetCtx)),
                    decoration: InputDecoration(
                      labelText: isFa ? 'یادداشت' : 'Note',
                      filled: true,
                      fillColor: AppTok.cardSoft(sheetCtx),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTok.accent(sheetCtx),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      final nm = nameC.text.trim();
                      if (nm.isEmpty) return;
                      Navigator.pop(sheetCtx);
                      await _dests.doc(doc?.id).set({
                        'nameFa': nm,
                        'nameEn': nm,
                        'countryFa': countryC.text.trim(),
                        'countryEn': countryC.text.trim(),
                        'price': int.tryParse(priceC.text) ?? 0,
                        'region': region,
                        'styles': styles.toList(),
                        'seasons': seasons.toList(),
                        'climates': climates.toList(),
                        'prosFa': prosC.text
                            .split('\n')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList(),
                        'consFa': consC.text
                            .split('\n')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList(),
                        'note': noteC.text.trim(),
                        'source': source,
                        'vendorName': vendorC.text.trim(),
                        'vendorPhone': phoneC.text.trim(),
                        if (imageUrl != null) 'imageUrl': imageUrl,
                        'updatedAt': FieldValue.serverTimestamp(),
                        if (doc == null) ...{
                          'fav': false,
                          'finalPick': false,
                          'status': 'none',
                          'createdAt': FieldValue.serverTimestamp(),
                        },
                      }, SetOptions(merge: true));
                    },
                    child: Text(
                      isFa ? 'ذخیره' : 'Save',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    nameC.dispose();
    countryC.dispose();
    priceC.dispose();
    phoneC.dispose();
    vendorC.dispose();
    noteC.dispose();
    prosC.dispose();
    consC.dispose();
  }

  Widget _editChips(
    BuildContext sheetCtx,
    List<_Option> opts,
    Set<String> sel,
    void Function(void Function()) setSheet,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: opts.map((o) {
        final on = sel.contains(o.id);
        return FilterChip(
          selected: on,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          onSelected: (v) => setSheet(() {
            if (v) {
              sel.add(o.id);
            } else {
              sel.remove(o.id);
            }
          }),
          label: Text(
            AppLang.I.isFa ? o.fa : o.en,
            style: const TextStyle(fontSize: 11),
          ),
          avatar: Icon(o.icon, size: 13),
        );
      }).toList(),
    );
  }
}
