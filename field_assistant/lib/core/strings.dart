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
    required this.healthy,
    required this.photoNotSureOther,
    required this.photoNotSureGuess,
    required this.photoNotSure,
    required this.photoCaution,
    required this.photoAskDefault,
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
  final String Function(String crop, String percent) healthy;
  final String photoNotSureOther;
  final String Function(String label, String percent) photoNotSureGuess;
  final String Function(String guess) photoNotSure;
  final String photoCaution;
  final String Function(String crop) photoAskDefault;

  // Diagnosis card
  final String diagLikely, diagHealthy, diagNotSure;
  final String Function(String percent) diagSure, diagThreshold;

  // Message bubble
  final String askPerson, sources, matchStrong, matchWeak, details;
  final String sendToOfficer, queuedNote, consentTitle, consentBody, cancel, save, delete;

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

// ------------------------------------------------------------------ English

final S _en = S(
  appName: 'Field Assistant',
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
  sellIntro: 'Selling your harvest is coming soon. Here is what this page will help with:',
  sellComing: [
    'Keep a record of what you harvested and sold.',
    'Find your cooperative and buyers near you.',
    'Get your coffee ready for the buyer: drying, sorting, storage.',
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
    'Sharing this phone? Use "Forget everything" in My farm, and delete photos in Officer.',
  ],
  limitsTitle: 'What it cannot do',
  limits: [
    'It only knows what is in its guides. It can be wrong.',
    'The photo check knows coffee, bean and maize leaves only.',
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
  appName: 'Msaidizi wa Shamba',
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
  sellIntro: 'Kuuza mavuno yako kunakuja hivi karibuni. Ukurasa huu utakusaidia:',
  sellComing: [
    'Kuweka kumbukumbu ya ulichovuna na kuuza.',
    'Kupata chama chako cha ushirika na wanunuzi karibu nawe.',
    'Kuandaa kahawa yako kwa mnunuzi: kukausha, kuchambua, kuhifadhi.',
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
    'Unashirikiana simu hii? Tumia "Sahau kila kitu" kwenye Shamba langu, na futa picha kwenye Afisa.',
  ],
  limitsTitle: 'Isichoweza kufanya',
  limits: [
    'Inajua tu kilichomo kwenye miongozo yake. Inaweza kukosea.',
    'Ukaguzi wa picha unajua majani ya kahawa, maharage na mahindi tu.',
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
  appName: 'Assistant agricole',
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
  sellIntro: 'La vente de votre récolte arrive bientôt. Cette page vous aidera à :',
  sellComing: [
    'Garder une trace de ce que vous avez récolté et vendu.',
    'Trouver votre coopérative et des acheteurs près de chez vous.',
    "Préparer votre café pour l'acheteur : séchage, tri, stockage.",
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
    'Téléphone partagé ? Utilisez « Tout oublier » dans Ma ferme et supprimez les photos dans Conseiller.',
  ],
  limitsTitle: "Ce qu'il ne sait pas faire",
  limits: [
    "Il ne connaît que ce qui est dans ses guides. Il peut se tromper.",
    'La vérification photo ne connaît que les feuilles de café, haricot et maïs.',
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
