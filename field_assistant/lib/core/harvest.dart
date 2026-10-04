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

/// The farmer is asking how much coffee she will harvest, or when (en, sw, fr).
/// Needs a harvest word AND a how-much/when word, and no other crop (whole
/// words, so "price" is not "rice"): the formulas are for coffee, so "When
/// should I harvest maize?" or "How do I improve my yield?" get a normal answer.
bool isHarvestQuestion(String q) {
  final t = q.toLowerCase();
  // Kiswahili: mavuno (harvest), kuvuna / nitavuna (to harvest / I will harvest).
  const harvestWords = ['harvest', 'yield', 'mavuno', 'vuna', 'récolte', 'recolte', 'rendement'];
  const howMuchOrWhen = [
    'how much', 'how many', 'when', 'kg', 'kilo', 'expect', 'forecast', // en
    'kiasi', 'ngapi', 'lini', 'tarajia', // sw
    'combien', 'quand', 'prévoir', 'prevoir', // fr
  ];
  return harvestWords.any(t.contains) && howMuchOrWhen.any(t.contains) && !_otherCrop.hasMatch(t);
}

final _otherCrop = RegExp(
  r'\b(?:maize|corn|beans?|rice|cassava|sorghum|millet|potato(?:es)?|' // en
  r'mahindi|maharagwe|mchele|mpunga|muhogo|mtama|viazi|' // sw
  r'maïs|haricots?|riz|manioc|sorgho|patates?)\b', // fr
);

/// Reads trees and flowering month from things the farmer said, e.g.
/// "I have about 400 coffee trees" and "Our trees flowered in early March",
/// also in Kiswahili ("Nina miti 400 ya kahawa", "ilichanua Machi") and French
/// ("400 caféiers", "ont fleuri en mars"), since My farm keeps facts in the
/// farmer's language. This is the fallback the AI's extraction is checked against.
HarvestInputs? harvestInputsFrom(Iterable<String> facts, {required DateTime today}) {
  int? trees;
  int? month;
  for (final f in facts) {
    final t = f.toLowerCase();
    // The largest count wins: a later note like "I planted 50 new trees" must
    // not shrink a farm the farmer said has 400.
    for (final p in _treePatterns) {
      for (final m in p.allMatches(t)) {
        final n = int.tryParse(m.group(1)!.replaceAll(RegExp(r'\D'), ''));
        if (n != null && n > 0 && (trees == null || n > trees)) trees = n;
      }
    }
    if (month == null) {
      // The month that belongs to the flowering: the first one named after the
      // word ("flowered in March, sprayed in May" → March; "they may flower in
      // April" → April), else the closest one before it.
      int? key;
      for (final w in _floweringWords) {
        final i = t.indexOf(w);
        if (i >= 0 && (key == null || i < key)) key = i;
      }
      if (key != null) {
        final found = [
          for (final (re, n) in _monthPatterns)
            for (final m in re.allMatches(t)) (m.start, n),
        ]..sort((a, b) => a.$1.compareTo(b.$1));
        final after = found.where((m) => m.$1 >= key!);
        if (after.isNotEmpty) {
          month = after.first.$2;
        } else if (found.isNotEmpty) {
          month = found.last.$2;
        }
      }
    }
  }
  if (trees == null || month == null) return null;
  // The flowering that feeds this season: the latest one not in the future.
  final year = month <= today.month ? today.year : today.year - 1;
  return HarvestInputs(trees: trees, floweredMonth: month, floweredYear: year);
}

/// A count as farmers write it: 400, 1,200 or 1 200 (not the end of a year
/// just before it, as in "in 2024 400 trees").
const _count = r'(?<![\d,.])(\d{1,3}(?:[,.\s]\d{3})+|\d+)';

final _treePatterns = [
  RegExp('$_count\\s+(?:[a-z]+\\s+){0,2}trees'), // 400 trees · 400 coffee trees · 400 young coffee trees
  RegExp('$_count\\s+(?:caf[ée]iers|arbres|pieds)'), // 400 caféiers / arbres / pieds de café
  RegExp('$_count\\s+(?:miti|mikahawa)'), // 400 mikahawa
  // miti 400 ya kahawa · miti ya kahawa takriban 400
  RegExp('(?:miti|mikahawa)\\s+(?:ya\\s+kahawa\\s+)?(?:(?:takriban|karibu|kama|zaidi\\s+ya)\\s+)?$_count'),
];

const _floweringWords = ['flower', 'bloom', 'maua', 'chanua', 'fleur', 'florais'];

/// English as before (first three letters: "Mar", "March"), plus the Kiswahili
/// and French names that do not start the same way. Short words like "mai"
/// must stand alone ("mais", "maize" are not May).
final _monthPatterns = <(RegExp, int)>[
  for (final (i, m) in ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'].indexed)
    (RegExp('\\b$m'), i + 1),
  (RegExp(r'\bf[ée]v'), 2), // février
  (RegExp(r'\bmachi\b'), 3),
  (RegExp(r'\bavr'), 4), // avril
  (RegExp(r'\b(?:mei|mai)\b'), 5),
  (RegExp(r'\bjuin\b'), 6),
  (RegExp(r'\bjuil'), 7), // juillet
  (RegExp(r'\b(?:agosti|ao[uû]t)'), 8),
  (RegExp(r'\boktoba'), 10),
  (RegExp(r'\b(?:desemba|d[ée]c)'), 12),
];

/// Lets a chat reply carry a forecast without changing the message class:
/// `harvestOf[turn] = forecast`, read by the message bubble.
final harvestOf = Expando<HarvestForecast>('harvest');
