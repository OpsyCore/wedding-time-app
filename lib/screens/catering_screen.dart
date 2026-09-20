import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_effects.dart';
import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';

/// برنامه‌ریز پذیرایی: شام، نوشیدنی، دسر + حساب‌کتاب کامل هزینه‌ها.
/// ذخیره در: weddings/{weddingId}/catering/{prefs | items}
class CateringScreen extends StatefulWidget {
  const CateringScreen({super.key, required this.weddingId});

  final String weddingId;

  @override
  State<CateringScreen> createState() => _CateringScreenState();
}

const _catFood = 'food';
const _catDrink = 'drink';
const _catDessert = 'dessert';
const _catFruit = 'fruit';
const _catSnack = 'snack';
const _catAlcohol = 'alcohol';

class _Preset {
  const _Preset(this.name, this.cat, this.price,
      {this.pp = true, this.qty = 0});
  final String name;
  final String cat;
  final int price;
  final bool pp;
  final int qty;
}

const _presets = <_Preset>[
  // ── شام و غذا (۱۰)
  _Preset('چلوکباب کوبیده', _catFood, 1900000),
  _Preset('چلوکباب برگ', _catFood, 2600000),
  _Preset('چلوجوجه کباب', _catFood, 1600000),
  _Preset('زرشک‌پلو با مرغ', _catFood, 1400000),
  _Preset('قورمه‌سبزی با برنج', _catFood, 1300000),
  _Preset('خورشت قیمه', _catFood, 1200000),
  _Preset('باقالی‌پلو با ماهیچه', _catFood, 3200000),
  _Preset('ماهی کبابی با سبزی‌پلو', _catFood, 2100000),
  _Preset('سالاد فصل', _catFood, 350000),
  _Preset('ماست موسیر', _catFood, 250000),
  // ── نوشیدنی (۱۰)
  _Preset('نوشابه', _catDrink, 90000),
  _Preset('آب معدنی', _catDrink, 40000),
  _Preset('دوغ', _catDrink, 60000),
  _Preset('آبمیوه طبیعی', _catDrink, 120000),
  _Preset('چای و قهوه', _catDrink, 150000),
  _Preset('موهیتو و شربت', _catDrink, 110000),
  _Preset('لیموناد', _catDrink, 100000),
  _Preset('اسموتی', _catDrink, 140000),
  _Preset('کاپوچینو و اسپرسو', _catDrink, 180000),
  _Preset('دمنوش گیاهی', _catDrink, 90000),
  // ── دسر و شیرینی (۱۰)
  _Preset('شیرینی دانمارکی', _catDessert, 400000),
  _Preset('باقلوا', _catDessert, 450000),
  _Preset('بستنی سنتی', _catDessert, 180000),
  _Preset('کیک و کاپ‌کیک', _catDessert, 250000),
  _Preset('دسر شکلاتی', _catDessert, 220000),
  _Preset('شیرینی خامه‌ای', _catDessert, 320000),
  _Preset('شکلات و دراژه', _catDessert, 200000),
  _Preset('ژله و شیر خامه', _catDessert, 150000),
  _Preset('زولبیا بامیه', _catDessert, 120000),
  _Preset('فرنی و شله‌زرد', _catDessert, 100000),
  // ── میوه (۱۰)
  _Preset('موز', _catFruit, 300000),
  _Preset('سیب', _catFruit, 250000),
  _Preset('پرتقال', _catFruit, 280000),
  _Preset('انگور', _catFruit, 350000),
  _Preset('هندوانه', _catFruit, 200000),
  _Preset('خربزه', _catFruit, 220000),
  _Preset('کیوی', _catFruit, 320000),
  _Preset('انار', _catFruit, 400000),
  _Preset('توت‌فرنگی', _catFruit, 500000),
  _Preset('سبد میوه فصل', _catFruit, 350000),
  // ── خوراکی و تنقلات (۱۰)
  _Preset('آجیل مخلوط', _catSnack, 800000),
  _Preset('چیپس و پفک', _catSnack, 100000),
  _Preset('تخمه آفتابگردان', _catSnack, 180000),
  _Preset('ساندویچ سرد', _catSnack, 250000),
  _Preset('فلافل', _catSnack, 120000),
  _Preset('سمبوسه', _catSnack, 140000),
  _Preset('کوکی و بیسکویت', _catSnack, 160000),
  _Preset('خرما', _catSnack, 200000),
  _Preset('گز و سوهان', _catSnack, 350000),
  _Preset('پاپ‌کورن', _catSnack, 90000),
  // ── نوشیدنی الکلی (۱۰) — برای مهمان‌هایی که مشروب می‌نوشند
  _Preset('آبجو', _catAlcohol, 200000, pp: false),
  _Preset('شراب قرمز', _catAlcohol, 800000, pp: false),
  _Preset('شراب سفید', _catAlcohol, 750000, pp: false),
  _Preset('ویسکی', _catAlcohol, 2500000, pp: false),
  _Preset('ودکا', _catAlcohol, 1800000, pp: false),
  _Preset('جین', _catAlcohol, 2000000, pp: false),
  _Preset('رم', _catAlcohol, 2200000, pp: false),
  _Preset('تکیلا', _catAlcohol, 2800000, pp: false),
  _Preset('کوکتل الکلی', _catAlcohol, 350000, pp: false),
  _Preset('لیکور', _catAlcohol, 1500000, pp: false),
];

class _CateringScreenState extends State<CateringScreen> {
  int _guests = 0;
  bool _guestsLoaded = false;
  int _extraPct = 0;
  final _extraC = TextEditingController();
  String _filter = 'all';

  CollectionReference<Map<String, dynamic>> get _items => FirebaseFirestore
      .instance
      .collection('weddings')
      .doc(widget.weddingId)
      .collection('cateringItems');

  DocumentReference<Map<String, dynamic>> get _prefs => FirebaseFirestore
      .instance
      .collection('weddings')
      .doc(widget.weddingId)
      .collection('catering')
      .doc('prefs');

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _extraC.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    try {
      final s = await _prefs.get();
      final d = s.data() ?? {};
      _extraPct = d['extraPct'] is int ? d['extraPct'] as int : 0;
      _extraC.text = _extraPct == 0 ? '' : '$_extraPct';
      var g = d['guestCount'] is int ? d['guestCount'] as int : 0;
      if (g == 0) {
        final guests = await FirebaseFirestore.instance
            .collection('weddings')
            .doc(widget.weddingId)
            .collection('guests')
            .get();
        final confirmed = guests.docs
            .where((x) => x.data()['status'] == 'confirmed')
            .length;
        g = confirmed > 0 ? confirmed : guests.docs.length;
      }
      _guests = g;
    } catch (_) {}
    if (mounted) setState(() => _guestsLoaded = true);
  }

  Future<void> _savePrefs() async {
    await _prefs.set({
      'guestCount': _guests,
      'extraPct': _extraPct,
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

  String _money(num v) => _faNum(v.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      ));

  String _catLabel(String cat) {
    final isFa = AppLang.I.isFa;
    switch (cat) {
      case _catFood:
        return isFa ? 'شام و غذا' : 'Food';
      case _catDrink:
        return isFa ? 'نوشیدنی' : 'Drinks';
      case _catDessert:
        return isFa ? 'دسر و شیرینی' : 'Dessert';
      case _catFruit:
        return isFa ? 'میوه' : 'Fruit';
      case _catSnack:
        return isFa ? 'خوراکی و تنقلات' : 'Snacks';
      default:
        return isFa ? 'نوشیدنی الکلی' : 'Alcoholic';
    }
  }

  Color _catColor(String cat) {
    switch (cat) {
      case _catFood:
        return const Color(0xFFD1A36B);
      case _catDrink:
        return const Color(0xFF6F9BB5);
      case _catDessert:
        return const Color(0xFFE58FA2);
      case _catFruit:
        return const Color(0xFF7FA871);
      case _catSnack:
        return const Color(0xFFB08968);
      default:
        return const Color(0xFF9B7FB8);
    }
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case _catDrink:
        return Icons.local_drink_outlined;
      case _catDessert:
        return Icons.cake_outlined;
      case _catFruit:
        return Icons.eco_outlined;
      case _catSnack:
        return Icons.fastfood_outlined;
      case _catAlcohol:
        return Icons.local_bar_outlined;
      default:
        return Icons.dinner_dining_outlined;
    }
  }

  int _itemTotal(Map<String, dynamic> d) {
    final price = d['price'] is num ? d['price'] as num : 0;
    final perPerson = d['perPerson'] != false;
    final qty = d['qty'] is int ? d['qty'] as int : 0;
    return (price * (perPerson ? _guests : qty)).round();
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
                isFa ? 'شام و نوشیدنی' : 'Catering',
                style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              iconTheme: IconThemeData(color: text),
            ),
            body: !_guestsLoaded
                ? Center(child: CircularProgressIndicator(color: accent))
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _items.snapshots(),
                    builder: (context, snap) {
                      final docs = (snap.data?.docs ?? []).toList();
                      final visible = docs
                          .where((d) =>
                              _filter == 'all' ||
                              (d.data()['cat'] ?? _catFood).toString() ==
                                  _filter)
                          .toList();

                      final sums = <String, int>{
                        _catFood: 0,
                        _catDrink: 0,
                        _catDessert: 0,
                        _catFruit: 0,
                        _catSnack: 0,
                        _catAlcohol: 0,
                      };
                      final counts = <String, int>{
                        _catFood: 0,
                        _catDrink: 0,
                        _catDessert: 0,
                        _catFruit: 0,
                        _catSnack: 0,
                        _catAlcohol: 0,
                      };
                      for (final d in docs) {
                        final t = _itemTotal(d.data());
                        var cat = (d.data()['cat'] ?? _catFood).toString();
                        if (!sums.containsKey(cat)) cat = _catFood;
                        sums[cat] = sums[cat]! + t;
                        counts[cat] = counts[cat]! + 1;
                      }
                      final sub = sums.values.fold(0, (a, b) => a + b);
                      final extra = (sub * _extraPct / 100).round();
                      final grand = sub + extra;
                      final perPerson =
                          _guests > 0 ? (grand / _guests).round() : 0;

                      return ListView(
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        children: [
                          _summaryCard(
                            sums: sums,
                            counts: counts,
                            sub: sub,
                            extra: extra,
                            grand: grand,
                            perPerson: perPerson,
                          ),
                          const SizedBox(height: 14),
                          _filterRow(),
                          const SizedBox(height: 10),
                          ...visible.map(_itemCard),
                          if (visible.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                isFa
                                    ? 'هنوز آیتمی نیست — از «افزودن سریع» یا دکمهٔ + استفاده کن.'
                                    : 'No items yet — use quick-add or the + button.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTok.textSoft(context),
                                  fontSize: 12.5,
                                  height: 1.7,
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),
                          _quickAdd(),
                        ],
                      );
                    },
                  ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              onPressed: () => _openEditor(null),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                isFa ? 'آیتم سفارشی' : 'Custom item',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────── کارت خلاصهٔ حساب ───────────────────────────

  Widget _summaryCard({
    required Map<String, int> sums,
    required Map<String, int> counts,
    required int sub,
    required int extra,
    required int grand,
    required int perPerson,
  }) {
    final isFa = AppLang.I.isFa;
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    final accent = AppTok.accent(context);

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
              Icon(Icons.restaurant_menu_outlined, color: accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFa ? 'حساب‌کتاب پذیرایی' : 'Catering calculator',
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
                  isFa ? 'مهمان‌های احتمالی' : 'Expected guests',
                  style: TextStyle(color: textSoft, fontSize: 12),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: () => setState(() {
                  if (_guests > 0) _guests--;
                  _savePrefs();
                }),
              ),
              Text(
                _faNum(_guests),
                style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () => setState(() {
                  _guests++;
                  _savePrefs();
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _extraC,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {
              _extraPct = int.tryParse(v) ?? 0;
              _savePrefs();
            },
            style: TextStyle(color: text, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppTok.cardSoft(context),
              labelText: isFa
                  ? '٪ خدمات و متفرقه (اختیاری)'
                  : 'Service & misc % (optional)',
              labelStyle: TextStyle(color: textSoft, fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final c in [
            _catFood,
            _catDrink,
            _catDessert,
            _catFruit,
            _catSnack,
            _catAlcohol,
          ])
            if ((counts[c] ?? 0) > 0)
              _sumRow(
                _catLabel(c),
                sums[c] ?? 0,
                _catColor(c),
                count: counts[c] ?? 0,
                share: sub > 0 ? ((sums[c] ?? 0) * 100 ~/ sub) : 0,
              ),
          if (extra > 0)
            _sumRow(isFa ? 'خدمات و متفرقه' : 'Service & misc', extra,
                const Color(0xFF9AA0A6)),
          Divider(color: AppTok.border(context)),
          Row(
            children: [
              Text(
                isFa ? 'جمع کل' : 'Grand total',
                style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
              const Spacer(),
              Text(
                isFa
                    ? '${_money(grand)} تومان'
                    : '${_money(grand)} Toman',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                isFa ? 'سر هر نفر' : 'Per person',
                style: TextStyle(color: textSoft, fontSize: 11.5),
              ),
              const Spacer(),
              Text(
                isFa
                    ? '≈ ${_money(perPerson)} تومان'
                    : '≈ ${_money(perPerson)} Toman',
                style: TextStyle(
                  color: textSoft,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sumRow(String label, int value, Color color,
      {int count = 0, int share = 0}) {
    final isFa = AppLang.I.isFa;
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              count > 0
                  ? '$label (${isFa ? _faNum(count) : count} ${isFa ? 'آیتم' : 'items'})'
                  : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textSoft, fontSize: 12),
            ),
          ),
          if (share > 0) ...[
            Text(
              isFa ? '${_faNum(share)}٪' : '$share%',
              style: TextStyle(color: textSoft, fontSize: 10.5),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            _money(value),
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── فیلتر ───────────────────────────

  Widget _filterRow() {
    final isFa = AppLang.I.isFa;
    final opts = [
      ('all', isFa ? 'همه' : 'All'),
      (_catFood, _catLabel(_catFood)),
      (_catDrink, _catLabel(_catDrink)),
      (_catDessert, _catLabel(_catDessert)),
      (_catFruit, _catLabel(_catFruit)),
      (_catSnack, _catLabel(_catSnack)),
      (_catAlcohol, _catLabel(_catAlcohol)),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: opts.map((o) {
        final on = _filter == o.$1;
        return ChoiceChip(
          selected: on,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          selectedColor: AppTok.accent(context).withValues(alpha: 0.18),
          onSelected: (_) => setState(() => _filter = o.$1),
          label: Text(
            o.$2,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: on
                  ? AppTok.accent(context)
                  : AppTok.textSoft(context),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────── کارت آیتم ───────────────────────────

  Widget _itemCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final isFa = AppLang.I.isFa;
    final name = (d['name'] ?? '').toString();
    final cat = (d['cat'] ?? _catFood).toString();
    final price = d['price'] is num ? d['price'] as num : 0;
    final perPerson = d['perPerson'] != false;
    final qty = d['qty'] is int ? d['qty'] as int : 0;
    final total = _itemTotal(d);
    final color = _catColor(cat);
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTok.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openEditor(doc),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_catIcon(cat), color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isFa
                        ? '${_catLabel(cat)} • ${_money(price)} ت/${perPerson ? 'هر نفر' : 'واحد'}'
                        : '${_catLabel(cat)} • ${_money(price)}/${perPerson ? 'person' : 'unit'}',
                    style: TextStyle(color: textSoft, fontSize: 10.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isFa
                        ? 'تعداد: ${_faNum(perPerson ? _guests : qty)}'
                        : 'Qty: ${perPerson ? _guests : qty}',
                    style: TextStyle(color: textSoft, fontSize: 10.5),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _money(total),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isFa ? 'تومان' : 'Toman',
                  style: TextStyle(color: textSoft, fontSize: 9.5),
                ),
              ],
            ),
            IconButton(
              tooltip: isFa ? 'حذف' : 'Delete',
              icon: Icon(Icons.delete_outline,
                  size: 18, color: AppTok.danger(context)),
              onPressed: () => _items.doc(doc.id).delete(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── افزودن سریع ───────────────────────────

  Widget _quickAdd() {
    final isFa = AppLang.I.isFa;
    final text = AppTok.text(context);
    final textSoft = AppTok.textSoft(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isFa ? 'افزودن سریع — غذا، نوشیدنی، دسر، میوه، تنقلات' : 'Quick add — food, drinks, dessert, fruit, snacks',
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _presets.map((p) {
            return ActionChip(
              avatar: Icon(
                _catIcon(p.cat),
                size: 14,
                color: _catColor(p.cat),
              ),
              onPressed: () async {
                await _items.add({
                  'name': p.name,
                  'cat': p.cat,
                  'price': p.price,
                  'perPerson': p.pp,
                  'qty': p.qty,
                  'note': '',
                  'createdAt': FieldValue.serverTimestamp(),
                });
              },
              label: Text(
                p.name,
                style: TextStyle(fontSize: 11, color: textSoft),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─────────────────────────── ویرایشور ───────────────────────────

  Future<void> _openEditor(
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  ) async {
    final isFa = AppLang.I.isFa;
    final existing = doc?.data();
    final nameC =
        TextEditingController(text: (existing?['name'] ?? '').toString());
    final priceC = TextEditingController(
      text: existing?['price'] is num ? '${existing!['price']}' : '',
    );
    final qtyC = TextEditingController(
      text: existing?['qty'] is int && (existing!['qty'] as int) > 0
          ? '${existing['qty']}'
          : '',
    );
    final noteC = TextEditingController(text: (existing?['note'] ?? '').toString());
    var cat = existing?['cat']?.toString() ?? _catFood;
    var perPerson = existing?['perPerson'] != false;

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
              MediaQuery.of(sheetCtx).viewInsets.bottom + MediaQuery.of(sheetCtx).padding.bottom + 18,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    doc == null
                        ? (isFa ? 'آیتم پذیرایی جدید' : 'New catering item')
                        : (isFa ? 'ویرایش آیتم' : 'Edit item'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTok.text(sheetCtx),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final c in [
                        _catFood,
                        _catDrink,
                        _catDessert,
                        _catFruit,
                        _catSnack,
                        _catAlcohol,
                      ])
                        ChoiceChip(
                          selected: cat == c,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          selectedColor: AppTok.accent(sheetCtx)
                              .withValues(alpha: 0.18),
                          onSelected: (_) => setSheet(() => cat = c),
                          label: Text(
                            _catLabel(c),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  if (cat == _catAlcohol)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        isFa
                            ? 'برای مهمان‌هایی که مشروب می‌نوشند — تعداد دستی است.'
                            : 'For guests who drink — quantity is manual.',
                        style: TextStyle(
                          color: AppTok.textSoft(sheetCtx),
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameC,
                    style: TextStyle(color: AppTok.text(sheetCtx)),
                    decoration: InputDecoration(
                      labelText: isFa ? 'نام آیتم' : 'Item name',
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
                    controller: priceC,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: TextStyle(color: AppTok.text(sheetCtx)),
                    decoration: InputDecoration(
                      labelText:
                          isFa ? 'قیمت واحد (تومان)' : 'Unit price (Toman)',
                      filled: true,
                      fillColor: AppTok.cardSoft(sheetCtx),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: perPerson,
                    title: Text(
                      isFa ? 'به ازای هر مهمان' : 'Per guest',
                      style: TextStyle(
                        color: AppTok.text(sheetCtx),
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      isFa
                          ? 'خاموش = تعداد دستی (مثلاً بر اساس میز/واحد)'
                          : 'Off = manual quantity (e.g. per table/unit)',
                      style: TextStyle(
                        color: AppTok.textSoft(sheetCtx),
                        fontSize: 11,
                      ),
                    ),
                    onChanged: (v) => setSheet(() => perPerson = v),
                  ),
                  if (!perPerson)
                    TextField(
                      controller: qtyC,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: TextStyle(color: AppTok.text(sheetCtx)),
                      decoration: InputDecoration(
                        labelText: isFa ? 'تعداد' : 'Quantity',
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
                      try {
                        await _items.doc(doc?.id).set({
                          'name': nm,
                          'cat': cat,
                          'price': int.tryParse(priceC.text) ?? 0,
                          'perPerson': perPerson,
                          'qty': int.tryParse(qtyC.text) ?? 0,
                          'note': noteC.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                          if (doc == null)
                            'createdAt': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));
                      } catch (e) {
                        if (mounted) {
                          showAppSnack(
                            context,
                            '${AppLang.tr('save_error')}: $e',
                            error: true,
                          );
                        }
                        return;
                      }
                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
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
    // صبر تا پایان انیمیشن بستن شیت، بعد dispose —
    // جلوگیری از assert «_dependents.isEmpty» فریم‌ورک
    await Future<void>.delayed(const Duration(milliseconds: 400));
    nameC.dispose();
    priceC.dispose();
    qtyC.dispose();
    noteC.dispose();
  }
}
