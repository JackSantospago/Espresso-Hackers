// Weather: Open-Meteo parsing (a real saved response), the warning rules,
// the prompt text and the HTTP client — no plugins, no network.
import 'dart:convert';
import 'dart:io';

import 'package:field_assistant/core/config.dart';
import 'package:field_assistant/services/weather.dart';
import 'package:field_assistant/services/weather_risk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Real response for Nyeri, Kenya (-0.4, 36.9), 14 days from 2026-10-04.
String _fixture() => File('test/fixtures/open_meteo_nyeri.json').readAsStringSync();

final _d0 = DateTime(2026, 10, 4);

/// Builds consecutive days from [_d0]; each entry overrides the calm defaults.
List<DayForecast> _days(List<Map<String, num?>> overrides) => [
      for (var i = 0; i < overrides.length; i++)
        DayForecast(
          date: DateTime(_d0.year, _d0.month, _d0.day + i),
          code: (overrides[i]['code'] ?? 2).toInt(),
          tMin: overrides[i].containsKey('tMin') ? overrides[i]['tMin']?.toDouble() : 12,
          tMax: overrides[i].containsKey('tMax') ? overrides[i]['tMax']?.toDouble() : 24,
          rainMm: overrides[i].containsKey('rain') ? overrides[i]['rain']?.toDouble() : 3,
          gustKmh: overrides[i].containsKey('gust') ? overrides[i]['gust']?.toDouble() : 20,
          humidity: overrides[i].containsKey('hum') ? overrides[i]['hum']?.toInt() : 60,
        ),
    ];

List<Map<String, num?>> _calm(int n) => List.generate(n, (_) => <String, num?>{});

void main() {
  group('Open-Meteo response', () {
    late Forecast f;
    setUp(() => f = Forecast.fromOpenMeteo(jsonDecode(_fixture()) as Map<String, dynamic>, fetchedAt: _d0));

    test('parses all 14 days with every field', () {
      expect(f.days, hasLength(kForecastDays));
      expect(f.days.first.date, DateTime(2026, 10, 4));
      expect(f.days.last.date, DateTime(2026, 10, 17));
      expect(f.elevation, 1963);
      final d = f.days[1];
      expect(d.code, 81);
      expect(d.tMax, 21.8);
      expect(d.tMin, 12.7);
      expect(d.rainMm, 10.4);
      expect(d.rainChance, 93);
      expect(d.gustKmh, 39.2);
      expect(d.humidity, 81);
    });

    test('missing values become null instead of crashing', () {
      final j = jsonDecode(_fixture()) as Map<String, dynamic>;
      (j['daily'] as Map<String, dynamic>)
        ..remove('relative_humidity_2m_mean')
        ..['temperature_2m_min'] = List<num?>.filled(14, null);
      final g = Forecast.fromOpenMeteo(j, fetchedAt: _d0);
      expect(g.days.every((d) => d.humidity == null && d.tMin == null), isTrue);
    });

    test('survives a save and load round trip', () {
      final back = Forecast.fromJson(jsonDecode(jsonEncode(f.toJson())) as Map<String, dynamic>);
      expect(back.days.map((d) => d.toJson()), f.days.map((d) => d.toJson()));
      expect(back.fetchedAt, f.fetchedAt);
      expect(back.elevation, f.elevation);
    });

    test('drops days that are already past', () {
      expect(f.upcoming(DateTime(2026, 10, 10, 15)).first.date, DateTime(2026, 10, 10));
      expect(f.upcoming(DateTime(2026, 10, 18)), isEmpty);
    });

    test('this real forecast has one warning: a 13-day wet, humid spell', () {
      final alerts = findAlerts(f.days);
      expect(alerts, hasLength(1));
      expect(alerts.single.risk, WeatherRisk.wetSpell);
      expect(alerts.single.from, DateTime(2026, 10, 5));
      expect(alerts.single.to, DateTime(2026, 10, 17));
      expect(alerts.single.days, 13);
    });
  });

  group('warning rules', () {
    test('calm weather gives no warnings', () {
      expect(findAlerts(_days(_calm(14))), isEmpty);
    });

    test('frost: consecutive cold nights become one warning with the lowest temperature', () {
      final days = _calm(14)
        ..[3] = {'tMin': 1.5}
        ..[4] = {'tMin': -0.4}
        ..[9] = {'tMin': 2.5}; // above the limit
      final a = findAlerts(_days(days));
      expect(a, hasLength(1));
      expect(a.single.risk, WeatherRisk.frost);
      expect(a.single.days, 2);
      expect(a.single.value, -0.4);
      expect(a.single.from, DateTime(2026, 10, 7));
    });

    test('heat', () {
      final a = findAlerts(_days(_calm(5)..[2] = {'tMax': 33.6}));
      expect(a.single.risk, WeatherRisk.heat);
      expect(a.single.value, 33.6);
    });

    test('heavy rain: one very wet day', () {
      final a = findAlerts(_days(_calm(5)..[1] = {'rain': 55}));
      expect(a.single.risk, WeatherRisk.heavyRain);
      expect(a.single.value, 55);
    });

    test('heavy rain: three days that add up, but not the dry day in the window', () {
      final days = _calm(6)
        ..[1] = {'rain': 45}
        ..[2] = {'rain': 0}
        ..[3] = {'rain': 58};
      final a = findAlerts(_days(days)).where((x) => x.risk == WeatherRisk.heavyRain).toList();
      expect(a, hasLength(2)); // day 1 and day 3, split by the dry day
      expect(a.map((x) => x.value), [45, 58]);
    });

    test('heavy rain: just under both limits gives nothing', () {
      final days = _calm(5)
        ..[1] = {'rain': 33}
        ..[2] = {'rain': 33}
        ..[3] = {'rain': 33};
      expect(findAlerts(_days(days)).where((x) => x.risk == WeatherRisk.heavyRain), isEmpty);
    });

    test('wind, thunderstorm and hail', () {
      final days = _calm(6)
        ..[0] = {'gust': 72}
        ..[2] = {'code': 95}
        ..[4] = {'code': 99};
      final risks = findAlerts(_days(days)).map((a) => a.risk);
      expect(risks, [WeatherRisk.wind, WeatherRisk.storm, WeatherRisk.hail]);
    });

    test('dry spell needs ${WeatherLimits.drySpellDays} days in a row', () {
      List<Map<String, num?>> dry(int n) => [...List.generate(n, (_) => {'rain': 0.2}), ..._calm(14 - n)];
      expect(findAlerts(_days(dry(WeatherLimits.drySpellDays - 1))), isEmpty);
      final a = findAlerts(_days(dry(WeatherLimits.drySpellDays)));
      expect(a.single.risk, WeatherRisk.drySpell);
      expect(a.single.days, WeatherLimits.drySpellDays);
    });

    test('unknown rain does not count as dry', () {
      expect(findAlerts(_days(List.generate(14, (_) => {'rain': null}))), isEmpty);
    });

    test('wet spell needs rain AND humid air, ${WeatherLimits.wetSpellDays} days in a row', () {
      List<Map<String, num?>> wet(int n, int hum) =>
          [...List.generate(n, (_) => {'rain': 6, 'hum': hum}), ..._calm(14 - n)];
      expect(findAlerts(_days(wet(WeatherLimits.wetSpellDays - 1, 90))), isEmpty);
      expect(findAlerts(_days(wet(8, 70))), isEmpty); // rainy but not humid
      expect(findAlerts(_days(wet(WeatherLimits.wetSpellDays, 90))).single.risk, WeatherRisk.wetSpell);
    });

    test('warnings are sorted soonest first', () {
      final days = _calm(10)
        ..[7] = {'tMin': 0}
        ..[2] = {'tMax': 35};
      expect(findAlerts(_days(days)).map((a) => a.risk), [WeatherRisk.heat, WeatherRisk.frost]);
    });
  });

  group('text for the LLM', () {
    test('alert lines carry the rule numbers and dates', () {
      final a = findAlerts(_days(_calm(5)..[1] = {'tMin': -1.2}));
      expect(alertForPrompt(a.single), 'Frost risk, Mon 5 Oct: nights down to -1 °C.');
    });

    test('the chat weather block lists 3 days and the warnings', () {
      final f = Forecast.fromOpenMeteo(jsonDecode(_fixture()) as Map<String, dynamic>,
          fetchedAt: DateTime(2026, 10, 4, 6));
      final text = forecastForPrompt(f, DateTime(2026, 10, 4, 9));
      expect(text, contains('downloaded 3 hours ago'));
      expect(text, contains('- Sun 4 Oct: 11 to 22 °C, rain 0 mm (71% chance)'));
      expect('- '.allMatches(text).length, 4); // 3 days + 1 warning
      expect(text, contains('Long wet, humid spell: 13 days'));
    });

    test('every risk has a search query for the guides', () {
      for (final r in WeatherRisk.values) {
        expect(riskQuery(r), isNotEmpty);
      }
    });
  });

  group('farm location and client', () {
    test('the location is rounded before it is stored or sent', () {
      final farm = FarmLocation.rounded(-0.38664, 36.87256, _d0);
      expect(farm.lat, -0.40);
      expect(farm.lon, 36.85);
      final uri = Weather.forecastUri(farm);
      expect(uri.queryParameters['latitude'], '-0.40');
      expect(uri.queryParameters['longitude'], '36.85');
      expect(uri.queryParameters['forecast_days'], '$kForecastDays');
      expect(uri.toString(), isNot(contains('0.3866')));
    });

    test('fetch parses a good answer', () async {
      final client = MockClient((req) async {
        expect(req.url.host, 'api.open-meteo.com');
        return http.Response(_fixture(), 200);
      });
      final f = await Weather.fetch(FarmLocation(-0.4, 36.9, _d0), client: client);
      expect(f.days, hasLength(14));
    });

    test('fetch turns server errors, bad data and no connection into WeatherFetchError', () async {
      final farm = FarmLocation(-0.4, 36.9, _d0);
      for (final client in [
        MockClient((_) async => http.Response('{"error":true,"reason":"bad"}', 400)),
        MockClient((_) async => http.Response('not json', 200)),
        MockClient((_) async => http.Response('{"daily": 5}', 200)),
        MockClient((_) async => throw const SocketException('no signal')),
      ]) {
        await expectLater(Weather.fetch(farm, client: client), throwsA(isA<WeatherFetchError>()));
      }
    });
  });
}
