import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../services/assistant.dart';
import '../../services/brain.dart';
import '../../services/outbox.dart';
import '../shared/farm_data.dart';
import '../shared/guides.dart';
import '../shared/ui.dart';
import 'guides_screen.dart';
import 'memory_screen.dart';
import 'outbox_screen.dart';

/// "Grow": the farm at a glance, built only on things that are true offline.
///  - Your farm: what the app remembers, plus notes the farmer adds herself.
///  - Guides: the sourced material answers come from, readable directly.
///  - Extension officer: photos waiting for a person to review.
class GrowScreen extends StatefulWidget {
  const GrowScreen({super.key, required this.assistant, this.data = const FarmData(), this.onAsk});
  final Assistant assistant;
  final FarmData data;

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

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final d = widget.data;
    final results = await Future.wait([
      d.memories().catchError((Object _) => <MemoryItem>[]),
      d.outbox().catchError((Object _) => <OutboxItem>[]),
      d.guides().catchError((Object _) => <Guide>[]),
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
        for (final f in facts.take(3)) RowTile(icon: Icons.spa_outlined, title: f.text),
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
