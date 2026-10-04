// Fake data for the UI: used by test/ui_smoke_test.dart and lib/main_preview.dart.
// Nothing here touches models or plugins.
import 'dart:typed_data';

import '../core/strings.dart';
import '../services/assistant.dart';
import '../services/brain.dart';
import '../services/leaf_diagnosis.dart';
import '../services/weather.dart';

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
        ..sources = ['coffee_growing.md']
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
        ..sources = ['coffee_leaf_rust.md'],
      ChatTurn(s.photoNotSure(s.photoNotSureOther), fromUser: false)
        ..diagnosis = fakeDiagnosis(p: 0.4)
        ..notSure = true
        ..queued = true,
    ];

List<MemoryItem> fakeMemories() => [
      MemoryItem('mem:1', 'I have about 400 coffee trees on two plots.', DateTime(2026, 10, 2, 9, 30)),
      MemoryItem('mem:2', 'The lower plot is shaded by banana plants.', DateTime(2026, 10, 1, 17, 5)),
      MemoryItem('mem:3', 'I saw orange powder on leaves in the upper plot last week.', DateTime(2026, 9, 28, 8, 12)),
      MemoryItem('mem:4', 'Our coffee trees flowered in early March.', DateTime(2026, 3, 9, 7, 40)),
    ];

/// 14 days from today in a coffee highland at the start of the rains: a cold
/// night (frost warning), a very wet weekend (heavy rain) and a long wet,
/// humid spell (fungal disease weather). Shaped like a real Open-Meteo answer.
Forecast fakeForecast({DateTime? now}) {
  final n = now ?? DateTime.now();
  //            code  max   min   rain  chance gust  humidity
  const rows = <List<num>>[
    [2, 23.4, 11.0, 0.0, 10, 28, 62],
    [1, 24.1, 1.6, 0.0, 5, 18, 58],
    [3, 22.0, 9.8, 1.2, 40, 31, 70],
    [81, 20.5, 13.1, 32.0, 90, 44, 88],
    [95, 19.8, 13.4, 41.5, 95, 52, 92],
    [80, 20.9, 13.0, 30.2, 85, 39, 90],
    [61, 21.3, 12.8, 6.4, 70, 30, 86],
    [61, 21.0, 12.9, 4.1, 65, 29, 85],
    [3, 22.6, 12.2, 0.6, 30, 27, 76],
    [2, 23.0, 11.7, 0.0, 15, 25, 70],
    [80, 21.8, 12.5, 7.9, 60, 33, 83],
    [80, 21.1, 12.7, 9.3, 65, 35, 86],
    [3, 22.4, 12.1, 2.0, 40, 28, 78],
    [2, 23.2, 11.5, 0.0, 20, 24, 68],
  ];
  return Forecast(
    fetchedAt: n.subtract(const Duration(hours: 2)),
    elevation: 1650,
    days: [
      for (var i = 0; i < rows.length; i++)
        DayForecast(
          date: DateTime(n.year, n.month, n.day + i),
          code: rows[i][0].toInt(),
          tMax: rows[i][1].toDouble(),
          tMin: rows[i][2].toDouble(),
          rainMm: rows[i][3].toDouble(),
          rainChance: rows[i][4].toInt(),
          gustKmh: rows[i][5].toDouble(),
          humidity: rows[i][6].toInt(),
        ),
    ],
  );
}
