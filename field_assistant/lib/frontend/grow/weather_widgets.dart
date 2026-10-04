import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/strings.dart';
import '../../services/weather.dart';
import '../../services/weather_risk.dart';

/// Small pieces shared by the Weather card on Grow and the full Weather screen.

/// WMO weather code → icon.
IconData weatherIcon(int? code) => code == null
    ? Icons.help_outline
    : switch (code) {
        0 || 1 => Icons.wb_sunny_outlined,
        2 => Icons.wb_cloudy_outlined,
        3 => Icons.cloud_outlined,
        45 || 48 => Icons.foggy,
        >= 51 && <= 57 => Icons.grain,
        (>= 61 && <= 67) || (>= 80 && <= 82) => Icons.umbrella_outlined,
        (>= 71 && <= 77) || 85 || 86 => Icons.ac_unit,
        >= 95 => Icons.thunderstorm_outlined,
        _ => Icons.cloud_outlined,
      };

/// "Today", "Tomorrow" or "Sat 12 Oct" in the farmer's language.
String dayLabel(WeatherStrings w, DateTime d, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  if (d == today) return w.today;
  if (d == DateTime(today.year, today.month, today.day + 1)) return w.tomorrow;
  return w.date(d);
}

/// "Sat 12 Oct" or "Sat 12 Oct – Mon 14 Oct".
String alertWhen(WeatherStrings w, WeatherAlert a) =>
    a.days == 1 ? w.date(a.from) : '${w.date(a.from)} – ${w.date(a.to)}';

bool alertCovers(WeatherAlert a, DateTime d) => !d.isBefore(a.from) && !d.isAfter(a.to);

/// Title, icon and detail line of a warning (the numbers come from the rules).
(String, IconData, String) alertText(WeatherStrings w, WeatherAlert a) => switch (a.risk) {
      WeatherRisk.frost => (w.frost, Icons.ac_unit, w.frostDetail(a.value.round())),
      WeatherRisk.heat => (w.heat, Icons.thermostat, w.heatDetail(a.value.round())),
      WeatherRisk.heavyRain => (w.heavyRain, Icons.flood_outlined, w.rainDetail(a.value.round())),
      WeatherRisk.wind => (w.wind, Icons.air, w.windDetail(a.value.round())),
      WeatherRisk.storm => (w.storm, Icons.thunderstorm_outlined, w.daysCount(a.days)),
      WeatherRisk.hail => (w.hail, Icons.grain, w.daysCount(a.days)),
      WeatherRisk.drySpell => (w.drySpell, Icons.format_color_reset_outlined, w.dryDetail(a.days)),
      WeatherRisk.wetSpell => (w.wetSpell, Icons.water_drop_outlined, w.wetDetail(a.days)),
    };

/// One warning. [compact]: title and dates only (the Grow card); otherwise
/// also the detail line, on a tinted background (the Weather screen).
class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert, this.compact = false});
  final WeatherAlert alert;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final w = context.s.weather;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final (title, icon, detail) = alertText(w, alert);
    final body = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: compact ? 20 : 24, color: c.error),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: t.titleSmall),
          Text(alertWhen(w, alert), style: t.bodySmall),
          if (!compact) Text(detail, style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
        ]),
      ),
    ]);
    if (compact) return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: body);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: c.error, width: 4)),
      ),
      child: body,
    );
  }
}

/// One day as a small column (Grow card: the next three days side by side).
class DayColumn extends StatelessWidget {
  const DayColumn({super.key, required this.day, required this.now});
  final DayForecast day;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final w = context.s.weather;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Column(children: [
      Text(dayLabel(w, day.date, now), style: t.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 4),
      Icon(weatherIcon(day.code), color: c.primary),
      const SizedBox(height: 4),
      Text('${_deg(day.tMax)} / ${_deg(day.tMin)}', style: t.bodyMedium),
      Text(_mm(day.rainMm), style: t.bodySmall),
    ]);
  }
}

/// One day as a row (Weather screen: the 14-day list). [flagged]: part of a warning.
class DayRow extends StatelessWidget {
  const DayRow({super.key, required this.day, required this.now, required this.flagged});
  final DayForecast day;
  final DateTime now;
  final bool flagged;

  @override
  Widget build(BuildContext context) {
    final w = context.s.weather;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      color: flagged ? c.errorContainer.withValues(alpha: 0.18) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Icon(weatherIcon(day.code), color: c.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(dayLabel(w, day.date, now),
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyLarge?.copyWith(fontWeight: flagged ? FontWeight.w700 : null)),
              ),
              if (flagged) ...[
                const SizedBox(width: 6),
                Icon(Icons.warning_amber_rounded, size: 16, color: c.error),
              ],
            ]),
            Text('${_deg(day.tMax)} / ${_deg(day.tMin)}', style: t.bodySmall),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.water_drop_outlined, size: 14, color: c.primary),
            const SizedBox(width: 2),
            Text(_mm(day.rainMm), style: t.bodyMedium),
          ]),
          Text(
            [
              if (day.rainChance != null) '${day.rainChance}%',
              if ((day.gustKmh ?? 0) >= 40) '${day.gustKmh!.round()} km/h',
            ].join(' · '),
            style: t.bodySmall,
          ),
        ]),
      ]),
    );
  }
}

String _deg(double? v) => v == null ? '–' : '${v.round()}°';
String _mm(double? v) => v == null ? '–' : '${v.round()} mm';
