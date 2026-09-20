import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _Preset {
  const _Preset(this.name, this.cat, this.price);
  final String name;
  final String cat;
  final int price;
}

const _presets = <_Preset>[
  _Preset('چلوکباب کوبیده', _catFood, 1900000),
  _Preset('چلوکباب برگ', _catFood, 2600000),
  _Preset('چلوجوجه', _catFood, 1600000),
  _Preset('خورشت قیمه', _catFood, 1200000),
  _Preset('سالاد فصل', _catFood, 350000),
  _Preset('ماست موسیر', _catFood, 250000),
  _Preset('نوشابه', _catDrink, 90000),
  _Preset('آبمیوه طبیعی', _catDrink, 120000),
  _Preset('دوغ', _catDrink, 60000),
  _Preset('آب معدنی', _catDrink, 40000),
  _Preset('چای و قهوه', _catDrink, 150000),
  _Preset('شیرینی', _catDessert, 400000),
  _Preset('بستنی', _catDessert, 180000),
  _Preset('میوه', _catDessert, 300000),
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
      default:
        return isFa ? 'دسر و شیرینی' : 'Dessert';
    }
  }

  Color _catColor(String cat) {
    switch (cat) {
      case _catFood:
        return const Color(0xFFD1A36B);
      case _catDrink:
        return const Color(0xFF6F9BB5);
      default:
        return const Color(0xFFE58FA2);
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

                      int foodSum = 0;
                      int drinkSum = 0;
                      int dessertSum = 0;
                      for (final d in docs) {
                        final t = _itemTotal(d.data());
                        switch ((d.data()['cat'] ?? _catFood).toString()) {
                          case _catDrink:
                            drinkSum += t;
                            break;
                          case _catDessert:
                            dessertSum += t;
                            break;
                          default:
                            foodSum += t;
                        }
                      }
                      final sub = foodSum + drinkSum + dessertSum;
                      final extra = (sub * _extraPct / 100).round();
                      final grand = sub + extra;
                      final perPerson =
                          _guests > 0 ? (grand / _guests).round() : 0;

                      return ListView(
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        children: [
                          _summaryCard(
                            foodSum: foodSum,
                            drinkSum: drinkSum,
                            dessertSum: dessertSum,
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
    required int foodSum,
    required int drinkSum,
    required int dessertSum,
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
          _sumRow(
              isFa ? 'شام و غذا' : 'Food', foodSum, const Color(0xFFD1A36B)),
          _sumRow(isFa ? 'نوشیدنی' : 'Drinks', drinkSum,
              const Color(0xFF6F9BB5)),
          _sumRow(isFa ? 'دسر و شیرینی' : 'Dessert', dessertSum,
              const Color(0xFFE58FA2)),
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

  Widget _sumRow(String label, int value, Color color) {
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
          Text(
            label,
            style: TextStyle(color: textSoft, fontSize: 12),
          ),
          const Spacer(),
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
              child: Icon(
                cat == _catDrink
                    ? Icons.local_drink_outlined
                    : cat == _catDessert
                        ? Icons.cake_outlined
                        : Icons.dinner_dining_outlined,
                color: color,
                size: 20,
              ),
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
          isFa ? 'افزودن سریع منوی معمول' : 'Quick add common menu',
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
                p.cat == _catDrink
                    ? Icons.local_drink_outlined
                    : p.cat == _catDessert
                        ? Icons.cake_outlined
                        : Icons.dinner_dining_outlined,
                size: 14,
                color: _catColor(p.cat),
              ),
              onPressed: () async {
                await _items.add({
                  'name': p.name,
                  'cat': p.cat,
                  'price': p.price,
                  'perPerson': true,
                  'qty': 0,
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
                  Row(
                    children: [
                      for (final c in [
                        _catFood,
                        _catDrink,
                        _catDessert
                      ]) ...[
                        Expanded(
                          child: ChoiceChip(
                            selected: cat == c,
                            onSelected: (_) => setSheet(() => cat = c),
                            label: Text(
                              _catLabel(c),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
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
                      Navigator.pop(sheetCtx);
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
    priceC.dispose();
    qtyC.dispose();
    noteC.dispose();
  }
}
