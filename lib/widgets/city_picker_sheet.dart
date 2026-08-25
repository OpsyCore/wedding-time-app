import 'package:flutter/material.dart';

import '../core/app_lang.dart';
import '../core/app_theme.dart';
import '../core/app_theme_controller.dart';
import '../data/iran_cities.dart';


/// نتیجهٔ انتخاب شهر — invitation_screen: picked.name / lat / lng
class CityPickResult {
  const CityPickResult({
    required this.name,
    required this.lat,
    required this.lng,
  });

  final String name;
  final double lat;
  final double lng;
}

class CityPickerSheet extends StatefulWidget {
  const CityPickerSheet({
    super.key,
    this.selectedCity,
    this.initialCity,
  });

  final String? selectedCity;
  final String? initialCity;

  /// API که invitation_screen صدا می‌زند
  static Future<CityPickResult?> show(
    BuildContext context, {
    String? selectedCity,
    String? initialCity,
    String? currentCity,
  }) {
    final selected = selectedCity ?? initialCity ?? currentCity;
    return showModalBottomSheet<CityPickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTok.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => CityPickerSheet(
        selectedCity: selected,
        initialCity: selected,
      ),
    );
  }

  @override
  State<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<CityPickerSheet> {
  final _searchCtrl = TextEditingController();
  late final List<CityPickResult> _all;
  late List<CityPickResult> _filtered;
  String? _selectedName;

  @override
  void initState() {
    super.initState();
    _selectedName = widget.selectedCity ?? widget.initialCity;
    _all = _loadCities();
    _filtered = List<CityPickResult>.from(_all);
    _searchCtrl.addListener(_onSearch);
  }

  /// IranCities را بدون حدس getter ثابت می‌خوانیم.
  /// اگر ساختار فرق دارد، فقط این متد را با فایل data خودت عوض کن.
  List<CityPickResult> _loadCities() {
    final out = <CityPickResult>[];

    // شکل ۱: IranCities.iranCities / allCities / data به‌صورت List
    final candidates = <dynamic>[
      _try(() => IranCities.all),
      _try(() => (IranCities as dynamic).cities),
      _try(() => (IranCities as dynamic).list),
      _try(() => (IranCities as dynamic).iranCities),
      _try(() => (IranCities as dynamic).allCities),
      _try(() => (IranCities as dynamic).data),
      _try(() => (IranCities as dynamic).items),
    ];

    for (final raw in candidates) {
      if (raw is! List || raw.isEmpty) continue;
      for (final item in raw) {
        final parsed = _parseItem(item);
        if (parsed != null) out.add(parsed);
      }
      if (out.isNotEmpty) break;
    }

    // شکل ۲: Map نام → مختصات
    if (out.isEmpty) {
      final mapLike = _try(() => (IranCities as dynamic).byName) ??
          _try(() => (IranCities as dynamic).coordinates);
      if (mapLike is Map) {
        mapLike.forEach((key, value) {
          final name = key.toString();
          if (value is Map) {
            final lat = (value['lat'] as num?)?.toDouble() ??
                (value['latitude'] as num?)?.toDouble() ??
                0;
            final lng = (value['lng'] as num?)?.toDouble() ??
                (value['lon'] as num?)?.toDouble() ??
                (value['longitude'] as num?)?.toDouble() ??
                0;
            out.add(CityPickResult(name: name, lat: lat, lng: lng));
          }
        });
      }
    }

    out.sort((a, b) => a.name.compareTo(b.name));
    return out;
  }

  dynamic _try(dynamic Function() f) {
    try {
      return f();
    } catch (_) {
      return null;
    }
  }

  CityPickResult? _parseItem(dynamic item) {
    if (item == null) return null;

    if (item is String) {
      return CityPickResult(name: item, lat: 0, lng: 0);
    }

    if (item is Map) {
      final name = (item['name'] ??
              item['city'] ??
              item['title'] ??
              item['fa'] ??
              item['label'] ??
              '')
          .toString()
          .trim();
      if (name.isEmpty) return null;
      final lat = (item['lat'] as num?)?.toDouble() ??
          (item['latitude'] as num?)?.toDouble() ??
          0;
      final lng = (item['lng'] as num?)?.toDouble() ??
          (item['lon'] as num?)?.toDouble() ??
          (item['longitude'] as num?)?.toDouble() ??
          0;
      return CityPickResult(name: name, lat: lat, lng: lng);
    }

    // آبجکت با فیلد
    try {
      final dyn = item as dynamic;
      final name = (dyn.name ?? dyn.city ?? dyn.title ?? '').toString().trim();
      if (name.isEmpty) return null;
      final lat = (dyn.lat as num?)?.toDouble() ??
          (dyn.latitude as num?)?.toDouble() ??
          0.0;
      final lng = (dyn.lng as num?)?.toDouble() ??
          (dyn.lon as num?)?.toDouble() ??
          (dyn.longitude as num?)?.toDouble() ??
          0.0;
      return CityPickResult(name: name, lat: lat, lng: lng);
    } catch (_) {
      return null;
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<CityPickResult>.from(_all);
      } else {
        _filtered = _all
            .where((c) => c.name.toLowerCase().contains(q))
            .toList(growable: false);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLang.I, AppThemeController.I]),
      builder: (context, _) {
        final card = AppTok.card(context);
        final bg = AppTok.background(context);
        final text = AppTok.text(context);
        final textSoft = AppTok.textSoft(context);
        final accent = AppTok.accent(context);
        final h = MediaQuery.sizeOf(context).height * 0.75;

        return Directionality(
          textDirection: AppLang.I.direction,
          child: SizedBox(
            height: h,
            child: Material(
              color: card,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textSoft.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _title(),
                            style: TextStyle(
                              color: text,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: textSoft),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchCtrl,
                      style: TextStyle(color: text),
                      decoration: InputDecoration(
                        hintText: _hint(),
                        hintStyle: TextStyle(color: textSoft),
                        prefixIcon: Icon(Icons.search, color: textSoft),
                        filled: true,
                        fillColor: bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _all.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                AppLang.I.isFa
                                    ? 'لیست شهرها لود نشد — lib/data/iran_cities.dart را چک کن'
                                    : 'City list failed to load — check iran_cities.dart',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: textSoft),
                              ),
                            ),
                          )
                        : _filtered.isEmpty
                            ? Center(
                                child: Text(
                                  _empty(),
                                  style: TextStyle(color: textSoft),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filtered.length,
                                itemBuilder: (context, i) {
                                  final city = _filtered[i];
                                  final selected =
                                      city.name == _selectedName;
                                  return ListTile(
                                    leading: Icon(
                                      Icons.location_city_outlined,
                                      color: selected ? accent : textSoft,
                                    ),
                                    title: Text(
                                      city.name,
                                      style: TextStyle(
                                        color: text,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    trailing: selected
                                        ? Icon(Icons.check, color: accent)
                                        : null,
                                    onTap: () =>
                                        Navigator.pop(context, city),
                                  );
                                },
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

  String _title() {
    final v = AppLang.tr('select_city');
    if (v.isEmpty || v == 'select_city') {
      return AppLang.I.isFa ? 'انتخاب شهر' : 'Select city';
    }
    return v;
  }

  String _hint() {
    final v = AppLang.tr('search_city');
    if (v.isEmpty || v == 'search_city') {
      return AppLang.I.isFa ? 'جستجوی شهر...' : 'Search city...';
    }
    return v;
  }

  String _empty() {
    final v = AppLang.tr('no_results');
    if (v.isEmpty || v == 'no_results') {
      return AppLang.I.isFa ? 'نتیجه‌ای نیست' : 'No results';
    }
    return v;
  }
}