import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:image_picker/image_picker.dart';

import 'brain.dart';
import 'config.dart';
import 'leaf_classifier.dart';
import 'outbox.dart';

const kNotSure = "I'm not sure. Please ask your extension officer or cooperative.";

class _Turn {
  _Turn(this.text, {required this.fromUser, this.footnote = '', this.image});
  String text;
  final bool fromUser;
  String footnote;

  /// Photo shown in a farmer's bubble.
  final Uint8List? image;

  /// Set on assistant replies to a photo: lets the farmer send it for human review.
  Uint8List? reviewPhoto;
  String reviewNote = '';
  Diagnosis? diagnosis;
  bool queued = false;
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _turns = <_Turn>[];
  InferenceModel? _model;
  InferenceChat? _chat;
  LeafClassifier? _classifier;
  bool _busy = false;
  String _status = 'Loading model…';
  int _memoryCount = 0;
  int _outboxCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
      await Brain.indexKnowledge(); // no-op unless assets/knowledge changed
      final mems = await Brain.memories();
      final classifier = await LeafClassifier.load(); // null if the model files are not bundled
      if (!mounted) return;
      setState(() {
        _model = model;
        _chat = chat;
        _classifier = classifier;
        _memoryCount = mems.length;
        _status = '';
      });
      _flushOutbox(); // store-and-forward: try queued photos whenever the app starts
    } catch (e) {
      if (mounted) setState(() => _status = 'Model failed to load: $e');
    }
  }

  Future<void> _flushOutbox() async {
    if (await Outbox.pendingCount() > 0) await Outbox.sendPending();
    final n = await Outbox.pendingCount();
    if (mounted) setState(() => _outboxCount = n);
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

  String _recentHistory() => _turns.reversed
      .take(4)
      .toList()
      .reversed
      .map((t) => '${t.fromUser ? 'Farmer' : 'Assistant'}: ${_clip(t.text, 300)}')
      .join('\n');

  Future<void> _send() async {
    final question = _input.text.trim();
    if (_chat == null || question.isEmpty || _busy) return;
    final history = _recentHistory();
    final reply = _Turn('', fromUser: false);
    setState(() {
      _turns
        ..add(_Turn(question, fromUser: true))
        ..add(reply);
      _input.clear();
      _busy = true;
    });

    try {
      // 1. Retrieve from knowledge + memory
      final hits = await Brain.searchKnowledge(question);
      final mems = await Brain.relevantMemories(question);
      final top = hits.isEmpty ? 0.0 : hits.first.score;
      final confident = top >= kConfidenceThreshold;

      final prompt = '''
You are an offline farming assistant for smallholder coffee farmers.
Rules: Answer ONLY from CONTEXT and MEMORY below. Max 5 short sentences, plain words.
If CONTEXT does not contain the answer, reply exactly: "$kNotSure"
Never invent prices, numbers or chemical doses. The farmer makes the final decision.
Reply in the same language as the QUESTION.

MEMORY (facts about this farmer):
${_bullets(mems)}

CONTEXT:
${_context(hits)}

RECENT CONVERSATION:
${history.isEmpty ? '(start)' : history}

QUESTION: $question''';

      // 2. Generate (streamed into the bubble)
      final answer = await _generate(prompt, onPartial: (t) {
        if (mounted) setState(() => reply.text = t);
        _toBottom();
      });

      // 3. Fail-safe: weak retrieval => tell the farmer to check with a person
      setState(() {
        reply.text = confident || answer.contains("not sure")
            ? answer
            : '$answer\n\nNote: weak match in my knowledge. Please check this with a person.';
        reply.footnote = 'Sources: ${_sources(hits)} · match ${top.toStringAsFixed(2)}';
        _status = 'Updating memory…';
      });

      // 4. Memory: extract durable facts the FARMER stated (never the model's own claims)
      await _updateMemory(question);
    } catch (e) {
      if (mounted) setState(() => reply.text = '$kNotSure\n(error: $e)');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = '';
        });
      }
    }
  }

  // ------------------------------------------------------------- photo check

  Future<void> _pickPhoto() async {
    if (_classifier == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Photo check is not installed. Copy leaf_classifier.tflite and leaf_classifier.json '
          'from training/ into assets/models/ and rebuild.\n(${LeafClassifier.loadError})',
        ),
      ));
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo of one leaf'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;
    // The picker downsizes natively, so decoding on the phone stays fast.
    final file = await ImagePicker().pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (file == null) return;
    await _sendPhoto(await file.readAsBytes());
  }

  Future<void> _sendPhoto(Uint8List photo) async {
    if (_chat == null || _busy) return;
    final question = _input.text.trim();
    final reply = _Turn('', fromUser: false)
      ..reviewPhoto = photo
      ..reviewNote = question;
    setState(() {
      _turns
        ..add(_Turn(question.isEmpty ? 'What is wrong with this leaf?' : question, fromUser: true, image: photo))
        ..add(reply);
      _input.clear();
      _busy = true;
      _status = 'Checking the photo…';
    });
    _toBottom();

    try {
      // 1. On-device classifier
      final d = await _classifier!.classify(photo);
      reply.diagnosis = d;
      final photoNote = 'Photo check: ${d.top.join(', ')} · needs ${(d.threshold * 100).round()}% · ${d.millis} ms';

      // 2. Fail-safe: not confident, or not one of our crops → no diagnosis, no LLM.
      if (!d.confident) {
        setState(() {
          reply.text = _notSurePhoto(d);
          reply.footnote = photoNote;
        });
        return;
      }

      final label = d.best.label;

      // 3. Healthy → fixed answer (nothing for the LLM to explain).
      if (label.isHealthy) {
        setState(() {
          reply.text = 'This ${label.crop.toLowerCase()} leaf looks healthy (${d.best.percent} sure). '
              'If other leaves, berries or stems look different, take a photo of those too. '
              'Many causes of a smaller harvest (soil, rain, tree age) do not show on leaves — '
              'your extension officer can help find them.';
          reply.footnote = photoNote;
        });
        return;
      }

      // 4. Confident disease → explain it from the knowledge base, in the farmer's language.
      setState(() => _status = 'Looking up ${label.condition}…');
      final query = '${label.crop} ${label.condition} symptoms management $question';
      final hits = await Brain.searchKnowledge(query);
      final mems = await Brain.relevantMemories(query);
      final asked = question.isEmpty ? 'What is wrong with my ${label.crop.toLowerCase()} leaf and what can I do?' : question;

      final prompt = '''
You are an offline farming assistant for smallholder farmers.
A photo check on this phone looked at the farmer's leaf and suggests: ${label.display} (${d.best.percent} sure). It can be wrong.
Rules: Use ONLY the CONTEXT and MEMORY below. Max 5 short sentences, plain words.
First say how ${label.condition} usually looks, so the farmer can compare it with her leaf. Then say what she can do.
If CONTEXT says nothing about ${label.condition}, reply exactly: "$kNotSure"
Never invent prices, numbers or chemical doses. The farmer makes the final decision.
Reply in the same language as the QUESTION.

MEMORY (facts about this farmer):
${_bullets(mems)}

CONTEXT:
${_context(hits)}

QUESTION: $asked''';

      setState(() => _status = '');
      final answer = await _generate(prompt, onPartial: (t) {
        if (mounted) setState(() => reply.text = '${label.display}? (${d.best.percent} sure)\n\n$t');
        _toBottom();
      });

      setState(() {
        reply.text = '${label.display}? (${d.best.percent} sure)\n\n$answer\n\n'
            'This is a machine guess from one photo. Check other leaves, and confirm with your '
            'extension officer before buying or spraying anything.';
        reply.footnote = '$photoNote\nSources: ${_sources(hits)}';
      });

      // Only what the farmer typed goes to memory — never the classifier's guess.
      if (question.isNotEmpty) {
        setState(() => _status = 'Updating memory…');
        await _updateMemory(question);
      }
    } catch (e) {
      if (mounted) setState(() => reply.text = '$kNotSure\n(photo error: $e)');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = '';
        });
      }
      _toBottom();
    }
  }

  String _notSurePhoto(Diagnosis d) {
    final guess = d.isOther
        ? 'It does not look like a coffee, bean or maize leaf I know.'
        : 'My best guess is ${d.best.label.display}, but I am only ${d.best.percent} sure — '
            'not enough to give advice.';
    return "I can't tell from this photo. $guess\n\n"
        'Tips: photograph ONE leaf in daylight, filling the screen, with the spots in focus. '
        'I know coffee, bean and maize leaves only.\n\n'
        'You can save the photo for your extension officer — it is sent when the phone has signal.';
  }

  /// Human in the loop: the farmer decides (with consent) to send the photo for review.
  Future<void> _queueForReview(_Turn turn) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send to extension officer?'),
        content: const Text(
          'The photo is saved on this phone and sent the next time there is signal.\n\n'
          'What is sent: the leaf photo (about 60 KB), your question, and the app\'s guess. '
          'No name and no location. You can delete it before it is sent.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || turn.reviewPhoto == null) return;
    await Outbox.add(photo: turn.reviewPhoto!, note: turn.reviewNote, diagnosis: turn.diagnosis);
    if (!mounted) return;
    setState(() => turn.queued = true);
    await _flushOutbox();
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
    final count = (await Brain.memories()).length;
    if (mounted) setState(() => _memoryCount = count);
  }

  // ----------------------------------------------------------------- helpers

  String _bullets(List<String> mems) => mems.isEmpty ? '(none yet)' : mems.map((m) => '- $m').join('\n');
  String _context(List<Hit> hits) =>
      hits.isEmpty ? '(nothing found)' : hits.map((h) => '[${h.source}] ${h.text}').join('\n---\n');
  String _sources(List<Hit> hits) {
    final s = hits.map((h) => h.source).toSet().join(', ');
    return s.isEmpty ? '–' : s;
  }

  String _clip(String s, int n) => s.length <= n ? s : '${s.substring(0, n)}…';

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });

  @override
  void dispose() {
    _model?.close().catchError((Object _) {});
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _chat != null;
    return Scaffold(
      appBar: AppBar(
        title: Text('Field Assistant · ${activeLlm.label}'),
        actions: [
          IconButton(
            tooltip: 'Photos for the extension officer',
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const OutboxPage()));
              final n = await Outbox.pendingCount();
              if (mounted) setState(() => _outboxCount = n);
            },
            icon: Badge(
              isLabelVisible: _outboxCount > 0,
              label: Text('$_outboxCount'),
              child: const Icon(Icons.outbox_outlined),
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MemoryPage()));
              final n = (await Brain.memories()).length;
              if (mounted) setState(() => _memoryCount = n);
            },
            icon: const Icon(Icons.psychology_outlined),
            label: Text('$_memoryCount'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                if (_busy || !ready) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Expanded(child: Text(_status, style: Theme.of(context).textTheme.bodySmall)),
              ]),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _turns.length,
              itemBuilder: (context, i) {
                final t = _turns[i];
                return _Bubble(
                  turn: t,
                  onSendForReview: t.reviewPhoto != null && !t.queued && !(_busy && i == _turns.length - 1)
                      ? () => _queueForReview(t)
                      : null,
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(children: [
                IconButton(
                  tooltip: 'Check a leaf photo',
                  onPressed: ready && !_busy ? _pickPhoto : null,
                  icon: const Icon(Icons.add_a_photo_outlined),
                ),
                Expanded(
                  child: TextField(
                    controller: _input,
                    enabled: ready && !_busy,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Ask about your farm…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: ready && !_busy ? _send : null, icon: const Icon(Icons.send)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.turn, this.onSendForReview});
  final _Turn turn;
  final VoidCallback? onSendForReview;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Align(
      alignment: turn.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: turn.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 520),
            decoration: BoxDecoration(
              color: turn.fromUser ? c.primaryContainer : c.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (turn.image != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(turn.image!, height: 180, fit: BoxFit.cover),
                    ),
                  ),
                SelectableText(turn.text.isEmpty ? '…' : turn.text),
              ],
            ),
          ),
          if (turn.footnote.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Text(turn.footnote, style: Theme.of(context).textTheme.labelSmall),
            ),
          if (turn.queued)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text('Saved for your extension officer — sent when there is signal.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.primary)),
            )
          else if (onSendForReview != null)
            TextButton.icon(
              onPressed: onSendForReview,
              icon: const Icon(Icons.support_agent_outlined, size: 18),
              label: const Text('Send to extension officer'),
            ),
        ],
      ),
    );
  }
}

/// Everything the app remembers, visible and deletable by the farmer.
class MemoryPage extends StatefulWidget {
  const MemoryPage({super.key});
  @override
  State<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends State<MemoryPage> {
  List<MemoryItem> _items = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final items = await Brain.memories();
    if (mounted) setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('What I remember')),
        body: _items.isEmpty
            ? const Center(child: Text('Nothing remembered yet.'))
            : ListView(
                children: [
                  for (final m in _items)
                    ListTile(
                      title: Text(m.text),
                      subtitle: Text(m.date.toLocal().toString().substring(0, 16)),
                      trailing: IconButton(
                        tooltip: 'Forget',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await Brain.forget(m.id);
                          await _refresh();
                        },
                      ),
                    ),
                ],
              ),
      );
}
