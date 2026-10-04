// The guides and My farm in every app language. No models, no widgets.
import 'dart:convert';
import 'dart:io';

import 'package:field_assistant/core/strings.dart';
import 'package:field_assistant/frontend/shared/guides.dart';
import 'package:field_assistant/services/assistant.dart';
import 'package:field_assistant/services/brain.dart';
import 'package:field_assistant/services/leaf_diagnosis.dart';
import 'package:flutter_test/flutter_test.dart';

/// Numbers in a text, with thousands and decimal separators dropped, so
/// "1,700 m", "1 700 m" and "1.5 cm" / "1,5 cm" compare equal.
List<String> _numbers(String s) =>
    RegExp(r'\d+').allMatches(s.replaceAll(RegExp(r'(?<=\d)[ ,.  ](?=\d)'), '')).map((m) => m[0]!).toList()
      ..sort();

void main() {
  final english = Directory('assets/knowledge').listSync().whereType<File>().where((f) => f.path.endsWith('.md')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final lang in AppLanguage.values.where((l) => l != AppLanguage.en)) {
    test('every guide is translated to ${lang.nativeName}, with the same sections, sources and numbers', () {
      expect(english, isNotEmpty);
      for (final f in english) {
        final name = f.uri.pathSegments.last;
        final file = File('assets/guides/${lang.name}/$name');
        expect(file.existsSync(), isTrue, reason: '${file.path} is missing');
        final en = parseGuides(f.readAsStringSync(), name).single;
        final tr = parseGuides(file.readAsStringSync(), name).single;
        expect(tr.title, isNot(en.title), reason: '$name: title not translated');
        expect(tr.summary, isNotEmpty, reason: name);
        expect(tr.sections.length, en.sections.length, reason: '$name: number of sections');
        for (var i = 0; i < en.sections.length; i++) {
          final (a, b) = (en.sections[i], tr.sections[i]);
          expect(b.sources, a.sources, reason: '$name §$i: sources');
          expect(b.heading.isEmpty, a.heading.isEmpty, reason: '$name §$i: heading');
          expect(_numbers(b.text), _numbers(a.text), reason: '$name §$i: numbers');
        }
      }
    });
  }

  test('every leaf model label has a name in every language', () {
    final labels = (jsonDecode(File('assets/models/leaf_classifier.json').readAsStringSync())['labels'] as List)
        .map((l) => l['id'] as String);
    for (final lang in AppLanguage.values) {
      final s = S.forLanguage(lang);
      for (final id in labels) {
        expect(s.leafConditions[id], isNotNull, reason: '${lang.name}: $id');
        if (id.contains('__')) expect(s.crops[id.split('__').first], isNotNull, reason: '${lang.name}: $id');
      }
    }
  });

  test('a photo check in My farm follows the language; what the farmer said does not', () {
    const d = Diagnosis(
      top: [Guess(LeafLabel('coffee__leaf_rust', 'Coffee', 'leaf rust'), 0.93)],
      threshold: 0.6,
      otherId: 'other',
      millis: 100,
    );
    final when = DateTime(2026, 10, 3, 9);
    final en = S.forLanguage(AppLanguage.en), sw = S.forLanguage(AppLanguage.sw);
    final photo = MemoryItem('${photoMemoryIdPrefix(d)}123', photoMemoryText(en, d, when), when);
    expect(photo.id, startsWith(photoMemoryPrefix(d))); // still replaced by the next check of this crop
    expect(memoryText(en, photo), photoMemoryText(en, d, when));
    expect(memoryText(sw, photo), photoMemoryText(sw, d, when));
    expect(memoryText(sw, photo), contains('kutu ya majani'));

    final said = MemoryItem('mem:1', 'I have 400 coffee trees.', when);
    expect(memoryText(sw, said), said.text);
  });
}
