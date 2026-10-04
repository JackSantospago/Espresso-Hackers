/// Harvest forecast: the AI reads the farm facts (trees, when they flowered),
/// these formulas do the arithmetic exactly, and the AI explains the result.
/// The figures below are sourced; the answer is always a range, not one number.
library;

/// Kenyan smallholder arabica: about 2–3 kg of cherry per tree and year
/// (unirrigated ~2.4 kg, irrigated up to ~6.3 kg).
/// Sources: Business Daily Africa (2024), "Give farmers quality fertiliser…";
/// Kenyatta University, smallholder coffee irrigation research.
const kCherryKgPerTreeLow = 2.0;
const kCherryKgPerTreeHigh = 3.0;

/// Arabica cherries are ripe about 7–9 months after flowering (faster where it
/// is warmer). Sources: UNESP (Brazil) maturation study; roaster farm guides.
const kMonthsToRipeLow = 7;
const kMonthsToRipeHigh = 9;

/// What the forecast needs from the farm. The AI fills it from what the farmer
/// said (memory) and asks for whatever is missing.
class HarvestInputs {
  const HarvestInputs({required this.trees, required this.floweredMonth, required this.floweredYear});
  final int trees;

  /// 1 = January … 12 = December.
  final int floweredMonth;
  final int floweredYear;
}

/// The result: a range of kg, the months it will be ready, and how much ripens
/// each month (for the chart). [steps] shows how it was worked out.
class HarvestForecast {
  const HarvestForecast({
    required this.inputs,
    required this.kgLow,
    required this.kgHigh,
    required this.readyFrom,
    required this.readyTo,
    required this.byMonth,
  });
  final HarvestInputs inputs;
  final int kgLow, kgHigh;

  /// First day of the first and of the last month of picking.
  final DateTime readyFrom, readyTo;

  /// Expected kg (middle of the range) ripening in each month, in order.
  final List<(DateTime month, int kg)> byMonth;

  int get kgMid => ((kgLow + kgHigh) / 2).round();
}

/// The formulas. Pure arithmetic, so the same inputs always give the same answer.
HarvestForecast forecastHarvest(HarvestInputs i) {
  final low = (i.trees * kCherryKgPerTreeLow).round();
  final high = (i.trees * kCherryKgPerTreeHigh).round();
  final from = DateTime(i.floweredYear, i.floweredMonth + kMonthsToRipeLow);
  final to = DateTime(i.floweredYear, i.floweredMonth + kMonthsToRipeHigh);

  // Picking is spread over the window and peaks in the middle month(s):
  // weights 1, 2, …, 2, 1 across the months, then scaled to the middle of the range.
  final months = [for (var m = from; !m.isAfter(to); m = DateTime(m.year, m.month + 1)) m];
  final n = months.length;
  final weights = [for (var k = 0; k < n; k++) 1 + (k < n - 1 - k ? k : n - 1 - k)];
  final sum = weights.fold<int>(0, (a, b) => a + b);
  final mid = ((low + high) / 2).round();
  final byMonth = <(DateTime, int)>[];
  var given = 0;
  for (var k = 0; k < n; k++) {
    final kg = k == n - 1 ? mid - given : (mid * weights[k] / sum).round();
    given += kg;
    byMonth.add((months[k], kg));
  }
  return HarvestForecast(inputs: i, kgLow: low, kgHigh: high, readyFrom: from, readyTo: to, byMonth: byMonth);
}

/// The farmer is asking how much / when she will harvest (en, sw, fr).
bool isHarvestQuestion(String q) {
  final t = q.toLowerCase();
  // Kiswahili: mavuno (harvest), kuvuna / nitavuna (to harvest / I will harvest).
  const words = ['harvest', 'how much coffee', 'yield', 'mavuno', 'vuna', 'récolte', 'recolte', 'rendement'];
  return words.any(t.contains);
}

/// Reads trees and flowering month from things the farmer said, e.g.
/// "I have about 400 coffee trees" and "Our trees flowered in early March".
/// This is the fallback the AI's extraction is checked against.
HarvestInputs? harvestInputsFrom(Iterable<String> facts, {required DateTime today}) {
  int? trees;
  int? month;
  const names = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };
  for (final f in facts) {
    final t = f.toLowerCase();
    trees ??= int.tryParse(RegExp(r'(\d[\d,]*)\s+(?:coffee\s+)?trees').firstMatch(t)?.group(1)?.replaceAll(',', '') ?? '');
    if (month == null && (t.contains('flower') || t.contains('bloom'))) {
      for (final e in names.entries) {
        if (RegExp('\\b${e.key}').hasMatch(t)) month = e.value;
      }
    }
  }
  if (trees == null || month == null) return null;
  // The flowering that feeds this season: the latest one not in the future.
  final year = month <= today.month ? today.year : today.year - 1;
  return HarvestInputs(trees: trees, floweredMonth: month, floweredYear: year);
}

/// Lets a chat reply carry a forecast without changing the message class:
/// `harvestOf[turn] = forecast`, read by the message bubble.
final harvestOf = Expando<HarvestForecast>('harvest');
