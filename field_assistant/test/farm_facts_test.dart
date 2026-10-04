// The harvest forecast must work from what the farmer said in an earlier chat
// or wrote as a note, in any of the three languages, for coffee, maize and beans.
import 'package:field_assistant/core/harvest.dart';
import 'package:field_assistant/core/strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 3);

  group('saved farm facts read back in every language', () {
    for (final lang in AppLanguage.values) {
      final s = S.forLanguage(lang);
      test(lang.name, () {
        // What _rememberFarmFacts saves, then what the forecast reads.
        final saved = [
          FarmFact.trees(400).text(s),
          FarmFact.month(HarvestCrop.coffee, 3).text(s),
          FarmFact.acres(HarvestCrop.maize, 2).text(s),
          FarmFact.month(HarvestCrop.maize, 4).text(s),
          FarmFact.acres(HarvestCrop.beans, 1.5).text(s),
        ];
        final coffee = harvestInputsFrom(saved, today: today)!;
        expect((coffee.trees, coffee.floweredMonth, coffee.monthAssumed), (400, 3, false), reason: saved.join(' | '));
        final maize = harvestInputsFrom(saved, today: today, crop: HarvestCrop.maize)!;
        expect((maize.acres, maize.floweredMonth, maize.monthAssumed), (2.0, 4, false), reason: saved.join(' | '));
        final beans = harvestInputsFrom(saved, today: today, crop: HarvestCrop.beans)!;
        expect((beans.acres, beans.monthAssumed), (1.5, true), reason: saved.join(' | '));

        // And each saved sentence is recognised again as the same fact.
        expect(farmFactsIn(saved[0]).single.count, 400);
        expect(farmFactsIn(saved[1]).single.month, 3);
        expect(farmFactsIn(saved[2]).single.acres, 2.0);
        expect(farmFactsIn(saved[3]).single.month, 4);
      });
    }
  });

  test('facts in a statement, as a farmer says them', () {
    final f = farmFactsIn('I have 400 coffee trees and they flowered in early March');
    expect([for (final x in f) x.key], ['coffee-trees', 'coffee-month']);
    expect((f[0].count, f[1].month), (400, 3));
    expect(farmFactsIn('I have 2 acres of maize, planted in April').map((x) => (x.key, x.acres ?? x.month)),
        [('maize-acres', 2.0), ('maize-month', 4)]);
    expect(farmFactsIn('Nina ekari 3 za kahawa').single.acres, 3.0);
    expect(farmFactsIn("J'ai 1,5 ha de café").single.acres, closeTo(3.7, 0.01));
    // An addition is not the farm's total.
    expect(farmFactsIn('I planted 50 new trees on the lower plot.'), isEmpty);
  });

  test('a question is not a statement: no month, no acres without a crop', () {
    expect(farmFactsIn('When should I plant maize in March?', isQuestion: true).map((x) => x.key), isEmpty);
    expect(farmFactsIn('How much fertiliser for 2 acres?', isQuestion: true), isEmpty);
    expect(farmFactsIn('My 400 trees have rust, what should I do?', isQuestion: true).single.count, 400);
  });

  test('a short reply to our question', () {
    expect(farmFactsIn('400', askedFor: HarvestCrop.coffee).single.count, 400);
    expect(farmFactsIn('about 1,200', askedFor: HarvestCrop.coffee).single.count, 1200);
    expect(farmFactsIn('2', askedFor: HarvestCrop.maize).single.acres, 2.0);
    expect(farmFactsIn('1.5', askedFor: HarvestCrop.beans).single.acres, 1.5);
    expect(farmFactsIn('I do not know yet, sorry about that', askedFor: HarvestCrop.coffee), isEmpty);
  });

  test('acres of coffee become trees at the standard spacing', () {
    final i = harvestInputsFrom(['I have 2 acres of coffee', 'They flowered in March'], today: today)!;
    expect((i.trees, i.acres, i.coffeeTrees), (null, 2.0, 2 * kCoffeeTreesPerAcre));
    final f = forecastHarvest(i);
    expect((f.kgLow, f.kgHigh), (2160, 3240));
  });

  test('a tree count beats an area for coffee', () {
    final i = harvestInputsFrom(['I have 400 coffee trees', 'I have 2 acres of coffee'], today: today)!;
    expect((i.trees, i.acres), (400, null));
  });

  test('newer facts come first and replace older ones', () {
    // As the assistant passes them: the question, saved farm facts, then the rest newest first.
    final i = harvestInputsFrom(['How much will I harvest?', 'I have 600 coffee trees.', 'I have 400 coffee trees.'],
        today: today)!;
    expect(i.trees, 600);
  });

  test('young coffee gives no forecast yet', () {
    expect(harvestInputsFrom(['I planted 400 coffee trees in 2025'], today: today)!.youngTrees, isTrue);
    expect(harvestInputsFrom(['I planted 400 coffee trees in 2015'], today: today)!.youngTrees, isFalse);
  });

  test('maize and beans forecasts', () {
    final maize = forecastHarvest(
        harvestInputsFrom(['I have 2 acres of maize', 'I planted maize in March'], today: today, crop: HarvestCrop.maize)!);
    expect((maize.kgLow, maize.kgHigh), (2 * kMaizeKgPerAcreLow, 2 * kMaizeKgPerAcreHigh));
    expect((maize.readyFrom, maize.readyTo), (DateTime(2026, 7), DateTime(2026, 10)));
    final beans = forecastHarvest(
        harvestInputsFrom(['Nina ekari 1 za maharagwe', 'Nilipanda maharagwe Agosti'], today: today, crop: HarvestCrop.beans)!);
    expect((beans.kgLow, beans.kgHigh), (kBeansKgPerAcreLow, kBeansKgPerAcreHigh));
    expect((beans.readyFrom, beans.readyTo), (DateTime(2026, 10), DateTime(2026, 11)));
    // Maize facts never count as coffee, and the other way round.
    expect(harvestInputsFrom(['I have 2 acres of maize'], today: today), isNull);
    expect(harvestInputsFrom(['I have 400 coffee trees'], today: today, crop: HarvestCrop.maize), isNull);
  });

  test('which crop a harvest question is about', () {
    expect(harvestCropOf('How much coffee will I harvest?'), HarvestCrop.coffee);
    expect(harvestCropOf('How much will I harvest?'), HarvestCrop.coffee);
    expect(harvestCropOf('How much maize will I harvest?'), HarvestCrop.maize);
    expect(harvestCropOf('Nitavuna maharagwe kiasi gani?'), HarvestCrop.beans);
    expect(harvestCropOf('Combien de maïs vais-je récolter ?'), HarvestCrop.maize);
    expect(isHarvestQuestion('Combien de café vais-je récolter, mais quand ?'), isTrue); // "mais" is "but"
    expect(harvestCropOf('Combien de café vais-je récolter, mais quand ?'), HarvestCrop.coffee);
  });

  test("photo-check memories never pass for farm facts", () {
    for (final lang in AppLanguage.values) {
      final s = S.forLanguage(lang);
      final photos = [
        s.photoMemoryHealthy('2026-10-04', 'coffee', '88%'),
        s.photoMemoryProblem('2026-10-04', 'coffee', 'leaf rust', '91%'),
      ];
      for (final p in photos) {
        expect(farmFactsIn(p), isEmpty, reason: p);
      }
      final i = harvestInputsFrom([...photos, s.factTrees(400), s.factFlowered(s.monthsLong[2])], today: today)!;
      expect((i.trees, i.floweredMonth, i.youngTrees), (400, 3, false), reason: lang.name);
    }
  });

  test('a month named in a fact', () {
    expect(monthNamedIn('They flowered in March', 3), isTrue);
    expect(monthNamedIn('ilichanua Machi', 3), isTrue);
    expect(monthNamedIn('fleuri en mai', 5), isTrue);
    expect(monthNamedIn('le maïs', 5), isFalse);
  });

  group('crop recognition', () {
    test('every crop is recognised, sweet potatoes are not potatoes, "the" is not tea', () {
      expect(cropKeysIn('We planted the potatoes in March'), {'potato'});
      expect(cropKeysIn('My sweet potatoes are yellow'), {'sweet potato'});
      expect(cropKeysIn('Nilipanda viazi vitamu na viazi'), {'sweet potato', 'potato'});
      expect(cropKeysIn("J'ai planté des pommes de terre"), {'potato'});
      expect(cropKeysIn('400 coffee trees and 2 acres of maize'), {'coffee', 'maize'});
      expect(cropKeysIn('When will I harvest the coffee?'), {'coffee'});
      expect(cropWordIn('Nilipanda viazi mwezi Machi', 'potato'), 'viazi');
    });

    test('a harvest question without a crop is about the crop of the conversation', () {
      const potatoes = 'We have 2 acres with average soil for the region and planted the potatoes in march';
      expect(cropKeyOf('How much will we harvest and when?', recent: [potatoes]), 'potato');
      expect(harvestCropByKey('potato'), isNull); // no figures: never the coffee forecast
      expect(cropKeyOf('How much will we harvest?', recent: ['I planted 2 acres of maize in April']), 'maize');
      // The newest message naming a crop decides.
      expect(cropKeyOf('And when?', recent: ['What about the beans?', 'My potatoes are fine']), 'beans');
      // Named in the question wins.
      expect(cropKeyOf('How much coffee will I harvest?', recent: [potatoes]), 'coffee');
      // Nothing in the conversation: the only crop with farm facts, else unknown (coffee).
      expect(cropKeyOf('How much will I harvest?', farmFactKeys: ['maize-acres', 'maize-month']), 'maize');
      expect(cropKeyOf('How much will I harvest?', farmFactKeys: ['maize-acres', 'coffee-trees']), isNull);
      expect(cropKeyOf('How much will I harvest?'), isNull);
    });

    test('facts about potatoes are never saved or read as coffee facts', () {
      expect(farmFactsIn('We have 2 acres with average soil and planted the potatoes in march'), isEmpty);
      expect(farmFactsIn('2 acres of potatoes', askedFor: HarvestCrop.maize), isEmpty);
      expect(harvestInputsFrom(['I planted 2 acres of potatoes in March'], today: today), isNull);
      // Each area goes to the crop named next to it.
      expect(farmFactsIn('I have 2 acres of maize and 1 acre of potatoes').map((f) => (f.key, f.acres)),
          [('maize-acres', 2.0)]);
      expect(harvestInputsFrom(['I have 1 acre of potatoes and 3 acres of beans'], today: today, crop: HarvestCrop.beans)!.acres,
          3.0);
      // Planted months per crop.
      expect(farmFactsIn('I planted potatoes in March and maize in May').map((f) => (f.key, f.month)),
          [('maize-month', 5)]);
    });

    test('harvest questions about crops without figures go to the guides', () {
      expect(isHarvestQuestion('How much potatoes will I harvest?'), isFalse);
      expect(isHarvestQuestion('When will I harvest the coffee?'), isTrue); // "the" is not "thé"
      expect(isHarvestQuestion('How much will we harvest and when?'), isTrue);
    });

    test('guides of other crops are not used for a crop without a guide', () {
      expect(cropsWithGuides.contains('potato'), isFalse);
      expect(guideForAnotherCrop('sweet_potato_growing.md', 'potato'), isTrue);
      expect(guideForAnotherCrop('coffee_growing.md', 'potato'), isTrue);
      expect(guideForAnotherCrop('soil_types.md', 'potato'), isFalse);
      expect(guideForAnotherCrop('sorghum_and_millet_growing.md', 'millet'), isFalse);
    });
  });
}
