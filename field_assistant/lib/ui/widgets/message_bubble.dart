import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/config.dart';
import '../../services/assistant.dart';
import 'diagnosis_card.dart';

/// One message. Farmer messages sit on the right; assistant replies on the
/// left with their grounding (sources, match strength) and fail-safes
/// (not sure / weak match / photo caution) shown as distinct, visible blocks.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.turn, this.streaming = false, this.onSendForReview});

  final ChatTurn turn;

  /// This reply is still being generated.
  final bool streaming;

  /// Non-null when the farmer can send this photo to the extension officer.
  final VoidCallback? onSendForReview;

  @override
  Widget build(BuildContext context) => turn.fromUser ? _farmer(context) : _assistant(context);

  Widget _farmer(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 10, left: 48),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: c.primaryContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (turn.image != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(turn.image!, height: 200, fit: BoxFit.cover),
                ),
              ),
            SelectableText(
              turn.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: c.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assistant(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: c.secondaryContainer,
            child: Icon(Icons.eco, size: 18, color: c.onSecondaryContainer),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 560),
                  decoration: BoxDecoration(
                    color: c.surfaceContainerHigh,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (turn.diagnosis != null) ...[
                        DiagnosisCard(diagnosis: turn.diagnosis!),
                        const SizedBox(height: 10),
                      ],
                      if (turn.notSure && !streaming) ...[
                        _Tag(icon: Icons.support_agent, text: s.askPerson, color: c.tertiary),
                        const SizedBox(height: 8),
                      ],
                      if (turn.text.isEmpty)
                        const _Typing()
                      else
                        SelectableText(turn.text, style: t.bodyLarge),
                      if (turn.warning.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _Notice(icon: Icons.report_outlined, text: turn.warning, color: c.tertiary),
                      ],
                      if (turn.caution.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _Notice(icon: Icons.verified_user_outlined, text: turn.caution, color: c.secondary),
                      ],
                      if (!streaming && (turn.sources.isNotEmpty || turn.details.isNotEmpty)) ...[
                        const SizedBox(height: 8),
                        _Grounding(turn: turn),
                      ],
                    ],
                  ),
                ),
                if (turn.queued)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.schedule_send_outlined, size: 16, color: c.primary),
                      const SizedBox(width: 6),
                      Flexible(child: Text(s.queuedNote, style: t.labelMedium?.copyWith(color: c.primary))),
                    ]),
                  )
                else if (onSendForReview != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: OutlinedButton.icon(
                      onPressed: onSendForReview,
                      icon: const Icon(Icons.support_agent_outlined, size: 18),
                      label: Text(s.sendToOfficer),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Where the answer came from, how strong the match was, and a "Details"
/// toggle with the raw scores (useful for judges and for tuning thresholds).
class _Grounding extends StatefulWidget {
  const _Grounding({required this.turn});
  final ChatTurn turn;

  @override
  State<_Grounding> createState() => _GroundingState();
}

class _GroundingState extends State<_Grounding> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final turn = widget.turn;
    final match = turn.match;
    final strong = match != null && match >= kConfidenceThreshold;
    final small = t.labelSmall?.copyWith(color: c.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (turn.sources.isNotEmpty) ...[
              Text('${s.sources}:', style: small),
              for (final src in turn.sources)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.menu_book_outlined, size: 12, color: c.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(src, style: small),
                  ]),
                ),
            ],
            if (match != null)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle, size: 8, color: strong ? c.primary : c.tertiary),
                const SizedBox(width: 4),
                Text(strong ? s.matchStrong : s.matchWeak, style: small),
              ]),
            if (turn.details.isNotEmpty)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(s.details, style: small?.copyWith(decoration: TextDecoration.underline)),
                    Icon(_open ? Icons.expand_less : Icons.expand_more, size: 14, color: c.onSurfaceVariant),
                  ]),
                ),
              ),
          ],
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SelectableText(turn.details, style: small),
          ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
          ),
        ]),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ]),
      );
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 10),
        Text(context.s.statusThinking, style: Theme.of(context).textTheme.bodyMedium),
      ]);
}
