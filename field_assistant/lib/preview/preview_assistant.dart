import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/harvest.dart';
import '../core/strings.dart';

import '../services/assistant.dart';
import '../services/brain.dart';
import '../services/outbox.dart';
import '../services/weather.dart';
import '../services/weather_risk.dart';
import '../frontend/shared/farm_data.dart';
import 'fake_data.dart';
import 'preview_options.dart';

/// An [Assistant] with no models: canned answers stream in word by word, so
/// every UI state (searching, streaming, not sure, photo check) can be tried.
class PreviewAssistant extends Assistant {
  PreviewAssistant(super.strings, this.data) {
    state = AssistantState.ready;
    knowledgePassages = 5;
    // ?chat=demo: start on a conversation with every kind of message.
    if (PreviewOptions.demoChat) turns.addAll(fakeConversation(strings));
    memoryCount = data.memoryItems.length;
    outboxCount = data.outboxItems.where((i) => !i.sent).length;
  }

  final PreviewFarmData data;
  final _rng = Random();

  @override
  bool get hasPhotoCheck => true;

  @override
  Future<void> load() async {
    state = AssistantState.ready;
    notifyListeners();
  }

  Future<void> _stream(ChatTurn reply, String text) async {
    status = strings.statusSearching;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    status = strings.statusThinking;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    status = '';
    final words = text.split(' ');
    for (var i = 0; i < words.length; i++) {
      reply.text = words.take(i + 1).join(' ');
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
  }

  @override
  Future<void> send(String question) async {
    question = question.trim();
    if (question.isEmpty || busy) return;
    final recent = [for (final t in turns.reversed) if (t.fromUser) t.text].take(4).toList();
    final reply = ChatTurn('', fromUser: false);
    turns
      ..add(ChatTurn(question, fromUser: true))
      ..add(reply);
    busy = true;
    // Same flow as the real Assistant: farm facts are saved first; harvest
    // questions (or the answer to our question) get a forecast; a statement
    // with farm facts gets "Noted".
    final asked = _asked;
    _asked = null;
    final saved = _rememberFacts(question, askedFor: asked);
    final harvestQuestion = isHarvestQuestion(question);
    final farmKeys = [
      for (final m in data.memoryItems)
        if (m.id.startsWith('mem:farm:')) m.id.substring('mem:farm:'.length).split(':').first,
    ];
    final key = cropKeyOf(question, recent: recent, farmFactKeys: farmKeys);
    final crop = harvestQuestion ? (key == null ? HarvestCrop.coffee : harvestCropByKey(key)) : asked;
    if (crop != null) {
      final handled = await _harvest(reply, question, crop: crop, followUp: !harvestQuestion);
      if (handled) return;
    } else if (saved.isNotEmpty && !question.contains('?')) {
      await _stream(reply, '${saved.join(' ')}\n${strings.notedForForecast}');
      busy = false;
      status = '';
      notifyListeners();
      return;
    }
    // A crop the guides do not cover (potatoes) is said so, like the real Assistant.
    final about = cropKeyOf(question, recent: recent);
    if (about != null && !cropsWithGuides.contains(about)) {
      final word = cropWordIn(question, about) ?? recent.map((r) => cropWordIn(r, about)).nonNulls.firstOrNull ?? about;
      await _stream(reply, strings.notCovered(word));
      reply
        ..notSure = true
        ..details = 'no guide for $about · preview (no model)';
      busy = false;
      notifyListeners();
      return;
    }
    // Questions mentioning a price get the "not sure" path, everything else a grounded answer.
    final notSure = RegExp(r'\b(?:prices?|bei|prix)\b').hasMatch(question.toLowerCase());
    await _stream(reply, notSure ? strings.notSure : demoText(strings).answer);
    final match = notSure ? 0.08 : 0.35 + _rng.nextDouble() * 0.3;
    reply
      ..notSure = notSure
      ..warning = notSure ? strings.weakMatch : ''
      ..sources = notSure ? const [] : const ['coffee_growing.md']
      ..match = match
      ..details = 'match ${match.toStringAsFixed(2)} · preview (no model)';
    busy = false;
    notifyListeners();
  }

  /// "How much will I harvest?": read the farm facts, run the formulas
  /// (core/harvest.dart), attach the forecast card, explain it in words.
  /// We asked for the trees / acres of this crop.
  HarvestCrop? _asked;

  /// Saves farm facts like the real Assistant: one entry per kind of fact,
  /// a newer value replacing the older one.
  List<String> _rememberFacts(String text, {HarvestCrop? askedFor}) {
    final facts = farmFactsIn(text, askedFor: askedFor, isQuestion: text.contains('?') && askedFor == null);
    final saved = <String>[];
    for (final f in facts) {
      final prefix = 'mem:farm:${f.key}:';
      data.memoryItems.removeWhere((m) => m.id.startsWith(prefix));
      final sentence = f.text(strings);
      data.memoryItems.insert(0, MemoryItem('$prefix${DateTime.now().microsecondsSinceEpoch}', sentence, DateTime.now()));
      saved.add(sentence);
    }
    if (saved.isNotEmpty) memoryCount = data.memoryItems.length;
    return saved;
  }

  @override
  Future<void> noteFarmFacts(String note) async => _rememberFacts(note);

  /// "How much will I harvest?": read the farm facts (question, saved farm
  /// facts, the rest of My farm), run the formulas (core/harvest.dart), attach
  /// the forecast card. Returns false for a reply that still lacks the facts.
  Future<bool> _harvest(ChatTurn reply, String question, {required HarvestCrop crop, bool followUp = false}) async {
    status = strings.statusSearching;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    status = strings.statusCalculating;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final facts = [
      question,
      for (final m in data.memoryItems)
        if (m.id.startsWith('mem:farm:')) m.text,
      for (final m in data.memoryItems)
        if (!m.id.startsWith('mem:farm:')) m.text,
    ];
    final inputs = harvestInputsFrom(facts, today: DateTime.now(), crop: crop);
    if (inputs == null) {
      if (followUp) {
        status = strings.statusSearching;
        return false;
      }
      final cropName = switch (crop) {
        HarvestCrop.coffee => strings.guidesCoffee,
        HarvestCrop.maize => strings.guidesMaize,
        HarvestCrop.beans => strings.guidesBeans,
      }.toLowerCase();
      _asked = crop;
      await _stream(reply, crop == HarvestCrop.coffee ? strings.harvestNeed : strings.harvestNeedArea(cropName));
    } else if (inputs.youngTrees) {
      await _stream(reply, strings.harvestYoung);
    } else {
      final f = forecastHarvest(inputs);
      harvestOf[reply] = f;
      status = '';
      notifyListeners();
      String n(int v) => v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
      await _stream(
        reply,
        strings.harvestSummary(n(f.kgLow), n(f.kgHigh), strings.monthsLong[f.readyFrom.month - 1],
            strings.monthsLong[f.readyTo.month - 1]),
      );
    }
    busy = false;
    status = '';
    notifyListeners();
    return true;
  }

  @override
  Future<void> sendPhoto(Uint8List photo, String question) async {
    if (busy) return;
    question = question.trim();
    final reply = ChatTurn('', fromUser: false)
      ..reviewPhoto = photo
      ..reviewNote = question;
    turns
      ..add(ChatTurn(question.isEmpty ? strings.photoDefaultQuestion : question, fromUser: true, image: photo))
      ..add(reply);
    busy = true;
    status = strings.statusCheckingPhoto;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 900));

    // Alternate between a confident and an unsure result so both layouts show up.
    final confident = turns.where((t) => t.diagnosis != null).length.isEven;
    final d = fakeDiagnosis(p: confident ? 0.88 : 0.42);
    reply.diagnosis = d;
    if (confident) {
      await _stream(reply, demoText(strings).rustPhotoAnswer);
      reply
        ..caution = strings.photoCaution
        ..sources = const ['coffee_leaf_rust.md']
        ..match = 0.51;
      // Same rule as the real app: a very confident result is noted in My farm.
      if (photoWorthRemembering(d)) {
        final prefix = photoMemoryPrefix(d);
        data.memoryItems
          ..removeWhere((m) => m.id.startsWith(prefix))
          ..insert(0, MemoryItem('${photoMemoryIdPrefix(d)}${DateTime.now().microsecondsSinceEpoch}',
              photoMemoryText(strings, d, DateTime.now()), DateTime.now()));
        await refreshMemoryCount();
      }
    } else {
      reply
        ..text = strings.photoNotSure(strings.photoNotSureGuess(d.best.label.display, d.best.percent))
        ..notSure = true;
    }
    reply.details = 'preview (no model)';
    busy = false;
    status = '';
    notifyListeners();
  }

  @override
  Future<void> assessWeather(Forecast forecast, List<WeatherAlert> alerts) async {
    if (busy) return;
    final w = strings.weather;
    final reply = ChatTurn('', fromUser: false);
    weatherAdvice = reply;
    weatherAdviceFor = forecast.fetchedAt;
    busy = true;
    weatherBusy = true;
    if (alerts.isEmpty) {
      reply.text = w.noAlertsAnswer;
    } else {
      weatherStatus = w.statusChecking;
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 900));
      weatherStatus = '';
      final text = demoText(strings).weatherAdvice;
      final words = text.split(' ');
      for (var i = 0; i < words.length; i++) {
        reply.text = words.take(i + 1).join(' ');
        notifyListeners();
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }
      reply
        ..sources = const ['soil_types.md', 'coffee_leaf_rust.md']
        ..match = 0.44;
    }
    reply
      ..caution = w.caution
      ..details = '${alerts.map(alertForPrompt).join(' ')} · preview (no model)';
    busy = false;
    weatherBusy = false;
    notifyListeners();
  }

  @override
  Future<void> saveForReview(ChatTurn turn) async {
    final photo = turn.reviewPhoto;
    if (photo == null || turn.queued) return;
    data.queue(turn.reviewNote, turn.diagnosis?.toJson());
    turn.queued = true;
    await refreshOutbox();
  }

  @override
  Future<void> refreshOutbox({bool flush = false}) async {
    outboxCount = data.outboxItems.where((i) => !i.sent).length;
    notifyListeners();
  }

  @override
  Future<void> refreshMemoryCount() async {
    memoryCount = data.memoryItems.length;
    notifyListeners();
  }
}

/// In-memory My farm and Officer data. Changes last until the page reloads.
/// [language] is the app's current language: the demo facts are shown in it.
class PreviewFarmData extends FarmData {
  PreviewFarmData({AppLanguage Function()? language}) : _language = language ?? (() => AppLanguage.en) {
    queue(demoText(S.forLanguage(_language())).officerNote, fakeDiagnosis(p: 0.85).toJson());
    queue('', fakeDiagnosis(p: 0.4).toJson(), sent: true);
  }

  final AppLanguage Function() _language;

  /// What the farm "remembers". The demo facts are kept in English here (the
  /// harvest demo reads them) and shown in the app's language by [memories].
  final memoryItems = fakeMemories();
  final outboxItems = <OutboxItem>[];

  void queue(String note, Map<String, dynamic>? guess, {bool sent = false}) {
    final id = 'p${outboxItems.length}';
    final now = DateTime.now();
    outboxItems.insert(
      0,
      OutboxItem(
        id: id,
        created: now,
        note: note,
        modelGuess: guess,
        photo: File('preview/$id.jpg'), // never read: the preview has no files
        sentAt: sent ? now : null,
      ),
    );
  }

  @override
  Future<List<MemoryItem>> memories() async {
    final demo = {for (final m in fakeMemories(_language())) m.id: m};
    return [for (final m in memoryItems) demo[m.id] ?? m];
  }

  @override
  Future<void> forget(String id) async => memoryItems.removeWhere((m) => m.id == id);

  @override
  Future<void> remember(String fact) async =>
      memoryItems.insert(0, MemoryItem('mem:${DateTime.now().microsecondsSinceEpoch}', fact.trim(), DateTime.now()));

  @override
  Future<List<OutboxItem>> outbox() async => List.of(outboxItems);

  @override
  Future<SendReport> sendPending() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    final waiting = outboxItems.where((i) => !i.sent).length;
    return SendReport(sent: 0, waiting: waiting, noServer: true);
  }

  @override
  Future<void> removeFromOutbox(OutboxItem item) async => outboxItems.remove(item);
}
