import 'package:flutter/material.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_embeddings/flutter_edge_ai_embeddings.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';
import 'package:flutter_edge_ai_sqlite/flutter_edge_ai_sqlite.dart';

import 'app.dart';
import 'core/app_settings.dart';
import 'core/config.dart';
import 'services/brain.dart';
import 'services/weather_sync.dart';

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
  await WeatherSync.initBackground(); // background forecast refresh (scheduled once weather is on)
  final settings = AppSettings();
  await settings.load();
  runApp(FieldAssistantApp(settings: settings));
}
