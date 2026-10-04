import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../core/config.dart';

/// The farm's location, already rounded to [kLocationStepDeg]. The precise
/// position is never stored or sent.
class FarmLocation {
  const FarmLocation(this.lat, this.lon, this.setAt);

  /// Rounds a raw GPS position before anything else sees it.
  factory FarmLocation.rounded(double lat, double lon, DateTime setAt) =>
      FarmLocation(_round(lat), _round(lon), setAt);

  final double lat, lon;
  final DateTime setAt;

  static double _round(double v) =>
      double.parse(((v / kLocationStepDeg).round() * kLocationStepDeg).toStringAsFixed(2));

  String get label => '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';

  bool sameSpot(FarmLocation o) => o.lat == lat && o.lon == lon;

  Map<String, dynamic> toJson() => {'lat': lat, 'lon': lon, 'set_at': setAt.toIso8601String()};
  static FarmLocation fromJson(Map<String, dynamic> j) =>
      FarmLocation((j['lat'] as num).toDouble(), (j['lon'] as num).toDouble(), DateTime.parse(j['set_at'] as String));
}

/// One forecast day at the farm. Any value can be missing (null) far out.
class DayForecast {
  const DayForecast({
    required this.date,
    this.code,
    this.tMax,
    this.tMin,
    this.rainMm,
    this.rainChance,
    this.gustKmh,
    this.humidity,
  });

  /// Local calendar date at the farm (no time of day).
  final DateTime date;

  /// WMO weather code (0 clear … 95–99 thunderstorm).
  final int? code;
  final double? tMax, tMin, rainMm, gustKmh;

  /// Percent.
  final int? rainChance, humidity;

  Map<String, dynamic> toJson() => {
        'date': _ymd(date),
        'code': code,
        't_max': tMax,
        't_min': tMin,
        'rain_mm': rainMm,
        'rain_chance': rainChance,
        'gust_kmh': gustKmh,
        'humidity': humidity,
      };

  static DayForecast fromJson(Map<String, dynamic> j) => DayForecast(
        date: _parseYmd(j['date'] as String),
        code: (j['code'] as num?)?.toInt(),
        tMax: (j['t_max'] as num?)?.toDouble(),
        tMin: (j['t_min'] as num?)?.toDouble(),
        rainMm: (j['rain_mm'] as num?)?.toDouble(),
        rainChance: (j['rain_chance'] as num?)?.toInt(),
        gustKmh: (j['gust_kmh'] as num?)?.toDouble(),
        humidity: (j['humidity'] as num?)?.toInt(),
      );
}

/// A downloaded forecast, as saved on the phone.
class Forecast {
  const Forecast({required this.fetchedAt, required this.days, this.elevation});

  final DateTime fetchedAt;
  final List<DayForecast> days;

  /// Metres, of the forecast grid point (Open-Meteo picks it from the location).
  final double? elevation;

  /// Days from [now]'s date onwards — past days of an old forecast are dropped.
  List<DayForecast> upcoming(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return days.where((d) => !d.date.isBefore(today)).toList();
  }

  Duration age(DateTime now) => now.difference(fetchedAt);

  /// Parses an Open-Meteo `/v1/forecast` response with the [_dailyFields] below.
  factory Forecast.fromOpenMeteo(Map<String, dynamic> json, {required DateTime fetchedAt}) {
    final daily = json['daily'] as Map<String, dynamic>;
    final times = (daily['time'] as List).cast<String>();
    List<num?> col(String k) => (daily[k] as List?)?.cast<num?>() ?? List<num?>.filled(times.length, null);
    final code = col('weather_code'),
        tMax = col('temperature_2m_max'),
        tMin = col('temperature_2m_min'),
        rain = col('precipitation_sum'),
        chance = col('precipitation_probability_max'),
        gust = col('wind_gusts_10m_max'),
        hum = col('relative_humidity_2m_mean');
    return Forecast(
      fetchedAt: fetchedAt,
      elevation: (json['elevation'] as num?)?.toDouble(),
      days: [
        for (var i = 0; i < times.length; i++)
          DayForecast(
            date: _parseYmd(times[i]),
            code: code[i]?.toInt(),
            tMax: tMax[i]?.toDouble(),
            tMin: tMin[i]?.toDouble(),
            rainMm: rain[i]?.toDouble(),
            rainChance: chance[i]?.toInt(),
            gustKmh: gust[i]?.toDouble(),
            humidity: hum[i]?.toInt(),
          ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'fetched_at': fetchedAt.toIso8601String(),
        'elevation': elevation,
        'days': days.map((d) => d.toJson()).toList(),
      };

  static Forecast fromJson(Map<String, dynamic> j) => Forecast(
        fetchedAt: DateTime.parse(j['fetched_at'] as String),
        elevation: (j['elevation'] as num?)?.toDouble(),
        days: (j['days'] as List).map((d) => DayForecast.fromJson(d as Map<String, dynamic>)).toList(),
      );
}

/// What is saved in weather.json. No farm = weather is turned off.
class WeatherData {
  const WeatherData({this.farm, this.forecast});
  final FarmLocation? farm;
  final Forecast? forecast;
}

/// The weather service could not give a forecast (offline, server error, bad data).
class WeatherFetchError implements Exception {
  WeatherFetchError(this.message);
  final String message;
  @override
  String toString() => 'WeatherFetchError: $message';
}

/// Open-Meteo client + the on-phone store. No widgets and no plugins other
/// than path_provider, so the background task can use it too.
abstract final class Weather {
  static const _dailyFields = [
    'weather_code',
    'temperature_2m_max',
    'temperature_2m_min',
    'precipitation_sum',
    'precipitation_probability_max',
    'wind_gusts_10m_max',
    'relative_humidity_2m_mean',
  ];

  static Uri forecastUri(FarmLocation farm) => Uri.parse(kWeatherApi).replace(queryParameters: {
        'latitude': farm.lat.toStringAsFixed(2),
        'longitude': farm.lon.toStringAsFixed(2),
        'daily': _dailyFields.join(','),
        'forecast_days': '$kForecastDays',
        'timezone': 'auto',
      });

  /// Downloads the forecast. Throws [WeatherFetchError] on no connection,
  /// timeout or a bad answer.
  static Future<Forecast> fetch(FarmLocation farm, {http.Client? client}) async {
    final c = client ?? http.Client();
    try {
      final res = await c.get(forecastUri(farm)).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) throw WeatherFetchError('HTTP ${res.statusCode}');
      return Forecast.fromOpenMeteo(jsonDecode(res.body) as Map<String, dynamic>, fetchedAt: DateTime.now());
    } on WeatherFetchError {
      rethrow;
    } catch (e) {
      throw WeatherFetchError('$e');
    } finally {
      if (client == null) c.close();
    }
  }

  // ------------------------------------------------------------------- store

  static Future<File> _file() async => File('${(await getApplicationDocumentsDirectory()).path}/weather.json');

  static Future<WeatherData> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return const WeatherData();
      final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return WeatherData(
        farm: j['farm'] == null ? null : FarmLocation.fromJson(j['farm'] as Map<String, dynamic>),
        forecast: j['forecast'] == null ? null : Forecast.fromJson(j['forecast'] as Map<String, dynamic>),
      );
    } catch (_) {
      return const WeatherData(); // corrupt file: start again
    }
  }

  /// Written to a temp file first, so the app and the background task never
  /// read half a file.
  static Future<void> save(WeatherData data) async {
    final f = await _file();
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(
      jsonEncode({'farm': data.farm?.toJson(), 'forecast': data.forecast?.toJson()}),
      flush: true,
    );
    await tmp.rename(f.path);
  }

  /// Turning weather off deletes the location and the forecast.
  static Future<void> clear() async {
    final f = await _file();
    if (await f.exists()) await f.delete();
  }

  /// The saved forecast, or null when weather is off or nothing was downloaded yet.
  static Future<Forecast?> savedForecast() async {
    final d = await load();
    return d.farm == null ? null : d.forecast;
  }

  /// Downloads a new forecast for the saved farm if one is due. Used by the
  /// app and by the background task, so both follow the same rules.
  static Future<RefreshResult> refreshSaved({bool force = false, http.Client? client}) async {
    final d = await load();
    final farm = d.farm;
    if (farm == null) return RefreshResult.off;
    final old = d.forecast;
    if (!force && old != null && old.age(DateTime.now()) < kWeatherRefreshEvery) return RefreshResult.notDue;
    final Forecast f;
    try {
      f = await fetch(farm, client: client);
    } on WeatherFetchError {
      return RefreshResult.failed;
    }
    // The farmer may have turned weather off or moved the farm meanwhile.
    final now = await load();
    if (now.farm == null || !now.farm!.sameSpot(farm)) return RefreshResult.off;
    await save(WeatherData(farm: now.farm, forecast: f));
    return RefreshResult.updated;
  }
}

enum RefreshResult { updated, notDue, failed, off }

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _parseYmd(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}
