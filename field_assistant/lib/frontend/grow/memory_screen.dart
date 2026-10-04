import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../services/assistant.dart';
import '../../services/brain.dart';
import '../shared/farm_data.dart';

/// "My farm": everything the app remembers, visible and deletable by the farmer.
class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key, required this.assistant, this.data = const FarmData()});
  final Assistant assistant;
  final FarmData data;

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  List<MemoryItem>? _items;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final items = await widget.data.memories();
    if (mounted) setState(() => _items = items);
    await widget.assistant.refreshMemoryCount();
  }

  Future<void> _forget(MemoryItem m) async {
    final s = context.s;
    final messenger = ScaffoldMessenger.of(context);
    await widget.data.forget(m.id);
    await _refresh();
    messenger.showSnackBar(SnackBar(content: Text(s.forgotten)));
  }

  Future<void> _forgetAll() async {
    final s = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_outlined),
        title: Text(s.forgetAll),
        content: Text(s.forgetAllConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    for (final m in await widget.data.memories()) {
      await widget.data.forget(m.id);
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.memoryTitle),
        actions: [
          if (items != null && items.isNotEmpty)
            IconButton(tooltip: s.forgetAll, onPressed: _forgetAll, icon: const Icon(Icons.delete_sweep_outlined)),
        ],
      ),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _InfoBanner(icon: Icons.lock_outline, text: s.memoryIntro),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 8),
                      child: Column(children: [
                        Icon(Icons.agriculture_outlined, size: 56, color: c.outline),
                        const SizedBox(height: 12),
                        Text(s.memoryEmpty, textAlign: TextAlign.center, style: t.bodyLarge),
                      ]),
                    )
                  else
                    for (final m in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
                            leading: Icon(Icons.spa_outlined, color: c.onSurfaceVariant),
                            title: Text(memoryText(s, m), style: t.bodyLarge),
                            subtitle: Text(_date(m.date), style: t.bodySmall),
                            trailing: IconButton(
                              tooltip: s.forget,
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _forget(m),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}

String _date(DateTime d) => d.toLocal().toString().substring(0, 16);

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.surfaceContainer, borderRadius: BorderRadius.circular(16)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: c.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ]),
    );
  }
}
