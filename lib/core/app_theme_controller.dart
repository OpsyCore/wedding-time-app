import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._();
  static final AppThemeController I = AppThemeController._();

  static const _key = 'theme_mode';

  bool _isDark = false;
  bool _loaded = false;

  bool get isLoaded => _loaded;
  bool get isDark => _isDark;
  bool get isLight => !_isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = (prefs.getString(_key) ?? 'light').toLowerCase().trim();
      _isDark = raw == 'dark';
    } catch (_) {
      _isDark = false;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setDark(bool dark) async {
    if (_isDark == dark && _loaded) {
      notifyListeners();
      return;
    }
    _isDark = dark;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, _isDark ? 'dark' : 'light');
    } catch (_) {}
  }

  Future<void> toggle() => setDark(!_isDark);
}