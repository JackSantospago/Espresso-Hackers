import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';

import '../core/config.dart';
import '../core/harvest.dart';
import '../core/strings.dart';
import 'brain.dart';
import 'leaf_classifier.dart' if (dart.library.js_interop) 'leaf_classifier_stub.dart';
import 'outbox.dart';
import 'weather.dart';
import 'weather_risk.dart';

/// One message in the conversation. Assistant replies carry structured
/// fail-safe information so the UI can show it clearly, not as raw text.
class ChatTurn {
  ChatTurn(this.text, {required this.fromUser, this.image});

  String text;
  final bool fromUser;

  /// Photo shown in a farmer's message.
  final Uint8List? image;

  /// Knowledge files the answer was grounded on, and the best retrieval score.
  List<String> sources = const [];
  double? match;

  /// The reply is (or contains) "not sure — ask a person".
  bool notSure = false;

  /// Shown as a warning under the answer (e.g. weak retrieval match).
  String warning = '';

  /// Shown under a confident photo answer: it is a guess, confirm before acting.
  String caution = '';

  /// Technical line (scores, timings) behind the "Details" toggle.
  String details = '';

  /// Set on replies to a photo: lets the farmer send it for human review.
  Uint8List? reviewPhoto;
  String reviewNote = '';
  Diagnosis? diagnosis;
  bool queued = false;
}

enum AssistantState { loading, ready, failed }

/// Owns the on-device models and the conversation. Screens listen to it.
///
/// Flow per question: retrieve (knowledge + memory) → grounded prompt → stream
/// the answer → fail-safe flags → extract durable facts the farmer stated.
/// Flow per photo: on-device classifier → (not confident | healthy | disease)
/// → only a confident disease reaches the LLM, grounded on the knowledge base.
/// A very confident result (≥ [kPhotoMemoryThreshold]) is also noted in My farm.
/// Flow per weather check: the rules find the warnings → no warnings: fixed
/// answer, no LLM → warnings: the LLM explains what to do, grounded on the
/// knowledge base and on what the farmer said about the crops (memory).
class Assistant extends ChangeNotifier {
  Assistant(this.strings);

  /// Current UI language; fixed answers and the "not sure" sentence use it.
  S strings;

  final turns = <ChatTurn>[];

  /// The last "What should I do?" answer in Grow → Weather, and the forecast
  /// it was made for (a newer forecast hides it).
  ChatTurn? weatherAdvice;
  DateTime? weatherAdviceFor;

  /// The weather advice is being written, and what it is doing right now.
  bool weatherBusy = false;
  String weatherStatus = '';
  AssistantState state = AssistantState.loading;
  Object? error;
  bool busy = false;
  String status = '';
  int memoryCount = 0;
  int outboxCount = 0;
  int knowledgePassages = 0;

  InferenceModel? _model;
  InferenceChat? _chat;
  LeafClassifier? _classifier;
  bool _disposed = false;

  bool get ready => state == AssistantState.ready;
  bool get canSend => ready && !busy;
  bool get hasPhotoCheck => _classifier != null;
  LeafClassifier? get classifier => _classifier;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    state = AssistantState.loading;
    error = null;
    _notify();
    try {
      // maxTokens = context window (prompt + reply). We rebuild the prompt
      // every turn, so it never grows past this.
      final model = await FlutterEdgeAi.getActiveModel(
        maxTokens: 2048,
        preferredBackend: activeLlm.backend,
      );
      final chat = await model.createChat(
        modelType: activeLlm.modelType,
        maxOutputTokens: 320,
      );
      knowledgePassages = await Brain.indexKnowledge(); // no-op unless assets/knowledge changed
      memoryCount = (await Brain.memories()).length;
      _classifier = await LeafClassifier.load(); // null if the model files are not bundled
      _model = model;
      _chat = chat;
      state = AssistantState.ready;
      _notify();
      await refreshOutbox(flush: true); // store-and-forward: try queued photos whenever the app starts
    } catch (e) {
      error = e;
      state = AssistantState.failed;
      _notify();
    }
  }

  Future<void> refreshOutbox({bool flush = false}) async {
    if (flush && await Outbox.pendingCount() > 0) await Outbox.sendPending();
    outboxCount = await Outbox.pendingCount();
    _notify();
  }

  Future<void> refreshMemoryCount() async {
    memoryCount = (await Brain.memories()).length;
    _notify();
  }

  void clearConversation() {
    if (busy) return;
    turns.clear();
    _notify();
  }

  /// Runs one prompt on a fresh context and returns the full text.
  Future<String> _generate(String prompt, {void Function(String)? onPartial}) async {
    final chat = _chat!;
    await chat.clearHistory();
    await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
    final buf = StringBuffer();
    await for (final r in chat.generateChatResponseAsync()) {
      if (r is TextResponse) {
        buf.write(r.token);
        onPartial?.call(buf.toString());
      }
    }
    return buf.toString().trim();
  }

  String _recentHistory() => turns.reversed
      .take(4)
      .toList()
      .reversed
      .map((t) => '${t.fromUser ? 'Farmer' : 'Assistant'}: ${_clip(t.text, 300)}')
      .join('\n');

  // -------------------------------------------------------------- questions

  Future<void> send(String question) async {
    question = question.trim();
    if (_chat == null || question.isEmpty || busy) return;
    final s = strings;
    final history = _recentHistory();
    // The farmer's last messages, newest first: a question that names no crop
    // is about the crop she was just talking about (see cropKeyOf).
    final recent = [for (final t in turns.reversed) if (t.fromUser) t.text].take(4).toList();
    final reply = ChatTurn('', fromUser: false);
    turns
      ..add(ChatTurn(question, fromUser: true))
      ..add(reply);
    busy = true;
    status = s.statusSearching;
    _notify();

    // Farm facts in what the farmer just said (trees, acres, flowering or
    // planting month) are saved exactly, before anything else, so a later
    // question in any chat can use them.
    final asked = _awaitingHarvestCrop;
    _awaitingHarvestCrop = null;
    final saved = await _rememberFarmFacts(question, askedFor: asked);

    // Harvest forecast: asked directly, or the farmer answering our question
    // about her trees / acres. A reply without those facts is answered like
    // any other question. Which crop: the one named, else the one of the
    // conversation, else the only one with farm facts saved, else coffee. A
    // crop without figures (potatoes) is answered from the guides below.
    final harvestQuestion = isHarvestQuestion(question);
    final followUp = asked != null && !harvestQuestion;
    final harvestCrop = followUp
        ? asked
        : harvestQuestion
            ? _harvestCrop(cropKeyOf(question, recent: recent, farmFactKeys: await _farmFactKeys()))
            : null;
    if (harvestCrop != null) {
      var handled = true;
      try {
        handled = await _harvest(reply, question, crop: harvestCrop, followUp: followUp);
      } catch (e) {
        reply
          ..text = s.notSure
          ..notSure = true
          ..details = 'harvest error: $e';
      }
      if (handled) {
        busy = false;
        status = '';
        _notify();
        return;
      }
      status = s.statusSearching;
      _notify();
    } else if (saved.isNotEmpty && !question.contains('?')) {
      // A statement about the farm ("I have 400 coffee trees and they flowered
      // in March"): confirm what was saved instead of searching the guides.
      reply.text = '${saved.join(' ')}\n${s.notedForForecast}';
      status = s.statusUpdatingMemory;
      _notify();
      try {
        await _updateMemory(question); // anything else she said (observations, decisions)
      } catch (_) {/* the facts above are already saved */}
      busy = false;
      status = '';
      _notify();
      return;
    }

    try {
      // 0. Which crop this is about: named, or from the conversation. A follow-up
      //    that names no crop is searched together with that crop.
      final cropKey = cropKeyOf(question, recent: recent);
      final cropWord = cropKey == null
          ? ''
          : cropWordIn(question, cropKey) ?? recent.map((r) => cropWordIn(r, cropKey)).nonNulls.firstOrNull ?? cropKey;
      final query = cropKey != null && cropKeysIn(question).isEmpty ? '$question ($cropWord)' : question;

      // 1. Retrieve from knowledge + memory, and the saved forecast (null when weather is off).
      //    A crop without its own guide (potatoes) is never answered from another
      //    crop's guide (sweet potatoes, coffee): only the general guides count.
      var hits = await Brain.searchKnowledge(query);
      final noGuide = cropKey != null && !cropsWithGuides.contains(cropKey);
      if (cropKey != null && noGuide) {
        hits = hits.where((h) => !guideForAnotherCrop(h.source, cropKey) && h.score >= kConfidenceThreshold).toList();
        if (hits.isEmpty) {
          reply
            ..text = s.notCovered(cropWord)
            ..notSure = true
            ..details = 'no guide for $cropKey';
          status = s.statusUpdatingMemory;
          _notify();
          try {
            await _updateMemory(question);
          } catch (_) {/* the answer above stands */}
          return;
        }
      }
      final mems = await Brain.relevantMemories(query);
      final top = Brain.topScore(hits);
      final confident = top >= kConfidenceThreshold;
      final forecast = await Weather.savedForecast();
      final weather = forecast == null
          ? ''
          : '\nWEATHER (forecast for the farm; use it only if it matters for the QUESTION):\n'
              '${forecastForPrompt(forecast, DateTime.now())}\n';

      final prompt = '''
You are an offline farming assistant for smallholder farmers.
${cropKey == null ? '' : 'The QUESTION is about $cropWord.${noGuide ? ' CONTEXT has only general advice, nothing specific to $cropWord: never use advice for another crop.' : ''}\n'}Rules: Answer ONLY from CONTEXT, MEMORY${weather.isEmpty ? '' : ' and WEATHER'} below. Max 3 short sentences, plain words.
${weather.isEmpty ? 'If CONTEXT does not contain' : 'If neither CONTEXT nor WEATHER contains'} the answer, reply exactly: "${s.notSure}"
Never invent prices, numbers or chemical doses. The farmer makes the final decision.
Reply in the same language as the QUESTION.

MEMORY (facts about this farmer):
${_bullets(mems)}
$weather
CONTEXT:
${_context(hits)}

RECENT CONVERSATION:
${history.isEmpty ? '(start)' : history}

QUESTION: $question''';

      // 2. Generate (streamed into the bubble)
      status = s.statusThinking;
      _notify();
      final answer = await _generate(prompt, onPartial: (t) {
        reply.text = t;
        status = '';
        _notify();
      });

      // 3. Fail-safe: "not sure", or weak retrieval => tell the farmer to check with a person
      final notSure = answer.isEmpty || _saysNotSure(answer);
      reply
        ..text = answer.isEmpty ? s.notSure : answer
        ..notSure = notSure
        ..warning = confident || notSure ? '' : s.weakMatch
        ..sources = _sources(hits)
        ..match = top
        ..details = 'match ${top.toStringAsFixed(2)} (threshold $kConfidenceThreshold) · ${activeLlm.label}';
      status = s.statusUpdatingMemory;
      _notify();

      // 4. Memory: extract durable facts the FARMER stated (never the model's own claims)
      await _updateMemory(question);
    } catch (e) {
      reply
        ..text = s.notSure
        ..notSure = true
        ..details = 'error: $e';
    } finally {
      busy = false;
      status = '';
      _notify();
    }
  }

  // -------------------------------------------------------- harvest forecast

  /// We asked for the trees / acres of this crop; the next message answers it.
  HarvestCrop? _awaitingHarvestCrop;

  /// The crop to forecast for a harvest question about [key]: coffee when
  /// nothing says which crop, null for a crop without figures.
  static HarvestCrop? _harvestCrop(String? key) => key == null ? HarvestCrop.coffee : harvestCropByKey(key);

  /// Kinds of farm facts saved ('coffee-trees', 'maize-acres', …).
  Future<List<String>> _farmFactKeys() async {
    try {
      return [
        for (final m in await Brain.memories())
          if (m.id.startsWith(_farmFactPrefix)) m.id.substring(_farmFactPrefix.length).split(':').first,
      ];
    } catch (_) {
      return const []; // then coffee, as before
    }
  }

  static const _farmFactPrefix = 'mem:farm:';

  /// Saves the farm facts found in [text] exactly (one entry per kind of fact:
  /// a newer value replaces the older one, nothing else is touched). Returns
  /// the sentences saved. A failure here never breaks the answer.
  Future<List<String>> _rememberFarmFacts(String text, {HarvestCrop? askedFor}) async {
    final facts = farmFactsIn(text, askedFor: askedFor, isQuestion: text.contains('?') && askedFor == null);
    if (facts.isEmpty) return const [];
    final saved = <String>[];
    try {
      final existing = await Brain.memories();
      for (final f in facts) {
        final prefix = '$_farmFactPrefix${f.key}:';
        for (final m in existing) {
          if (m.id.startsWith(prefix)) await Brain.forget(m.id);
        }
        final sentence = f.text(strings);
        await Brain.remember(sentence, merge: false, idPrefix: prefix);
        saved.add(sentence);
      }
      await refreshMemoryCount();
    } catch (_) {/* keep answering; the facts are still in the question itself */}
    return saved;
  }

  /// A note the farmer wrote in My farm: its farm facts are saved the same way
  /// as facts said in the chat, so the forecast uses them.
  Future<void> noteFarmFacts(String note) => _rememberFarmFacts(note);

  /// "How much will I harvest, and when?" The farm facts are read from the
  /// question, the saved farm facts and the rest of My farm (newest first); the
  /// model reads them only when that finds nothing, and may only use numbers
  /// the farmer actually wrote. core/harvest.dart does the arithmetic with
  /// sourced figures and the answer sentence is fixed, so every number shown
  /// is exactly what the formula gave. Missing quantity → ask, never guess.
  /// Returns false when this was a reply to our question that still lacks the
  /// facts, so the caller answers it as a normal question instead.
  Future<bool> _harvest(ChatTurn reply, String question, {required HarvestCrop crop, bool followUp = false}) async {
    final s = strings;
    status = s.statusCalculating;
    _notify();
    final memories = await Brain.memories(); // newest first
    final facts = [
      question,
      for (final m in memories)
        if (m.id.startsWith(_farmFactPrefix)) m.text,
      for (final m in memories)
        if (!m.id.startsWith(_farmFactPrefix)) m.text,
    ];
    final today = DateTime.now();

    final inputs = harvestInputsFrom(facts, today: today, crop: crop) ?? await _inputsFromModel(facts, crop, today);
    final cropName = switch (crop) {
      HarvestCrop.coffee => s.guidesCoffee,
      HarvestCrop.maize => s.guidesMaize,
      HarvestCrop.beans => s.guidesBeans,
    }.toLowerCase();
    if (inputs == null) {
      if (followUp) return false;
      reply.text = crop == HarvestCrop.coffee ? s.harvestNeed : s.harvestNeedArea(cropName);
      _awaitingHarvestCrop = crop;
      return true;
    }
    if (inputs.youngTrees) {
      reply.text = s.harvestYoung;
      return true;
    }

    // The formulas, then a fixed sentence with exactly those numbers.
    final f = forecastHarvest(inputs);
    harvestOf[reply] = f;
    String n(int v) => v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    reply.text = s.harvestSummary(
        n(f.kgLow), n(f.kgHigh), s.monthsLong[f.readyFrom.month - 1], s.monthsLong[f.readyTo.month - 1]);
    return true;
  }

  /// For phrasings the plain reading misses: the model fills the inputs as
  /// JSON. A quantity the farmer never wrote is a guess and is rejected; a
  /// month is used only if that month is named in the facts.
  Future<HarvestInputs?> _inputsFromModel(List<String> facts, HarvestCrop crop, DateTime today) async {
    try {
      final out = await _generate("""
From the farmer's facts below, find for ${crop.name}: how many trees (coffee only), how many acres,
and the month (1 to 12) the ${crop == HarvestCrop.coffee ? 'trees last flowered' : 'crop was planted'}.
Use only the facts. Do not guess. Reply with JSON only:
{"trees": number or null, "acres": number or null, "month": number or null}

FACTS:
${facts.map((f) => '- $f').join('\n')}""");
      final j = jsonDecode(RegExp(r'\{.*\}', dotAll: true).firstMatch(out)!.group(0)!) as Map<String, dynamic>;
      final said = facts.join(' ').replaceAll(',', '');
      bool written(num? v) => v != null && v > 0 && said.contains(v == v.roundToDouble() ? '${v.round()}' : '$v');
      final trees = crop == HarvestCrop.coffee && written(j['trees'] as num?) ? (j['trees'] as num).round() : null;
      final acres = written(j['acres'] as num?) ? (j['acres'] as num).toDouble() : null;
      if (trees == null && acres == null) return null;
      final m = (j['month'] as num?)?.round();
      final named = m != null && m >= 1 && m <= 12 && facts.any((f) => monthNamedIn(f, m));
      final month = named ? m : kUsualMonth;
      return HarvestInputs(
        crop: crop,
        trees: trees,
        acres: trees == null ? acres : null,
        floweredMonth: month,
        floweredYear: month <= today.month ? today.year : today.year - 1,
        monthAssumed: !named,
      );
    } catch (_) {
      return null; // not JSON, or nothing usable
    }
  }

  bool _saysNotSure(String answer) {
    final a = answer.toLowerCase();
    return a.contains(strings.notSure.toLowerCase()) || a.contains('not sure');
  }

  // ------------------------------------------------------------ photo check

  Future<void> sendPhoto(Uint8List photo, String question) async {
    final classifier = _classifier;
    if (_chat == null || classifier == null || busy) return;
    final s = strings;
    question = question.trim();
    final reply = ChatTurn('', fromUser: false)
      ..reviewPhoto = photo
      ..reviewNote = question;
    turns
      ..add(ChatTurn(question.isEmpty ? s.photoDefaultQuestion : question, fromUser: true, image: photo))
      ..add(reply);
    busy = true;
    status = s.statusCheckingPhoto;
    _notify();

    try {
      // 1. On-device classifier
      final d = await classifier.classify(photo);
      reply.diagnosis = d;
      final photoNote = 'Photo check: ${d.top.join(', ')} · needs ${(d.threshold * 100).round()}% · ${d.millis} ms';

      // 2. Fail-safe: not confident, or not one of our crops → no diagnosis, no LLM.
      if (!d.confident) {
        final guess = d.isOther ? s.photoNotSureOther : s.photoNotSureGuess(d.best.label.localized(s), d.best.percent);
        reply
          ..text = s.photoNotSure(guess)
          ..notSure = true
          ..details = photoNote;
        return;
      }

      final label = d.best.label;

      // 3. Healthy → fixed answer (nothing for the LLM to explain).
      if (label.isHealthy) {
        reply
          ..text = s.healthy(s.cropName(label.crop), d.best.percent)
          ..details = photoNote + await _rememberPhoto(d);
        return;
      }

      // 4. Confident disease → explain it from the knowledge base, in the farmer's language.
      status = s.statusLookingUp(s.conditionName(label.id, label.condition));
      _notify();
      final query = '${label.crop} ${label.condition} symptoms management $question';
      final hits = await Brain.searchKnowledge(query);
      final mems = await Brain.relevantMemories(query);
      final asked = question.isEmpty ? s.photoAskDefault(s.cropName(label.crop)) : question;

      final prompt = '''
You are an offline farming assistant for smallholder farmers.
A photo check on this phone looked at the farmer's leaf and suggests: ${label.display} (${d.best.percent} sure). It can be wrong.
Rules: Use ONLY the CONTEXT and MEMORY below. Max 3 short sentences, plain words.
First say how ${label.condition} usually looks, so the farmer can compare it with her leaf. Then say what she can do.
If CONTEXT says nothing about ${label.condition}, reply exactly: "${s.notSure}"
Never invent prices, numbers or chemical doses. The farmer makes the final decision.
Reply in the same language as the QUESTION.

MEMORY (facts about this farmer):
${_bullets(mems)}

CONTEXT:
${_context(hits)}

QUESTION: $asked''';

      status = s.statusThinking;
      _notify();
      final answer = await _generate(prompt, onPartial: (t) {
        reply.text = t;
        status = '';
        _notify();
      });

      reply
        ..text = answer.isEmpty ? s.notSure : answer
        ..notSure = answer.isEmpty || _saysNotSure(answer)
        ..caution = s.photoCaution
        ..sources = _sources(hits)
        ..match = Brain.topScore(hits)
        ..details = photoNote + await _rememberPhoto(d);

      // What the farmer typed is mined for facts; the photo result itself was
      // saved above only as a dated, labelled guess (never as a fact).
      if (question.isNotEmpty) {
        status = s.statusUpdatingMemory;
        _notify();
        await _updateMemory(question);
      }
    } catch (e) {
      reply
        ..text = s.notSure
        ..notSure = true
        ..details = 'photo error: $e';
    } finally {
      busy = false;
      status = '';
      _notify();
    }
  }

  // ---------------------------------------------------------- weather check

  /// "What should I do?" in Grow → Weather. The rules already found [alerts]
  /// in [forecast]; the LLM only explains how to protect the crops, and only
  /// for the warnings the guides cover. Uses [weatherStatus], not [status], so
  /// the chat's status strip does not show weather progress.
  Future<void> assessWeather(Forecast forecast, List<WeatherAlert> alerts) async {
    if (busy) return;
    final s = strings;
    final w = s.weather;
    final now = DateTime.now();
    final staleNote = forecast.isStale(now) ? w.stale(w.ago(forecast.age(now))) : '';

    // 1. No warnings → fixed answer, nothing for the LLM to explain (works without the model).
    if (alerts.isEmpty) {
      weatherAdvice = ChatTurn(w.noAlertsAnswer, fromUser: false)
        ..warning = staleNote
        ..caution = w.caution
        ..details = 'no warnings in ${forecast.upcoming(now).length} forecast days';
      weatherAdviceFor = forecast.fetchedAt;
      _notify();
      return;
    }
    if (_chat == null) return;

    final reply = ChatTurn('', fromUser: false);
    weatherAdvice = reply;
    weatherAdviceFor = forecast.fetchedAt;
    busy = true;
    weatherBusy = true;
    weatherStatus = w.statusChecking;
    _notify();

    try {
      // 2. Protection advice for EVERY kind of warning. A warning the guides do
      //    not cover (weak best match) is not explained by the LLM: it gets
      //    "ask your extension officer" instead of invented advice.
      final covered = <WeatherAlert>[], uncovered = <WeatherAlert>[];
      final found = <Hit>[];
      final best = <WeatherRisk, double>{};
      for (final r in alerts.map((a) => a.risk).toSet()) {
        final hits = await Brain.searchKnowledge(riskQuery(r), k: 2);
        best[r] = Brain.topScore(hits);
        if (best[r]! >= kConfidenceThreshold) found.addAll(hits);
      }
      for (final a in alerts) {
        (best[a.risk]! >= kConfidenceThreshold ? covered : uncovered).add(a);
      }
      found.sort((a, b) => b.score.compareTo(a.score));
      final seen = <String>{};
      final hits = found.where((h) => seen.add(h.text)).take(5).toList();
      final scores = best.entries.map((e) => '${e.key.name} ${e.value.toStringAsFixed(2)}').join(', ');

      // Nothing in the guides for any warning: say so, without the LLM.
      if (covered.isEmpty) {
        reply
          ..text = s.notSure
          ..notSure = true
          ..warning = staleNote
          ..caution = w.caution
          ..details = '${alerts.map(alertForPrompt).join(' ')} · match $scores';
        return;
      }

      final mems = await Brain.relevantMemories(
          'my crops and how they are doing: growth stage, flowering, young plants, harvest, health');
      final prompt = '''
You are an offline farming assistant for smallholder farmers.
The app's weather rules found these warnings in the forecast for the farm:
${covered.map((a) => '- ${alertForPrompt(a)}').join('\n')}
Rules: Use ONLY the CONTEXT and MEMORY below. Max 6 short sentences, plain words.
Start with the most urgent warning. For each warning, say what the farmer can do now to protect the crops.
Use MEMORY to fit the advice to the farmer's crops and how they are doing now.
If CONTEXT says nothing about protecting crops from these warnings, reply exactly: "${s.notSure}"
Never invent prices, numbers or chemical doses. Do not repeat the forecast numbers. The farmer makes the final decision.
${uncovered.isEmpty ? '' : 'The guides say nothing about: ${uncovered.map((a) => alertForPrompt(a)).join(' ')} '
          'End with one sentence saying to ask the extension officer about that.\n'}Reply in ${w.replyLanguage}.

MEMORY (facts about this farmer and the crops):
${_bullets(mems)}

CONTEXT:
${_context(hits)}''';

      // 3. Generate (streamed into Grow → Weather)
      weatherStatus = s.statusThinking;
      _notify();
      final answer = await _generate(prompt, onPartial: (t) {
        reply.text = t;
        weatherStatus = '';
        _notify();
      });

      // 4. Fail-safes: not sure, warnings the guides do not cover, old forecast
      final notSure = answer.isEmpty || _saysNotSure(answer);
      final top = Brain.topScore(hits);
      reply
        ..text = answer.isEmpty ? s.notSure : answer
        ..notSure = notSure
        ..warning = [staleNote, if (uncovered.isNotEmpty && !notSure) s.weakMatch]
            .where((x) => x.isNotEmpty)
            .join('\n')
        ..caution = w.caution
        ..sources = _sources(hits)
        ..match = top
        ..details = '${alerts.map(alertForPrompt).join(' ')} · match $scores · ${activeLlm.label}';
    } catch (e) {
      reply
        ..text = s.notSure
        ..notSure = true
        ..details = 'weather error: $e';
    } finally {
      busy = false;
      weatherBusy = false;
      weatherStatus = '';
      _notify();
    }
  }

  /// Human in the loop: called only after the farmer agreed in the consent dialog.
  Future<void> saveForReview(ChatTurn turn) async {
    final photo = turn.reviewPhoto;
    if (photo == null || turn.queued) return;
    await Outbox.add(photo: photo, note: turn.reviewNote, diagnosis: turn.diagnosis);
    turn.queued = true;
    _notify();
    await refreshOutbox(flush: true);
  }

  // ------------------------------------------------------------------ memory

  /// Notes a very confident photo check in My farm, so later answers know about
  /// it. One line per crop: a newer photo check of that crop replaces the older
  /// one, and it never replaces anything the farmer said. Returns a note for
  /// the "Details" line; a failure here never breaks the photo answer.
  Future<String> _rememberPhoto(Diagnosis d) async {
    if (!photoWorthRemembering(d)) return '';
    try {
      final prefix = photoMemoryPrefix(d);
      for (final m in await Brain.memories()) {
        if (m.id.startsWith(prefix)) await Brain.forget(m.id);
      }
      await Brain.remember(photoMemoryText(strings, d, DateTime.now()), merge: false, idPrefix: photoMemoryIdPrefix(d));
      await refreshMemoryCount();
      return ' · saved to My farm';
    } catch (e) {
      return ' · not saved to My farm: $e';
    }
  }

  Future<void> _updateMemory(String farmerSaid) async {
    if (farmerSaid.length < 15) return;
    final out = await _generate('''
Extract lasting facts that the farmer states about themselves, their farm, crops, plots,
observations or decisions. Ignore questions and greetings. Do not guess.
Write each fact as a short standalone sentence in ${strings.weather.replyLanguage}, on its own line starting with "- ".
If there is nothing to remember, write exactly: NONE

Farmer said: "$farmerSaid"''');
    final facts = out
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.startsWith('- ') || l.startsWith('* '))
        .map((l) => l.substring(2).trim())
        .where((l) => l.isNotEmpty && !l.contains('?') && l.toUpperCase() != 'NONE')
        .take(3);
    for (final f in facts) {
      await Brain.remember(f);
    }
    await refreshMemoryCount();
  }

  // ----------------------------------------------------------------- helpers

  String _bullets(List<String> mems) => mems.isEmpty ? '(none yet)' : mems.map((m) => '- $m').join('\n');
  String _context(List<Hit> hits) =>
      hits.isEmpty ? '(nothing found)' : hits.map((h) => '[${h.source}] ${h.text}').join('\n---\n');
  List<String> _sources(List<Hit> hits) => hits.map((h) => h.source).toSet().toList();
  String _clip(String s, int n) => s.length <= n ? s : '${s.substring(0, n)}…';

  @override
  void dispose() {
    _disposed = true;
    _model?.close().catchError((Object _) {});
    super.dispose();
  }
}

// ------------------------------------------------- photo check → My farm

/// Only a confident crop diagnosis that also clears the stricter memory bar.
bool photoWorthRemembering(Diagnosis d) =>
    d.confident && d.best.probability >= math.max(kPhotoMemoryThreshold, d.threshold);

/// Id prefix of the photo-check entry for this crop (one per crop).
String photoMemoryPrefix(Diagnosis d) => 'mem:photo:${d.best.label.crop.toLowerCase()}:';

/// Full id prefix of a new photo-check entry: [photoMemoryPrefix] plus the
/// label and certainty, so My farm can word it again in another language.
/// Example: 'mem:photo:coffee:coffee__leaf_rust:91:' (+ a timestamp).
String photoMemoryIdPrefix(Diagnosis d) =>
    '${photoMemoryPrefix(d)}${d.best.label.id}:${(d.best.probability * 100).round()}:';

/// The My farm line for a photo check, dated and worded as a guess.
String photoMemoryText(S s, Diagnosis d, DateTime when) {
  final date = when.toIso8601String().substring(0, 10);
  final label = d.best.label;
  final crop = s.cropName(label.crop);
  return label.isHealthy
      ? s.photoMemoryHealthy(date, crop, d.best.percent)
      : s.photoMemoryProblem(date, crop, s.conditionName(label.id, label.condition), d.best.percent);
}

/// What My farm shows for a memory, in the farmer's current language.
/// Photo checks are worded again from their id (see [photoMemoryIdPrefix]), so
/// they follow a language change; what the farmer said stays in her own words.
String memoryText(S s, MemoryItem m) {
  final p = m.id.split(':'); // mem, photo, crop, label id, percent, timestamp
  if (p.length != 6 || p[0] != 'mem' || p[1] != 'photo') return m.text;
  final condition = s.leafConditions[p[3]];
  if (condition == null || int.tryParse(p[4]) == null) return m.text;
  final date = m.date.toLocal().toIso8601String().substring(0, 10);
  final crop = s.cropName(p[2]);
  final pct = '${p[4]}%';
  return p[3].endsWith('__healthy')
      ? s.photoMemoryHealthy(date, crop, pct)
      : s.photoMemoryProblem(date, crop, condition, pct);
}
