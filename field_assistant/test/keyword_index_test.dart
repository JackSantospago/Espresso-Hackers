import 'dart:io';

import 'package:field_assistant/services/brain.dart';
import 'package:field_assistant/services/keyword_index.dart';
import 'package:flutter_test/flutter_test.dart';

/// The real knowledge files, chunked exactly as the app indexes them.
List<Passage> _knowledge() {
  final files = Directory('assets/knowledge').listSync().whereType<File>().where((f) => f.path.endsWith('.md')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return [
    for (final f in files)
      for (final (i, text) in Brain.chunk(f.readAsStringSync()).indexed)
        Passage('doc:${f.uri.pathSegments.last}:$i', f.uri.pathSegments.last, text),
  ];
}

void main() {
  final index = KeywordIndex(_knowledge());

  test('tokenize drops stop words and trims plurals', () {
    expect(KeywordIndex.tokenize('The soils around here have a lot of IRON.'), ['soil', 'iron']);
  });

  test('an iron-rich soil question finds the soil guide, not only coffee guides', () {
    final hits = index.search('The soil around here has a lot of iron. What can i do to grow coffee?', k: 3);
    expect(hits.map((p) => p.source), contains('soil_types.md'));
  });

  test('fusion keeps a keyword-only passage and caps passages per guide', () {
    Passage p(String src, int i) => Passage('doc:$src:$i', src, '');
    // The embedding search sees only coffee guides (what happened on the phone).
    final semantic = [
      (p('coffee_growing.md', 4), 0.59),
      (p('coffee_growing.md', 1), 0.57),
      (p('coffee_growing.md', 2), 0.55),
      (p('coffee_brown_eye_spot.md', 0), 0.54),
      (p('coffee_leaf_rust.md', 0), 0.53),
    ];
    final keyword = [p('soil_types.md', 4), p('coffee_growing.md', 4), p('soil_types.md', 3)];
    final out = fuseRankings(semantic: semantic, keyword: keyword, k: 4);
    final sources = out.map((f) => f.passage.source).toList();
    expect(sources, contains('soil_types.md'));
    expect(sources.where((s) => s == 'coffee_growing.md').length, lessThanOrEqualTo(2));
    expect(out.first.similarity, 0.59); // in both lists, so it ranks first and keeps its score
    expect(out.firstWhere((f) => f.passage.source == 'soil_types.md').similarity, isNull);
  });

  test('topScore is the best embedding score, whatever the order', () {
    expect(Brain.topScore(const [Hit('a', '', 0), Hit('b', '', 0.42)]), 0.42);
    expect(Brain.topScore(const []), 0.0);
  });
}
