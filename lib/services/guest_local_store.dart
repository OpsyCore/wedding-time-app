import 'package:shared_preferences/shared_preferences.dart';

/// وضعیت مهمان روی همین دستگاه (بدون لاگین)
/// RSVP یک‌بار + نام برای «میز من» + سهمیه دوربین مهمان
class GuestLocalStore {
  GuestLocalStore._();

  static String _rsvpStatusKey(String weddingId) =>
      'guest_rsvp_status_${weddingId.trim()}';

  static String _rsvpNameKey(String weddingId) =>
      'guest_rsvp_name_${weddingId.trim()}';

  static String _displayNameKey(String weddingId) =>
      'guest_display_name_${weddingId.trim()}';

  /// FIX-03: مهمان بدون لاگین نمی‌تواند عکس‌های در انتظار خودش را
  /// از Firestore بخواند (rules)، پس شمارنده سهمیه دوربین محلی است.
  static String _cameraUsageKey(String weddingId) =>
      'guest_camera_usage_${weddingId.trim()}';

  /// status: yes | no
  static Future<void> saveRsvp({
    required String weddingId,
    required String name,
    required String status,
  }) async {
    final wid = weddingId.trim();
    if (wid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final n = name.trim();
    final s = status.trim().toLowerCase();
    await prefs.setString(_rsvpStatusKey(wid), s);
    if (n.isNotEmpty) {
      await prefs.setString(_rsvpNameKey(wid), n);
      await prefs.setString(_displayNameKey(wid), n);
    }
  }

  static Future<({String? status, String? name})> loadRsvp(
    String weddingId,
  ) async {
    final wid = weddingId.trim();
    if (wid.isEmpty) return (status: null, name: null);
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString(_rsvpStatusKey(wid))?.trim();
    final name = prefs.getString(_rsvpNameKey(wid))?.trim();
    if (status == null || status.isEmpty) {
      return (status: null, name: name);
    }
    return (status: status, name: name);
  }

  static Future<bool> hasRsvp(String weddingId) async {
    final r = await loadRsvp(weddingId);
    return r.status == 'yes' || r.status == 'no';
  }

  static Future<void> saveDisplayName({
    required String weddingId,
    required String name,
  }) async {
    final wid = weddingId.trim();
    final n = name.trim();
    if (wid.isEmpty || n.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayNameKey(wid), n);
  }

  static Future<String?> loadDisplayName(String weddingId) async {
    final wid = weddingId.trim();
    if (wid.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getString(_displayNameKey(wid))?.trim();
    if (n != null && n.isNotEmpty) return n;
    return prefs.getString(_rsvpNameKey(wid))?.trim();
  }

  // ─── سهمیه دوربین مهمان (بدون لاگین) ───

  static Future<int> loadCameraUsage(String weddingId) async {
    final wid = weddingId.trim();
    if (wid.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cameraUsageKey(wid)) ?? 0;
  }

  /// یک عکس موفق به شمارنده اضافه می‌کند و مقدار جدید را برمی‌گرداند.
  static Future<int> bumpCameraUsage(String weddingId) async {
    final wid = weddingId.trim();
    if (wid.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(_cameraUsageKey(wid)) ?? 0) + 1;
    await prefs.setInt(_cameraUsageKey(wid), next);
    return next;
  }

  /// نرمال برای match نام روی میز
  static String normalizeName(String raw) {
    var s = raw.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const en = '0123456789';
    for (var i = 0; i < fa.length; i++) {
      s = s.replaceAll(fa[i], en[i]);
    }
    s = s
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('ة', 'ه')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا');
    return s.trim();
  }
}
