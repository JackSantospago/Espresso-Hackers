import 'dart:io';

import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:path_provider/path_provider.dart';

import '../core/config.dart';
import 'brain.dart';

enum SetupStep { llm, embedder, indexing }

/// One-time download of the LLM + embedder and indexing of the knowledge base.
/// A marker file is written once everything is on disk; after that the app
/// never touches the network.
class ModelSetup {
  static Future<File> _readyMarker() async =>
      File('${(await getApplicationDocumentsDirectory()).path}/models_ready.txt');
  static String get _readyKey => '${activeLlm.fileName}|${activeEmbedder.fileName}';

  static Future<bool> isReady() async {
    final f = await _readyMarker();
    return await f.exists() &&
        (await f.readAsString()) == _readyKey &&
        await FlutterEdgeAi.isModelInstalled(activeLlm.fileName);
  }

  /// [onProgress] gets the current step and a 0..1 fraction (null = unknown).
  static Future<void> run({required void Function(SetupStep step, double? progress) onProgress}) async {
    onProgress(SetupStep.llm, 0);
    await FlutterEdgeAi.installModel(
      modelType: activeLlm.modelType,
      fileType: ModelFileType.litertlm,
    )
        .fromNetwork(activeLlm.url)
        .withProgress((p) => onProgress(SetupStep.llm, p / 100))
        .install();

    onProgress(SetupStep.embedder, 0);
    final token = hfToken.isEmpty ? null : hfToken;
    await FlutterEdgeAi.installEmbedder()
        .modelFromNetwork(activeEmbedder.modelUrl, token: token)
        .tokenizerFromNetwork(activeEmbedder.tokenizerUrl, token: token)
        .withModelProgress((p) => onProgress(SetupStep.embedder, p / 100))
        .install();

    onProgress(SetupStep.indexing, null);
    await Brain.indexKnowledge(force: true);
    await (await _readyMarker()).writeAsString(_readyKey);
  }
}
