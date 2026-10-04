import 'package:field_assistant/core/harvest.dart';
import 'package:field_assistant/core/strings.dart';
import 'package:field_assistant/frontend/sell/market_demo.dart';
import 'package:field_assistant/preview/fake_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('400 trees that flowered in March: 800–1,200 kg, ready Oct to Dec, peak in Nov', () {
    final f = forecastHarvest(const HarvestInputs(trees: 400, floweredMonth: 3, floweredYear: 2026));
    expect(f.kgLow, 800);
    expect(f.kgHigh, 1200);
    expect(f.readyFrom, DateTime(2026, 10));
    expect(f.readyTo, DateTime(2026, 12));
    expect([for (final m in f.byMonth) m.$2], [250, 500, 250]);
    expect(f.byMonth.fold<int>(0, (a, m) => a + m.$2), f.kgMid);
  });

  test('a window across the new year', () {
    final f = forecastHarvest(const HarvestInputs(trees: 100, floweredMonth: 6, floweredYear: 2026));
    expect(f.readyFrom, DateTime(2027, 1));
    expect(f.readyTo, DateTime(2027, 3));
  });

  test('the inputs are read from what the farmer said', () {
    final i = harvestInputsFrom(fakeMemories().map((m) => m.text), today: DateTime(2026, 10, 3))!;
    expect(i.trees, 400);
    expect(i.floweredMonth, 3);
    expect(i.floweredYear, 2026);
    // No flowering month said: Kenya's usual season, marked as assumed.
    final noMonth = harvestInputsFrom(['I have 1,200 coffee trees'], today: DateTime(2026, 10, 3))!;
    expect((noMonth.trees, noMonth.floweredMonth, noMonth.monthAssumed), (1200, kUsualMonth, true));
    // A flowering month later than today belongs to last year.
    expect(harvestInputsFrom(['50 trees', 'They flowered in November'], today: DateTime(2026, 10, 3))!.floweredYear, 2025);
  });

  test('both facts in one reply (what a farmer types after "How many trees…?")', () {
    final i = harvestInputsFrom(['I have 400 coffee trees and they flowered in early March'], today: DateTime(2026, 10, 3))!;
    expect((i.trees, i.floweredMonth), (400, 3));
  });

  test('the facts can be in Kiswahili or French (My farm keeps the farmer\'s language)', () {
    for (final lang in AppLanguage.values) {
      final i = harvestInputsFrom(fakeMemories(lang).map((m) => m.text), today: DateTime(2026, 10, 3))!;
      expect((i.trees, i.floweredMonth), (400, 3), reason: lang.name);
    }
    final sw = harvestInputsFrom(['Nina mikahawa 650.', 'Kahawa ilitoa maua Aprili.'], today: DateTime(2026, 10, 3))!;
    expect((sw.trees, sw.floweredMonth), (650, 4));
    final fr = harvestInputsFrom(["J'ai 1 200 pieds de café", 'Le maïs a fleuri en mai, mais le café en juin'],
        today: DateTime(2026, 10, 3))!;
    // "The maize flowered in May, but the coffee in June": for coffee that is June (and
    // "maïs" / "mais" are not May).
    expect((fr.trees, fr.floweredMonth), (1200, 6));
    // A year right before the count is not part of it.
    expect(harvestInputsFrom(['In 2024 400 trees were planted', 'They flowered in April'], today: DateTime(2026, 10, 3))!.trees,
        400);
    expect(harvestInputsFrom(['My maize flowered in April'], today: DateTime(2026, 10, 3)), isNull);
  });

  test('demo-proof reading of the facts', () {
    final today = DateTime(2026, 10, 3);
    // A later note about new trees must not shrink the farm.
    expect(harvestInputsFrom(['I planted 50 new trees on the lower plot.', 'I have about 400 coffee trees on two plots.',
        'Our coffee trees flowered in early March.'], today: today)!.trees, 400);
    // The month that belongs to "flowered", not the last one named.
    expect(harvestInputsFrom(['400 trees', 'The trees flowered in March, I sprayed in May'], today: today)!.floweredMonth, 3);
    // "may" as a verb before the flowering does not count.
    expect(harvestInputsFrom(['400 trees', 'They may flower in April'], today: today)!.floweredMonth, 4);
    expect(harvestInputsFrom(['I have 400 young coffee trees that flowered in March'], today: today)!.trees, 400);
  });

  test('other questions do not trigger the forecast', () {
    expect(isHarvestQuestion('When should I harvest rice?'), isFalse); // no figures for rice
    expect(isHarvestQuestion('How do I improve my yield?'), isFalse);
    expect(isHarvestQuestion('How do I store my harvest?'), isFalse);
    expect(isHarvestQuestion('Nitavuna mchele lini?'), isFalse); // rice, in Kiswahili
    expect(isHarvestQuestion('Nitavuna mahindi lini?'), isTrue); // maize is supported
    expect(isHarvestQuestion('How much will I harvest?'), isTrue);
    expect(isHarvestQuestion('How much will I harvest, and at what price?'), isTrue); // "price" is not "rice"
  });

  test('harvest questions in all three languages', () {
    expect(isHarvestQuestion('How much coffee will I harvest, and when?'), isTrue);
    expect(isHarvestQuestion('Nitavuna kahawa kiasi gani, na lini?'), isTrue);
    expect(isHarvestQuestion('Mavuno yangu yatakuwa lini?'), isTrue);
    expect(isHarvestQuestion('Combien de café vais-je récolter ? Ma récolte'), isTrue);
    expect(isHarvestQuestion('How do I manage leaf rust?'), isFalse);
  });

  test('demo offers and sales always fit inside the harvest, whatever the trees', () {
    for (final trees in [20, 75, 150, 400, 1200, 5000]) {
      final m = MarketDemo()..setForecast(forecastHarvest(HarvestInputs(trees: trees, floweredMonth: 3, floweredYear: 2026)));
      expect(m.soldKg + m.offeredKg, lessThanOrEqualTo(m.seasonBase), reason: '$trees trees');
      expect(m.toSellKg, greaterThan(0), reason: '$trees trees');
      m.accept(m.offers.first);
      expect(m.soldKg + m.offeredKg, lessThanOrEqualTo(m.seasonBase), reason: '$trees trees after accepting');
    }
  });
}
