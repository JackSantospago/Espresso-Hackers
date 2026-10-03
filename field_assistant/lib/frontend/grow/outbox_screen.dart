import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/strings.dart';
import '../../services/assistant.dart';
import '../../services/outbox.dart';
import '../shared/farm_data.dart';

/// "Officer": photos the farmer chose to send for human review. She can see
/// everything queued, send it now, or delete it before it goes.
class OutboxScreen extends StatefulWidget {
  const OutboxScreen({super.key, required this.assistant, this.data = const FarmData(), this.embedded = false});
  final Assistant assistant;
  final FarmData data;

  /// Shown as a tab inside Grow: no app bar of its own.
  final bool embedded;

  @override
  State<OutboxScreen> createState() => _OutboxScreenState();
}

class _OutboxScreenState extends State<OutboxScreen> {
  List<OutboxItem>? _items;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final items = await widget.data.outbox();
    if (mounted) setState(() => _items = items);
    await widget.assistant.refreshOutbox();
  }

  Future<void> _sendNow() async {
    final s = context.s;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    final report = await widget.data.sendPending();
    if (!mounted) return;
    setState(() => _sending = false);
    messenger.showSnackBar(SnackBar(content: Text(describeSendReport(s, report))));
    await _refresh();
  }

  Future<void> _delete(OutboxItem item) async {
    final s = context.s;
    if (!item.sent) {
      // Unsent photo: deleting it means the officer never sees it, so confirm.
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(s.deletePhotoConfirm),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s.delete)),
          ],
        ),
      );
      if (ok != true) return;
    }
    await widget.data.removeFromOutbox(item);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final items = _items;
    final pending = items?.where((i) => !i.sent).length ?? 0;

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: Text(s.outboxTitle)),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.secondaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.privacy_tip_outlined, color: c.secondary),
                      const SizedBox(width: 12),
                      Expanded(child: Text(s.outboxIntro)),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 8),
                      child: Column(children: [
                        Icon(Icons.outbox_outlined, size: 56, color: c.outline),
                        const SizedBox(height: 12),
                        Text(s.outboxEmpty, textAlign: TextAlign.center, style: t.bodyLarge),
                      ]),
                    )
                  else
                    for (final item in items) _OutboxCard(item: item, onDelete: () => _delete(item)),
                ],
              ),
            ),
      bottomNavigationBar: items == null || items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: pending == 0 || _sending ? null : _sendNow,
                  icon: _sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(pending == 0 ? s.nothingToSend : s.sendNow(pending)),
                ),
              ),
            ),
    );
  }
}

String describeSendReport(S s, SendReport r) {
  if (r.sent == 0 && r.waiting == 0) return s.sendNothing;
  if (r.noServer) return s.sendNoServer(r.waiting);
  if (r.sent == 0) return s.sendOffline(r.waiting);
  return s.sendDone(r.sent, r.waiting);
}

class _OutboxCard extends StatelessWidget {
  const _OutboxCard({required this.item, required this.onDelete});
  final OutboxItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final guess = item.modelGuess;
    final placeholder =
        Container(width: 96, height: 96, color: c.surfaceContainerHighest, child: const Icon(Icons.broken_image_outlined));
    final guessText = guess == null
        ? null
        : '${s.appGuess}: ${_prettyLabel(guess['label'] as String? ?? '?')}'
            '${guess['probability'] is num ? ' · ${((guess['probability'] as num) * 100).round()}%' : ''}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // No files in the browser preview (main_preview.dart): show the placeholder.
          kIsWeb
              ? placeholder
              : Image.file(item.photo, width: 96, height: 96, fit: BoxFit.cover, errorBuilder: (context, _, _) => placeholder),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  item.note.isEmpty ? s.noNote : item.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyLarge,
                ),
                if (guessText != null) ...[
                  const SizedBox(height: 2),
                  Text(guessText, style: t.bodySmall?.copyWith(color: c.onSurfaceVariant)),
                ],
                const SizedBox(height: 6),
                Row(children: [
                  _StatusChip(sent: item.sent),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item.created.toLocal().toString().substring(0, 16),
                      style: t.labelSmall?.copyWith(color: c.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ]),
            ),
          ),
          IconButton(tooltip: s.delete, onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
        ]),
      ),
    );
  }

  static String _prettyLabel(String id) => id.replaceAll('__', ' – ').replaceAll('_', ' ');
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.sent});
  final bool sent;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final color = sent ? c.primary : c.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(sent ? Icons.cloud_done_outlined : Icons.schedule_outlined, size: 14, color: color),
        const SizedBox(width: 4),
        Text(sent ? s.statusSent : s.statusWaiting,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
