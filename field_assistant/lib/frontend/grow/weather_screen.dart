import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/strings.dart';
import '../../services/assistant.dart';
import '../../services/weather_sync.dart';
import '../chatbot/widgets/message_bubble.dart';
import 'weather_widgets.dart';

/// Grow → Weather: the farm's 14-day forecast, the warnings the app's rules
/// found, and "What should I do?" (advice for the crops from the on-device LLM).
/// Weather is opt-in: until the farmer saves the farm's location, this screen
/// explains what is sent and to whom.
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key, required this.weather, required this.assistant, this.askNow = false});
  final WeatherSync weather;
  final Assistant assistant;

  /// Opened from the Grow card's "What should I do?": start the advice right away.
  final bool askNow;

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  WeatherSync get _weather => widget.weather;
  Assistant get _assistant => widget.assistant;

  @override
  void initState() {
    super.initState();
    if (widget.askNow) WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  /// No warnings: a fixed answer, so it works even without the model.
  bool get _canAsk => !_assistant.busy && (_assistant.ready || _weather.alerts.isEmpty);

  void _ask() {
    final f = _weather.forecast;
    if (f != null && _canAsk) _assistant.assessWeather(f, _weather.alerts);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([_weather, _assistant]),
        builder: (context, _) {
          final w = context.s.weather;
          return Scaffold(
            appBar: AppBar(title: Text(w.screenTitle)),
            body: _weather.enabled ? _forecast(context, w) : _turnOn(context, w),
          );
        },
      );

  // ------------------------------------------------------------- weather off

  Widget _turnOn(BuildContext context, WeatherStrings w) {
    final c = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(w.intro, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        _Banner(icon: Icons.lock_outline, text: w.privacyNote, color: c.primary),
        ..._problem(context, w),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _weather.locating ? null : _weather.setFarmHere,
          icon: _weather.locating
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location),
          label: Text(_weather.locating ? w.locating : w.turnOn),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- weather on

  Widget _forecast(BuildContext context, WeatherStrings w) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final f = _weather.forecast;
    final farm = _weather.farm!;
    final days = _weather.upcoming;
    final alerts = _weather.alerts;
    final advice = _assistant.weatherAdvice;
    // Advice for an older forecast is hidden, unless it is still being written.
    final showAdvice =
        advice != null && f != null && (_assistant.weatherAdviceFor == f.fetchedAt || _assistant.weatherBusy);
    final now = DateTime.now();

    return RefreshIndicator(
      onRefresh: () => _weather.refresh(force: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // Where, and how fresh
          Row(children: [
            Icon(Icons.place_outlined, size: 18, color: c.primary),
            const SizedBox(width: 6),
            Expanded(child: Text(w.farmAt(farm.label, f?.elevation?.round()), style: t.bodyMedium)),
          ]),
          Row(children: [
            if (_weather.updating)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(Icons.schedule, size: 16, color: c.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text(_freshness(w, now), style: t.bodySmall)),
            IconButton(
              tooltip: w.updating,
              onPressed: _weather.updating ? null : () => _weather.refresh(force: true),
              icon: const Icon(Icons.refresh),
            ),
          ]),
          ..._problem(context, w),
          if (_weather.stale && !_weather.updating) ...[
            const SizedBox(height: 10),
            _Banner(icon: Icons.history, text: w.stale(w.ago(f!.age(now))), color: c.tertiary),
          ],
          if (f != null && days.isNotEmpty) ...[
            // Warnings, from the rules
            _Heading(w.warningsTitle),
            if (alerts.isEmpty)
              _Banner(icon: Icons.check_circle_outline, text: w.noAlerts, color: c.primary)
            else
              for (final a in alerts) AlertTile(alert: a),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _canAsk ? _ask : null,
              icon: const Icon(Icons.health_and_safety_outlined),
              label: Text(w.askWhatToDo),
            ),
            if (!_assistant.ready && alerts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_assistant.state == AssistantState.failed ? s.loadFailed : s.loadingModel,
                    textAlign: TextAlign.center, style: t.bodySmall),
              ),
            if (showAdvice)
              MessageBubble(turn: advice, streaming: _assistant.weatherBusy, status: _assistant.weatherStatus),
            // The days
            _Heading(w.nextDays(days.length)),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (var i = 0; i < days.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  DayRow(day: days[i], now: now, flagged: alerts.any((a) => alertCovers(a, days[i].date))),
                ],
              ]),
            ),
          ],
          const SizedBox(height: 16),
          Text(w.attribution, textAlign: TextAlign.center, style: t.labelSmall?.copyWith(color: c.onSurfaceVariant)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _weather.locating ? null : _weather.setFarmHere,
            icon: const Icon(Icons.my_location, size: 18),
            label: Text(_weather.locating ? w.locating : w.farmHere),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _weather.locating ? null : () => _confirmTurnOff(context),
            icon: const Icon(Icons.location_off_outlined, size: 18),
            label: Text(w.turnOff),
          ),
        ],
      ),
    );
  }

  String _freshness(WeatherStrings w, DateTime now) {
    final f = _weather.forecast;
    if (_weather.updating) return w.updating;
    if (f == null) return w.waiting;
    return w.updated(w.ago(f.age(now)));
  }

  List<Widget> _problem(BuildContext context, WeatherStrings w) {
    final text = weatherProblemText(w, _weather.problem);
    if (text == null) return const [];
    final fixable =
        _weather.problem == WeatherProblem.locationOff || _weather.problem == WeatherProblem.permissionDenied;
    return [
      const SizedBox(height: 10),
      _Banner(icon: Icons.report_outlined, text: text, color: Theme.of(context).colorScheme.tertiary),
      if (fixable)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: _weather.openSettings, child: Text(w.openSettings)),
        ),
    ];
  }

  Future<void> _confirmTurnOff(BuildContext context) async {
    final s = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.location_off_outlined),
        title: Text(s.weather.turnOff),
        content: Text(s.weather.turnOffConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s.weather.turnOff)),
        ],
      ),
    );
    if (ok == true) await _weather.turnOff();
  }
}

/// The farmer-facing sentence for a [WeatherProblem], or null when there is none.
String? weatherProblemText(WeatherStrings w, WeatherProblem p) => switch (p) {
      WeatherProblem.none => null,
      WeatherProblem.notUpdated => w.notUpdated,
      WeatherProblem.locationOff => w.locationOff,
      WeatherProblem.permissionDenied => w.permissionDenied,
      WeatherProblem.noFix => w.noFix,
    };

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ]),
      );
}
