import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/strings.dart';
import '../../services/assistant.dart';
import '../../services/brain.dart';
import '../../services/outbox.dart';
import '../../services/weather_sync.dart';
import '../shared/farm_data.dart';
import '../shared/guides.dart';
import '../shared/ui.dart';
import 'guides_screen.dart';
import 'memory_screen.dart';
import 'outbox_screen.dart';
import 'weather_screen.dart';
import 'weather_widgets.dart';

/// "Grow": the farm at a glance, built only on things that are true offline.
///  - Weather: the farm's forecast and warnings (downloaded whenever the phone
///    is online, so the last one is always there), and "What should I do?".
///  - Your farm: what the app remembers, plus notes the farmer adds herself.
///  - Guides: the sourced material answers come from, readable directly.
///  - Extension officer: photos waiting for a person to review.
class GrowScreen extends StatefulWidget {
  const GrowScreen({super.key, required this.assistant, this.data = const FarmData(), this.weather, this.onAsk});
  final Assistant assistant;
  final FarmData data;

  /// The farm's forecast. Null: no Weather card (e.g. a test of the other cards).
  final WeatherSync? weather;

  /// Ask the assistant a question (switches to the Ask tab).
  final void Function(String question)? onAsk;

  @override
  State<GrowScreen> createState() => _GrowScreenState();
}

class _GrowScreenState extends State<GrowScreen> {
  List<MemoryItem>? _facts;
  List<OutboxItem>? _outbox;
  List<Guide>? _guides;
  bool _sending = false;
  AppLanguage? _language;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // First build, and again when the farmer picks another language: the guides are translated.
    final language = SettingsScope.of(context).language;
    if (language != _language) {
      _language = language;
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final d = widget.data;
    final results = await Future.wait([
      d.memories().catchError((Object _) => <MemoryItem>[]),
      d.outbox().catchError((Object _) => <OutboxItem>[]),
      d.guides(_language ?? AppLanguage.en).catchError((Object _) => <Guide>[]),
    ]);
    if (!mounted) return;
    setState(() {
      _facts = results[0] as List<MemoryItem>;
      _outbox = results[1] as List<OutboxItem>;
      _guides = results[2] as List<Guide>;
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    await _refresh();
  }

  Future<void> _addNote() async {
    final s = context.s;
    final messenger = ScaffoldMessenger.of(context);
    final note = await showDialog<String>(context: context, builder: (_) => const _NoteDialog());
    if (note == null || note.trim().isEmpty) return;
    await widget.data.remember(note);
    await widget.assistant.refreshMemoryCount();
    await _refresh();
    messenger.showSnackBar(SnackBar(content: Text(s.noteSaved)));
  }

  Future<void> _sendNow() async {
    final s = context.s;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    final report = await widget.data.sendPending();
    if (!mounted) return;
    setState(() => _sending = false);
    messenger.showSnackBar(SnackBar(content: Text(describeSendReport(s, report))));
    await widget.assistant.refreshOutbox();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final facts = _facts, outbox = _outbox, guides = _guides;
    return Scaffold(
      body: SafeArea(
        child: facts == null || outbox == null || guides == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    PageHeader(title: s.tabGrow),
                    if (widget.weather != null) ...[
                      ListenableBuilder(
                        listenable: widget.weather!,
                        builder: (context, _) => Column(children: _weatherGroup(context, widget.weather!)),
                      ),
                      const SizedBox(height: 24),
                    ],
                    ..._farm(context, facts),
                    const SizedBox(height: 24),
                    ..._guidesGroup(context, guides, facts),
                    const SizedBox(height: 24),
                    ..._officer(context, outbox),
                  ],
                ),
              ),
      ),
    );
  }

  /// Off: what weather does, and a button to turn it on (the screen explains
  /// what is sent). On: freshness, the next three days, the warnings, advice.
  List<Widget> _weatherGroup(BuildContext context, WeatherSync weather) {
    final w = context.s.weather;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();
    final f = weather.forecast;
    final days = weather.upcoming;
    final alerts = weather.alerts;
    void open({bool askNow = false}) =>
        _open(WeatherScreen(weather: weather, assistant: widget.assistant, askNow: askNow));
    final note = weather.updating ? w.updating : weatherProblemText(w, weather.problem);

    return [
      SectionLabel(
        w.title,
        action: weather.enabled ? context.s.seeAll : null,
        onAction: weather.enabled ? open : null,
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (!weather.enabled) ...[
              Text(w.intro, style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: open,
                icon: const Icon(Icons.my_location, size: 20),
                label: Text(w.setUp),
              ),
            ] else if (f == null)
              Text(w.waiting, style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant))
            else if (days.isEmpty) // every forecast day is in the past
              Text(w.stale(w.ago(f.age(now))), style: t.bodyMedium?.copyWith(color: c.tertiary))
            else ...[
              Text(w.updated(w.ago(f.age(now))), style: t.bodySmall),
              const SizedBox(height: 10),
              Row(children: [
                for (final d in days.take(3)) Expanded(child: DayColumn(day: d, now: now)),
              ]),
              const SizedBox(height: 8),
              const Divider(),
              if (alerts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Icon(Icons.check_circle_outline, size: 20, color: c.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(w.noAlerts, style: t.bodyMedium)),
                  ]),
                )
              else
                for (final a in alerts.take(3)) AlertTile(alert: a, compact: true),
              if (weather.stale) Text(w.stale(w.ago(f.age(now))), style: t.bodySmall?.copyWith(color: c.tertiary)),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: () => open(askNow: true),
                icon: const Icon(Icons.health_and_safety_outlined),
                label: Text(w.askWhatToDo),
              ),
            ],
            if (weather.enabled && note != null) ...[
              const SizedBox(height: 8),
              Text(note, style: t.bodySmall?.copyWith(color: c.tertiary)),
            ],
          ]),
        ),
      ),
    ];
  }

  List<Widget> _farm(BuildContext context, List<MemoryItem> facts) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    return [
      SectionLabel(
        s.farmTitle,
        action: s.seeAll,
        onAction: facts.isEmpty ? null : () => _open(MemoryScreen(assistant: widget.assistant, data: widget.data)),
      ),
      GroupCard(children: [
        if (facts.isEmpty) RowTile(title: s.memoryEmpty, titleStyle: Theme.of(context).textTheme.bodyMedium),
        for (final f in facts.take(3)) RowTile(icon: Icons.spa_outlined, title: memoryText(s, f)),
        RowTile(
          icon: Icons.add_rounded,
          iconColor: c.primary,
          title: s.addNote,
          titleStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: c.primary, fontWeight: FontWeight.w600),
          trailing: const SizedBox.shrink(),
          onTap: _addNote,
        ),
      ]),
    ];
  }

  List<Widget> _guidesGroup(BuildContext context, List<Guide> guides, List<MemoryItem> facts) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final openAll = guides.length <= 3 ? null : () => _open(GuidesScreen(guides: guides, onAsk: widget.onAsk));
    return [
      SectionLabel(s.guidesTitle, action: s.seeAllGuides(guides.length), onAction: openAll),
      if (guides.isEmpty)
        GroupCard(children: [RowTile(title: s.guidesEmpty)])
      else
        GroupCard(children: [
          for (final g in _forFarm(guides, facts).take(3))
            GuideTile(guide: g, onTap: () => showGuide(context, g, onAsk: widget.onAsk)),
        ]),
      // The trust line: where answers come from, and that it works offline.
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.verified_outlined, size: 15, color: c.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(s.guidesNote, style: t.bodySmall)),
        ]),
      ),
    ];
  }

  List<Widget> _officer(BuildContext context, List<OutboxItem> outbox) {
    final s = context.s;
    final waiting = outbox.where((i) => !i.sent).length;
    final sent = outbox.length - waiting;
    return [
      SectionLabel(
        s.outboxTitle,
        action: s.seeAll,
        onAction: outbox.isEmpty ? null : () => _open(OutboxScreen(assistant: widget.assistant, data: widget.data)),
      ),
      GroupCard(children: [
        RowTile(
          icon: Icons.support_agent_outlined,
          title: outbox.isEmpty ? s.outboxEmpty : s.officerSummary(waiting, sent),
        ),
        if (waiting > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: FilledButton.tonal(
              onPressed: _sending ? null : _sendNow,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              child: _sending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(s.sendNow(waiting)),
            ),
          ),
      ]),
    ];
  }
}

/// Guides for the crops the farmer has mentioned come first (from her own facts
/// only); the rest keep their order.
List<Guide> _forFarm(List<Guide> guides, List<MemoryItem> facts) {
  final said = facts.map((f) => f.text.toLowerCase()).join(' ');
  bool mentioned(GuideCrop crop) => switch (crop) {
        GuideCrop.coffee => said.contains('coffee') || said.contains('kahawa') || said.contains('café'),
        GuideCrop.maize => said.contains('maize') || said.contains('corn') || said.contains('mahindi') || said.contains('maïs'),
        GuideCrop.beans => said.contains('bean') || said.contains('maharagwe') || said.contains('haricot'),
        GuideCrop.more => false,
      };
  return [...guides.where((g) => mentioned(g.crop)), ...guides.where((g) => !mentioned(g.crop))];
}

/// "Add a note": owns its text controller so it outlives the closing animation.
class _NoteDialog extends StatefulWidget {
  const _NoteDialog();

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(s.addNote),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: s.addNoteHint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _controller.text), child: Text(s.save)),
      ],
    );
  }
}
