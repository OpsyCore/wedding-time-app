import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_effect.dart';

class AppEffectController extends ChangeNotifier {
  AppEffectController._();
  static final AppEffectController I = AppEffectController._();

  static const _prefKey = 'app_effect_id';

  String _effectId = AppEffect.none;
  bool _loaded = false;

  String get effectId => _effectId;
  bool get isLoaded => _loaded;
  bool get isNone => _effectId == AppEffect.none;
  AppEffect get effect => AppEffect.byId(_effectId);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      _effectId = AppEffect.normalizeId(raw);
    } catch (_) {
      _effectId = AppEffect.none;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setEffect(String id) async {
    final norm = AppEffect.normalizeId(id);
    if (_effectId == norm && _loaded) {
      notifyListeners();
      return;
    }
    _effectId = norm;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, norm);
    } catch (_) {}
  }

  Future<void> clear() => setEffect(AppEffect.none);
}
