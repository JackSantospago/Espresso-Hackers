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

/// The "Ask" tab: the conversation with the on-device assistant.
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
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.appName),
              _OfflineBadge(label: '${s.offlineBadge} · ${activeLlm.label}'),
            ],
          ),
          actions: [
            const LanguageMenuButton(),
            if (_a.turns.isNotEmpty)
              IconButton(
                tooltip: s.newChat,
                onPressed: _a.busy ? null : _a.clearConversation,
                icon: const Icon(Icons.add_comment_outlined),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: _body(context)),
            if (_a.status.isNotEmpty && _a.ready) _StatusStrip(text: _a.status),
            Composer(
              controller: _input,
              enabled: _a.canSend,
              onSend: _send,
              onPhoto: _pickPhoto,
            ),
          ],
        ),
      ),
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
        if (_a.turns.isEmpty) return _Welcome(onAsk: _send, onPhoto: _pickPhoto);
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
              onSendForReview: t.reviewPhoto != null && !t.queued && !streaming ? () => _confirmReview(t) : null,
            );
          },
        );
    }
  }
}

/// Empty conversation: greeting, a big photo action and tap-to-ask questions,
/// so a first-time user never faces a blank screen.
class _Welcome extends StatelessWidget {
  const _Welcome({required this.onAsk, required this.onPhoto});
  final void Function(String) onAsk;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: c.primaryContainer,
          child: Icon(Icons.eco, size: 40, color: c.onPrimaryContainer),
        ),
        const SizedBox(height: 16),
        Text(s.welcomeTitle, textAlign: TextAlign.center, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(s.welcomeBody, textAlign: TextAlign.center, style: t.bodyLarge?.copyWith(color: c.onSurfaceVariant)),
        const SizedBox(height: 24),
        Card(
          color: c.secondaryContainer,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPhoto,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.photo_camera, size: 32, color: c.onSecondaryContainer),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(s.checkLeaf,
                      style: t.titleMedium?.copyWith(color: c.onSecondaryContainer, fontWeight: FontWeight.w600)),
                ),
                Icon(Icons.chevron_right, color: c.onSecondaryContainer),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final q in s.suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onAsk(q),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    Icon(Icons.chat_bubble_outline, size: 20, color: c.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(q, style: t.bodyLarge)),
                  ]),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(s.answersLanguageNote,
            textAlign: TextAlign.center, style: t.labelMedium?.copyWith(color: c.onSurfaceVariant)),
      ],
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

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: c.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
      ]),
    );
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
