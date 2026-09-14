/// استخراج slug مهمان از مسیر یا URL
///
/// منطق خالص و بدون هیچ وابستگی به Firebase/Flutter-web است
/// تا بتوان آن را در تست واحد بررسی کرد.
///
/// مثال‌های معتبر:
///   /invite/zaza-sara
///   /portal/zaza-sara
///   /guest/zaza-sara
///   /g/zaza-sara
///   https://example.com/invite/zaza-sara?x=1
///   #/invite/zaza-sara
class GuestSlug {
  GuestSlug._();

  /// ریشه‌های مجاز برای مسیر پورتال مهمان
  static const List<String> roots = ['invite', 'portal', 'guest', 'g'];

  /// مسیر یا URL را می‌گیرد:
  /// - slug مهمان در صورت وجود
  /// - رشتهٔ خالی '' وقتی مسیر معتبر است اما slug نیامده (/invite)
  /// - null وقتی اصلاً مسیر مهمان نیست
  static String? from(String? raw) {
    if (raw == null) return null;

    var s = raw.trim();
    if (s.isEmpty) return null;

    // URL کامل → فقط مسیر (یا فرگمنت برای #/invite/...)
    final asUri = Uri.tryParse(s);
    if (asUri != null && (asUri.hasScheme || s.contains('://'))) {
      s = asUri.path;
      if ((s.isEmpty || s == '/') && asUri.fragment.isNotEmpty) {
        s = asUri.fragment;
      }
    }

    if (s.startsWith('#')) s = s.substring(1);
    if (!s.startsWith('/')) s = '/$s';

    // حذف query و hash
    final qi = s.indexOf('?');
    if (qi >= 0) s = s.substring(0, qi);
    final hi = s.indexOf('#');
    if (hi >= 0) s = s.substring(0, hi);

    final parts = s.split('/').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return null;

    final root = parts.first.toLowerCase();
    if (!roots.contains(root)) return null;

    if (parts.length >= 2) return Uri.decodeComponent(parts[1]).trim();
    return '';
  }
}
