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
        Guess(const LeafLabel('coffee__leaf_rust', 'Coffee', 'Leaf rust'), p),
        Guess(const LeafLabel('coffee__leaf_miner', 'Coffee', 'Leaf miner'), (1 - p) * 0.7),
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
      ChatTurn(demoText(s).oldTrees, fromUser: false)
        ..sources = ['coffee_growing.md']
        ..match = 0.42
        ..details = 'match 0.42',
      ChatTurn(demoText(s).priceQuestion, fromUser: true),
      ChatTurn(s.notSure, fromUser: false)
        ..notSure = true
        ..warning = s.weakMatch
        ..match = 0.05,
      ChatTurn(s.photoDefaultQuestion, fromUser: true),
      ChatTurn(demoText(s).rustAnswer, fromUser: false)
        ..diagnosis = fakeDiagnosis(p: 0.85)
        ..caution = s.photoCaution
        ..reviewPhoto = Uint8List(1)
        ..sources = ['coffee_leaf_rust.md'],
      ChatTurn(s.photoNotSure(s.photoNotSureOther), fromUser: false)
        ..diagnosis = fakeDiagnosis(p: 0.4)
        ..notSure = true
        ..queued = true,
    ];

/// The demo farmer's facts in My farm, in [language] (as she would have said them).
List<MemoryItem> fakeMemories([AppLanguage language = AppLanguage.en]) {
  final f = _demo[language]!.facts;
  return [
    MemoryItem('mem:1', f[0], DateTime(2026, 10, 2, 9, 30)),
    MemoryItem('mem:2', f[1], DateTime(2026, 10, 1, 17, 5)),
    MemoryItem('mem:3', f[2], DateTime(2026, 9, 28, 8, 12)),
    MemoryItem('mem:4', f[3], DateTime(2026, 3, 9, 7, 40)),
  ];
}

/// The canned texts of the preview (answers a model would write, notes and
/// facts the farmer would type), in each app language.
class DemoText {
  const DemoText({
    required this.answer,
    required this.oldTrees,
    required this.priceQuestion,
    required this.rustAnswer,
    required this.rustPhotoAnswer,
    required this.weatherAdvice,
    required this.officerNote,
    required this.facts,
  });
  final String answer, oldTrees, priceQuestion, rustAnswer, rustPhotoAnswer, weatherAdvice, officerNote;
  final List<String> facts;
}

DemoText demoText(S s) => _demo[AppLanguage.values.firstWhere((l) => identical(S.forLanguage(l), s),
    orElse: () => AppLanguage.en)]!;

const _demo = {
  AppLanguage.en: DemoText(
    answer: 'Prune old stems in rotation and keep shade light so air moves. Pick up fallen berries after harvest.',
    oldTrees: 'Old trees produce less. Prune in rotation.',
    priceQuestion: 'What is the price of fertiliser?',
    rustAnswer: 'Leaf rust shows yellow-orange powder under the leaf.',
    rustPhotoAnswer: 'Leaf rust: yellow-orange powder under the leaf. Prune for airflow.',
    weatherAdvice: 'Cover young plants and nursery beds on the cold night and take the cover off in the morning. '
        'Before the heavy rain, clear drainage channels and keep the soil covered with mulch. '
        'In the long wet spell, check leaves and berries for rust every few days.',
    officerNote: 'Spots on the upper plot, older trees',
    facts: [
      'I have about 400 coffee trees on two plots.',
      'The lower plot is shaded by banana plants.',
      'I saw orange powder on leaves in the upper plot last week.',
      'Our coffee trees flowered in early March.',
    ],
  ),
  AppLanguage.sw: DemoText(
    answer: 'Pogoa mashina ya zamani kwa zamu na weka kivuli chepesi ili hewa ipite. Okota buni zilizoanguka baada ya mavuno.',
    oldTrees: 'Miti mizee huzaa kidogo. Ipogoe kwa zamu.',
    priceQuestion: 'Bei ya mbolea ni kiasi gani?',
    rustAnswer: 'Kutu ya majani huonyesha unga wa njano-machungwa chini ya jani.',
    rustPhotoAnswer: 'Kutu ya majani: unga wa njano-machungwa chini ya jani. Pogoa ili hewa ipite.',
    weatherAdvice: 'Funika mimea michanga na vitalu usiku wa baridi kali na uondoe kifuniko asubuhi. '
        'Kabla ya mvua kubwa, safisha mifereji ya maji na funika udongo kwa matandazo. '
        'Katika kipindi kirefu cha mvua, kagua majani na buni kuona kutu kila baada ya siku chache.',
    officerNote: 'Madoa kwenye kipande cha juu, miti ya zamani',
    facts: [
      'Nina takriban miti 400 ya kahawa kwenye vipande viwili vya shamba.',
      'Kipande cha chini kina kivuli cha migomba.',
      'Wiki iliyopita niliona unga wa rangi ya machungwa kwenye majani ya kipande cha juu.',
      'Mikahawa yetu ilichanua mwanzoni mwa Machi.',
    ],
  ),
  AppLanguage.fr: DemoText(
    answer: "Taillez les vieilles tiges à tour de rôle et gardez un ombrage léger pour que l'air circule. "
        'Ramassez les cerises tombées après la récolte.',
    oldTrees: 'Les vieux arbres produisent moins. Taillez-les à tour de rôle.',
    priceQuestion: "Quel est le prix de l'engrais ?",
    rustAnswer: 'La rouille montre une poudre jaune-orange sous la feuille.',
    rustPhotoAnswer: "Rouille : poudre jaune-orange sous la feuille. Taillez pour que l'air circule.",
    weatherAdvice: 'Couvrez les jeunes plants et les pépinières pendant la nuit froide et enlevez la couverture le matin. '
        'Avant les fortes pluies, dégagez les rigoles de drainage et gardez le sol couvert de paillis. '
        'Pendant la longue période humide, cherchez la rouille sur les feuilles et les cerises tous les deux ou trois jours.',
    officerNote: 'Taches sur la parcelle du haut, vieux arbres',
    facts: [
      "J'ai environ 400 caféiers sur deux parcelles.",
      'La parcelle du bas est ombragée par des bananiers.',
      "La semaine dernière, j'ai vu une poudre orange sur les feuilles de la parcelle du haut.",
      'Nos caféiers ont fleuri début mars.',
    ],
  ),
};

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
