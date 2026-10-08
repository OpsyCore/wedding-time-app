import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// کنترل فونت سراسری — مانند AppLang / AppThemeController
/// خانوادهٔ انتخاب‌شده در SharedPreferences و Firestore ذخیره می‌شود و
/// فوراً روی Theme اعمال می‌گردد.
class AppFontController extends ChangeNotifier {
  AppFontController._();
  static final AppFontController I = AppFontController._();

  static const _prefKey = 'app_font_family';
  static const _field = 'fontFamily';
  static const defaultFamily = 'Estedad';

  /// لیست خانواده‌های قابل انتخاب — باید دقیقاً با pubspec.yaml هماهنگ باشد
  static const List<String> supported = [
    'Estedad',
    'Vazirmatn',
    'VazirmatnFD',
    'Samim',
    'Gandom',
    'MjParand',
  ];

  String _family = defaultFamily;
  bool _loaded = false;

  String get family => _family;
  bool get isLoaded => _loaded;

  bool get isEstedad => _family == 'Estedad';
  bool get isVazirmatn => _family == 'Vazirmatn';
  bool get isVazirmatnFD => _family == 'VazirmatnFD';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = (prefs.getString(_prefKey) ?? defaultFamily).trim();
      _family = _normalize(raw);
      // اگر لاگین است و Firestore مقدار دارد، آن را ترجیح بده
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          final remote = (doc.data()?[_field] ?? '').toString().trim();
          if (remote.isNotEmpty) {
            final norm = _normalize(remote);
            if (supported.contains(norm)) {
              _family = norm;
              // همگام‌سازی لوکال
              try {
                await prefs.setString(_prefKey, _family);
              } catch (_) {}
            }
          }
        } catch (_) {}
      }
    } catch (_) {
      _family = defaultFamily;
    }
    _loaded = true;
    notifyListeners();
  }

  static String _normalize(String raw) {
    if (raw.isEmpty) return defaultFamily;
    // نگاشت نام‌های قدیمی/جایگزین
    final m = raw.trim();
    // پشتیبانی از نام‌های با خط تیره/فاصله
    if (m == 'Vazir' || m == 'Vazirmatn-FD' || m == 'Vazir_FD') return 'VazirmatnFD';
    if (m == 'Parand' || m == 'Mj_Parand' || m == 'MjParand ' ) return 'MjParand';
    // حساس به حروف برای خانواده‌های ما
    for (final s in supported) {
      if (s.toLowerCase() == m.toLowerCase()) return s;
    }
    return defaultFamily;
  }

  Future<void> setFont(String family) async {
    final next = _normalize(family);
    if (_family == next && _loaded) {
      notifyListeners();
      return;
    }
    _family = next;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, _family);
    } catch (_) {}
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          _field: _family,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  /// نمایش فارسی/انگلیسی برای هر خانواده
  static String displayNameFa(String family) {
    switch (family) {
      case 'Estedad':
        return 'استعداد';
      case 'Vazirmatn':
        return 'وزیرمتن';
      case 'VazirmatnFD':
        return 'وزیرمتن — ارقام فارسی';
      case 'Samim':
        return 'صمیم';
      case 'Gandom':
        return 'گندم';
      case 'MjParand':
        return 'پرند';
      default:
        return family;
    }
  }

  static String displayNameEn(String family) {
    switch (family) {
      case 'Estedad':
        return 'Estedad';
      case 'Vazirmatn':
        return 'Vazirmatn';
      case 'VazirmatnFD':
        return 'Vazirmatn FD';
      case 'Samim':
        return 'Samim';
      case 'Gandom':
        return 'Gandom';
      case 'MjParand':
        return 'Parand';
      default:
        return family;
    }
  }

  static String displayLabelFa(String family) {
    switch (family) {
      case 'Estedad':
        return 'پیش‌فرض — لوکس و خوانا';
      case 'Vazirmatn':
        return 'مدرن و استاندارد';
      case 'VazirmatnFD':
        return 'وزیرمتن با ارقام فارسی';
      case 'Samim':
        return 'نرم و دوستانه';
      case 'Gandom':
        return 'گرم و دست‌نویس';
      case 'MjParand':
        return 'فانتزی و خاص';
      default:
        return '';
    }
  }

  static String displayLabelEn(String family) {
    switch (family) {
      case 'Estedad':
        return 'Default — elegant & readable';
      case 'Vazirmatn':
        return 'Modern & standard';
      case 'VazirmatnFD':
        return 'With Persian digits';
      case 'Samim':
        return 'Soft & friendly';
      case 'Gandom':
        return 'Warm & handwritten';
      case 'MjParand':
        return 'Playful & fancy';
      default:
        return '';
    }
  }
}

/// لیست انتخاب برای UI — ترتیب نمایش
class AppFontOptions {
  AppFontOptions._();
  static const List<String> ordered = [
    'Estedad',
    'Vazirmatn',
    'VazirmatnFD',
    'Samim',
    'Gandom',
    'MjParand',
  ];
}
