// Fake data for the UI: used by test/ui_smoke_test.dart and lib/main_preview.dart.
// Nothing here touches models or plugins.
import 'dart:typed_data';

import '../core/strings.dart';
import '../services/assistant.dart';
import '../services/brain.dart';
import '../services/leaf_diagnosis.dart';

Diagnosis fakeDiagnosis({required double p}) => Diagnosis(
      top: [
        Guess(const LeafLabel('coffee__rust', 'Coffee', 'Leaf rust'), p),
        Guess(const LeafLabel('coffee__miner', 'Coffee', 'Leaf miner'), (1 - p) * 0.7),
        Guess(const LeafLabel('other', '', 'Other'), (1 - p) * 0.3),
      ],
      threshold: 0.6,
      otherId: 'other',
      millis: 120,
    );

/// A conversation that shows every kind of bubble: grounded answer, "not sure"
/// with a weak-match warning, confident photo answer, unsure photo answer.
List<ChatTurn> fakeConversation(S s) => [
      ChatTurn(s.suggestions.first, fromUser: true),
      ChatTurn('Old trees produce less. Prune in rotation.', fromUser: false)
        ..sources = ['coffee_sample.md']
        ..match = 0.42
        ..details = 'match 0.42',
      ChatTurn('What is the price of fertiliser?', fromUser: true),
      ChatTurn(s.notSure, fromUser: false)
        ..notSure = true
        ..warning = s.weakMatch
        ..match = 0.05,
      ChatTurn(s.photoDefaultQuestion, fromUser: true),
      ChatTurn('Leaf rust shows yellow-orange powder under the leaf.', fromUser: false)
        ..diagnosis = fakeDiagnosis(p: 0.85)
        ..caution = s.photoCaution
        ..reviewPhoto = Uint8List(1)
        ..sources = ['coffee_sample.md'],
      ChatTurn(s.photoNotSure(s.photoNotSureOther), fromUser: false)
        ..diagnosis = fakeDiagnosis(p: 0.4)
        ..notSure = true
        ..queued = true,
    ];

List<MemoryItem> fakeMemories() => [
      MemoryItem('mem:1', 'I have about 400 coffee trees on two plots.', DateTime(2026, 10, 2, 9, 30)),
      MemoryItem('mem:2', 'The lower plot is shaded by banana plants.', DateTime(2026, 10, 1, 17, 5)),
      MemoryItem('mem:3', 'I saw orange powder on leaves in the upper plot last week.', DateTime(2026, 9, 28, 8, 12)),
    ];
