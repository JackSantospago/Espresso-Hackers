import 'dart:math' as math;

import '../core/config.dart';
import 'weather.dart';

/// Extreme conditions the app watches for. The RULES decide (fixed limits in
/// [WeatherLimits]); the LLM only explains what to do about them.
enum WeatherRisk { frost, heat, heavyRain, wind, storm, hail, drySpell, wetSpell }

/// One warning: a run of consecutive forecast days with the same risk.
class WeatherAlert {
  const WeatherAlert(this.risk, this.from, this.to, this.days, this.value);
  final WeatherRisk risk;
  final DateTime from, to;
  final int days;

  /// frost: lowest °C · heat: highest °C · heavyRain: total mm ·
  /// wind: strongest gust km/h · storm, hail, drySpell, wetSpell: = [days].
  final double value;
}

/// Finds the warnings in [days] (pass `forecast.upcoming(now)`), soonest first.
List<WeatherAlert> findAlerts(List<DayForecast> days) {
  final out = <WeatherAlert>[];

  void runs(WeatherRisk risk, bool Function(int i) hit, double Function(List<DayForecast> run) value,
      {int minDays = 1}) {
    var start = -1;
    for (var i = 0; i <= days.length; i++) {
      final on = i < days.length && hit(i);
      if (on && start < 0) start = i;
      if (!on && start >= 0) {
        final run = days.sublist(start, i);
        if (run.length >= minDays) out.add(WeatherAlert(risk, run.first.date, run.last.date, run.length, value(run)));
        start = -1;
      }
    }
  }

  double rain(int i) => days[i].rainMm ?? 0;
  double count(List<DayForecast> r) => r.length.toDouble();

  runs(WeatherRisk.frost, (i) => (days[i].tMin ?? 99) <= WeatherLimits.frostMinC,
      (r) => r.map((d) => d.tMin!).reduce(math.min));
  runs(WeatherRisk.heat, (i) => (days[i].tMax ?? -99) >= WeatherLimits.heatMaxC,
      (r) => r.map((d) => d.tMax!).reduce(math.max));

  // Heavy rain: one very wet day, or three days in a row that add up to a lot
  // (only the days of such a window that actually have rain are flagged).
  final heavy = List<bool>.generate(days.length, (i) => rain(i) >= WeatherLimits.heavyRainDayMm);
  for (var i = 0; i + 2 < days.length; i++) {
    if (rain(i) + rain(i + 1) + rain(i + 2) >= WeatherLimits.heavyRain3DaysMm) {
      for (var j = i; j <= i + 2; j++) {
        if (rain(j) >= WeatherLimits.wetDayMm) heavy[j] = true;
      }
    }
  }
  runs(WeatherRisk.heavyRain, (i) => heavy[i], (r) => r.fold(0.0, (s, d) => s + (d.rainMm ?? 0)));

  runs(WeatherRisk.wind, (i) => (days[i].gustKmh ?? 0) >= WeatherLimits.windGustKmh,
      (r) => r.map((d) => d.gustKmh!).reduce(math.max));
  runs(WeatherRisk.hail, (i) => days[i].code == 96 || days[i].code == 99, count);
  runs(WeatherRisk.storm, (i) => days[i].code == 95, count);
  runs(WeatherRisk.drySpell, (i) => days[i].rainMm != null && rain(i) < WeatherLimits.wetDayMm, count,
      minDays: WeatherLimits.drySpellDays);
  runs(
      WeatherRisk.wetSpell,
      (i) =>
          rain(i) >= WeatherLimits.wetDayMm &&
          days[i].humidity != null &&
          days[i].humidity! >= WeatherLimits.humidPct,
      count,
      minDays: WeatherLimits.wetSpellDays);

  out.sort((a, b) {
    final byDate = a.from.compareTo(b.from);
    return byDate != 0 ? byDate : a.risk.index.compareTo(b.risk.index);
  });
  return out;
}

// ------------------------------------------------------- text for the LLM
// The prompts are in English (like the rest of the prompts); the model answers
// in the farmer's language.

const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String _day(DateTime d) => '${_wd[d.weekday - 1]} ${d.day} ${_mo[d.month - 1]}';
String _range(WeatherAlert a) => a.days == 1 ? _day(a.from) : '${_day(a.from)} to ${_day(a.to)}';

/// One line per alert, with the numbers the rules found.
String alertForPrompt(WeatherAlert a) => switch (a.risk) {
      WeatherRisk.frost => 'Frost risk, ${_range(a)}: nights down to ${a.value.round()} °C.',
      WeatherRisk.heat => 'Very hot days, ${_range(a)}: up to ${a.value.round()} °C.',
      WeatherRisk.heavyRain => 'Heavy rain, ${_range(a)}: about ${a.value.round()} mm in total.',
      WeatherRisk.wind => 'Strong wind, ${_range(a)}: gusts up to ${a.value.round()} km/h.',
      WeatherRisk.storm => 'Thunderstorms, ${_range(a)}.',
      WeatherRisk.hail => 'Thunderstorms with possible hail, ${_range(a)}.',
      WeatherRisk.drySpell => 'Dry spell: ${a.days} days in a row with almost no rain, ${_range(a)}.',
      WeatherRisk.wetSpell => 'Long wet, humid spell: ${a.days} days in a row of rain and humid air, '
          '${_range(a)}. Fungal diseases spread easily in this weather.',
    };

/// Search text for the knowledge base (the guides are in English).
String riskQuery(WeatherRisk r) => switch (r) {
      WeatherRisk.frost => 'protect crops and seedlings from frost on cold nights',
      WeatherRisk.heat => 'protect crops from heat stress on very hot days',
      WeatherRisk.heavyRain => 'protect crops and soil from heavy rain, flooding and erosion',
      WeatherRisk.wind => 'protect crops and young trees from strong wind',
      WeatherRisk.storm => 'protect crops from thunderstorms',
      WeatherRisk.hail => 'protect crops from hail damage',
      WeatherRisk.drySpell => 'protect crops during a dry spell, keep soil moisture',
      WeatherRisk.wetSpell => 'long wet humid weather, fungal disease, leaf rust, prevent spread',
    };

String _ago(Duration d) => d.inHours < 1
    ? 'less than an hour'
    : d.inHours < 48
        ? '${d.inHours} hours'
        : '${d.inDays} days';

String _n(double? v, [String unit = '']) => v == null ? '?' : '${v.round()}${unit.isEmpty ? '' : ' $unit'}';

/// Short weather block for the chat prompt: the next 3 days and all warnings.
String forecastForPrompt(Forecast f, DateTime now) {
  final days = f.upcoming(now);
  if (days.isEmpty) return 'No forecast for the coming days (last download ${_ago(f.age(now))} ago).';
  final alerts = findAlerts(days);
  final b = StringBuffer('Forecast downloaded ${_ago(f.age(now))} ago.\n');
  for (final d in days.take(3)) {
    final chance = d.rainChance == null ? '' : ' (${d.rainChance}% chance)';
    b.writeln('- ${_day(d.date)}: ${_n(d.tMin)} to ${_n(d.tMax, '°C')}, rain ${_n(d.rainMm, 'mm')}$chance');
  }
  b.write('Warnings, next ${days.length} days: ');
  b.write(alerts.isEmpty ? 'none — no extreme weather expected.' : '\n${alerts.map((a) => '- ${alertForPrompt(a)}').join('\n')}');
  return b.toString();
}
