import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/config.dart';
import '../../services/assistant.dart';
import '../widgets/language_picker.dart';

/// "Help": language, how the assistant works, where data lives, and its limits.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, required this.assistant});
  final Assistant assistant;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.helpTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _Section(
            icon: Icons.translate,
            title: s.language,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const LanguagePicker(),
              const SizedBox(height: 8),
              Text(s.answersLanguageNote, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          _Section(icon: Icons.lightbulb_outline, title: s.howTitle, child: _Steps(items: s.how)),
          _Section(icon: Icons.lock_outline, title: s.privacyTitle, child: _Bullets(items: s.privacy)),
          _Section(icon: Icons.do_not_disturb_on_outlined, title: s.limitsTitle, child: _Bullets(items: s.limits)),
          ListenableBuilder(
            listenable: assistant,
            builder: (context, _) => _Section(
              icon: Icons.phone_android,
              title: s.onThisPhone,
              child: Column(children: [
                _Row(label: s.modelLlm, value: '${activeLlm.label} · ${activeLlm.sizeLabel}'),
                _Row(label: s.modelEmbedder, value: '${activeEmbedder.label} · ${activeEmbedder.sizeLabel}'),
                _Row(
                  label: s.modelLeaf,
                  value: assistant.classifier != null
                      ? 'MobileNetV3 · ${assistant.classifier!.labels.length} classes · ${s.installed}'
                      : s.notInstalled,
                ),
                if (assistant.ready) _Row(label: '', value: s.passages(assistant.knowledgePassages)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.child});
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: c.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 12),
            child,
          ]),
        ),
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Column(children: [
      for (var i = 0; i < items.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: c.primaryContainer,
              child: Text('${i + 1}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.onPrimaryContainer)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(items[i])),
          ]),
        ),
    ]);
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Column(children: [
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(Icons.check_circle_outline, size: 16, color: c.primary),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(item)),
          ]),
        ),
    ]);
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 2, child: Text(label, style: t.bodySmall)),
        Expanded(flex: 3, child: Text(value, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
