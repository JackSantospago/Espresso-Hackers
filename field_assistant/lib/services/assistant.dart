import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';

import '../core/config.dart';
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
Rules: Answer ONLY from CONTEXT, MEMORY${weather.isEmpty ? '' : ' and WEATHER'} below. Max 5 short sentences, plain words.
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
          ..details = photoNote;
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
Rules: Use ONLY the CONTEXT and MEMORY below. Max 5 short sentences, plain words.
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
        ..details = photoNote;

      // Only what the farmer typed goes to memory — never the classifier's guess.
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
  /// in [forecast]; the LLM only explains how to protect the crops.
  Future<void> assessWeather(Forecast forecast, List<WeatherAlert> alerts) async {
    if (_chat == null || busy) return;
    final s = strings;
    final w = s.weather;
    final reply = ChatTurn('', fromUser: false);
    weatherAdvice = reply;
    weatherAdviceFor = forecast.fetchedAt;
    final age = forecast.age(DateTime.now());
    final staleNote = age > kWeatherStaleAfter ? w.stale(w.ago(age)) : '';
    final alertLines = alerts.map(alertForPrompt).toList();
    busy = true;
    status = w.statusChecking;
    _notify();

    try {
      // 1. No warnings → fixed answer, nothing for the LLM to explain.
      if (alerts.isEmpty) {
        reply
          ..text = w.noAlertsAnswer
          ..warning = staleNote
          ..caution = w.caution
          ..details = 'no warnings in ${forecast.upcoming(DateTime.now()).length} forecast days';
        return;
      }

      // 2. Protection advice for each kind of warning (soonest first) + what the farmer said about the crops.
      final found = <Hit>[];
      for (final r in alerts.map((a) => a.risk).toSet().take(3)) {
        found.addAll(await Brain.searchKnowledge(riskQuery(r), k: 2));
      }
      found.sort((a, b) => b.score.compareTo(a.score));
      final seen = <String>{};
      final hits = found.where((h) => seen.add(h.text)).take(4).toList();
      final mems = await Brain.relevantMemories(
          'my crops and how they are doing: growth stage, flowering, young plants, harvest, health');
      final top = hits.isEmpty ? 0.0 : hits.first.score;

      final prompt = '''
You are an offline farming assistant for smallholder farmers.
The app's weather rules found these warnings in the forecast for the farm:
${alertLines.map((l) => '- $l').join('\n')}
Rules: Use ONLY the CONTEXT and MEMORY below. Max 6 short sentences, plain words.
Start with the most urgent warning. For each warning, say what the farmer can do now to protect the crops.
Use MEMORY to fit the advice to the farmer's crops and how they are doing now.
If CONTEXT says nothing about protecting crops from these warnings, reply exactly: "${s.notSure}"
Never invent prices, numbers or chemical doses. Do not repeat the forecast numbers. The farmer makes the final decision.
Reply in ${w.replyLanguage}.

MEMORY (facts about this farmer and the crops):
${_bullets(mems)}

CONTEXT:
${_context(hits)}''';

      // 3. Generate (streamed into Grow → Weather)
      status = s.statusThinking;
      _notify();
      final answer = await _generate(prompt, onPartial: (t) {
        reply.text = t;
        status = '';
        _notify();
      });

      // 4. Fail-safes: not sure, weak match in the guides, old forecast
      final notSure = answer.isEmpty || _saysNotSure(answer);
      reply
        ..text = answer.isEmpty ? s.notSure : answer
        ..notSure = notSure
        ..warning = [staleNote, if (top < kConfidenceThreshold && !notSure) s.weakMatch]
            .where((x) => x.isNotEmpty)
            .join('\n')
        ..caution = w.caution
        ..sources = _sources(hits)
        ..match = top
        ..details = '${alertLines.join(' ')} · match ${top.toStringAsFixed(2)} · ${activeLlm.label}';
    } catch (e) {
      reply
        ..text = s.notSure
        ..notSure = true
        ..details = 'weather error: $e';
    } finally {
      busy = false;
      status = '';
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
