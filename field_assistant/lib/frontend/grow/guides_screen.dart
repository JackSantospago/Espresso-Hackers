import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/strings.dart';
import '../shared/guides.dart';
import '../shared/ui.dart';

/// Icon for a guide, from words in its (English) file name: pests, diseases, soil, water…
IconData guideIcon(Guide g) {
  final t = g.source.toLowerCase();
  bool any(List<String> words) => words.any(t.contains);
  if (any(['borer', 'armyworm', 'miner', 'pest', 'insect'])) return Icons.bug_report_outlined;
  if (any(['rust', 'blight', 'spot', 'disease'])) return Icons.coronavirus_outlined;
  if (any(['soil', 'compost', 'liming', 'nutrient'])) return Icons.landscape_outlined;
  if (any(['water', 'dryland', 'climate'])) return Icons.water_drop_outlined;
  if (any(['storage', 'aflatoxin'])) return Icons.inventory_2_outlined;
  if (any(['rotation', 'intercropping'])) return Icons.autorenew_rounded;
  return Icons.spa_outlined;
}

String cropLabel(S s, GuideCrop crop) => switch (crop) {
      GuideCrop.coffee => s.guidesCoffee,
      GuideCrop.maize => s.guidesMaize,
      GuideCrop.beans => s.guidesBeans,
      GuideCrop.more => s.guidesMore,
    };

/// One guide in a list: plain icon, title, crop.
class GuideTile extends StatelessWidget {
  const GuideTile({super.key, required this.guide, required this.onTap});
  final Guide guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => RowTile(
        icon: guideIcon(guide),
        title: guide.title,
        subtitle: cropLabel(context.s, guide.crop),
        onTap: onTap,
      );
}

/// Opens a guide to read: sections with their sources, and a shortcut to ask
/// the assistant about it.
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
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, scroll) => Column(children: [
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              children: [
                Text(cropLabel(s, guide.crop), style: t.labelLarge?.copyWith(color: c.primary)),
                const SizedBox(height: 8),
                Text(guide.title, style: t.headlineSmall),
                if (guide.summary.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(guide.summary, style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
                ],
                for (final sec in guide.sections) ...[
                  const SizedBox(height: 20),
                  if (sec.heading.isNotEmpty) ...[
                    Text(sec.heading, style: t.titleSmall),
                    const SizedBox(height: 6),
                  ],
                  Text(sec.text, style: t.bodyLarge?.copyWith(height: 1.55)),
                  if (sec.sources.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(Icons.verified_outlined, size: 14, color: c.primary),
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text('${s.sources} ${sec.sources}', style: t.labelSmall?.copyWith(color: c.onSurfaceVariant))),
                    ]),
                  ],
                ],
              ],
            ),
          ),
          if (onAsk != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onAsk(s.askAbout(guide.title));
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(s.askAboutThis),
                  ),
                ),
              ),
            ),
        ]),
      );
    },
  );
}

/// Every guide on the phone, with crop filters and search.
class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key, required this.guides, this.onAsk});
  final List<Guide> guides;
  final void Function(String question)? onAsk;

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  GuideCrop? _crop;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final g in widget.guides)
        if ((_crop == null || g.crop == _crop) && (q.isEmpty || g.text.toLowerCase().contains(q))) g,
    ];
    final crops = GuideCrop.values.where((cr) => widget.guides.any((g) => g.crop == cr)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.guidesTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: s.guidesSearch,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final cr in <GuideCrop?>[null, ...crops])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cr == null ? s.guidesAll : cropLabel(s, cr)),
                    selected: _crop == cr,
                    onSelected: (_) => setState(() => _crop = cr),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(widget.guides.isEmpty ? s.guidesEmpty : s.guidesNoMatch,
                  textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
            )
          else
            GroupCard(children: [
              for (final g in shown)
                GuideTile(guide: g, onTap: () => showGuide(context, g, onAsk: widget.onAsk == null ? null : _askAndClose)),
            ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.verified_outlined, size: 16, color: c.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(s.guidesNote, style: t.bodySmall)),
          ]),
        ],
      ),
    );
  }

  /// "Ask about this" from the full list: leave the list, then ask.
  void _askAndClose(String question) {
    Navigator.pop(context);
    widget.onAsk!(question);
  }
}
