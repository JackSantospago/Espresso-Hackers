/// Harvest forecast: the farm facts (trees or acres, when they flowered or were
/// planted) are read from what the farmer said and wrote, these formulas do the
/// arithmetic exactly, and the answer shows how it was worked out. The figures
/// below are sourced; the answer is always a range, never one number.
library;

import 'strings.dart';

/// The crops the formulas know.
enum HarvestCrop { coffee, maize, beans }

// ---------------------------------------------------------------- figures

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

/// Conventional Kenyan coffee spacing, 2.75 m x 2.75 m: about 1,330 trees per
/// hectare, so about 540 per acre. Source: Kenyan density trials (University of
/// Embu repository; "The costs of establishing various coffee densities in Kenya").
const kCoffeeTreesPerAcre = 540;

/// Young coffee first flowers 3 to 4 years after planting (assets/knowledge/
/// coffee_growing.md), so trees planted less than 3 years ago give no crop yet.
const kCoffeeYearsToFirstCrop = 3;

/// Maize: Kenyan smallholder average about 1.6–1.7 t/ha; 600–800 kg per acre
/// covers it with some spread. Ready 4–7 months after planting (H513, mid
/// altitude: 100–110 days; H614, highland: 160–210 days).
/// Sources: AgEcon "Maize yields in Kenya"; CIMMYT Kenya maize profile; Kenya Seed.
const kMaizeKgPerAcreLow = 600;
const kMaizeKgPerAcreHigh = 800;
const kMaizeMonthsLow = 4;
const kMaizeMonthsHigh = 7;

/// Beans: Kenyan average about 490 kg/ha, common varieties 560–935 kg/ha, so
/// 200–360 kg per acre. Ready 60–90 days after planting.
/// Sources: One Acre Fund "Common Bean Ag Innovations"; Kenya bean variety data.
const kBeansKgPerAcreLow = 200;
const kBeansKgPerAcreHigh = 360;
const kBeansMonthsLow = 2;
const kBeansMonthsHigh = 3;

/// When the farmer has not said the month: Kenya's main season. Coffee flowers
/// with the rains around March (main crop picked October–December); maize and
/// beans are planted with the long rains from March. Shown as "usual season".
const kUsualMonth = 3;

const _hectareInAcres = 2.471;

// ---------------------------------------------------------------- inputs

/// What the forecast needs from the farm.
class HarvestInputs {
  const HarvestInputs({
    this.crop = HarvestCrop.coffee,
    this.trees,
    this.acres,
    required this.floweredMonth,
    required this.floweredYear,
    this.monthAssumed = false,
    this.youngTrees = false,
  }) : assert(trees != null || acres != null, 'a forecast needs trees or acres');

  final HarvestCrop crop;

  /// Coffee trees, when the farmer said how many.
  final int? trees;

  /// Area in acres (any crop), when the farmer said it instead of trees.
  final double? acres;

  /// Coffee: the month the trees flowered. Maize and beans: the month they were
  /// planted. 1 = January … 12 = December.
  final int floweredMonth;
  final int floweredYear;

  /// The farmer did not say the month; [kUsualMonth] was used.
  final bool monthAssumed;

  /// Coffee planted less than [kCoffeeYearsToFirstCrop] years ago: no crop yet.
  final bool youngTrees;

  /// Coffee trees counted or worked out from the area.
  int get coffeeTrees => trees ?? ((acres ?? 0) * kCoffeeTreesPerAcre).round();
}

/// The result: a range of kg, the months it will be ready, and how much ripens
/// each month (for the chart).
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
  final (int low, int high, int monthsLow, int monthsHigh) = switch (i.crop) {
    HarvestCrop.coffee => (
        (i.coffeeTrees * kCherryKgPerTreeLow).round(),
        (i.coffeeTrees * kCherryKgPerTreeHigh).round(),
        kMonthsToRipeLow,
        kMonthsToRipeHigh,
      ),
    HarvestCrop.maize => (
        ((i.acres ?? 0) * kMaizeKgPerAcreLow).round(),
        ((i.acres ?? 0) * kMaizeKgPerAcreHigh).round(),
        kMaizeMonthsLow,
        kMaizeMonthsHigh,
      ),
    HarvestCrop.beans => (
        ((i.acres ?? 0) * kBeansKgPerAcreLow).round(),
        ((i.acres ?? 0) * kBeansKgPerAcreHigh).round(),
        kBeansMonthsLow,
        kBeansMonthsHigh,
      ),
  };
  final from = DateTime(i.floweredYear, i.floweredMonth + monthsLow);
  final to = DateTime(i.floweredYear, i.floweredMonth + monthsHigh);

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

// ---------------------------------------------------------------- questions

/// The farmer is asking how much she will harvest, or when (en, sw, fr), for a
/// crop the formulas know. Needs a harvest word AND a how-much/when word, and
/// no crop we have no figures for (whole words, so "price" is not "rice" and
/// "the" is not French "thé"). A question that names no crop is about the crop
/// of the conversation: see [cropKeyOf].
bool isHarvestQuestion(String q) {
  final t = q.toLowerCase();
  // Kiswahili: mavuno (harvest), kuvuna / nitavuna (to harvest / I will harvest).
  const harvestWords = ['harvest', 'yield', 'mavuno', 'vuna', 'récolte', 'recolte', 'rendement'];
  const howMuchOrWhen = [
    'how much', 'how many', 'when', 'kg', 'kilo', 'expect', 'forecast', // en
    'kiasi', 'ngapi', 'lini', 'tarajia', // sw
    'combien', 'quand', 'prévoir', 'prevoir', // fr
  ];
  return harvestWords.any(t.contains) && howMuchOrWhen.any(t.contains) && cropKeysIn(t).every(_hasFigures);
}

bool _hasFigures(String key) => harvestCropByKey(key) != null;

/// Whole words, with accented letters counted as letters (a plain \b does not,
/// so "café" or "blé" would never match).
RegExp _words(String alternatives) => RegExp('(?<!\\p{L})(?:$alternatives)(?!\\p{L})', unicode: true);

final _cropWords = <HarvestCrop, RegExp>{
  HarvestCrop.coffee: _words(r'coffee|kahawa|mikahawa|caf[ée]|caf[ée]iers?'),
  // Not "mais" (French "but"): only the spelling with ï.
  HarvestCrop.maize: _words(r'maize|corn|mahindi|maïs'),
  HarvestCrop.beans: _words(r'beans?|maharagwe|haricots?'),
};

/// Every crop named in [t] (lower case).
Set<HarvestCrop> _cropsIn(String t) => {
      for (final e in _cropWords.entries)
        if (e.value.hasMatch(t)) e.key,
    };

/// The crop named in [text], if any.
HarvestCrop? cropIn(String text) {
  final t = text.toLowerCase();
  for (final e in _cropWords.entries) {
    if (e.value.hasMatch(t)) return e.key;
  }
  return null;
}

/// Which crop a harvest question is about; coffee unless another is named.
/// The chat uses [cropKeyOf], which also reads the conversation.
HarvestCrop harvestCropOf(String question) => cropIn(question) ?? HarvestCrop.coffee;

// ---------------------------------------------------------------- any crop

/// Crops without harvest figures, by key, in English, Kiswahili and French, so
/// a message about potatoes is never read as one about coffee (the crop of a
/// message that names none). Order matters: "sweet potatoes" and "viazi vikuu"
/// (yams) are found first and are then not also "potatoes" / "viazi".
final _otherCropWords = <String, RegExp>{
  'sweet potato': _words(r'sweet\s+potato(?:e?s)?|viazi\s+vitamu|patates?\s+douces?'),
  'yam': _words(r'yams?|viazi\s+vikuu|ignames?'),
  'potato': _words(r'(?:irish\s+)?potato(?:e?s)?|spuds?|viazi(?:\s+(?:mviringo|ulaya))?|pommes?\s+de\s+terre|patates?'),
  'cassava': _words(r'cassava|muhogo|mihogo|manioc'),
  'rice': _words(r'rice|paddy|mchele|mpunga|riz'),
  'sorghum': _words(r'sorghum|mtama|sorgho'),
  'millet': _words(r'millets?|wimbi|uwele'),
  'wheat': _words(r'wheat|ngano|blé'),
  'banana': _words(r'bananas?|plantains?|ndizi|bananes?|bananiers?'),
  'tea': _words(r'tea|chai|thé'), // not "the"
  'tomato': _words(r'tomato(?:e?s)?|nyanya|tomates?'),
  'cabbage': _words(r'cabbages?|kale|sukuma(?:\s+wiki)?|kabichi|choux?'),
  'onion': _words(r'onions?|vitunguu|kitunguu|oignons?'),
  'avocado': _words(r'avocados?|parachichi|avocats?|avocatiers?'),
  'mango': _words(r'mango(?:e?s)?|maembe|embe|mangues?|manguiers?'),
  'groundnut': _words(r'groundnuts?|peanuts?|karanga|arachides?'),
  'sugarcane': _words(r'sugar\s*canes?|miwa|canne\s+à\s+sucre'),
  'cotton': _words(r'cotton|pamba|coton'),
  'sunflower': _words(r'sunflowers?|alizeti|tournesols?'),
  'cocoa': _words(r'cocoa|cacao|kakao'),
};

/// Every crop named in [t] (lower case): start, end and key ('coffee', 'maize',
/// 'beans' — see [HarvestCrop] — or a key of [_otherCropWords]).
List<(int, int, String)> _cropMentions(String t) {
  final out = <(int, int, String)>[
    for (final e in _cropWords.entries)
      for (final m in e.value.allMatches(t)) (m.start, m.end, e.key.name),
  ];
  var rest = t;
  for (final e in _otherCropWords.entries) {
    for (final m in e.value.allMatches(rest)) {
      out.add((m.start, m.end, e.key));
    }
    // Blanked out with spaces (so positions stay): "sweet potatoes" is not also "potatoes".
    rest = rest.replaceAllMapped(e.value, (m) => ' ' * m[0]!.length);
  }
  return out;
}

/// Every crop named in [text], by key: 'coffee', 'maize' or 'beans' (the crops
/// with figures, [HarvestCrop.name]) or another crop ('potato', 'rice', …).
Set<String> cropKeysIn(String text) => {for (final m in _cropMentions(text.toLowerCase())) m.$3};

/// The crop with harvest figures for [key], or null ('potato', 'rice', …).
HarvestCrop? harvestCropByKey(String key) {
  for (final c in HarvestCrop.values) {
    if (c.name == key) return c;
  }
  return null;
}

/// The word the farmer used for the crop [key] in [text] ("potatoes", "viazi"),
/// so an answer can name it in her language; null if [text] does not name it.
String? cropWordIn(String text, String key) {
  final t = text.toLowerCase();
  for (final m in _cropMentions(t)) {
    if (m.$3 == key) return t.substring(m.$1, m.$2);
  }
  return null;
}

/// Which crop a message is about, by key (see [cropKeysIn]):
///  1. the crop it names (a crop with figures first, as [cropIn]);
///  2. else the crop of the farmer's recent messages ([recent], newest first):
///     "…planted the potatoes in March" then "How much will we harvest?" is
///     about potatoes. The newest message naming a crop decides; if it names
///     several, the conversation does not say which;
///  3. else the only crop with farm facts saved ([farmFactKeys], like
///     'maize-acres' — pass them for harvest questions).
/// Null when nothing says which crop.
String? cropKeyOf(String question, {Iterable<String> recent = const [], Iterable<String> farmFactKeys = const []}) {
  final named = cropKeysIn(question);
  if (named.isNotEmpty) return cropIn(question)?.name ?? named.first;
  for (final r in recent) {
    final keys = cropKeysIn(r);
    if (keys.length == 1) return keys.single;
    if (keys.length > 1) break;
  }
  final withFacts = {for (final k in farmFactKeys) k.split('-').first};
  return withFacts.length == 1 ? withFacts.single : null;
}

/// Crops the knowledge base (assets/knowledge) has a guide for. A question
/// about any other crop must not be answered from another crop's guide.
const cropsWithGuides = {'coffee', 'maize', 'beans', 'cassava', 'rice', 'sorghum', 'millet', 'sweet potato'};

/// The knowledge file [source] is a guide for a crop other than [key]
/// ("sweet_potato_growing.md" when the farmer asks about potatoes). General
/// guides (soil, compost, pests, water, storage…) are for every crop.
bool guideForAnotherCrop(String source, String key) {
  const guides = <String, Set<String>>{
    'coffee_': {'coffee'},
    'maize_': {'maize'},
    'bean_': {'beans'},
    'beans_': {'beans'},
    'cassava_': {'cassava'},
    'rice_': {'rice'},
    'sweet_potato_': {'sweet potato'},
    'sorghum_and_millet_': {'sorghum', 'millet'},
  };
  for (final e in guides.entries) {
    if (source.startsWith(e.key)) return !e.value.contains(key);
  }
  return false;
}

// ---------------------------------------------------------------- reading facts

/// Reads the inputs for [crop] from things the farmer said or wrote, most
/// relevant first (put the question first, then saved farm facts, then the
/// rest of My farm, newest first): the first fact that gives a value wins, so
/// newer statements replace older ones. Works in English, Kiswahili and French
/// (My farm keeps facts in the farmer's language).
///  - coffee: trees ("400 coffee trees", "miti 400 ya kahawa", "400 caféiers"),
///    or acres of coffee; flowering month; a planting year makes young trees.
///    Counts of "new" / "more" trees are not the farm's total.
///  - maize, beans: acres of that crop; planting month.
/// Returns null only when the quantity (trees or acres) is unknown; a missing
/// month becomes Kenya's usual season ([kUsualMonth], flagged as assumed).
HarvestInputs? harvestInputsFrom(Iterable<String> facts, {required DateTime today, HarvestCrop crop = HarvestCrop.coffee}) {
  int? trees, month, plantedYear;
  double? acres;
  for (final f in facts) {
    final t = f.toLowerCase();
    final keys = cropKeysIn(t);
    // A fact that names no crop is about coffee, the app's main crop; one that
    // names only other crops ("2 acres of potatoes") is not.
    final unnamed = keys.isEmpty;
    final aboutThisCrop = keys.contains(crop.name) || (unnamed && crop == HarvestCrop.coffee);
    if (crop == HarvestCrop.coffee && trees == null && aboutThisCrop) trees = _treesIn(t);
    if (acres == null && aboutThisCrop) acres = _acresFor(t, crop.name, unnamed: unnamed);
    if (month == null && aboutThisCrop) month = _monthFor(t, crop);
    if (crop == HarvestCrop.coffee && plantedYear == null && aboutThisCrop && _planting.hasMatch(t)) {
      plantedYear = _yearIn(t);
    }
  }
  if (crop == HarvestCrop.coffee ? (trees == null && acres == null) : acres == null) return null;
  final assumed = month == null;
  final m = month ?? kUsualMonth;
  // The flowering / planting that feeds this season: the latest one not in the future.
  final year = m <= today.month ? today.year : today.year - 1;
  return HarvestInputs(
    crop: crop,
    trees: crop == HarvestCrop.coffee ? trees : null,
    acres: crop == HarvestCrop.coffee && trees != null ? null : acres,
    floweredMonth: m,
    floweredYear: year,
    monthAssumed: assumed,
    youngTrees: crop == HarvestCrop.coffee && plantedYear != null && today.year - plantedYear < kCoffeeYearsToFirstCrop,
  );
}

/// One clean farm fact found in what the farmer said, to remember exactly
/// (instead of hoping a summary keeps the number). [key] is unique per kind of
/// fact, so a newer value replaces the older one.
class FarmFact {
  const FarmFact.trees(this.count)
      : key = 'coffee-trees',
        crop = HarvestCrop.coffee,
        acres = null,
        month = null;
  FarmFact.acres(this.crop, double this.acres)
      : key = '${crop.name}-acres',
        count = null,
        month = null;
  FarmFact.month(this.crop, int this.month)
      : key = '${crop.name}-month',
        count = null,
        acres = null;

  final String key;
  final HarvestCrop crop;
  final int? count;
  final double? acres;

  /// Coffee: flowering month. Maize and beans: planting month.
  final int? month;

  /// The sentence saved in My farm, in the farmer's language. Written so that
  /// [harvestInputsFrom] reads it back.
  String text(S s) {
    final cropName = switch (crop) {
      HarvestCrop.coffee => s.guidesCoffee,
      HarvestCrop.maize => s.guidesMaize,
      HarvestCrop.beans => s.guidesBeans,
    }.toLowerCase();
    if (count != null) return s.factTrees(count!);
    if (acres != null) return s.factAcres(_acresText(acres!), cropName);
    final monthName = s.monthsLong[month! - 1];
    return crop == HarvestCrop.coffee ? s.factFlowered(monthName) : s.factPlanted(cropName, monthName);
  }
}

/// The farm facts in one message or note: trees, acres per crop, and the
/// flowering (coffee) or planting (maize, beans) month. [askedFor]: the crop we
/// just asked about, so a short reply like "400" or "about 2" is understood
/// (trees for coffee, acres for maize and beans).
/// [isQuestion]: a question is not a statement of fact ("When should I plant
/// maize in March?"), so it gives no month, and acres only with a crop named.
List<FarmFact> farmFactsIn(String text, {HarvestCrop? askedFor, bool isQuestion = false}) {
  final t = text.toLowerCase();
  final keys = cropKeysIn(t);
  // No crop named: coffee, the app's main crop. Only crops without figures
  // named ("I planted 2 acres of potatoes"): nothing here is a coffee fact.
  final crops = keys.isEmpty ? {HarvestCrop.coffee} : _cropsIn(t);
  final out = <FarmFact>[];
  if (crops.contains(HarvestCrop.coffee)) {
    final trees = _treesIn(t);
    if (trees != null) out.add(FarmFact.trees(trees));
  }
  for (final c in HarvestCrop.values.where(crops.contains)) {
    // An area with no crop named is coffee's only in a statement with nothing else in it.
    final acres = keys.isNotEmpty
        ? _acresFor(t, c.name)
        : out.isEmpty && !isQuestion
            ? _acresFor(t, c.name, unnamed: true)
            : null;
    if (acres != null) out.add(FarmFact.acres(c, acres));
  }
  if (!isQuestion) {
    for (final c in HarvestCrop.values.where(crops.contains)) {
      final month = _monthFor(t, c);
      if (month != null) out.add(FarmFact.month(c, month));
    }
  }
  final otherCrop = keys.isNotEmpty && !keys.contains(askedFor?.name);
  if (out.isEmpty && askedFor != null && !otherCrop && t.trim().split(RegExp(r'\s+')).length <= 4) {
    final m = RegExp(r'(?<![\d,.])(\d{1,3}(?:[,\s]\d{3})+|\d+(?:[.,]\d+)?)').firstMatch(t);
    final v = m == null ? null : double.tryParse(m.group(1)!.replaceAll(RegExp(r'[,\s](?=\d{3})'), '').replaceAll(',', '.'));
    if (v != null && v > 0) {
      out.add(askedFor == HarvestCrop.coffee ? FarmFact.trees(v.round()) : FarmFact.acres(askedFor, v));
    }
  }
  return out;
}

String _acresText(double a) => a == a.roundToDouble() ? a.round().toString() : a.toStringAsFixed(1);

/// A count as farmers write it: 400, 1,200 or 1 200 (not the end of a year
/// just before it, as in "in 2024 400 trees").
const _count = r'(?<![\d,.])(\d{1,3}(?:[,.\s]\d{3})+|\d+)';

final _treePatterns = [
  // 400 trees · 400 coffee trees · 400 young coffee trees (group 2: the words between)
  RegExp('$_count\\s+((?:[a-z]+\\s+){0,2})trees'),
  RegExp('$_count\\s+()(?:caf[ée]iers|arbres|pieds)'), // 400 caféiers / arbres / pieds de café
  RegExp('$_count\\s+()(?:miti|mikahawa)'), // 400 mikahawa
  // miti 400 ya kahawa · miti ya kahawa takriban 400
  RegExp('(?:miti|mikahawa)\\s+(?:ya\\s+kahawa\\s+)?(?:(?:takriban|karibu|kama|zaidi\\s+ya)\\s+)?$_count()'),
];

/// "50 new trees" is an addition, not the farm's total.
final _notATotal = _words(r'new|more|extra|additional|another|other|mpya|nouveaux|suppl[ée]mentaires|autres');

int? _treesIn(String t) {
  for (final p in _treePatterns) {
    for (final m in p.allMatches(t)) {
      if (_notATotal.hasMatch(m.group(2) ?? '')) continue;
      // "planted 50 new trees", "nimepanda miti 50 mipya": an addition too.
      final after = t.substring(m.end, (m.end + 12).clamp(0, t.length));
      if (RegExp(r'^\s*(?:mipya|nouveaux|de plus)').hasMatch(after)) continue;
      final n = int.tryParse(m.group(1)!.replaceAll(RegExp(r'\D'), ''));
      if (n != null && n > 0) return n;
    }
  }
  return null;
}

/// Every area in [t]: "2 acres", "1.5 ha", "2 hectares", "ekari 2", "1,5 ha".
/// Start, end and the area in acres, in reading order.
List<(int, int, double)> _areasIn(String t) {
  const number = r'(\d+(?:[.,]\d+)?)';
  final out = <(int, int, double)>[];
  void add(RegExpMatch m, String n, String unit) {
    final v = double.tryParse(n.replaceAll(',', '.'));
    if (v != null && v > 0) out.add((m.start, m.end, unit.startsWith('h') ? v * _hectareInAcres : v));
  }

  for (final m in RegExp('$number\\s*(acres?|ac|ekari|hectares?|ha)\\b').allMatches(t)) {
    add(m, m.group(1)!, m.group(2)!);
  }
  for (final m in RegExp('\\b(ekari|hekta|hectares?)\\s+(?:takriban\\s+|karibu\\s+)?$number').allMatches(t)) {
    add(m, m.group(2)!, m.group(1)!);
  }
  return out..sort((a, b) => a.$1.compareTo(b.$1));
}

/// Acres of the crop [key] in [t]. An area belongs to the crop named closest
/// to it, preferring the one right after it ("2 acres of maize and 1 acre of
/// potatoes": maize 2, potatoes 1). An area in a sentence that names no crop
/// counts only when [unnamed] is true.
double? _acresFor(String t, String key, {bool unnamed = false}) {
  final mentions = _cropMentions(t);
  for (final (start, end, acres) in _areasIn(t)) {
    if (mentions.isEmpty) {
      if (unnamed) return acres;
      continue;
    }
    int gap((int, int, String) m) => m.$1 >= end ? m.$1 - end : start - m.$2 + 3;
    final nearest = mentions.reduce((a, b) => gap(b) < gap(a) ? b : a);
    if (nearest.$3 == key) return acres;
  }
  return null;
}

int? _yearIn(String t) {
  final m = RegExp(r'\b(19[5-9]\d|20\d\d)\b').firstMatch(t);
  return m == null ? null : int.parse(m.group(1)!);
}

/// Flowering and planting, as real words (not any substring: "semblait" is not
/// "semer", "semaine" is not sowing). Kiswahili verbs take prefixes
/// (ilitoa maua, ilichanua, nilipanda, ilipandwa), so those match inside a word.
final _flowering = RegExp(
  r'(?<!\p{L})(?:flower(?:ed|ing|s)?|bloom(?:ed|ing|s)?|fleur(?:i|ie|is|it|issent|ir|aison)?|florais\w*)(?!\p{L})'
  r'|maua|chanua',
  unicode: true,
);
final _planting = RegExp(
  r'(?<!\p{L})(?:plant(?:ed|ing)?|sow(?:ed|n|ing)?|sem[ée](?:e|s|es)?|semer|semons|plant[ée](?:e|s|es)?|planter)(?!\p{L})'
  r'|pand(?:a|wa|e)',
  unicode: true,
);

/// The flowering (coffee) or planting (maize, beans) month for [crop] in one
/// fact. When the sentence names several crops ("le maïs a fleuri en mai, mais
/// le café en juin"), the month named after this crop's word.
int? _monthFor(String t, HarvestCrop crop) {
  final words = crop == HarvestCrop.coffee ? _flowering : _planting;
  if (!words.hasMatch(t)) return null;
  if (cropKeysIn(t).length > 1) {
    final at = _cropWords[crop]!.firstMatch(t);
    if (at != null) {
      final month = _firstMonthFrom(t, at.end);
      if (month != null) return month;
    }
  }
  return _monthAfter(t, words);
}

int? _firstMonthFrom(String t, int start) {
  final found = [
    for (final (re, n) in _monthPatterns)
      for (final m in re.allMatches(t))
        if (m.start >= start) (m.start, n),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  return found.isEmpty ? null : found.first.$2;
}

/// The month that belongs to the flowering / planting: the first one named after
/// the word ("flowered in March, sprayed in May" → March; "they may flower in
/// April" → April), else the closest one before it.
int? _monthAfter(String t, RegExp words) {
  final key = words.firstMatch(t)?.start;
  if (key == null) return null;
  final found = [
    for (final (re, n) in _monthPatterns)
      for (final m in re.allMatches(t)) (m.start, n),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  final after = found.where((m) => m.$1 >= key);
  if (after.isNotEmpty) return after.first.$2;
  return found.isNotEmpty ? found.last.$2 : null;
}

/// [month] (1–12) is named in [text], in English, Kiswahili or French.
bool monthNamedIn(String text, int month) {
  final t = text.toLowerCase();
  return _monthPatterns.any((p) => p.$2 == month && p.$1.hasMatch(t));
}

/// English (first three letters: "Mar", "March"), plus the Kiswahili and French
/// names that do not start the same way. Short words like "mai" must stand
/// alone ("mais", "maize" are not May).
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
