import 'package:flutter/material.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';

import 'brain.dart';
import 'config.dart';

const kNotSure = "I'm not sure. Please ask your extension officer or cooperative.";

class _Turn {
  _Turn(this.text, {required this.fromUser, this.footnote = ''});
  String text;
  final bool fromUser;
  String footnote;
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
  bool _busy = false;
  String _status = 'Loading model…';
  int _memoryCount = 0;

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
      if (!mounted) return;
      setState(() {
        _model = model;
        _chat = chat;
        _memoryCount = mems.length;
        _status = '';
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'Model failed to load: $e');
    }
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

  Future<void> _send() async {
    final question = _input.text.trim();
    if (_chat == null || question.isEmpty || _busy) return;
    final history = _turns.reversed
        .take(4)
        .toList()
        .reversed
        .map((t) => '${t.fromUser ? 'Farmer' : 'Assistant'}: ${_clip(t.text, 300)}')
        .join('\n');
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
${mems.isEmpty ? '(none yet)' : mems.map((m) => '- $m').join('\n')}

CONTEXT:
${hits.isEmpty ? '(nothing found)' : hits.map((h) => '[${h.source}] ${h.text}').join('\n---\n')}

RECENT CONVERSATION:
${history.isEmpty ? '(start)' : history}

QUESTION: $question''';

      // 2. Generate (streamed into the bubble)
      final answer = await _generate(prompt, onPartial: (t) {
        if (mounted) setState(() => reply.text = t);
        _toBottom();
      });

      // 3. Fail-safe: weak retrieval => tell the farmer to check with a person
      final sources = hits.map((h) => h.source).toSet().join(', ');
      setState(() {
        reply.text = confident || answer.contains("not sure")
            ? answer
            : '$answer\n\nNote: weak match in my knowledge. Please check this with a person.';
        reply.footnote = 'Sources: ${sources.isEmpty ? '–' : sources} · match ${top.toStringAsFixed(2)}';
        _status = 'Updating memory…';
      });

      // 4. Memory: extract durable facts the FARMER stated (never the model's own claims)
      await _updateMemory(question);
    } catch (e) {
      if (mounted) setState(() => reply.text = '$kNotSure\n(error: $e)');
    } finally {
      if (mounted) setState(() {
        _busy = false;
        _status = '';
      });
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
    final count = (await Brain.memories()).length;
    if (mounted) setState(() => _memoryCount = count);
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
              itemBuilder: (context, i) => _Bubble(turn: _turns[i]),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    enabled: ready && !_busy,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Ask about your coffee…',
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
  const _Bubble({required this.turn});
  final _Turn turn;
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
            child: SelectableText(turn.text.isEmpty ? '…' : turn.text),
          ),
          if (turn.footnote.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Text(turn.footnote, style: Theme.of(context).textTheme.labelSmall),
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
