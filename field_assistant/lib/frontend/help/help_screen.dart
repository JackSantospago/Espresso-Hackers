import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/config.dart';
import '../../services/assistant.dart';
import '../shared/language_picker.dart';
import '../shared/ui.dart';

/// "Help": language, the three promises, how it works in three steps, and what
/// runs on the phone. The full privacy notes and limits sit under "More details".
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, required this.assistant});
  final Assistant assistant;

  static const _promiseIcons = [Icons.lock_outline_rounded, Icons.support_agent_outlined, Icons.how_to_reg_outlined];
  static const _stepIcons = [Icons.chat_bubble_outline_rounded, Icons.menu_book_outlined, Icons.support_agent_outlined];

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final strong = t.bodyLarge?.copyWith(fontWeight: FontWeight.w600);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            PageHeader(title: s.helpTitle),
            SectionLabel(s.language),
            const Card(child: Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 12), child: LanguagePicker())),
            const SizedBox(height: 24),
            GroupCard(children: [
              for (var i = 0; i < s.promiseTitles.length; i++)
                RowTile(
                  icon: _promiseIcons[i % _promiseIcons.length],
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: s.promiseTitles[i],
                  titleStyle: strong,
                  subtitle: s.promiseTexts[i],
                ),
            ]),
            const SizedBox(height: 24),
            SectionLabel(s.howTitle),
            GroupCard(children: [
              for (var i = 0; i < s.howShort.length; i++)
                RowTile(icon: _stepIcons[i % _stepIcons.length], title: s.howShort[i]),
            ]),
            const SizedBox(height: 24),
            SectionLabel(s.onThisPhone),
            ListenableBuilder(
              listenable: assistant,
              builder: (context, _) => GroupCard(children: [
                RowTile(title: s.modelLlm, trailing: _Value('${activeLlm.label} · ${activeLlm.sizeLabel}')),
                RowTile(title: s.modelEmbedder, trailing: _Value(activeEmbedder.label)),
                RowTile(
                  title: s.modelLeaf,
                  trailing: _Value(assistant.classifier != null
                      ? '${assistant.classifier!.labels.length} classes · ${s.installed}'
                      : s.notInstalled),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            _Details(),
          ],
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.end,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
}

/// The full privacy notes and limits, folded away so the page stays short.
class _Details extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    Widget list(String title, List<String> items) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: t.titleSmall),
            const SizedBox(height: 6),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('·  $item', style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
              ),
          ]),
        );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Icon(Icons.info_outline_rounded, color: c.onSurfaceVariant),
          title: Text(s.moreDetails, style: t.bodyLarge),
          children: [
            list(s.privacyTitle, s.privacy),
            list(s.limitsTitle, s.limits),
            Text(s.answersLanguageNote, style: t.bodySmall),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
