import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../services/assistant.dart';
import '../services/brain.dart';
import '../services/outbox.dart';
import '../frontend/shared/farm_data.dart';
import 'fake_data.dart';

/// Start on a new chat (the potato), or with a conversation that shows every
/// kind of message: --dart-define=PREVIEW_CHAT=demo
const _demoChat = String.fromEnvironment('PREVIEW_CHAT') == 'demo';

/// An [Assistant] with no models: canned answers stream in word by word, so
/// every UI state (searching, streaming, not sure, photo check) can be tried.
class PreviewAssistant extends Assistant {
  PreviewAssistant(super.strings, this.data) {
    state = AssistantState.ready;
    knowledgePassages = 5;
    if (_demoChat) turns.addAll(fakeConversation(strings));
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
    final reply = ChatTurn('', fromUser: false);
    turns
      ..add(ChatTurn(question, fromUser: true))
      ..add(reply);
    busy = true;
    // Questions mentioning "price" get the "not sure" path, everything else a grounded answer.
    final notSure = question.toLowerCase().contains('price');
    await _stream(
      reply,
      notSure
          ? strings.notSure
          : 'Prune old stems in rotation and keep the shade light so air moves between the trees. '
              'Remove berries that fall to the ground after harvest. Check with your extension officer before spraying.',
    );
    final match = notSure ? 0.08 : 0.35 + _rng.nextDouble() * 0.3;
    reply
      ..notSure = notSure
      ..warning = notSure ? strings.weakMatch : ''
      ..sources = notSure ? const [] : const ['coffee_sample.md']
      ..match = match
      ..details = 'match ${match.toStringAsFixed(2)} · preview (no model)';
    busy = false;
    notifyListeners();
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
      await _stream(reply, 'Leaf rust shows yellow-orange powder under the leaf. Prune for airflow and keep trees well fed.');
      reply
        ..caution = strings.photoCaution
        ..sources = const ['coffee_sample.md']
        ..match = 0.51;
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
class PreviewFarmData extends FarmData {
  PreviewFarmData() {
    queue('Spots on the upper plot, older trees', fakeDiagnosis(p: 0.85).toJson());
    queue('', fakeDiagnosis(p: 0.4).toJson(), sent: true);
  }

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
  Future<List<MemoryItem>> memories() async => List.of(memoryItems);

  @override
  Future<void> forget(String id) async => memoryItems.removeWhere((m) => m.id == id);

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
