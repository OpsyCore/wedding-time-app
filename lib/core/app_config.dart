import 'package:flutter/foundation.dart' show kIsWeb;

/// تنظیمات سراسری اپ — دامنه عمومی و لینک دعوت
/// همه Share / QR / invite فقط از اینجا می‌آیند.
class AppConfig {
  AppConfig._();

  /// دامنه پیش‌فرض (موبایل / وقتی origin در دسترس نیست)
  /// سایت رسمی Netlify (FIX-05: دامنه صحیح بدون «2»)
  static const String defaultPublicBaseUrl =
      'https://wedding-time-app2.netlify.app';

  /// دامنه فعال:
  /// - روی وب: همان دامنه مرورگر (هر Netlify که دیپلوی کردی)
  /// - غیر وب: defaultPublicBaseUrl
  static String get publicBaseUrl {
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.startsWith('http://') || origin.startsWith('https://')) {
          // localhost برای تست لوکال
          if (origin.contains('localhost') || origin.contains('127.0.0.1')) {
            return origin;
          }
          // نتلیفای / دامنه واقعی
          return origin.endsWith('/')
              ? origin.substring(0, origin.length - 1)
              : origin;
        }
      } catch (_) {}
    }
    return defaultPublicBaseUrl;
  }

  /// لینک پورتال مهمان مخصوص هر عروسی
  /// مثال: https://wedding-time-app2.netlify.app/invite/zaza-sara
  static String inviteUrl(String slug) {
    final s = slug.trim().toLowerCase();
    final clean = s.isEmpty ? 'invite' : s;
    final base = publicBaseUrl.endsWith('/')
        ? publicBaseUrl.substring(0, publicBaseUrl.length - 1)
        : publicBaseUrl;
    return '$base/invite/$clean';
  }

  /// ImgBB
  static const String imgbbApiKey = String.fromEnvironment(
    'IMGBB_API_KEY',
    defaultValue: '63ad9a49b307c10e9cbcbbe65c1e23bf',
  );

  static bool get hasImgbbKey => imgbbApiKey.trim().isNotEmpty;

  static const List<String> adminEmails = [
    'mishe.nemishetube4@gmail.com',
  ];

  static bool isAdminEmail(String? email) {
    if (email == null) return false;
    final e = email.trim().toLowerCase();
    return adminEmails.any((a) => a.toLowerCase() == e);
  }
}
