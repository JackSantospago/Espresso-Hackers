/// Every piece of text the farmer sees, in each supported language.
///
/// Plain Dart instead of ARB/codegen so the build stays simple: adding a field
/// to [S] makes the compiler point at every language that is missing it.
/// The LLM is told to answer in the language of the question, so these strings
/// cover the fixed parts of the app (buttons, fail-safe answers, privacy text).
///
/// Kiswahili and French are first drafts — have a native speaker review them.
library;

enum AppLanguage {
  en('English'),
  sw('Kiswahili'),
  fr('Français');

  const AppLanguage(this.nativeName);
  final String nativeName;
}

class S {
  S({
    required this.appName,
    required this.offlineBadge,
    required this.language,
    required this.answersLanguageNote,
    required this.setupIntro,
    required this.setupDownload,
    required this.setupPoints,
    required this.setupButton,
    required this.setupDownloading,
    required this.setupIndexing,
    required this.setupFailed,
    required this.retry,
    required this.tabAsk,
    required this.tabFarm,
    required this.tabOfficer,
    required this.tabHelp,
    required this.tabGrow,
    required this.tabSell,
    required this.sellIntro,
    required this.sellComing,
    required this.comingSoon,
    required this.demoTag,
    required this.newOffer,
    required this.wantsKg,
    required this.vsMarket,
    required this.pickupIn,
    required this.kmAway,
    required this.expiresIn,
    required this.view,
    required this.decline,
    required this.acceptOffer,
    required this.saleAgreed,
    required this.offersTitle,
    required this.offersSynced,
    required this.salesHistory,
    required this.noSalesYet,
    required this.marketPrice,
    required this.noOffers,
    required this.marketRef,
    required this.quantity,
    required this.pricePerKg,
    required this.youReceive,
    required this.payment,
    required this.paymentOnPickup,
    required this.noFees,
    required this.verifiedBuyer,
    required this.ratingSales,
    required this.salesTitle,
    required this.seasonSummary,
    required this.statusPaid,
    required this.tipsTitle,
    required this.sellTips,
    required this.harvestTitle,
    required this.thisSeason,
    required this.harvestEstimate,
    required this.readyWindow,
    required this.soldKg,
    required this.offeredKg,
    required this.toSellKg,
    required this.howWorked,
    required this.treesTimesYield,
    required this.floweredRipe,
    required this.harvestSources,
    required this.seeInSell,
    required this.askHarvestTitle,
    required this.askHarvestBody,
    required this.askNow,
    required this.harvestQuestion,
    required this.statusCalculating,
    required this.harvestNeed,
    required this.factTrees,
    required this.factAcres,
    required this.factFlowered,
    required this.factPlanted,
    required this.treesFromAcres,
    required this.acresTimesYield,
    required this.plantedReady,
    required this.usualSeason,
    required this.harvestYoung,
    required this.harvestNeedArea,
    required this.notedForForecast,
    required this.harvestSummary,
    required this.monthsShort,
    required this.monthsLong,
    required this.sellTitle,
    required this.sellSubtitle,
    required this.promiseTitles,
    required this.promiseTexts,
    required this.howShort,
    required this.moreDetails,
    required this.greetingMorning,
    required this.greetingAfternoon,
    required this.greetingEvening,
    required this.copy,
    required this.copied,
    required this.loadingModel,
    required this.loadFailed,
    required this.welcomeTitle,
    required this.welcomeBody,
    required this.suggestions,
    required this.checkLeaf,
    required this.inputHint,
    required this.send,
    required this.photoTake,
    required this.photoGallery,
    required this.photoTip,
    required this.photoNotInstalled,
    required this.photoDefaultQuestion,
    required this.newChat,
    required this.statusSearching,
    required this.statusThinking,
    required this.statusCheckingPhoto,
    required this.statusLookingUp,
    required this.statusUpdatingMemory,
    required this.notSure,
    required this.weakMatch,
    required this.notCovered,
    required this.healthy,
    required this.photoNotSureOther,
    required this.photoNotSureGuess,
    required this.photoNotSure,
    required this.photoCaution,
    required this.photoAskDefault,
    required this.photoMemoryHealthy,
    required this.photoMemoryProblem,
    required this.crops,
    required this.leafConditions,
    required this.diagLikely,
    required this.diagHealthy,
    required this.diagNotSure,
    required this.diagSure,
    required this.diagThreshold,
    required this.askPerson,
    required this.sources,
    required this.matchStrong,
    required this.matchWeak,
    required this.details,
    required this.sendToOfficer,
    required this.queuedNote,
    required this.consentTitle,
    required this.consentBody,
    required this.cancel,
    required this.save,
    required this.delete,
    required this.growIntro,
    required this.farmTitle,
    required this.factsCount,
    required this.addNote,
    required this.addNoteHint,
    required this.noteSaved,
    required this.seeAll,
    required this.guidesTitle,
    required this.guidesNote,
    required this.seeAllGuides,
    required this.weather,
    required this.guidesEmpty,
    required this.askAbout,
    required this.askAboutThis,
    required this.officerSummary,
    required this.guidesAll,
    required this.guidesCoffee,
    required this.guidesMaize,
    required this.guidesBeans,
    required this.guidesMore,
    required this.guidesSearch,
    required this.guidesNoMatch,
    required this.memoryTitle,
    required this.memoryIntro,
    required this.memoryEmpty,
    required this.forget,
    required this.forgotten,
    required this.forgetAll,
    required this.forgetAllConfirm,
    required this.outboxTitle,
    required this.outboxIntro,
    required this.outboxEmpty,
    required this.noNote,
    required this.statusSent,
    required this.statusWaiting,
    required this.appGuess,
    required this.sendNow,
    required this.nothingToSend,
    required this.deletePhotoConfirm,
    required this.sendNothing,
    required this.sendNoServer,
    required this.sendOffline,
    required this.sendDone,
    required this.helpTitle,
    required this.howTitle,
    required this.how,
    required this.privacyTitle,
    required this.privacy,
    required this.limitsTitle,
    required this.limits,
    required this.onThisPhone,
    required this.modelLlm,
    required this.modelEmbedder,
    required this.modelLeaf,
    required this.installed,
    required this.notInstalled,
    required this.passages,
  });

  static S forLanguage(AppLanguage l) => switch (l) {
        AppLanguage.en => _en,
        AppLanguage.sw => _sw,
        AppLanguage.fr => _fr,
      };

  // General
  final String appName, offlineBadge, language, answersLanguageNote;

  // Setup
  final String setupIntro;
  final String Function(String llm, String llmSize, String emb, String embSize) setupDownload;
  final List<String> setupPoints;
  final String setupButton;
  final String Function(String name, String size) setupDownloading;
  final String setupIndexing, setupFailed, retry;

  // Tabs
  final String tabAsk, tabFarm, tabOfficer, tabHelp, tabGrow, tabSell;

  // Sell (placeholder until there is a market feature)
  final String sellIntro;
  final List<String> sellComing;
  final String comingSoon, sellTitle, sellSubtitle;

  // Sell: marketplace demo (offers from buyers, fairness vs a market reference, records)
  final String demoTag;
  final String newOffer;
  final String Function(String buyer, int kg) wantsKg;
  final String Function(int pct) vsMarket;
  final String Function(int days) pickupIn;
  final String Function(int km) kmAway;
  final String Function(int hours) expiresIn;
  final String view;
  final String decline;
  final String acceptOffer;
  final String Function(String buyer) saleAgreed;
  final String offersTitle, offersSynced, salesHistory, noSalesYet, marketPrice;
  final String noOffers;
  final String Function(String price) marketRef;
  final String quantity;
  final String pricePerKg;
  final String youReceive;
  final String payment;
  final String paymentOnPickup;
  final String noFees;
  final String verifiedBuyer;
  final String Function(String rating, int sales) ratingSales;
  final String salesTitle;
  final String Function(int kg, String total) seasonSummary;
  final String statusPaid;
  final String tipsTitle;
  final List<String> sellTips;

  // Harvest forecast (chat card + Sell chart)
  final String harvestTitle;
  final String thisSeason;
  final String harvestEstimate;
  final String Function(String from, String to) readyWindow;
  final String soldKg;
  final String offeredKg;
  final String toSellKg;
  final String howWorked;
  final String Function(int trees, String low, String high) treesTimesYield;
  final String Function(String month, int low, int high) floweredRipe;
  final String harvestSources;
  final String seeInSell;
  final String askHarvestTitle;
  final String askHarvestBody;
  final String askNow;
  final String harvestQuestion;
  final String statusCalculating;
  final String harvestNeed;
  final String Function(int n) factTrees;
  final String Function(String acres, String crop) factAcres;
  final String Function(String month) factFlowered;
  final String Function(String crop, String month) factPlanted;
  final String Function(String acres, int perAcre, int trees) treesFromAcres;
  final String Function(String acres, int low, int high) acresTimesYield;
  final String Function(String month, int low, int high) plantedReady;
  final String usualSeason;
  final String harvestYoung;
  final String Function(String crop) harvestNeedArea;
  final String notedForForecast;
  final String Function(String low, String high, String from, String to) harvestSummary;
  final List<String> monthsShort;
  final List<String> monthsLong;

  // Help (short versions for the main view; the long lists sit under "More details")
  final List<String> promiseTitles, promiseTexts, howShort;
  final String moreDetails;

  // Chat extras
  final String greetingMorning, greetingAfternoon, greetingEvening, copy, copied;

  // Chat
  final String loadingModel, loadFailed, welcomeTitle, welcomeBody;
  final List<String> suggestions;
  final String checkLeaf, inputHint, send, photoTake, photoGallery, photoTip, photoNotInstalled;
  final String photoDefaultQuestion, newChat;
  final String statusSearching, statusThinking, statusCheckingPhoto;
  final String Function(String condition) statusLookingUp;
  final String statusUpdatingMemory;

  // Fixed answers (the fail-safes)
  final String notSure, weakMatch;

  /// A crop the guides have nothing on, named the way the farmer wrote it.
  final String Function(String crop) notCovered;
  final String Function(String crop, String percent) healthy;
  final String photoNotSureOther;
  final String Function(String label, String percent) photoNotSureGuess;
  final String Function(String guess) photoNotSure;
  final String photoCaution;
  final String Function(String crop) photoAskDefault;

  /// Written to My farm after a confident photo check (a machine guess, so worded as one).
  final String Function(String date, String crop, String percent) photoMemoryHealthy;
  final String Function(String date, String crop, String condition, String percent) photoMemoryProblem;

  /// The leaf model's crops ('coffee', 'bean', 'maize') and conditions (by
  /// label id, see assets/models/leaf_classifier.json) in this language.
  final Map<String, String> crops, leafConditions;

  /// "Coffee" from the leaf model → "kahawa" (lower case, for use in a sentence).
  String cropName(String crop) => crops[crop.toLowerCase()] ?? crop.toLowerCase();

  /// "leaf rust" (label id coffee__leaf_rust) → "kutu ya majani".
  String conditionName(String labelId, String fallback) => leafConditions[labelId] ?? fallback;

  /// A leaf model label as a title: "Kahawa – kutu ya majani".
  String leafLabel(String labelId, String crop, String condition) {
    final c = conditionName(labelId, condition);
    if (crop.isEmpty) return c;
    final name = cropName(crop);
    return '${name[0].toUpperCase()}${name.substring(1)} – $c';
  }

  // Diagnosis card
  final String diagLikely, diagHealthy, diagNotSure;
  final String Function(String percent) diagSure, diagThreshold;

  // Message bubble
  final String askPerson, sources, matchStrong, matchWeak, details;
  final String sendToOfficer, queuedNote, consentTitle, consentBody, cancel, save, delete;

  // Grow (overview of the farm, the guides on the phone, the officer)
  final String growIntro, farmTitle, addNote, addNoteHint, noteSaved, seeAll;
  final String Function(int n) factsCount, seeAllGuides;
  final String guidesTitle, guidesNote, guidesEmpty, askAboutThis;
  final String Function(String topic) askAbout;
  final String Function(int waiting, int sent) officerSummary;
  final String guidesAll, guidesCoffee, guidesMaize, guidesBeans, guidesMore, guidesSearch, guidesNoMatch;

  // Grow → Weather (forecast card and screen, weather advice)
  final WeatherStrings weather;

  // Memory
  final String memoryTitle, memoryIntro, memoryEmpty, forget, forgotten, forgetAll, forgetAllConfirm;

  // Outbox
  final String outboxTitle, outboxIntro, outboxEmpty, noNote, statusSent, statusWaiting, appGuess;
  final String Function(int n) sendNow;
  final String nothingToSend, deletePhotoConfirm, sendNothing;
  final String Function(int n) sendNoServer, sendOffline;
  final String Function(int sent, int left) sendDone;

  // Help
  final String helpTitle, howTitle, privacyTitle, limitsTitle;
  final List<String> how, privacy, limits;
  final String onThisPhone, modelLlm, modelEmbedder, modelLeaf, installed, notInstalled;
  final String Function(int n) passages;
}

/// Texts of the weather card and screen in Grow, and of the weather advice.
class WeatherStrings {
  const WeatherStrings({
    required this.title,
    required this.screenTitle,
    required this.intro,
    required this.privacyNote,
    required this.turnOn,
    required this.setUp,
    required this.locating,
    required this.farmHere,
    required this.turnOff,
    required this.turnOffConfirm,
    required this.permissionDenied,
    required this.locationOff,
    required this.noFix,
    required this.openSettings,
    required this.notUpdated,
    required this.waiting,
    required this.updating,
    required this.updated,
    required this.stale,
    required this.ago,
    required this.farmAt,
    required this.warningsTitle,
    required this.nextDays,
    required this.noAlerts,
    required this.askWhatToDo,
    required this.statusChecking,
    required this.noAlertsAnswer,
    required this.caution,
    required this.attribution,
    required this.today,
    required this.tomorrow,
    required this.frost,
    required this.heat,
    required this.heavyRain,
    required this.wind,
    required this.storm,
    required this.hail,
    required this.drySpell,
    required this.wetSpell,
    required this.frostDetail,
    required this.heatDetail,
    required this.rainDetail,
    required this.windDetail,
    required this.daysCount,
    required this.dryDetail,
    required this.wetDetail,
    required this.weekdays,
    required this.months,
    required this.replyLanguage,
  });

  final String title, screenTitle, intro, privacyNote, turnOn, setUp, locating, farmHere, turnOff, turnOffConfirm;
  final String permissionDenied, locationOff, noFix, openSettings, notUpdated, waiting, updating;
  final String Function(String ago) updated, stale;
  final String Function(Duration age) ago;
  final String Function(String place, int? elevation) farmAt;
  final String warningsTitle;
  final String Function(int n) nextDays;
  final String noAlerts, askWhatToDo, statusChecking, noAlertsAnswer, caution, attribution, today, tomorrow;

  // Warning titles and details (numbers come from the app's rules, not the LLM)
  final String frost, heat, heavyRain, wind, storm, hail, drySpell, wetSpell;
  final String Function(int c) frostDetail, heatDetail;
  final String Function(int mm) rainDetail;
  final String Function(int kmh) windDetail;
  final String Function(int n) daysCount, dryDetail, wetDetail;

  /// Monday first / January first.
  final List<String> weekdays, months;

  /// The language the LLM is asked to write the weather advice in.
  final String replyLanguage;

  String date(DateTime d) => '${weekdays[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
}

// ------------------------------------------------------------------ English

final S _en = S(
  appName: 'Botato',
  offlineBadge: 'Works offline',
  language: 'Language',
  answersLanguageNote: 'Answers follow the language of your question.',
  setupIntro: 'Ask farming questions and check leaf photos. Answers come from farming guides stored on this phone.',
  setupDownload: (llm, llmSize, emb, embSize) =>
      'One-time download: $llm ($llmSize) and $emb ($embSize). Use Wi-Fi or a data bundle once — '
      'after that everything works offline.',
  setupPoints: [
    'Private: your questions never leave the phone.',
    'Honest: if it is not sure, it tells you to ask a person.',
    'You decide: it gives advice, it never acts for you.',
  ],
  setupButton: 'Download & set up',
  setupDownloading: (name, size) => 'Downloading $name ($size)…',
  setupIndexing: 'Preparing the farming guides…',
  setupFailed: 'Setup failed',
  retry: 'Try again',
  tabAsk: 'Ask',
  tabFarm: 'My farm',
  tabOfficer: 'Officer',
  tabHelp: 'Help',
  tabGrow: 'Grow',
  tabSell: 'Sell',
  comingSoon: 'Coming soon',
  demoTag: 'Demo',
  newOffer: 'New offer',
  wantsKg: (buyer, kg) => '$buyer wants $kg kg',
  vsMarket: (pct) => pct >= 0 ? '$pct% above market' : '${-pct}% below market',
  pickupIn: (days) => days == 1 ? 'Pickup tomorrow' : 'Pickup in $days days',
  kmAway: (km) => '$km km away',
  expiresIn: (hours) => 'Expires in $hours h',
  view: 'View',
  decline: 'Decline',
  acceptOffer: 'Accept offer',
  saleAgreed: (buyer) => 'Sale agreed with $buyer.',
  offersTitle: 'Offers from buyers',
  offersSynced: 'Received the last time your phone was online.',
  salesHistory: 'Sales history',
  noSalesYet: 'No sales yet this season.',
  marketPrice: 'Market price this week',
  noOffers: 'No new offers right now.',
  marketRef: (price) => 'Market reference this week: $price/kg',
  quantity: 'Quantity',
  pricePerKg: 'Price per kg',
  youReceive: 'You receive',
  payment: 'Payment',
  paymentOnPickup: 'Paid by mobile money at pickup',
  noFees: 'No middleman fees',
  verifiedBuyer: 'Verified buyer',
  ratingSales: (rating, sales) => '★ $rating · $sales sales',
  salesTitle: 'Your sales',
  seasonSummary: (kg, total) => 'This season: $kg kg · $total',
  statusPaid: 'Paid',
  tipsTitle: 'Tips to sell better',
  sellTips: [
    'Compare offers with the market price.',
    'Weigh your batch before pickup.',
    'Keep every receipt.',
  ],
  harvestTitle: 'Your harvest',
  thisSeason: 'this season',
  harvestEstimate: 'Estimate',
  readyWindow: (from, to) => 'Ready $from → $to',
  soldKg: 'Sold',
  offeredKg: 'Offers',
  toSellKg: 'To sell',
  howWorked: 'How I worked it out',
  treesTimesYield: (trees, low, high) => '$trees trees × $low–$high kg per tree',
  floweredRipe: (month, low, high) => 'Flowered in $month, ripe $low–$high months later',
  harvestSources: 'Source: Kenyan smallholder averages.',
  seeInSell: 'See in Sell',
  askHarvestTitle: 'How much will you harvest?',
  askHarvestBody: 'The assistant works it out from your farm facts.',
  askNow: 'Ask the assistant',
  harvestQuestion: 'How much coffee will I harvest, and when?',
  statusCalculating: 'Calculating your harvest…',
  harvestNeed: 'How many coffee trees do you have (or how many acres)?',
  factTrees: (n) => 'I have $n coffee trees.',
  factAcres: (acres, crop) => 'I have $acres acres of $crop.',
  factFlowered: (month) => 'My coffee trees flowered in $month.',
  factPlanted: (crop, month) => 'I planted my $crop in $month.',
  treesFromAcres: (acres, perAcre, trees) => '$acres acres × $perAcre trees per acre ≈ $trees trees',
  acresTimesYield: (acres, low, high) => '$acres acres × $low–$high kg per acre',
  plantedReady: (month, low, high) => 'Planted in $month, ready $low–$high months later',
  usualSeason: 'usual season',
  harvestYoung: 'Your coffee trees are still young: coffee first flowers 3 to 4 years after planting, so there is no harvest to forecast yet.',
  harvestNeedArea: (crop) => 'How many acres of $crop did you plant?',
  notedForForecast: 'Noted. I will use this for your harvest forecast.',
  harvestSummary: (low, high, from, to) => 'About $low–$high kg, ready $from to $to.',
  monthsShort: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
  monthsLong: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
  sellTitle: 'Sell your harvest',
  sellSubtitle: 'Everything to get your harvest to market.',
  promiseTitles: [
    'Private',
    'Honest',
    'You decide',
  ],
  promiseTexts: [
    'Your questions never leave this phone.',
    'When it is not sure, it says so.',
    'It advises. You make the decision.',
  ],
  howShort: [
    'Ask, or photograph a leaf.',
    'It reads the guides on this phone. No internet needed.',
    'Not sure? It points you to your extension officer.',
  ],
  moreDetails: 'More details',
  greetingMorning: 'Good morning',
  greetingAfternoon: 'Good afternoon',
  greetingEvening: 'Good evening',
  copy: 'Copy',
  copied: 'Copied',
  sellIntro: 'Selling your harvest is coming soon. Here is what this page will help with:',
  sellComing: [
    'Harvest and sales record',
    'Buyers and cooperatives near you',
    'Prepare coffee for the buyer',
  ],
  loadingModel: 'Loading the assistant…',
  loadFailed: 'The assistant could not start.',
  welcomeTitle: 'How can I help your farm today?',
  welcomeBody: 'Ask in your own words, or take a photo of a leaf.',
  suggestions: [
    'Why is my coffee harvest smaller this year?',
    'How do I manage coffee leaf rust?',
    'What is coffee berry borer?',
    'When should I prune old coffee trees?',
  ],
  checkLeaf: 'Check a leaf photo',
  inputHint: 'Ask about your farm…',
  send: 'Send',
  photoTake: 'Take a photo of one leaf',
  photoGallery: 'Choose from gallery',
  photoTip: 'One leaf, in daylight, filling the screen, spots in focus.',
  photoNotInstalled: 'Photo check is not installed on this phone yet.',
  photoDefaultQuestion: 'What is wrong with this leaf?',
  newChat: 'New conversation',
  statusSearching: 'Searching the guides…',
  statusThinking: 'Thinking…',
  statusCheckingPhoto: 'Checking the photo…',
  statusLookingUp: (c) => 'Looking up $c…',
  statusUpdatingMemory: 'Remembering what you told me…',
  notSure: "I'm not sure. Please ask your extension officer or cooperative.",
  weakMatch: 'Weak match in my guides. Please check this with a person.',
  notCovered: (crop) => 'My guides do not cover $crop yet. Please ask your extension officer or cooperative.',
  healthy: (crop, pct) => 'This $crop leaf looks healthy ($pct sure). '
      'If other leaves, berries or stems look different, take a photo of those too. '
      'Many causes of a smaller harvest (soil, rain, tree age) do not show on leaves — '
      'your extension officer can help find them.',
  photoNotSureOther: 'It does not look like a coffee, bean or maize leaf I know.',
  photoNotSureGuess: (label, pct) =>
      'My best guess is $label, but I am only $pct sure — not enough to give advice.',
  photoNotSure: (guess) => "I can't tell from this photo. $guess\n\n"
      'Tips: photograph ONE leaf in daylight, filling the screen, with the spots in focus. '
      'I know coffee, bean and maize leaves only.\n\n'
      'You can save the photo for your extension officer — it is sent when the phone has signal.',
  photoCaution: 'This is a machine guess from one photo. Check other leaves, and confirm with your '
      'extension officer before buying or spraying anything.',
  photoAskDefault: (crop) => 'What is wrong with my $crop leaf and what can I do?',
  photoMemoryHealthy: (date, crop, pct) => 'Photo check $date: a $crop leaf looked healthy ($pct sure).',
  photoMemoryProblem: (date, crop, cond, pct) =>
      'Photo check $date: a $crop leaf looked like $cond ($pct sure, not confirmed).',
  crops: const {'coffee': 'coffee', 'bean': 'bean', 'maize': 'maize'},
  leafConditions: const {
    'coffee__healthy': 'healthy leaf',
    'coffee__leaf_rust': 'leaf rust',
    'coffee__cercospora': 'Cercospora leaf spot (brown eye spot)',
    'coffee__phoma': 'Phoma leaf spot',
    'coffee__leaf_miner': 'leaf miner (insect damage)',
    'bean__healthy': 'healthy leaf',
    'bean__angular_leaf_spot': 'angular leaf spot',
    'bean__rust': 'bean rust',
    'maize__healthy': 'healthy leaf',
    'maize__common_rust': 'common rust',
    'maize__gray_leaf_spot': 'gray leaf spot',
    'maize__northern_leaf_blight': 'northern leaf blight',
    'other': 'not one of the crops this model knows',
  },
  diagLikely: 'Possible problem',
  diagHealthy: 'Looks healthy',
  diagNotSure: 'Not sure',
  diagSure: (pct) => '$pct sure',
  diagThreshold: (pct) => 'Needs $pct to give advice',
  askPerson: 'Not sure — ask a person',
  sources: 'From',
  matchStrong: 'Good match',
  matchWeak: 'Weak match',
  details: 'Details',
  sendToOfficer: 'Send to extension officer',
  queuedNote: 'Saved for your extension officer — sent when there is signal.',
  consentTitle: 'Send to extension officer?',
  consentBody: 'The photo is saved on this phone and sent the next time there is signal.\n\n'
      "What is sent: the leaf photo (about 60 KB), your question, and the app's guess. "
      'No name and no location. You can delete it before it is sent.',
  cancel: 'Cancel',
  save: 'Save',
  delete: 'Delete',
  growIntro: 'Your farm, your guides and your extension officer, all on this phone.',
  farmTitle: 'Your farm',
  factsCount: (n) => n == 1 ? '1 thing I remember' : '$n things I remember',
  addNote: 'Add a note',
  addNoteHint: 'For example: I planted 50 new trees on the lower plot.',
  noteSaved: 'Saved. I will use this in my answers.',
  seeAll: 'See all',
  guidesTitle: 'Guides on this phone',
  guidesNote: 'Sourced extension material, stored on this phone. Readable without internet.',
  seeAllGuides: (n) => 'See all $n guides',
  weather: WeatherStrings(
    title: 'Weather',
    screenTitle: 'Weather for your farm',
    intro: 'Get a 14-day forecast for your farm, and a warning when frost, heavy rain, strong wind, heat '
        'or a long dry or wet spell is coming — with advice on how to protect your crops.',
    privacyNote: 'Stand on your farm and tap the button. The app saves the farm\'s approximate location '
        '(about 5 km) on this phone. Whenever the phone is online, it sends only that approximate location '
        'to Open-Meteo, a free weather service, to download the forecast. Nothing else leaves the phone.',
    turnOn: "I'm at my farm — turn on weather",
    setUp: 'Turn on weather',
    locating: 'Finding your farm…',
    farmHere: "I'm at my farm now — update location",
    turnOff: 'Turn off weather',
    turnOffConfirm: 'Stop weather forecasts? The saved farm location and forecast are deleted from this phone.',
    permissionDenied: 'The app is not allowed to use your location. Allow it in the phone settings, then try again.',
    locationOff: 'Location is turned off on this phone. Turn it on, then try again.',
    noFix: 'Could not find your location. Go outside, wait a moment and try again.',
    openSettings: 'Open settings',
    notUpdated: 'Could not update the forecast. It will try again when the phone is online.',
    waiting: 'No forecast yet. It downloads automatically the next time the phone is online.',
    updating: 'Updating the forecast…',
    updated: (ago) => 'Updated $ago',
    stale: (ago) => 'Downloaded $ago — it may be out of date. It updates when the phone is online.',
    ago: (d) => d.inHours < 1
        ? 'less than an hour ago'
        : d.inHours < 48
            ? '${d.inHours} hour${d.inHours == 1 ? '' : 's'} ago'
            : '${d.inDays} days ago',
    farmAt: (place, elev) => 'Farm area ≈ $place${elev == null ? '' : ' · $elev m'}',
    warningsTitle: 'Weather warnings',
    nextDays: (n) => 'Next $n days',
    noAlerts: 'No extreme weather in the forecast.',
    askWhatToDo: 'What should I do?',
    statusChecking: 'Checking the warnings against your crops…',
    noAlertsAnswer: 'The forecast shows no extreme weather for the coming days, so no special protection is '
        'needed now. Keep caring for your crops as usual — check again after the next update.',
    caution: 'Forecasts can be wrong, especially after the first week. Look at the sky and your crops too, and '
        'ask your extension officer before buying or spraying anything.',
    attribution: 'Weather data: Open-Meteo.com (CC BY 4.0)',
    today: 'Today',
    tomorrow: 'Tomorrow',
    frost: 'Frost risk',
    heat: 'Very hot days',
    heavyRain: 'Heavy rain',
    wind: 'Strong wind',
    storm: 'Thunderstorms',
    hail: 'Thunderstorms with hail',
    drySpell: 'Dry spell',
    wetSpell: 'Long wet, humid spell',
    frostDetail: (c) => 'Nights down to $c °C',
    heatDetail: (c) => 'Up to $c °C',
    rainDetail: (mm) => 'About $mm mm in total',
    windDetail: (kmh) => 'Gusts up to $kmh km/h',
    daysCount: (n) => n == 1 ? '1 day' : '$n days',
    dryDetail: (n) => '$n days in a row with almost no rain',
    wetDetail: (n) => '$n days in a row of rain and humid air — fungal diseases spread easily',
    weekdays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    months: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    replyLanguage: 'English',
  ),
  guidesEmpty: 'No guides on this phone yet.',
  askAbout: (topic) => 'Tell me more about: $topic',
  askAboutThis: 'Ask about this',
  officerSummary: (waiting, sent) => '$waiting waiting · $sent sent',
  guidesAll: 'All',
  guidesCoffee: 'Coffee',
  guidesMaize: 'Maize',
  guidesBeans: 'Beans',
  guidesMore: 'Soil & more',
  guidesSearch: 'Search the guides',
  guidesNoMatch: 'No guide matches.',
  memoryTitle: 'What I remember',
  memoryIntro: 'Facts you told me about your farm. They stay on this phone and help me give '
      'better answers. Remove anything that is wrong.',
  memoryEmpty: 'Nothing remembered yet. Tell me about your farm — for example '
      '"I have 400 coffee trees on the upper slope."',
  forget: 'Forget',
  forgotten: 'Forgotten.',
  forgetAll: 'Forget everything',
  forgetAllConfirm: 'Delete everything I remember about your farm? This cannot be undone.',
  outboxTitle: 'For the extension officer',
  outboxIntro: 'These photos are sent to your extension officer for review the next time the phone has '
      "signal. Only the leaf photo, your note and the app's guess are sent — no name or location.",
  outboxEmpty: 'Nothing saved. After a photo check, tap "Send to extension officer" to keep it here.',
  noNote: '(no note)',
  statusSent: 'Sent',
  statusWaiting: 'Waiting for signal',
  appGuess: 'App guess',
  sendNow: (n) => 'Send $n now',
  nothingToSend: 'Nothing to send',
  deletePhotoConfirm: 'Delete this photo? It will not be sent.',
  sendNothing: 'Nothing waiting to send.',
  sendNoServer: (n) => 'No review server in this build. $n photo(s) stay safely on the phone.',
  sendOffline: (n) => 'No connection. $n photo(s) will be sent when there is signal.',
  sendDone: (sent, left) => 'Sent $sent photo(s).${left > 0 ? ' $left still waiting.' : ''}',
  helpTitle: 'Help & privacy',
  howTitle: 'How it works',
  how: [
    'You ask a question or take a leaf photo.',
    'The phone searches the farming guides stored on it, and a small AI model writes a short '
        'answer from them — no internet needed.',
    'If the guides do not cover it, or the photo is unclear, it says "not sure" and suggests '
        'asking your extension officer.',
    'You make the final decision.',
  ],
  privacyTitle: 'Your data',
  privacy: [
    'Everything stays on this phone: your questions, the answers and the facts I remember.',
    'Conversations are not saved — they disappear when you close the app.',
    'Only leaf photos you choose to send go to the extension officer, with no name and no location.',
    "Weather (only if you turn it on): the farm's approximate location (about 5 km) is sent to "
        'Open-Meteo to download the forecast. Turn it off in Grow → Weather to delete it.',
    'Sharing this phone? Use "Forget everything" in My farm, and delete photos in Officer.',
  ],
  limitsTitle: 'What it cannot do',
  limits: [
    'It only knows what is in its guides. It can be wrong.',
    'The photo check knows coffee, bean and maize leaves only.',
    'Weather forecasts can be wrong, especially more than a week ahead.',
    'It never gives prices or chemical doses.',
  ],
  onThisPhone: 'On this phone',
  modelLlm: 'Language model',
  modelEmbedder: 'Search model',
  modelLeaf: 'Leaf photo check',
  installed: 'installed',
  notInstalled: 'not installed',
  passages: (n) => '$n guide passages',
);

// ---------------------------------------------------------------- Kiswahili

final S _sw = S(
  appName: 'Botato',
  offlineBadge: 'Inafanya kazi bila mtandao',
  language: 'Lugha',
  answersLanguageNote: 'Majibu yanafuata lugha ya swali lako.',
  setupIntro: 'Uliza maswali ya kilimo na kagua picha za majani. Majibu yanatoka kwenye miongozo ya '
      'kilimo iliyohifadhiwa kwenye simu hii.',
  setupDownload: (llm, llmSize, emb, embSize) =>
      'Pakua mara moja tu: $llm ($llmSize) na $emb ($embSize). Tumia Wi-Fi au kifurushi cha data mara '
      'moja — baada ya hapo kila kitu kinafanya kazi bila mtandao.',
  setupPoints: [
    'Faragha: maswali yako hayatoki kwenye simu.',
    'Mkweli: kama haina uhakika, inakuambia umuulize mtu.',
    'Wewe ndiye unaamua: inatoa ushauri tu, haifanyi chochote kwa niaba yako.',
  ],
  setupButton: 'Pakua na uandae',
  setupDownloading: (name, size) => 'Inapakua $name ($size)…',
  setupIndexing: 'Inaandaa miongozo ya kilimo…',
  setupFailed: 'Maandalizi yameshindwa',
  retry: 'Jaribu tena',
  tabAsk: 'Uliza',
  tabFarm: 'Shamba langu',
  tabOfficer: 'Afisa',
  tabHelp: 'Msaada',
  tabGrow: 'Kilimo',
  tabSell: 'Uza',
  comingSoon: 'Inakuja hivi karibuni',
  demoTag: 'Onyesho',
  newOffer: 'Ofa mpya',
  wantsKg: (buyer, kg) => '$buyer anataka kilo $kg',
  vsMarket: (pct) => pct >= 0 ? '$pct% juu ya soko' : '${-pct}% chini ya soko',
  pickupIn: (days) => days == 1 ? 'Kuchukuliwa kesho' : 'Kuchukuliwa baada ya siku $days',
  kmAway: (km) => 'km $km',
  expiresIn: (hours) => 'Inaisha baada ya saa $hours',
  view: 'Angalia',
  decline: 'Kataa',
  acceptOffer: 'Kubali ofa',
  saleAgreed: (buyer) => 'Mauzo yamekubaliwa na $buyer.',
  offersTitle: 'Ofa za wanunuzi',
  offersSynced: 'Zilipokelewa mara ya mwisho simu ilipokuwa mtandaoni.',
  salesHistory: 'Historia ya mauzo',
  noSalesYet: 'Bado hakuna mauzo msimu huu.',
  marketPrice: 'Bei ya soko wiki hii',
  noOffers: 'Hakuna ofa mpya kwa sasa.',
  marketRef: (price) => 'Bei ya marejeo ya soko wiki hii: $price/kg',
  quantity: 'Kiasi',
  pricePerKg: 'Bei kwa kilo',
  youReceive: 'Utapokea',
  payment: 'Malipo',
  paymentOnPickup: 'Malipo kwa pesa ya simu wakati wa kuchukua',
  noFees: 'Hakuna ada ya madalali',
  verifiedBuyer: 'Mnunuzi aliyethibitishwa',
  ratingSales: (rating, sales) => '★ $rating · mauzo $sales',
  salesTitle: 'Mauzo yako',
  seasonSummary: (kg, total) => 'Msimu huu: kilo $kg · $total',
  statusPaid: 'Imelipwa',
  tipsTitle: 'Vidokezo vya kuuza vizuri',
  sellTips: [
    'Linganisha ofa na bei ya soko.',
    'Pima mzigo wako kabla haujachukuliwa.',
    'Weka kila risiti.',
  ],
  harvestTitle: 'Mavuno yako',
  thisSeason: 'msimu huu',
  harvestEstimate: 'Makadirio',
  readyWindow: (from, to) => 'Tayari $from → $to',
  soldKg: 'Imeuzwa',
  offeredKg: 'Ofa',
  toSellKg: 'Kuuza',
  howWorked: 'Jinsi nilivyohesabu',
  treesTimesYield: (trees, low, high) => 'Miti $trees × kilo $low–$high kwa mti',
  floweredRipe: (month, low, high) => 'Ilitoa maua $month, huiva baada ya miezi $low–$high',
  harvestSources: 'Chanzo: wastani wa wakulima wadogo Kenya.',
  seeInSell: 'Ona kwenye Uza',
  askHarvestTitle: 'Utavuna kiasi gani?',
  askHarvestBody: 'Msaidizi anahesabu kutoka kwa taarifa za shamba lako.',
  askNow: 'Muulize msaidizi',
  harvestQuestion: 'Nitavuna kahawa kiasi gani, na lini?',
  statusCalculating: 'Ninahesabu mavuno yako…',
  harvestNeed: 'Una miti mingapi ya kahawa (au ekari ngapi)?',
  factTrees: (n) => 'Nina miti $n ya kahawa.',
  factAcres: (acres, crop) => 'Nina ekari $acres za $crop.',
  factFlowered: (month) => 'Kahawa yangu ilitoa maua $month.',
  factPlanted: (crop, month) => 'Nilipanda $crop $month.',
  treesFromAcres: (acres, perAcre, trees) => 'Ekari $acres × miti $perAcre kwa ekari ≈ miti $trees',
  acresTimesYield: (acres, low, high) => 'Ekari $acres × kilo $low–$high kwa ekari',
  plantedReady: (month, low, high) => 'Ilipandwa $month, tayari baada ya miezi $low–$high',
  usualSeason: 'msimu wa kawaida',
  harvestYoung: 'Miti yako ya kahawa bado ni michanga: kahawa hutoa maua mara ya kwanza miaka 3 hadi 4 baada ya kupandwa, kwa hivyo bado hakuna mavuno ya kukadiria.',
  harvestNeedArea: (crop) => 'Ulipanda ekari ngapi za $crop?',
  notedForForecast: 'Nimeandika. Nitaitumia kukadiria mavuno yako.',
  harvestSummary: (low, high, from, to) => 'Takriban kilo $low–$high, tayari $from hadi $to.',
  monthsShort: ['Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'],
  monthsLong: ['Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni', 'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'],
  sellTitle: 'Uza mavuno yako',
  sellSubtitle: 'Kila kitu cha kufikisha mavuno yako sokoni.',
  promiseTitles: [
    'Faragha',
    'Ukweli',
    'Wewe unaamua',
  ],
  promiseTexts: [
    'Maswali yako hayatoki kwenye simu hii.',
    'Isipokuwa na uhakika, inakuambia.',
    'Inashauri. Uamuzi ni wako.',
  ],
  howShort: [
    'Uliza, au piga picha ya jani.',
    'Inasoma miongozo iliyo kwenye simu hii. Bila intaneti.',
    'Haina uhakika? Inakuelekeza kwa afisa ugani.',
  ],
  moreDetails: 'Maelezo zaidi',
  greetingMorning: 'Habari za asubuhi',
  greetingAfternoon: 'Habari za mchana',
  greetingEvening: 'Habari za jioni',
  copy: 'Nakili',
  copied: 'Imenakiliwa',
  sellIntro: 'Kuuza mavuno yako kunakuja hivi karibuni. Ukurasa huu utakusaidia:',
  sellComing: [
    'Kumbukumbu ya mavuno na mauzo',
    'Wanunuzi na vyama vya ushirika karibu nawe',
    'Andaa kahawa kwa mnunuzi',
  ],
  loadingModel: 'Inapakia msaidizi…',
  loadFailed: 'Msaidizi hakuweza kuanza.',
  welcomeTitle: 'Nikusaidie nini shambani leo?',
  welcomeBody: 'Uliza kwa maneno yako mwenyewe, au piga picha ya jani.',
  suggestions: [
    'Kwa nini mavuno yangu ya kahawa ni madogo mwaka huu?',
    'Nawezaje kudhibiti kutu ya majani ya kahawa?',
    'Mdudu anayetoboa matunda ya kahawa ni nini?',
    'Ni lini nipogoe miti ya zamani ya kahawa?',
  ],
  checkLeaf: 'Kagua picha ya jani',
  inputHint: 'Uliza kuhusu shamba lako…',
  send: 'Tuma',
  photoTake: 'Piga picha ya jani moja',
  photoGallery: 'Chagua kutoka kwenye picha',
  photoTip: 'Jani moja, mwanga wa mchana, lijaze skrini, madoa yaonekane wazi.',
  photoNotInstalled: 'Ukaguzi wa picha bado haujawekwa kwenye simu hii.',
  photoDefaultQuestion: 'Jani hili lina shida gani?',
  newChat: 'Mazungumzo mapya',
  statusSearching: 'Natafuta kwenye miongozo…',
  statusThinking: 'Ninafikiri…',
  statusCheckingPhoto: 'Ninakagua picha…',
  statusLookingUp: (c) => 'Natafuta habari za $c…',
  statusUpdatingMemory: 'Ninakumbuka ulichoniambia…',
  notSure: 'Sina uhakika. Tafadhali muulize afisa ugani au chama chako cha ushirika.',
  weakMatch: 'Miongozo yangu haina jibu la uhakika. Tafadhali hakikisha na mtu.',
  notCovered: (crop) => 'Miongozo yangu bado haina habari kuhusu $crop. Tafadhali muulize afisa ugani au chama chako cha ushirika.',
  healthy: (crop, pct) => 'Jani hili la $crop linaonekana zima (uhakika $pct). '
      'Kama majani mengine, matunda au mashina yanaonekana tofauti, yapige picha pia. '
      'Sababu nyingi za mavuno madogo (udongo, mvua, umri wa miti) hazionekani kwenye majani — '
      'afisa ugani anaweza kukusaidia kuzitafuta.',
  photoNotSureOther: 'Halionekani kama jani la kahawa, maharage au mahindi ninalolijua.',
  photoNotSureGuess: (label, pct) =>
      'Ninakisia ni $label, lakini nina uhakika wa $pct tu — haitoshi kutoa ushauri.',
  photoNotSure: (guess) => 'Siwezi kujua kutokana na picha hii. $guess\n\n'
      'Vidokezo: piga picha ya jani MOJA mchana, likijaza skrini, madoa yakionekana wazi. '
      'Ninajua majani ya kahawa, maharage na mahindi tu.\n\n'
      'Unaweza kuhifadhi picha kwa ajili ya afisa ugani — itatumwa simu ikipata mtandao.',
  photoCaution: 'Haya ni makisio ya mashine kutoka picha moja. Kagua majani mengine, na thibitisha na '
      'afisa ugani kabla ya kununua au kunyunyizia chochote.',
  photoAskDefault: (crop) => 'Jani langu la $crop lina shida gani na nifanye nini?',
  photoMemoryHealthy: (date, crop, pct) => 'Ukaguzi wa picha $date: jani la $crop lilionekana zima (uhakika $pct).',
  photoMemoryProblem: (date, crop, cond, pct) =>
      'Ukaguzi wa picha $date: jani la $crop lilionekana kuwa na $cond (uhakika $pct, haijathibitishwa).',
  crops: const {'coffee': 'kahawa', 'bean': 'maharagwe', 'maize': 'mahindi'},
  leafConditions: const {
    'coffee__healthy': 'jani zima',
    'coffee__leaf_rust': 'kutu ya majani',
    'coffee__cercospora': 'madoa ya Cercospora (jicho la kahawia)',
    'coffee__phoma': 'madoa ya Phoma',
    'coffee__leaf_miner': 'mchimba majani (uharibifu wa wadudu)',
    'bean__healthy': 'jani zima',
    'bean__angular_leaf_spot': 'madoa pembe',
    'bean__rust': 'kutu ya maharagwe',
    'maize__healthy': 'jani zima',
    'maize__common_rust': 'kutu ya kawaida',
    'maize__gray_leaf_spot': 'madoa ya kijivu',
    'maize__northern_leaf_blight': 'ukungu wa kaskazini wa majani',
    'other': 'si zao ambalo kipimo hiki kinalijua',
  },
  diagLikely: 'Tatizo linalowezekana',
  diagHealthy: 'Linaonekana zima',
  diagNotSure: 'Sina uhakika',
  diagSure: (pct) => 'uhakika $pct',
  diagThreshold: (pct) => 'Inahitaji $pct kutoa ushauri',
  askPerson: 'Sina uhakika — muulize mtu',
  sources: 'Kutoka',
  matchStrong: 'Inalingana vizuri',
  matchWeak: 'Hailingani vizuri',
  details: 'Maelezo',
  sendToOfficer: 'Tuma kwa afisa ugani',
  queuedNote: 'Imehifadhiwa kwa afisa ugani — itatumwa kukiwa na mtandao.',
  consentTitle: 'Tuma kwa afisa ugani?',
  consentBody: 'Picha inahifadhiwa kwenye simu hii na kutumwa wakati ujao kukiwa na mtandao.\n\n'
      'Kinachotumwa: picha ya jani (karibu KB 60), swali lako, na makisio ya programu. '
      'Hakuna jina wala mahali. Unaweza kuifuta kabla haijatumwa.',
  cancel: 'Ghairi',
  save: 'Hifadhi',
  delete: 'Futa',
  growIntro: 'Shamba lako, miongozo yako na afisa wako wa ugani, vyote kwenye simu hii.',
  farmTitle: 'Shamba lako',
  factsCount: (n) => n == 1 ? 'Jambo 1 ninalokumbuka' : 'Mambo $n ninayokumbuka',
  addNote: 'Ongeza dokezo',
  addNoteHint: 'Kwa mfano: Nimepanda miti mipya 50 kwenye shamba la chini.',
  noteSaved: 'Imehifadhiwa. Nitaitumia kwenye majibu yangu.',
  seeAll: 'Ona yote',
  guidesTitle: 'Miongozo kwenye simu hii',
  guidesNote: 'Taarifa za ugani zenye vyanzo, zimehifadhiwa kwenye simu hii. Zinasomeka bila intaneti.',
  seeAllGuides: (n) => 'Ona miongozo yote $n',
  weather: WeatherStrings(
    title: 'Hali ya hewa',
    screenTitle: 'Hali ya hewa shambani',
    intro: 'Pata utabiri wa siku 14 kwa shamba lako, na tahadhari kabla ya baridi kali, mvua kubwa, upepo '
        'mkali, joto kali au vipindi virefu vya ukame au mvua — pamoja na ushauri wa kulinda mazao yako.',
    privacyNote: 'Simama shambani kwako na ubonyeze kitufe. Programu inahifadhi mahali pa shamba kwa makadirio '
        '(karibu km 5) kwenye simu hii. Kila simu ikiwa na mtandao, inatuma makadirio hayo tu kwa Open-Meteo, '
        'huduma ya bure ya hali ya hewa, ili kupakua utabiri. Hakuna kingine kinachotoka kwenye simu.',
    turnOn: 'Niko shambani — washa hali ya hewa',
    setUp: 'Washa hali ya hewa',
    locating: 'Inatafuta shamba lako…',
    farmHere: 'Niko shambani sasa — sasisha mahali',
    turnOff: 'Zima hali ya hewa',
    turnOffConfirm: 'Acha utabiri wa hali ya hewa? Mahali pa shamba na utabiri uliohifadhiwa vitafutwa kwenye '
        'simu hii.',
    permissionDenied: 'Programu hairuhusiwi kutumia mahali ulipo. Iruhusu kwenye mipangilio ya simu, kisha '
        'ujaribu tena.',
    locationOff: 'Huduma ya mahali imezimwa kwenye simu hii. Iwashe, kisha ujaribu tena.',
    noFix: 'Imeshindwa kupata mahali ulipo. Toka nje, subiri kidogo kisha ujaribu tena.',
    openSettings: 'Fungua mipangilio',
    notUpdated: 'Imeshindwa kusasisha utabiri. Itajaribu tena simu ikiwa na mtandao.',
    waiting: 'Bado hakuna utabiri. Utapakuliwa wenyewe simu ikipata mtandao.',
    updating: 'Inasasisha utabiri…',
    updated: (ago) => 'Imesasishwa $ago',
    stale: (ago) => 'Ulipakuliwa $ago — huenda umepitwa na wakati. Unasasishwa simu ikiwa na mtandao.',
    ago: (d) => d.inHours < 1
        ? 'chini ya saa moja iliyopita'
        : d.inHours < 48
            ? 'saa ${d.inHours} zilizopita'
            : 'siku ${d.inDays} zilizopita',
    farmAt: (place, elev) => 'Eneo la shamba ≈ $place${elev == null ? '' : ' · mita $elev'}',
    warningsTitle: 'Tahadhari za hali ya hewa',
    nextDays: (n) => 'Siku $n zijazo',
    noAlerts: 'Hakuna hali mbaya ya hewa katika utabiri.',
    askWhatToDo: 'Nifanye nini?',
    statusChecking: 'Inalinganisha tahadhari na mazao yako…',
    noAlertsAnswer: 'Utabiri hauonyeshi hali mbaya ya hewa kwa siku zijazo, kwa hiyo hakuna kinga maalum '
        'inayohitajika sasa. Endelea kutunza mazao yako kama kawaida — angalia tena baada ya kusasisha.',
    caution: 'Utabiri unaweza kukosea, hasa baada ya wiki ya kwanza. Angalia pia anga na mazao yako, na muulize '
        'afisa ugani kabla ya kununua au kunyunyizia chochote.',
    attribution: 'Data ya hali ya hewa: Open-Meteo.com (CC BY 4.0)',
    today: 'Leo',
    tomorrow: 'Kesho',
    frost: 'Hatari ya baridi kali',
    heat: 'Siku za joto kali',
    heavyRain: 'Mvua kubwa',
    wind: 'Upepo mkali',
    storm: 'Radi na dhoruba',
    hail: 'Dhoruba yenye mvua ya mawe',
    drySpell: 'Kipindi cha ukame',
    wetSpell: 'Kipindi kirefu cha mvua na unyevu',
    frostDetail: (c) => 'Usiku hadi $c °C',
    heatDetail: (c) => 'Hadi $c °C',
    rainDetail: (mm) => 'Jumla ya karibu mm $mm',
    windDetail: (kmh) => 'Upepo hadi km $kmh kwa saa',
    daysCount: (n) => 'siku $n',
    dryDetail: (n) => 'Siku $n mfululizo karibu bila mvua',
    wetDetail: (n) => 'Siku $n mfululizo za mvua na unyevu — magonjwa ya ukungu huenea kwa urahisi',
    weekdays: ['Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Jumamosi', 'Jumapili'],
    months: ['Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'],
    replyLanguage: 'Swahili',
  ),
  guidesEmpty: 'Bado hakuna miongozo kwenye simu hii.',
  askAbout: (topic) => 'Nieleze zaidi kuhusu: $topic',
  askAboutThis: 'Uliza kuhusu hili',
  officerSummary: (waiting, sent) => '$waiting zinasubiri · $sent zimetumwa',
  guidesAll: 'Zote',
  guidesCoffee: 'Kahawa',
  guidesMaize: 'Mahindi',
  guidesBeans: 'Maharagwe',
  guidesMore: 'Udongo na mengine',
  guidesSearch: 'Tafuta kwenye miongozo',
  guidesNoMatch: 'Hakuna mwongozo unaolingana.',
  memoryTitle: 'Ninachokumbuka',
  memoryIntro: 'Mambo uliyoniambia kuhusu shamba lako. Yanabaki kwenye simu hii na yananisaidia kutoa '
      'majibu bora. Futa chochote kisicho sahihi.',
  memoryEmpty: 'Bado sijakumbuka chochote. Niambie kuhusu shamba lako — kwa mfano '
      '"Nina miti 400 ya kahawa kwenye mteremko wa juu."',
  forget: 'Sahau',
  forgotten: 'Imesahaulika.',
  forgetAll: 'Sahau kila kitu',
  forgetAllConfirm: 'Futa kila kitu ninachokumbuka kuhusu shamba lako? Haiwezi kurudishwa.',
  outboxTitle: 'Kwa afisa ugani',
  outboxIntro: 'Picha hizi zinatumwa kwa afisa ugani kukaguliwa simu ikipata mtandao. Ni picha ya jani, '
      'maelezo yako na makisio ya programu tu yanayotumwa — hakuna jina wala mahali.',
  outboxEmpty: 'Hakuna kilichohifadhiwa. Baada ya kukagua picha, bonyeza "Tuma kwa afisa ugani" ili '
      'kuihifadhi hapa.',
  noNote: '(hakuna maelezo)',
  statusSent: 'Imetumwa',
  statusWaiting: 'Inasubiri mtandao',
  appGuess: 'Makisio',
  sendNow: (n) => 'Tuma $n sasa',
  nothingToSend: 'Hakuna cha kutuma',
  deletePhotoConfirm: 'Futa picha hii? Haitatumwa.',
  sendNothing: 'Hakuna kinachosubiri kutumwa.',
  sendNoServer: (n) => 'Toleo hili halina seva ya ukaguzi. Picha $n zinabaki salama kwenye simu.',
  sendOffline: (n) => 'Hakuna mtandao. Picha $n zitatumwa kukiwa na mtandao.',
  sendDone: (sent, left) => 'Picha $sent zimetumwa.${left > 0 ? ' $left bado zinasubiri.' : ''}',
  helpTitle: 'Msaada na faragha',
  howTitle: 'Inavyofanya kazi',
  how: [
    'Unauliza swali au unapiga picha ya jani.',
    'Simu inatafuta kwenye miongozo ya kilimo iliyohifadhiwa ndani yake, na modeli ndogo ya AI '
        'inaandika jibu fupi kutoka humo — bila kuhitaji intaneti.',
    'Kama miongozo haina jibu, au picha haiko wazi, inasema "sina uhakika" na kupendekeza umuulize '
        'afisa ugani.',
    'Wewe ndiye unafanya uamuzi wa mwisho.',
  ],
  privacyTitle: 'Data yako',
  privacy: [
    'Kila kitu kinabaki kwenye simu hii: maswali yako, majibu na mambo ninayokumbuka.',
    'Mazungumzo hayahifadhiwi — yanapotea unapofunga programu.',
    'Ni picha za majani unazochagua kutuma tu zinazokwenda kwa afisa ugani, bila jina wala mahali.',
    'Hali ya hewa (ukiiwasha tu): mahali pa shamba kwa makadirio (karibu km 5) panatumwa kwa Open-Meteo '
        'ili kupakua utabiri. Izime kwenye Kilimo → Hali ya hewa ili kuifuta.',
    'Unashirikiana simu hii? Tumia "Sahau kila kitu" kwenye Shamba langu, na futa picha kwenye Afisa.',
  ],
  limitsTitle: 'Isichoweza kufanya',
  limits: [
    'Inajua tu kilichomo kwenye miongozo yake. Inaweza kukosea.',
    'Ukaguzi wa picha unajua majani ya kahawa, maharage na mahindi tu.',
    'Utabiri wa hali ya hewa unaweza kukosea, hasa zaidi ya wiki moja mbele.',
    'Haitoi bei wala vipimo vya dawa.',
  ],
  onThisPhone: 'Kwenye simu hii',
  modelLlm: 'Modeli ya lugha',
  modelEmbedder: 'Modeli ya utafutaji',
  modelLeaf: 'Ukaguzi wa picha ya jani',
  installed: 'imewekwa',
  notInstalled: 'haijawekwa',
  passages: (n) => 'vifungu $n vya miongozo',
);

// ------------------------------------------------------------------- French

final S _fr = S(
  appName: 'Botato',
  offlineBadge: 'Fonctionne hors ligne',
  language: 'Langue',
  answersLanguageNote: 'Les réponses suivent la langue de votre question.',
  setupIntro: 'Posez vos questions agricoles et vérifiez des photos de feuilles. Les réponses viennent de '
      'guides agricoles enregistrés sur ce téléphone.',
  setupDownload: (llm, llmSize, emb, embSize) =>
      'Téléchargement unique : $llm ($llmSize) et $emb ($embSize). Utilisez le Wi-Fi ou un forfait '
      'data une seule fois — ensuite tout fonctionne hors ligne.',
  setupPoints: [
    'Privé : vos questions ne quittent jamais le téléphone.',
    'Honnête : en cas de doute, il vous dit de demander à une personne.',
    "Vous décidez : il conseille, il n'agit jamais à votre place.",
  ],
  setupButton: 'Télécharger et installer',
  setupDownloading: (name, size) => 'Téléchargement de $name ($size)…',
  setupIndexing: 'Préparation des guides agricoles…',
  setupFailed: "L'installation a échoué",
  retry: 'Réessayer',
  tabAsk: 'Demander',
  tabFarm: 'Ma ferme',
  tabOfficer: 'Conseiller',
  tabHelp: 'Aide',
  tabGrow: 'Cultiver',
  tabSell: 'Vendre',
  comingSoon: 'Bientôt disponible',
  demoTag: 'Démo',
  newOffer: 'Nouvelle offre',
  wantsKg: (buyer, kg) => '$buyer veut $kg kg',
  vsMarket: (pct) => pct >= 0 ? '$pct % au-dessus du marché' : '${-pct} % sous le marché',
  pickupIn: (days) => days == 1 ? 'Enlèvement demain' : 'Enlèvement dans $days jours',
  kmAway: (km) => 'à $km km',
  expiresIn: (hours) => 'Expire dans $hours h',
  view: 'Voir',
  decline: 'Refuser',
  acceptOffer: "Accepter l'offre",
  saleAgreed: (buyer) => 'Vente conclue avec $buyer.',
  offersTitle: 'Offres des acheteurs',
  offersSynced: 'Reçues la dernière fois que le téléphone était en ligne.',
  salesHistory: 'Historique des ventes',
  noSalesYet: "Aucune vente cette saison pour l'instant.",
  marketPrice: 'Prix du marché cette semaine',
  noOffers: 'Aucune nouvelle offre pour le moment.',
  marketRef: (price) => 'Prix de référence du marché cette semaine : $price/kg',
  quantity: 'Quantité',
  pricePerKg: 'Prix au kg',
  youReceive: 'Vous recevez',
  payment: 'Paiement',
  paymentOnPickup: "Payé par mobile money à l'enlèvement",
  noFees: "Pas de frais d'intermédiaire",
  verifiedBuyer: 'Acheteur vérifié',
  ratingSales: (rating, sales) => '★ $rating · $sales ventes',
  salesTitle: 'Vos ventes',
  seasonSummary: (kg, total) => 'Cette saison : $kg kg · $total',
  statusPaid: 'Payé',
  tipsTitle: 'Conseils pour mieux vendre',
  sellTips: [
    "Comparez les offres au prix du marché.",
    "Pesez votre lot avant l'enlèvement.",
    'Gardez chaque reçu.',
  ],
  harvestTitle: 'Votre récolte',
  thisSeason: 'cette saison',
  harvestEstimate: 'Estimation',
  readyWindow: (from, to) => 'Prête $from → $to',
  soldKg: 'Vendu',
  offeredKg: 'Offres',
  toSellKg: 'À vendre',
  howWorked: "Comment j'ai calculé",
  treesTimesYield: (trees, low, high) => '$trees arbres × $low–$high kg par arbre',
  floweredRipe: (month, low, high) => 'Floraison en $month, mûr $low à $high mois plus tard',
  harvestSources: 'Source : moyennes des petits producteurs kényans.',
  seeInSell: 'Voir dans Vendre',
  askHarvestTitle: 'Combien allez-vous récolter ?',
  askHarvestBody: "L'assistant le calcule à partir des informations sur votre ferme.",
  askNow: "Demander à l'assistant",
  harvestQuestion: 'Combien de café vais-je récolter, et quand ?',
  statusCalculating: 'Je calcule votre récolte…',
  harvestNeed: "Combien de caféiers avez-vous (ou combien d'acres) ?",
  factTrees: (n) => "J'ai $n caféiers.",
  factAcres: (acres, crop) => "J'ai $acres acres de $crop.",
  factFlowered: (month) => 'Mes caféiers ont fleuri en $month.',
  factPlanted: (crop, month) => "J'ai semé mes $crop en $month.",
  treesFromAcres: (acres, perAcre, trees) => '$acres acres × $perAcre arbres par acre ≈ $trees arbres',
  acresTimesYield: (acres, low, high) => '$acres acres × $low–$high kg par acre',
  plantedReady: (month, low, high) => 'Semé en $month, prêt $low à $high mois plus tard',
  usualSeason: 'saison habituelle',
  harvestYoung: "Vos caféiers sont encore jeunes : le café fleurit pour la première fois 3 à 4 ans après la plantation, il n'y a donc pas encore de récolte à prévoir.",
  harvestNeedArea: (crop) => "Combien d'acres de $crop avez-vous semés ?",
  notedForForecast: "Noté. Je m'en servirai pour prévoir votre récolte.",
  harvestSummary: (low, high, from, to) => 'Environ $low–$high kg, prêts de $from à $to.',
  monthsShort: ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'],
  monthsLong: ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'],
  sellTitle: 'Vendez votre récolte',
  sellSubtitle: 'Tout pour amener votre récolte au marché.',
  promiseTitles: [
    'Privé',
    'Honnête',
    'Vous décidez',
  ],
  promiseTexts: [
    'Vos questions ne quittent jamais ce téléphone.',
    "Quand il n'est pas sûr, il le dit.",
    'Il conseille. Vous décidez.',
  ],
  howShort: [
    'Posez une question, ou photographiez une feuille.',
    'Il lit les guides stockés sur ce téléphone. Sans internet.',
    'Pas sûr ? Il vous oriente vers votre conseiller agricole.',
  ],
  moreDetails: 'Plus de détails',
  greetingMorning: 'Bonjour',
  greetingAfternoon: 'Bon après-midi',
  greetingEvening: 'Bonsoir',
  copy: 'Copier',
  copied: 'Copié',
  sellIntro: 'La vente de votre récolte arrive bientôt. Cette page vous aidera à :',
  sellComing: [
    'Registre des récoltes et des ventes',
    'Acheteurs et coopératives près de chez vous',
    "Préparer le café pour l'acheteur",
  ],
  loadingModel: "Chargement de l'assistant…",
  loadFailed: "L'assistant n'a pas pu démarrer.",
  welcomeTitle: "Comment puis-je aider votre ferme aujourd'hui ?",
  welcomeBody: 'Posez votre question avec vos mots, ou prenez une feuille en photo.',
  suggestions: [
    'Pourquoi ma récolte de café est-elle plus petite cette année ?',
    'Comment lutter contre la rouille du caféier ?',
    "Qu'est-ce que le scolyte des baies du café ?",
    'Quand faut-il tailler les vieux caféiers ?',
  ],
  checkLeaf: 'Vérifier une photo de feuille',
  inputHint: 'Posez une question sur votre ferme…',
  send: 'Envoyer',
  photoTake: 'Photographier une seule feuille',
  photoGallery: 'Choisir dans la galerie',
  photoTip: "Une feuille, en plein jour, qui remplit l'écran, taches nettes.",
  photoNotInstalled: "La vérification photo n'est pas encore installée sur ce téléphone.",
  photoDefaultQuestion: "Qu'est-ce qui ne va pas avec cette feuille ?",
  newChat: 'Nouvelle conversation',
  statusSearching: 'Recherche dans les guides…',
  statusThinking: 'Réflexion…',
  statusCheckingPhoto: 'Vérification de la photo…',
  statusLookingUp: (c) => 'Recherche sur $c…',
  statusUpdatingMemory: "Je retiens ce que vous m'avez dit…",
  notSure: 'Je ne suis pas sûr. Demandez à votre conseiller agricole ou à votre coopérative.',
  weakMatch: "Mes guides couvrent mal cette question. Vérifiez auprès d'une personne.",
  notCovered: (crop) => 'Mes guides ne parlent pas encore de « $crop ». Demandez à votre conseiller agricole ou à votre coopérative.',
  healthy: (crop, pct) => 'Cette feuille de $crop semble saine (sûr à $pct). '
      "Si d'autres feuilles, des baies ou des tiges ont un aspect différent, photographiez-les aussi. "
      "Beaucoup de causes d'une petite récolte (sol, pluie, âge des arbres) ne se voient pas sur les "
      'feuilles — votre conseiller agricole peut vous aider à les trouver.',
  photoNotSureOther: 'Elle ne ressemble pas à une feuille de café, de haricot ou de maïs que je connais.',
  photoNotSureGuess: (label, pct) =>
      "Ma meilleure hypothèse est $label, mais je ne suis sûr qu'à $pct — pas assez pour vous conseiller.",
  photoNotSure: (guess) => 'Je ne peux pas le dire avec cette photo. $guess\n\n'
      "Conseils : photographiez UNE feuille en plein jour, qui remplit l'écran, avec les taches nettes. "
      'Je ne connais que les feuilles de café, de haricot et de maïs.\n\n'
      "Vous pouvez garder la photo pour votre conseiller agricole — elle sera envoyée dès qu'il y a du réseau.",
  photoCaution: "Ceci est une estimation de la machine à partir d'une seule photo. Vérifiez d'autres "
      "feuilles et confirmez avec votre conseiller agricole avant d'acheter ou de pulvériser quoi que ce soit.",
  photoAskDefault: (crop) => "Qu'est-ce qui ne va pas avec ma feuille de $crop et que puis-je faire ?",
  photoMemoryHealthy: (date, crop, pct) => 'Vérification photo du $date : une feuille de $crop semblait saine (sûr à $pct).',
  photoMemoryProblem: (date, crop, cond, pct) =>
      'Vérification photo du $date : une feuille de $crop semblait atteinte de $cond (sûr à $pct, non confirmé).',
  crops: const {'coffee': 'caféier', 'bean': 'haricot', 'maize': 'maïs'},
  leafConditions: const {
    'coffee__healthy': 'feuille saine',
    'coffee__leaf_rust': 'rouille',
    'coffee__cercospora': 'cercosporiose (taches en œil brun)',
    'coffee__phoma': 'taches à Phoma',
    'coffee__leaf_miner': "mineuse des feuilles (dégâts d'insecte)",
    'bean__healthy': 'feuille saine',
    'bean__angular_leaf_spot': 'taches anguleuses',
    'bean__rust': 'rouille du haricot',
    'maize__healthy': 'feuille saine',
    'maize__common_rust': 'rouille commune',
    'maize__gray_leaf_spot': 'cercosporiose (taches grises)',
    'maize__northern_leaf_blight': 'helminthosporiose du nord',
    'other': 'pas une des cultures que ce modèle connaît',
  },
  diagLikely: 'Problème possible',
  diagHealthy: 'Semble saine',
  diagNotSure: 'Pas sûr',
  diagSure: (pct) => 'sûr à $pct',
  diagThreshold: (pct) => 'Il faut $pct pour conseiller',
  askPerson: 'Pas sûr — demandez à une personne',
  sources: 'Source',
  matchStrong: 'Bonne correspondance',
  matchWeak: 'Faible correspondance',
  details: 'Détails',
  sendToOfficer: 'Envoyer au conseiller agricole',
  queuedNote: "Gardée pour votre conseiller agricole — envoyée dès qu'il y a du réseau.",
  consentTitle: 'Envoyer au conseiller agricole ?',
  consentBody: "La photo est enregistrée sur ce téléphone et envoyée dès qu'il y a du réseau.\n\n"
      "Ce qui est envoyé : la photo de la feuille (environ 60 Ko), votre question et l'estimation de "
      "l'application. Ni nom, ni position. Vous pouvez la supprimer avant l'envoi.",
  cancel: 'Annuler',
  save: 'Enregistrer',
  delete: 'Supprimer',
  growIntro: 'Votre ferme, vos guides et votre conseiller agricole, tout sur ce téléphone.',
  farmTitle: 'Votre ferme',
  factsCount: (n) => n == 1 ? '1 chose que je retiens' : '$n choses que je retiens',
  addNote: 'Ajouter une note',
  addNoteHint: "Par exemple : j'ai planté 50 nouveaux arbres sur la parcelle du bas.",
  noteSaved: "Enregistré. Je m'en servirai dans mes réponses.",
  seeAll: 'Tout voir',
  guidesTitle: 'Guides sur ce téléphone',
  guidesNote: 'Documents de vulgarisation sourcés, stockés sur ce téléphone. Lisibles sans internet.',
  seeAllGuides: (n) => 'Voir les $n guides',
  weather: WeatherStrings(
    title: 'Météo',
    screenTitle: 'Météo de votre ferme',
    intro: 'Recevez une prévision sur 14 jours pour votre ferme, et une alerte quand du gel, de fortes pluies, '
        'du vent fort, de la chaleur ou une longue période sèche ou humide arrive — avec des conseils pour '
        'protéger vos cultures.',
    privacyNote: "Placez-vous sur votre ferme et touchez le bouton. L'application enregistre la position "
        'approximative de la ferme (à environ 5 km près) sur ce téléphone. Dès que le téléphone est en ligne, '
        'elle envoie seulement cette position approximative à Open-Meteo, un service météo gratuit, pour '
        "télécharger la prévision. Rien d'autre ne quitte le téléphone.",
    turnOn: 'Je suis sur ma ferme — activer la météo',
    setUp: 'Activer la météo',
    locating: 'Recherche de votre ferme…',
    farmHere: 'Je suis sur ma ferme — mettre à jour la position',
    turnOff: 'Désactiver la météo',
    turnOffConfirm: 'Arrêter la météo ? La position de la ferme et la prévision enregistrées seront supprimées '
        'de ce téléphone.',
    permissionDenied: "L'application n'a pas le droit d'utiliser votre position. Autorisez-la dans les réglages "
        'du téléphone, puis réessayez.',
    locationOff: 'La localisation est désactivée sur ce téléphone. Activez-la, puis réessayez.',
    noFix: "Position introuvable. Sortez à l'extérieur, attendez un instant et réessayez.",
    openSettings: 'Ouvrir les réglages',
    notUpdated: 'Impossible de mettre à jour la prévision. Nouvel essai dès que le téléphone sera en ligne.',
    waiting: 'Pas encore de prévision. Elle se télécharge automatiquement dès que le téléphone est en ligne.',
    updating: 'Mise à jour de la prévision…',
    updated: (ago) => 'Mise à jour $ago',
    stale: (ago) => 'Téléchargée $ago — elle peut être dépassée. Elle se met à jour dès que le téléphone est '
        'en ligne.',
    ago: (d) => d.inHours < 1
        ? "il y a moins d'une heure"
        : d.inHours < 48
            ? 'il y a ${d.inHours} h'
            : 'il y a ${d.inDays} jours',
    farmAt: (place, elev) => 'Zone de la ferme ≈ $place${elev == null ? '' : ' · $elev m'}',
    warningsTitle: 'Alertes météo',
    nextDays: (n) => 'Les $n prochains jours',
    noAlerts: 'Pas de météo extrême dans la prévision.',
    askWhatToDo: 'Que dois-je faire ?',
    statusChecking: 'Analyse des alertes pour vos cultures…',
    noAlertsAnswer: "La prévision n'annonce pas de météo extrême pour les prochains jours : aucune protection "
        "particulière n'est nécessaire pour l'instant. Continuez à entretenir vos cultures comme d'habitude — "
        'vérifiez à nouveau après la prochaine mise à jour.',
    caution: 'Les prévisions peuvent se tromper, surtout après la première semaine. Observez aussi le ciel et '
        "vos cultures, et demandez à votre conseiller agricole avant d'acheter ou de pulvériser quoi que ce soit.",
    attribution: 'Données météo : Open-Meteo.com (CC BY 4.0)',
    today: "Aujourd'hui",
    tomorrow: 'Demain',
    frost: 'Risque de gel',
    heat: 'Journées très chaudes',
    heavyRain: 'Fortes pluies',
    wind: 'Vent fort',
    storm: 'Orages',
    hail: 'Orages avec grêle',
    drySpell: 'Période sèche',
    wetSpell: 'Longue période humide',
    frostDetail: (c) => "Nuits jusqu'à $c °C",
    heatDetail: (c) => "Jusqu'à $c °C",
    rainDetail: (mm) => 'Environ $mm mm au total',
    windDetail: (kmh) => "Rafales jusqu'à $kmh km/h",
    daysCount: (n) => n == 1 ? '1 jour' : '$n jours',
    dryDetail: (n) => '$n jours de suite presque sans pluie',
    wetDetail: (n) => "$n jours de suite de pluie et d'air humide — les maladies fongiques se propagent "
        'facilement',
    weekdays: ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'],
    months: ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'],
    replyLanguage: 'French',
  ),
  guidesEmpty: 'Aucun guide sur ce téléphone pour le moment.',
  askAbout: (topic) => "Dites-m'en plus sur : $topic",
  askAboutThis: 'Poser une question',
  officerSummary: (waiting, sent) => '$waiting en attente · $sent envoyée(s)',
  guidesAll: 'Tous',
  guidesCoffee: 'Café',
  guidesMaize: 'Maïs',
  guidesBeans: 'Haricots',
  guidesMore: 'Sol et autres',
  guidesSearch: 'Rechercher dans les guides',
  guidesNoMatch: 'Aucun guide ne correspond.',
  memoryTitle: 'Ce dont je me souviens',
  memoryIntro: "Ce que vous m'avez dit sur votre ferme. Ces informations restent sur ce téléphone et "
      "m'aident à mieux répondre. Supprimez ce qui est faux.",
  memoryEmpty: "Rien pour l'instant. Parlez-moi de votre ferme — par exemple "
      '« J\'ai 400 caféiers sur le haut de la pente. »',
  forget: 'Oublier',
  forgotten: 'Oublié.',
  forgetAll: 'Tout oublier',
  forgetAllConfirm: 'Supprimer tout ce que je sais de votre ferme ? Action irréversible.',
  outboxTitle: 'Pour le conseiller agricole',
  outboxIntro: "Ces photos sont envoyées à votre conseiller agricole dès que le téléphone a du réseau. "
      "Seuls la photo, votre note et l'estimation de l'application sont envoyés — ni nom, ni position.",
  outboxEmpty: 'Rien pour le moment. Après une vérification photo, touchez « Envoyer au conseiller '
      'agricole » pour la garder ici.',
  noNote: '(pas de note)',
  statusSent: 'Envoyée',
  statusWaiting: 'En attente de réseau',
  appGuess: 'Estimation',
  sendNow: (n) => 'Envoyer $n maintenant',
  nothingToSend: 'Rien à envoyer',
  deletePhotoConfirm: 'Supprimer cette photo ? Elle ne sera pas envoyée.',
  sendNothing: "Rien en attente d'envoi.",
  sendNoServer: (n) => "Pas de serveur de relecture dans cette version. $n photo(s) restent sur le téléphone.",
  sendOffline: (n) => "Pas de connexion. $n photo(s) seront envoyées dès qu'il y aura du réseau.",
  sendDone: (sent, left) => '$sent photo(s) envoyée(s).${left > 0 ? ' $left en attente.' : ''}',
  helpTitle: 'Aide et confidentialité',
  howTitle: 'Comment ça marche',
  how: [
    'Vous posez une question ou photographiez une feuille.',
    "Le téléphone cherche dans les guides agricoles qu'il contient, et un petit modèle d'IA rédige "
        "une réponse courte à partir d'eux — sans internet.",
    'Si les guides ne couvrent pas la question ou si la photo est floue, il répond « pas sûr » et '
        'propose de demander à votre conseiller agricole.',
    'La décision finale vous appartient.',
  ],
  privacyTitle: 'Vos données',
  privacy: [
    'Tout reste sur ce téléphone : vos questions, les réponses et ce dont je me souviens.',
    'Les conversations ne sont pas enregistrées — elles disparaissent à la fermeture.',
    "Seules les photos de feuilles que vous choisissez d'envoyer vont au conseiller, sans nom ni position.",
    "Météo (seulement si vous l'activez) : la position approximative de la ferme (à environ 5 km près) est "
        "envoyée à Open-Meteo pour télécharger la prévision. Désactivez-la dans Cultiver → Météo pour l'effacer.",
    'Téléphone partagé ? Utilisez « Tout oublier » dans Ma ferme et supprimez les photos dans Conseiller.',
  ],
  limitsTitle: "Ce qu'il ne sait pas faire",
  limits: [
    "Il ne connaît que ce qui est dans ses guides. Il peut se tromper.",
    'La vérification photo ne connaît que les feuilles de café, haricot et maïs.',
    "Les prévisions météo peuvent se tromper, surtout au-delà d'une semaine.",
    'Il ne donne jamais de prix ni de doses de produits.',
  ],
  onThisPhone: 'Sur ce téléphone',
  modelLlm: 'Modèle de langage',
  modelEmbedder: 'Modèle de recherche',
  modelLeaf: 'Vérification photo',
  installed: 'installé',
  notInstalled: 'non installé',
  passages: (n) => '$n passages de guides',
);
