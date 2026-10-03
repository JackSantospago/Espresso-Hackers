import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;

import 'package:flutter/services.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:path_provider/path_provider.dart';

/// One retrieved passage.
class Hit {
  const Hit(this.source, this.text, this.score);
  final String source, text;
  final double score;
}

/// One remembered fact about the farmer.
class MemoryItem {
  const MemoryItem(this.id, this.text, this.date);
  final String id, text;
  final DateTime date;

  Map<String, dynamic> toJson() =>
      {'id': id, 'text': text, 'date': date.toIso8601String()};
  static MemoryItem fromJson(Map<String, dynamic> j) =>
      MemoryItem(j['id'] as String, j['text'] as String, DateTime.parse(j['date'] as String));
}

/// Knowledge base + long-term memory. Both live in ONE on-device sqlite-vec
/// index, separated by the `kind` metadata field ('doc' | 'memory').
/// `kind` must be declared in FilterSchema in main.dart, or filters are ignored.
class Brain {
  static Future<String> _path(String name) async =>
      '${(await getApplicationDocumentsDirectory()).path}/$name';

  static Filter _kind(String k) => Filter(must: [FieldEquals(key: 'kind', value: k)]);

  static Future<void> open() async =>
      FlutterEdgeAi.rag.initialize(await _path('field_assistant.db'));

  // ---------------------------------------------------------------- knowledge

  /// Embeds every .md/.txt in assets/knowledge/ the first time (or when the
  /// files change). Returns the number of indexed passages.
  static Future<int> indexKnowledge({bool force = false, void Function(String)? onStatus}) async {
    final marker = File(await _path('kb_index.json'));
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest
        .listAssets()
        .where((a) => a.startsWith('assets/knowledge/') && (a.endsWith('.md') || a.endsWith('.txt')))
        .toList()
      ..sort();

    final docs = <(String id, String source, String text)>[];
    final sig = StringBuffer();
    for (final a in assets) {
      final text = await rootBundle.loadString(a);
      final name = a.split('/').last;
      sig.write('$name:${text.length}|');
      final pieces = chunk(text);
      for (var i = 0; i < pieces.length; i++) {
        docs.add(('doc:$name:$i', name, pieces[i]));
      }
    }

    var oldIds = <String>[];
    if (await marker.exists()) {
      final m = jsonDecode(await marker.readAsString()) as Map<String, dynamic>;
      oldIds = (m['ids'] as List).cast<String>();
      if (!force && m['signature'] == sig.toString()) return oldIds.length;
    }
    for (final id in oldIds) {
      await FlutterEdgeAi.rag.removeDocument(id: id);
    }

    final embedder = await FlutterEdgeAi.getActiveEmbedder();
    for (var start = 0; start < docs.length; start += 8) {
      final batch = docs.sublist(start, min(start + 8, docs.length));
      onStatus?.call('Indexing knowledge ${start + batch.length}/${docs.length}…');
      final vectors = await embedder.generateEmbeddings(
        batch.map((d) => d.$3).toList(),
        taskType: TaskType.retrievalDocument,
      );
      for (var i = 0; i < batch.length; i++) {
        await FlutterEdgeAi.rag.addDocumentWithEmbedding(
          id: batch[i].$1,
          content: batch[i].$3,
          embedding: vectors[i],
          metadata: jsonEncode({'kind': 'doc', 'source': batch[i].$2}),
        );
      }
    }
    await FlutterEdgeAi.rag.flush();
    await marker.writeAsString(jsonEncode({
      'signature': sig.toString(),
      'ids': docs.map((d) => d.$1).toList(),
    }));
    return docs.length;
  }

  /// Splits on blank lines and packs paragraphs into ~600-character passages.
  static List<String> chunk(String text, {int maxChars = 600}) {
    final paras = text
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty);
    final out = <String>[];
    var cur = '';
    for (final p in paras) {
      if (cur.isNotEmpty && cur.length + p.length > maxChars) {
        out.add(cur);
        cur = '';
      }
      cur = cur.isEmpty ? p : '$cur\n$p';
    }
    if (cur.isNotEmpty) out.add(cur);
    return out;
  }

  static Future<List<Hit>> searchKnowledge(String query, {int k = 3}) async {
    await FlutterEdgeAi.getActiveEmbedder(); // the runtime does not survive restarts; the index does
    final results = await FlutterEdgeAi.rag.searchSimilar(query: query, topK: k, filter: _kind('doc'));
    return results.map((r) {
      var source = r.id;
      try {
        source = (jsonDecode(r.metadata ?? '{}') as Map)['source'] as String? ?? r.id;
      } catch (_) {}
      return Hit(source, r.content, r.similarity);
    }).toList();
  }

  // ------------------------------------------------------------------ memory

  static Future<File> _memFile() async => File(await _path('memories.json'));

  static Future<List<MemoryItem>> memories() async {
    final f = await _memFile();
    if (!await f.exists()) return [];
    final list = jsonDecode(await f.readAsString()) as List;
    return list.map((e) => MemoryItem.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> _saveMemories(List<MemoryItem> items) async =>
      (await _memFile()).writeAsString(jsonEncode(items.map((m) => m.toJson()).toList()));

  /// Adds a fact, or REPLACES the closest existing fact if it is about the same
  /// thing (e.g. "has 400 trees" -> "has 600 trees").
  static Future<void> remember(String fact) async {
    fact = fact.trim();
    if (fact.length < 8 || fact.length > 220) return;
    final items = await memories();
    if (items.any((m) => m.text.toLowerCase() == fact.toLowerCase())) return;

    await FlutterEdgeAi.getActiveEmbedder();
    final near = await FlutterEdgeAi.rag.searchSimilar(
      query: fact,
      topK: 1,
      threshold: 0.80, // tune: higher = fewer merges
      filter: _kind('memory'),
    );
    String id;
    if (near.isNotEmpty) {
      id = near.first.id;
      await FlutterEdgeAi.rag.removeDocument(id: id);
      items.removeWhere((m) => m.id == id);
    } else {
      id = 'mem:${DateTime.now().microsecondsSinceEpoch}';
    }

    final embedder = await FlutterEdgeAi.getActiveEmbedder();
    final vector = await embedder.generateEmbedding(fact, taskType: TaskType.retrievalDocument);
    await FlutterEdgeAi.rag.addDocumentWithEmbedding(
      id: id,
      content: fact,
      embedding: vector,
      metadata: jsonEncode({'kind': 'memory'}),
    );
    await FlutterEdgeAi.rag.flush();
    items.add(MemoryItem(id, fact, DateTime.now()));
    await _saveMemories(items);
  }

  static Future<List<String>> relevantMemories(String query, {int k = 5}) async {
    if ((await memories()).isEmpty) return [];
    await FlutterEdgeAi.getActiveEmbedder();
    final r = await FlutterEdgeAi.rag.searchSimilar(query: query, topK: k, filter: _kind('memory'));
    return r.map((e) => e.content).toList();
  }

  static Future<void> forget(String id) async {
    await FlutterEdgeAi.rag.removeDocument(id: id);
    await FlutterEdgeAi.rag.flush();
    final items = await memories();
    items.removeWhere((m) => m.id == id);
    await _saveMemories(items);
  }
}
