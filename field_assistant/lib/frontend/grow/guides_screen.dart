import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../shared/guides.dart';

/// Icon for a guide, from words in its title (pests, diseases, pruning…).
IconData guideIcon(Guide g) {
  final t = g.title.toLowerCase();
  if (t.contains('borer') || t.contains('pest') || t.contains('insect')) return Icons.bug_report_outlined;
  if (t.contains('rust') || t.contains('disease') || t.contains('blight')) return Icons.coronavirus_outlined;
  if (t.contains('prun') || t.contains('stump')) return Icons.content_cut_rounded;
  if (t.contains('harvest') || t.contains('yield') || t.contains('older')) return Icons.agriculture_outlined;
  return Icons.menu_book_outlined;
}

/// One guide in a list: icon, title, source.
class GuideTile extends StatelessWidget {
  const GuideTile({super.key, required this.guide, required this.onTap});
  final Guide guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: c.primaryContainer, borderRadius: BorderRadius.circular(12)),
            child: Icon(guideIcon(guide), size: 20, color: c.onPrimaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(guide.title, style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(guide.source, style: t.bodySmall),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: c.onSurfaceVariant),
        ]),
      ),
    );
  }
}

/// Opens a guide to read, with its source and a shortcut to ask the assistant.
Future<void> showGuide(BuildContext context, Guide guide, {void Function(String question)? onAsk}) {
  final s = context.s;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final c = Theme.of(context).colorScheme;
      final t = Theme.of(context).textTheme;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Row(children: [
              Icon(guideIcon(guide), color: c.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: c.surfaceContainer, borderRadius: BorderRadius.circular(8)),
                  child: Text('${s.sources} ${guide.source}', style: t.labelSmall, overflow: TextOverflow.ellipsis),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Text(guide.title, style: t.headlineSmall),
            const SizedBox(height: 12),
            Text(guide.text, style: t.bodyLarge?.copyWith(height: 1.55)),
            if (onAsk != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onAsk(s.askAbout(guide.title));
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(s.askAboutThis),
              ),
            ],
          ],
        ),
      );
    },
  );
}

/// Every guide on the phone.
class GuidesScreen extends StatelessWidget {
  const GuidesScreen({super.key, required this.guides, this.onAsk});
  final List<Guide> guides;
  final void Function(String question)? onAsk;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(s.guidesTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(s.guidesNote, style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          if (guides.isEmpty)
            Padding(padding: const EdgeInsets.all(24), child: Text(s.guidesEmpty, textAlign: TextAlign.center))
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(children: [
                  for (var i = 0; i < guides.length; i++) ...[
                    if (i > 0) const Divider(),
                    GuideTile(
                      guide: guides[i],
                      onTap: () => showGuide(context, guides[i], onAsk: onAsk == null ? null : _askAndClose(context)),
                    ),
                  ],
                ]),
              ),
            ),
        ],
      ),
    );
  }

  /// "Ask about this" from the full list: leave the list, then ask.
  void Function(String) _askAndClose(BuildContext context) => (q) {
        Navigator.pop(context);
        onAsk!(q);
      };
}
