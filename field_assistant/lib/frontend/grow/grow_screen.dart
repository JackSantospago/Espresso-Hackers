import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../services/assistant.dart';
import '../../services/brain.dart';
import '../../services/outbox.dart';
import '../shared/farm_data.dart';
import '../shared/guides.dart';
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
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final facts = _facts, outbox = _outbox, guides = _guides;
    return Scaffold(
      appBar: AppBar(title: Text(s.tabGrow)),
      body: facts == null || outbox == null || guides == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Text(s.growIntro, style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  _farmCard(context, facts),
                  const SizedBox(height: 14),
                  _guidesCard(context, guides),
                  const SizedBox(height: 14),
                  _officerCard(context, outbox),
                ],
              ),
            ),
    );
  }

  Widget _farmCard(BuildContext context, List<MemoryItem> facts) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return _Section(
      icon: Icons.agriculture_outlined,
      title: s.farmTitle,
      subtitle: s.factsCount(facts.length),
      onSeeAll: facts.isEmpty ? null : () => _open(MemoryScreen(assistant: widget.assistant, data: widget.data)),
      children: [
        if (facts.isEmpty)
          Text(s.memoryEmpty, style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant))
        else
          for (final f in facts.take(3))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.spa_outlined, size: 18, color: c.primary),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(f.text, style: t.bodyMedium)),
              ]),
            ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _addNote,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(s.addNote),
        ),
      ],
    );
  }

  Widget _guidesCard(BuildContext context, List<Guide> guides) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return _Section(
      icon: Icons.menu_book_outlined,
      title: s.guidesTitle,
      children: [
        if (guides.isEmpty)
          Text(s.guidesEmpty, style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant))
        else
          for (var i = 0; i < guides.length && i < 3; i++) ...[
            if (i > 0) const Divider(),
            GuideTile(guide: guides[i], onTap: () => showGuide(context, guides[i], onAsk: widget.onAsk)),
          ],
        const SizedBox(height: 8),
        // The trust line: where answers come from, and that it works offline.
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.verified_outlined, size: 16, color: c.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(s.guidesNote, style: t.bodySmall)),
        ]),
        if (guides.length > 3) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _open(GuidesScreen(guides: guides, onAsk: widget.onAsk)),
              child: Text(s.seeAllGuides(guides.length)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _officerCard(BuildContext context, List<OutboxItem> outbox) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final waiting = outbox.where((i) => !i.sent).length;
    final sent = outbox.length - waiting;
    return _Section(
      icon: Icons.support_agent_outlined,
      title: s.outboxTitle,
      subtitle: outbox.isEmpty ? null : s.officerSummary(waiting, sent),
      onSeeAll: outbox.isEmpty
          ? null
          : () => _open(OutboxScreen(assistant: widget.assistant, data: widget.data)),
      children: [
        Text(outbox.isEmpty ? s.outboxEmpty : s.outboxIntro, style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
        if (waiting > 0) ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _sending ? null : _sendNow,
            icon: _sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(s.sendNow(waiting)),
          ),
        ],
      ],
    );
  }
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
      icon: const Icon(Icons.edit_note_rounded),
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

/// A card with an icon, a title (and optional count line), a "See all" link and content.
class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.children, this.subtitle, this.onSeeAll});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: c.primaryContainer, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: c.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t.titleMedium),
                if (subtitle != null) Text(subtitle!, style: t.bodySmall),
              ]),
            ),
            if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: Text(s.seeAll)),
          ]),
          const SizedBox(height: 12),
          ...children,
        ]),
      ),
    );
  }
}
