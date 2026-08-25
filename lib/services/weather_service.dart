import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/app_lang.dart';

class WeatherDay {
  final DateTime date;
  final int weatherCode;
  final double tempMax;
  final double tempMin;
  final int? precipProbability;

  const WeatherDay({
    required this.date,
    required this.weatherCode,
    required this.tempMax,
    required this.tempMin,
    this.precipProbability,
  });
}

class WeatherSnapshot {
  final double temperature;
  final int weatherCode;
  final int? humidity;
  final int? precipProbability;
  final double? windSpeedKmh;
  final List<WeatherDay> daily;

  const WeatherSnapshot({
    required this.temperature,
    required this.weatherCode,
    this.humidity,
    this.precipProbability,
    this.windSpeedKmh,
    required this.daily,
  });
}

class WeatherService {
  WeatherService._();

  static WeatherSnapshot? _cache;
  static double? _cacheLat;
  static double? _cacheLng;
  static DateTime? _cacheAt;

  static const _cacheTtl = Duration(minutes: 20);

  /// برچسب کامل آب‌وهوا (i18n)
  static String label(int code) {
    if (code == 0) return AppLang.tr('weather_clear');
    if (code == 1) return AppLang.tr('weather_mainly_clear');
    if (code == 2) return AppLang.tr('weather_partly_cloudy');
    if (code == 3) return AppLang.tr('weather_overcast');
    if (code == 45 || code == 48) return AppLang.tr('weather_fog');
    if (code >= 51 && code <= 57) return AppLang.tr('weather_drizzle');
    if (code >= 61 && code <= 67) return AppLang.tr('weather_rain');
    if (code >= 71 && code <= 77) return AppLang.tr('weather_snow');
    if (code >= 80 && code <= 82) return AppLang.tr('weather_showers');
    if (code >= 85 && code <= 86) return AppLang.tr('weather_snow_showers');
    if (code >= 95) return AppLang.tr('weather_thunder');
    return AppLang.tr('weather_unknown');
  }

  /// برچسب کوتاه (i18n)
  static String conditionShort(int code) {
    if (code == 0) return AppLang.tr('weather_sunny');
    if (code == 1) return AppLang.tr('weather_mainly_sunny');
    if (code == 2) return AppLang.tr('weather_partly_cloudy');
    if (code == 3) return AppLang.tr('weather_overcast');
    if (code == 45 || code == 48) return AppLang.tr('weather_fog_short');
    if (code >= 51 && code <= 67) return AppLang.tr('weather_rain');
    if (code >= 71 && code <= 77) return AppLang.tr('weather_snow');
    if (code >= 80 && code <= 82) return AppLang.tr('weather_showers');
    if (code >= 95) return AppLang.tr('weather_thunder');
    return AppLang.tr('weather_dash');
  }

  static Future<WeatherSnapshot> fetch({
    required double lat,
    required double lng,
    bool force = false,
  }) async {
    final now = DateTime.now();
    if (!force &&
        _cache != null &&
        _cacheLat == lat &&
        _cacheLng == lng &&
        _cacheAt != null &&
        now.difference(_cacheAt!) < _cacheTtl) {
      return _cache!;
    }

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': lat.toString(),
      'longitude': lng.toString(),
      'current':
          'temperature_2m,relative_humidity_2m,precipitation_probability,weather_code,wind_speed_10m',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'timezone': 'auto',
      'forecast_days': '5',
      'wind_speed_unit': 'kmh',
    });

    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception(
        '${AppLang.tr('weather_fetch_error')} (${res.statusCode})',
      );
    }

    final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
    final current = (jsonMap['current'] as Map<String, dynamic>?) ?? {};
    final daily = (jsonMap['daily'] as Map<String, dynamic>?) ?? {};

    final times = (daily['time'] as List?) ?? [];
    final codes = (daily['weather_code'] as List?) ?? [];
    final maxs = (daily['temperature_2m_max'] as List?) ?? [];
    final mins = (daily['temperature_2m_min'] as List?) ?? [];
    final preci = (daily['precipitation_probability_max'] as List?) ?? [];

    final days = <WeatherDay>[];
    for (var i = 0; i < times.length; i++) {
      days.add(
        WeatherDay(
          date: DateTime.tryParse(times[i].toString()) ?? now,
          weatherCode:
              (codes.length > i ? (codes[i] as num?)?.toInt() : 0) ?? 0,
          tempMax: (maxs.length > i ? (maxs[i] as num?)?.toDouble() : 0) ?? 0,
          tempMin: (mins.length > i ? (mins[i] as num?)?.toDouble() : 0) ?? 0,
          precipProbability:
              preci.length > i ? (preci[i] as num?)?.toInt() : null,
        ),
      );
    }

    final snap = WeatherSnapshot(
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      humidity: (current['relative_humidity_2m'] as num?)?.toInt(),
      precipProbability:
          (current['precipitation_probability'] as num?)?.toInt(),
      windSpeedKmh: (current['wind_speed_10m'] as num?)?.toDouble(),
      daily: days,
    );

    _cache = snap;
    _cacheLat = lat;
    _cacheLng = lng;
    _cacheAt = now;
    return snap;
  }
}