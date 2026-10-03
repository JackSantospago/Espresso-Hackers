import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_embeddings/flutter_edge_ai_embeddings.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';
import 'package:flutter_edge_ai_sqlite/flutter_edge_ai_sqlite.dart';
import 'package:path_provider/path_provider.dart';

import 'brain.dart';
import 'chat_page.dart';
import 'config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterEdgeAi.initialize(
    inferenceEngines: [LiteRtLmEngine()],
    embeddingBackends: [LiteRtEmbeddingBackend()],
    embeddingTokenizers: [GemmaEmbeddingTokenizers()],
    vectorStore: SqliteVectorStore(),
    // `kind` separates knowledge passages from memories. Undeclared filter
    // fields are silently ignored, and the schema is fixed when the DB is created.
    filterSchema: const FilterSchema(fields: [
      FilterField(name: 'kind', type: FilterFieldType.string),
    ]),
    huggingFaceToken: hfToken.isEmpty ? null : hfToken,
  );
  await Brain.open();
  runApp(const FieldAssistantApp());
}

class FieldAssistantApp extends StatelessWidget {
  const FieldAssistantApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Field Assistant',
        theme: ThemeData(colorSchemeSeed: Colors.green),
        home: const SetupGate(),
      );
}

/// Marker written once both models are on disk and the knowledge is indexed.
/// After that the app never touches the network.
Future<File> _readyMarker() async =>
    File('${(await getApplicationDocumentsDirectory()).path}/models_ready.txt');
String get _readyKey => '${activeLlm.fileName}|${activeEmbedder.fileName}';

class SetupGate extends StatefulWidget {
  const SetupGate({super.key});
  @override
  State<SetupGate> createState() => _SetupGateState();
}

class _SetupGateState extends State<SetupGate> {
  bool? _ready;
  String _status = '';
  double? _progress;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final f = await _readyMarker();
    final ok = await f.exists() &&
        (await f.readAsString()) == _readyKey &&
        await FlutterEdgeAi.isModelInstalled(activeLlm.fileName);
    if (mounted) setState(() => _ready = ok);
  }

  Future<void> _setup() async {
    setState(() {
      _error = null;
      _status = 'Downloading ${activeLlm.label} (${activeLlm.sizeLabel})…';
      _progress = 0;
    });
    try {
      await FlutterEdgeAi.installModel(
        modelType: activeLlm.modelType,
        fileType: ModelFileType.litertlm,
      )
          .fromNetwork(activeLlm.url)
          .withProgress((p) {
            if (mounted) setState(() => _progress = p / 100);
          })
          .install();

      setState(() {
        _status = 'Downloading ${activeEmbedder.label} (${activeEmbedder.sizeLabel})…';
        _progress = 0;
      });
      final token = hfToken.isEmpty ? null : hfToken;
      await FlutterEdgeAi.installEmbedder()
          .modelFromNetwork(activeEmbedder.modelUrl, token: token)
          .tokenizerFromNetwork(activeEmbedder.tokenizerUrl, token: token)
          .withModelProgress((p) {
            if (mounted) setState(() => _progress = p / 100);
          })
          .install();

      setState(() => _progress = null);
      await Brain.indexKnowledge(
        force: true,
        onStatus: (s) {
          if (mounted) setState(() => _status = s);
        },
      );
      await (await _readyMarker()).writeAsString(_readyKey);
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_ready!) return const ChatPage();

    final busy = _status.isNotEmpty && _error == null;
    return Scaffold(
      appBar: AppBar(title: const Text('Field Assistant – setup')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'One-time download: ${activeLlm.label} (${activeLlm.sizeLabel}) + '
              '${activeEmbedder.label} (${activeEmbedder.sizeLabel}). '
              'After this everything runs offline on the phone.',
            ),
            const SizedBox(height: 24),
            if (busy) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(_status, textAlign: TextAlign.center),
            ] else
              FilledButton(onPressed: _setup, child: const Text('Download & set up')),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                'Setup failed: $_error\n\n'
                '${activeEmbedder.gated ? 'EmbeddingGemma is gated: accept its licence on huggingface.co and run with --dart-define=HF_TOKEN=hf_…' : ''}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
