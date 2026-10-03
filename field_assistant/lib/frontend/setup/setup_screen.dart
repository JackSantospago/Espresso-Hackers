import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/config.dart';
import '../../services/model_setup.dart';
import '../shared/language_picker.dart';

/// First launch: pick a language, understand the promise (private, honest,
/// you decide), then the one-time model download.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _running = false;
  SetupStep? _step;
  double? _progress;
  Object? _error;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      await ModelSetup.run(onProgress: (step, progress) {
        if (mounted) {
          setState(() {
            _step = step;
            _progress = progress;
          });
        }
      });
      widget.onDone();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _running = false;
        });
      }
    }
  }

  String _stepLabel() {
    final s = context.s;
    return switch (_step) {
      SetupStep.llm => s.setupDownloading(activeLlm.label, activeLlm.sizeLabel),
      SetupStep.embedder => s.setupDownloading(activeEmbedder.label, activeEmbedder.sizeLabel),
      SetupStep.indexing || null => s.setupIndexing,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    const points = [Icons.lock_outline, Icons.support_agent_outlined, Icons.how_to_reg_outlined];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Row(children: [
              Icon(Icons.translate, size: 20, color: c.onSurfaceVariant),
              const SizedBox(width: 8),
              const Expanded(child: LanguagePicker()),
            ]),
            const SizedBox(height: 32),
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: c.primaryContainer,
                child: Icon(Icons.eco, size: 48, color: c.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 20),
            Text(s.appName, textAlign: TextAlign.center, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(s.setupIntro, textAlign: TextAlign.center, style: t.bodyLarge?.copyWith(color: c.onSurfaceVariant)),
            const SizedBox(height: 28),
            for (var i = 0; i < s.setupPoints.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: c.secondaryContainer,
                    child: Icon(points[i % points.length], color: c.onSecondaryContainer, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(s.setupPoints[i], style: t.bodyLarge),
                    ),
                  ),
                ]),
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.download_for_offline_outlined, color: c.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s.setupDownload(
                      activeLlm.label,
                      activeLlm.sizeLabel,
                      activeEmbedder.label,
                      activeEmbedder.sizeLabel,
                    )),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            if (_running) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: _progress, minHeight: 10),
              ),
              const SizedBox(height: 10),
              Text(
                _progress == null ? _stepLabel() : '${_stepLabel()}  ${(_progress! * 100).round()}%',
                textAlign: TextAlign.center,
              ),
            ] else
              FilledButton.icon(
                onPressed: _run,
                icon: Icon(_error == null ? Icons.download : Icons.refresh),
                label: Text(_error == null ? s.setupButton : s.retry),
              ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: c.errorContainer, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '${s.setupFailed}: $_error'
                  '${activeEmbedder.gated ? '\n\nEmbeddingGemma is gated: accept its licence on huggingface.co '
                      'and run with --dart-define=HF_TOKEN=hf_…' : ''}',
                  style: TextStyle(color: c.onErrorContainer),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
