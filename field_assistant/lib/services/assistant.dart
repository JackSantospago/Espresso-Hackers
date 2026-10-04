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
    final reply = ChatTurn('', fromUser: false);
    turns
      ..add(ChatTurn(question, fromUser: true))
      ..add(reply);
    busy = true;
    status = s.statusSearching;
    _notify();

    // Harvest forecast: asked directly, or the farmer answering our question
    // about her trees and flowering month. A reply without those facts is
    // answered like any other question.
    final followUp = _awaitingHarvestFacts && !isHarvestQuestion(question);
    if (isHarvestQuestion(question) || followUp) {
      var handled = true;
      try {
        handled = await _harvest(reply, question, followUp: followUp);
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
    }

    try {
      // 1. Retrieve from knowledge + memory, and the saved forecast (null when weather is off)
      final hits = await Brain.searchKnowledge(question);
      final mems = await Brain.relevantMemories(question);
      final top = hits.isEmpty ? 0.0 : hits.first.score;
      final confident = top >= kConfidenceThreshold;
      final forecast = await Weather.savedForecast();
      final weather = forecast == null
          ? ''
          : '\nWEATHER (forecast for the farm; use it only if it matters for the QUESTION):\n'
              '${forecastForPrompt(forecast, DateTime.now())}\n';

      final prompt = '''
You are an offline farming assistant for smallholder coffee farmers.
Rules: Answer ONLY from CONTEXT, MEMORY${weather.isEmpty ? '' : ' and WEATHER'} below. Max 3 short sentences, plain words.
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

  /// We asked for the trees and the flowering month; the next message answers it.
  bool _awaitingHarvestFacts = false;

  /// "How much will I harvest, and when?" The model reads the farm facts and
  /// fills the formula's inputs; core/harvest.dart does the arithmetic with
  /// sourced figures; the answer sentence is fixed, so every number shown is
  /// exactly what the formula gave. Missing inputs → ask for them, never guess.
  /// Returns false when this was a reply to our question that still lacks the
  /// facts, so the caller answers it as a normal question instead.
  Future<bool> _harvest(ChatTurn reply, String question, {bool followUp = false}) async {
    final s = strings;
    _awaitingHarvestFacts = false;
    status = s.statusCalculating;
    _notify();
    final facts = [...(await Brain.memories()).map((m) => m.text), question];
    final today = DateTime.now();

    // 1. The model extracts the inputs.
    HarvestInputs? fromModel;
    final out = await _generate('''
From the farmer's facts below, find how many coffee trees the farmer has and
the month (1 to 12) the trees last flowered. Use only the facts. Do not guess.
Reply with JSON only: {"trees": number or null, "flowered_month": number or null}

FACTS:
${facts.map((f) => '- $f').join('\n')}''');
    try {
      final j = jsonDecode(RegExp(r'\{.*\}', dotAll: true).firstMatch(out)!.group(0)!) as Map<String, dynamic>;
      final trees = (j['trees'] as num?)?.round();
      final month = (j['flowered_month'] as num?)?.round();
      final said = facts.join(' ').replaceAll(',', '');
      // A number the farmer never said is a guess: reject it.
      if (trees != null && trees > 0 && said.contains('$trees') && month != null && month >= 1 && month <= 12) {
        fromModel = HarvestInputs(
          trees: trees,
          floweredMonth: month,
          floweredYear: month <= today.month ? today.year : today.year - 1,
        );
      }
    } catch (_) {/* not JSON: fall back to reading the facts directly */}

    // 2. Cross-check with a plain reading of the same facts.
    final inputs = fromModel ?? harvestInputsFrom(facts, today: today);
    if (inputs == null) {
      if (followUp) return false;
      reply.text = s.harvestNeed;
      _awaitingHarvestFacts = true;
      return true;
    }

    // 3. The formulas, then a fixed sentence with exactly those numbers.
    final f = forecastHarvest(inputs);
    harvestOf[reply] = f;
    String n(int v) => v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    reply.text = s.harvestSummary(
        n(f.kgLow), n(f.kgHigh), s.monthsLong[f.readyFrom.month - 1], s.monthsLong[f.readyTo.month - 1]);
    _notify();

    // 4. Remember what the farmer told us (trees, flowering) for next time.
    status = s.statusUpdatingMemory;
    _notify();
    await _updateMemory(question);
    return true;
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
        final guess = d.isOther ? s.photoNotSureOther : s.photoNotSureGuess(d.best.label.display, d.best.percent);
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
          ..text = s.healthy(label.crop.toLowerCase(), d.best.percent)
          ..details = photoNote + await _rememberPhoto(d);
        return;
      }

      // 4. Confident disease → explain it from the knowledge base, in the farmer's language.
      status = s.statusLookingUp(label.condition);
      _notify();
      final query = '${label.crop} ${label.condition} symptoms management $question';
      final hits = await Brain.searchKnowledge(query);
      final mems = await Brain.relevantMemories(query);
      final asked = question.isEmpty ? s.photoAskDefault(label.crop.toLowerCase()) : question;

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
        ..match = hits.isEmpty ? 0.0 : hits.first.score
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
        best[r] = hits.isEmpty ? 0.0 : hits.first.score;
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
      final top = hits.isEmpty ? 0.0 : hits.first.score;
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
      await Brain.remember(photoMemoryText(strings, d, DateTime.now()), merge: false, idPrefix: prefix);
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
Write each fact as a short standalone sentence on its own line starting with "- ".
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

/// The My farm line for a photo check, dated and worded as a guess.
String photoMemoryText(S s, Diagnosis d, DateTime when) {
  final date = when.toIso8601String().substring(0, 10);
  final label = d.best.label;
  final crop = label.crop.toLowerCase();
  return label.isHealthy
      ? s.photoMemoryHealthy(date, crop, d.best.percent)
      : s.photoMemoryProblem(date, crop, label.condition, d.best.percent);
}
