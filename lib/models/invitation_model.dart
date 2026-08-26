import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/app_config.dart';
import '../core/app_lang.dart';

class ScheduleItem {
  final String time;
  final String title;
  final String icon;

  const ScheduleItem({
    required this.time,
    required this.title,
    required this.icon,
  });

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      time: (map['time'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      icon: (map['icon'] ?? 'custom').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'title': title,
      'icon': icon,
    };
  }
}

class InvitationModel {
  final String coverTitle;
  final String brideName;
  final String groomName;
  final DateTime? weddingDate;
  final String eventTime;
  final String venueName;
  final String venueAddress;
  final String venueCity;
  final double? lat;
  final double? lng;
  final String mapUrl;
  final String slug;
  final bool showRsvp;
  final List<ScheduleItem> schedule;

  const InvitationModel({
    required this.coverTitle,
    required this.brideName,
    required this.groomName,
    required this.weddingDate,
    required this.eventTime,
    required this.venueName,
    required this.venueAddress,
    this.venueCity = '',
    required this.lat,
    required this.lng,
    required this.mapUrl,
    required this.slug,
    required this.showRsvp,
    required this.schedule,
  });

  String get coupleTitle {
    final g = groomName.trim();
    final b = brideName.trim();
    if (g.isEmpty && b.isEmpty) return AppLang.tr('couple_default_name');
    if (g.isEmpty) return b;
    if (b.isEmpty) return g;
    final joiner = AppLang.tr('couple_name_joiner');
    return '$g$joiner$b';
  }

  bool get hasGeo => lat != null && lng != null;

  /// slug تمیز برای URL — هرگز خالی برنمی‌گردد
  /// اگر slug خالی باشد از نام‌ها ساخته می‌شود، وگرنه 'invite'
  String get normalizedSlug {
    final s = slug.trim().toLowerCase();
    if (s.isNotEmpty) return s;

    String clean(String v) => v
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF\-]+'), '');

    final g = clean(groomName);
    final b = clean(brideName);
    if (g.isNotEmpty && b.isNotEmpty) return '$g-$b';
    if (g.isNotEmpty) return g;
    if (b.isNotEmpty) return b;
    return 'invite';
  }

  /// دامنه از [AppConfig] — یک جا برای کل اپ
  /// دامنه فعال — از AppConfig (روی وب = origin سایت)
static String get publicBaseUrl => AppConfig.publicBaseUrl;

  /// لینک پورتال مهمان — مخصوص همین عروسی
  /// مثال: https://wedding-time-app2.netlify.app/invite/zaza-sara
  String get shareLink => AppConfig.inviteUrl(normalizedSlug);

  /// متن اشتراک با لینک پورتال مهمان (نه ریشه سایت)
  String get shareText {
    final date = weddingDate == null
        ? ''
        : '${weddingDate!.year}/${weddingDate!.month.toString().padLeft(2, '0')}/${weddingDate!.day.toString().padLeft(2, '0')}';

    final portal = shareLink;
    final buf = StringBuffer();

    if (AppLang.I.isFa) {
      buf.writeln('💍 دعوت به عروسی');
    } else {
      buf.writeln('💍 Wedding invitation');
    }
    buf.writeln(coupleTitle);

    if (date.isNotEmpty) {
      buf.writeln(AppLang.I.isFa ? '📅 تاریخ: $date' : '📅 Date: $date');
    }
    if (eventTime.trim().isNotEmpty) {
      buf.writeln(
        AppLang.I.isFa
            ? '⏰ ساعت: ${eventTime.trim()}'
            : '⏰ Time: ${eventTime.trim()}',
      );
    }
    if (venueName.trim().isNotEmpty) {
      buf.writeln('📍 ${venueName.trim()}');
    }
    if (venueCity.trim().isNotEmpty) {
      buf.writeln('🏙 ${venueCity.trim()}');
    }
    if (venueAddress.trim().isNotEmpty) {
      buf.writeln(venueAddress.trim());
    }

    final maps = googleMapsLink;
    if (maps.isNotEmpty) {
      buf.writeln();
      buf.writeln(AppLang.I.isFa ? '🗺 مسیریابی:' : '🗺 Directions:');
      buf.writeln(maps);
    }

    buf.writeln();
    if (AppLang.I.isFa) {
      buf.writeln(
        '🔐 ورود به پورتال اختصاصی این عروسی'
        ' (دعوت‌نامه، تایم‌لاین، دوربین، صندلی، هدیه و ...):',
      );
    } else {
      buf.writeln(
        '🔐 Open this wedding’s guest portal'
        ' (invite, timeline, camera, seats, gifts, ...):',
      );
    }
    buf.writeln(portal);
    return buf.toString();
  }

  String get googleMapsLink {
    if (mapUrl.trim().isNotEmpty) {
      final u = mapUrl.trim();
      if (u.startsWith('http')) return u;
      if (u.startsWith('www.')) return 'https://$u';
    }
    if (hasGeo) {
      return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    }
    if (venueAddress.trim().isNotEmpty) {
      return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(venueAddress.trim())}';
    }
    if (venueName.trim().isNotEmpty) {
      final q = [
        venueName.trim(),
        if (venueCity.trim().isNotEmpty) venueCity.trim(),
      ].join(' ');
      return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}';
    }
    return '';
  }

  /// عنوان روی کارت — اگر خالی/پیش‌فرض قدیمی بود، i18n
  String get displayCoverTitle {
    final t = coverTitle.trim();
    const legacyFa = 'با افتخار شما را\nبه جشن عروسی';
    const legacyFaFlat = 'با افتخار شما را به جشن عروسی';
    if (t.isEmpty || t == legacyFa || t == legacyFaFlat) {
      return AppLang.tr('default_cover_title');
    }
    return coverTitle;
  }

  factory InvitationModel.fromMap(Map<String, dynamic> data) {
    DateTime? date;
    final rawDate = data['weddingDate'];
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is DateTime) {
      date = rawDate;
    }

    final scheduleRaw = (data['schedule'] as List?) ?? [];
    final schedule = <ScheduleItem>[];
    for (final e in scheduleRaw) {
      if (e is Map<String, dynamic>) {
        schedule.add(ScheduleItem.fromMap(e));
      } else if (e is Map) {
        schedule.add(ScheduleItem.fromMap(Map<String, dynamic>.from(e)));
      }
    }

    final rawShow = data['showRsvp'];
    final bool showRsvp;
    if (rawShow is bool) {
      showRsvp = rawShow;
    } else if (rawShow is num) {
      showRsvp = rawShow != 0;
    } else if (rawShow is String) {
      final s = rawShow.trim().toLowerCase();
      showRsvp = !(s == 'false' || s == '0' || s == 'no');
    } else {
      showRsvp = true;
    }

    final rawCover = (data['coverTitle'] ?? '').toString();

    return InvitationModel(
      coverTitle:
          rawCover.isEmpty ? AppLang.tr('default_cover_title') : rawCover,
      brideName: (data['brideName'] ?? '').toString(),
      groomName: (data['groomName'] ?? '').toString(),
      weddingDate: date,
      eventTime: (data['eventTime'] ?? '19:00').toString(),
      venueName: (data['venueName'] ?? '').toString(),
      venueAddress: (data['venueAddress'] ?? '').toString(),
      venueCity: (data['venueCity'] ?? '').toString(),
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      mapUrl: (data['mapUrl'] ?? '').toString(),
      slug: (data['slug'] ?? '').toString(),
      showRsvp: showRsvp,
      schedule: schedule,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coverTitle': coverTitle,
      'brideName': brideName,
      'groomName': groomName,
      'weddingDate':
          weddingDate == null ? null : Timestamp.fromDate(weddingDate!),
      'eventTime': eventTime,
      'venueName': venueName,
      'venueAddress': venueAddress,
      'venueCity': venueCity,
      'lat': lat,
      'lng': lng,
      'mapUrl': mapUrl,
      // همیشه slug نرمال‌شده ذخیره شود
      'slug': normalizedSlug,
      'showRsvp': showRsvp,
      'schedule': schedule.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  InvitationModel copyWith({
    String? coverTitle,
    String? brideName,
    String? groomName,
    DateTime? weddingDate,
    String? eventTime,
    String? venueName,
    String? venueAddress,
    String? venueCity,
    double? lat,
    double? lng,
    String? mapUrl,
    String? slug,
    bool? showRsvp,
    List<ScheduleItem>? schedule,
  }) {
    return InvitationModel(
      coverTitle: coverTitle ?? this.coverTitle,
      brideName: brideName ?? this.brideName,
      groomName: groomName ?? this.groomName,
      weddingDate: weddingDate ?? this.weddingDate,
      eventTime: eventTime ?? this.eventTime,
      venueName: venueName ?? this.venueName,
      venueAddress: venueAddress ?? this.venueAddress,
      venueCity: venueCity ?? this.venueCity,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      mapUrl: mapUrl ?? this.mapUrl,
      slug: slug ?? this.slug,
      showRsvp: showRsvp ?? this.showRsvp,
      schedule: schedule ?? this.schedule,
    );
  }
}