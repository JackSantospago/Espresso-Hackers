import 'package:flutter/material.dart';

import '../../core/app_settings.dart';

/// Camera button + text field + send button, pinned to the bottom of the chat.
class Composer extends StatelessWidget {
  const Composer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSend,
    required this.onPhoto,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    return Material(
      color: c.surface,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton.filledTonal(
                tooltip: s.checkLeaf,
                iconSize: 26,
                padding: const EdgeInsets.all(12),
                onPressed: enabled ? onPhoto : null,
                icon: const Icon(Icons.photo_camera_outlined),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(hintText: s.inputHint),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) => IconButton.filled(
                  tooltip: s.send,
                  iconSize: 24,
                  padding: const EdgeInsets.all(12),
                  onPressed: enabled && value.text.trim().isNotEmpty ? onSend : null,
                  icon: const Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
