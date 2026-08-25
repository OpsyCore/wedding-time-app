import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class MapLauncher {
  /// باز کردن نقشه / مسیریابی — اول HTTPS (سازگار با Android/iOS/Web)
  static Future<bool> openLocation({
    String? name,
    String? address,
    double? lat,
    double? lng,
    String? mapUrl,
  }) async {
    final candidates = <Uri>[];

    // 1) لینک ذخیره‌شده کاربر (اگر http/https بود)
    final rawUrl = mapUrl?.trim() ?? '';
    if (rawUrl.isNotEmpty) {
      final parsed = Uri.tryParse(rawUrl);
      if (parsed != null &&
          (parsed.scheme == 'http' || parsed.scheme == 'https')) {
        candidates.add(parsed);
      } else if (rawUrl.startsWith('www.')) {
        candidates.add(Uri.parse('https://$rawUrl'));
      }
    }

    // 2) مختصات → لینک گوگل‌مپ HTTPS (اولویت بالا)
    if (lat != null && lng != null) {
      candidates.add(
        Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
        ),
      );
      candidates.add(
        Uri.parse('https://maps.google.com/?q=$lat,$lng'),
      );
    }

    // 3) آدرس / نام
    final query = (address != null && address.trim().isNotEmpty)
        ? address.trim()
        : (name ?? '').trim();

    if (query.isNotEmpty) {
      final encoded = Uri.encodeComponent(query);
      candidates.add(
        Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encoded',
        ),
      );
      candidates.add(Uri.parse('https://maps.google.com/?q=$encoded'));
    }

    // 4) فقط روی موبایل native: geo / scheme اپ
    if (!kIsWeb && lat != null && lng != null) {
      candidates.add(Uri.parse('geo:$lat,$lng?q=$lat,$lng'));
      candidates.add(
        Uri.parse('comgooglemaps://?q=$lat,$lng&center=$lat,$lng'),
      );
    }

    if (!kIsWeb && query.isNotEmpty) {
      final encoded = Uri.encodeComponent(query);
      candidates.add(Uri.parse('geo:0,0?q=$encoded'));
    }

    // 5) fallback
    if (candidates.isEmpty) {
      candidates.add(Uri.parse('https://www.google.com/maps'));
    }

    for (final uri in candidates) {
      try {
        final ok = await _launch(uri);
        if (ok) return true;
      } catch (e) {
        debugPrint('Map launch failed: $uri -> $e');
      }
    }

    return false;
  }

  static Future<bool> _launch(Uri uri) async {
    if (kIsWeb) {
      return launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
    }

    // موبایل: اول اپ خارجی
    try {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (ok) return true;
    } catch (e) {
      debugPrint('externalApplication failed: $uri -> $e');
    }

    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
    } catch (_) {}

    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
    } catch (_) {
      return false;
    }
  }
}