import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_settings.dart';
import '../../core/config.dart';
import '../../services/assistant.dart';
import '../../services/leaf_classifier.dart'
    if (dart.library.js_interop) '../../services/leaf_classifier_stub.dart';
import '../widgets/composer.dart';
import '../widgets/language_picker.dart';
import '../widgets/message_bubble.dart';
import '../widgets/potato_mascot.dart';

/// The "Ask" tab, laid out like a chat with Claude: a new chat shows the potato
/// and a greeting; once the farmer sends something it gives way to the conversation.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.assistant});
  final Assistant assistant;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  Assistant get _a => widget.assistant;

  @override
  void initState() {
    super.initState();
    _a.addListener(_toBottom);
  }

  @override
  void dispose() {
    _a.removeListener(_toBottom);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });

  void _send([String? text]) {
    final q = (text ?? _input.text).trim();
    if (q.isEmpty || !_a.canSend) return;
    _input.clear();
    FocusScope.of(context).unfocus();
    _a.send(q);
  }

  Future<void> _pickPhoto() async {
    final s = context.s;
    if (!_a.hasPhotoCheck) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${s.photoNotInstalled}\n(${LeafClassifier.loadError})'),
      ));
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Row(children: [
              Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 12),
              Expanded(child: Text(s.photoTip)),
            ]),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(s.photoTake),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(s.photoGallery),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (source == null) return;
    // The picker downsizes natively, so decoding on the phone stays fast.
    final file = await ImagePicker().pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final note = _input.text;
    _input.clear();
    if (mounted) FocusScope.of(context).unfocus();
    await _a.sendPhoto(bytes, note);
  }

  /// Human in the loop: the farmer decides (with consent) to send the photo for review.
  Future<void> _confirmReview(ChatTurn turn) async {
    final s = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.support_agent_outlined),
        title: Text(s.consentTitle),
        content: Text(s.consentBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s.save)),
        ],
      ),
    );
    if (ok == true) await _a.saveForReview(turn);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListenableBuilder(
      listenable: _a,
      builder: (context, _) {
        final welcome = _a.ready && _a.turns.isEmpty;
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            leading: const LanguageMenuButton(),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.appName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                _OfflineBadge(label: '${s.offlineBadge} · ${activeLlm.label}'),
              ],
            ),
            actions: [
              IconButton(
                tooltip: s.newChat,
                onPressed: _a.busy || _a.turns.isEmpty ? null : _a.clearConversation,
                icon: const Icon(Icons.edit_square),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(child: _body(context)),
              if (welcome) _Suggestions(onAsk: _send),
              Composer(
                controller: _input,
                enabled: _a.canSend,
                onSend: _send,
                onPhoto: _pickPhoto,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context) {
    final s = context.s;
    switch (_a.state) {
      case AssistantState.loading:
        return _Centered(
          icon: Icons.eco,
          title: s.loadingModel,
          child: const Padding(padding: EdgeInsets.only(top: 16), child: CircularProgressIndicator()),
        );
      case AssistantState.failed:
        return _Centered(
          icon: Icons.error_outline,
          title: s.loadFailed,
          body: '${_a.error}',
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: FilledButton.icon(onPressed: _a.load, icon: const Icon(Icons.refresh), label: Text(s.retry)),
          ),
        );
      case AssistantState.ready:
        if (_a.turns.isEmpty) return const _Welcome();
        final turns = _a.turns;
        return ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          itemCount: turns.length,
          itemBuilder: (context, i) {
            final t = turns[i];
            final last = i == turns.length - 1;
            final streaming = _a.busy && last;
            return MessageBubble(
              turn: t,
              streaming: streaming,
              status: streaming ? _a.status : '',
              onSendForReview: t.reviewPhoto != null && !t.queued && !streaming ? () => _confirmReview(t) : null,
            );
          },
        );
    }
  }
}

/// New chat: the potato and a greeting in the middle of the screen.
class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const PotatoMascot(size: 150),
          const SizedBox(height: 20),
          Text(s.welcomeTitle,
              textAlign: TextAlign.center, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w500, height: 1.25)),
          const SizedBox(height: 10),
          Text(s.welcomeBody, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

/// Tap-to-ask questions in a row just above the input, only on a new chat.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onAsk});
  final void Function(String) onAsk;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final suggestions = context.s.suggestions;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ActionChip(
          label: Text(suggestions[i]),
          onPressed: () => onAsk(suggestions[i]),
          backgroundColor: c.surfaceContainerLow,
          side: BorderSide(color: c.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.cloud_off_outlined, size: 13, color: c.primary),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.primary),
        ),
      ),
    ]);
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.icon, required this.title, this.body, this.child});
  final IconData icon;
  final String title;
  final String? body;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: t.titleMedium),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(body!, textAlign: TextAlign.center, style: t.bodySmall),
          ],
          ?child,
        ]),
      ),
    );
  }
}
