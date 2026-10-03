import 'package:flutter/material.dart';

import '../../core/app_settings.dart';

/// The rounded input card at the bottom of the chat: text on top, the leaf
/// photo button and a round send arrow underneath.
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceContainerLow,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: c.outlineVariant),
          boxShadow: [BoxShadow(color: c.shadow.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.fromLTRB(6, 2, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: s.inputHint,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
              ),
            ),
            Row(
              children: [
                IconButton.outlined(
                  tooltip: s.checkLeaf,
                  onPressed: enabled ? onPhoto : null,
                  style: IconButton.styleFrom(side: BorderSide(color: c.outlineVariant)),
                  icon: const Icon(Icons.photo_camera_outlined),
                ),
                const Spacer(),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) => IconButton.filled(
                    tooltip: s.send,
                    onPressed: enabled && value.text.trim().isNotEmpty ? onSend : null,
                    style: IconButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: c.onPrimary,
                      disabledBackgroundColor: c.onSurface.withValues(alpha: 0.1),
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
