import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../services/leaf_classifier.dart';

/// Shows what the on-device photo check saw: a verdict, the top guesses as
/// bars, and the "needs X% to give advice" line so the farmer can see *why*
/// the app did or did not name a disease.
class DiagnosisCard extends StatelessWidget {
  const DiagnosisCard({super.key, required this.diagnosis});
  final Diagnosis diagnosis;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final d = diagnosis;
    final healthy = d.confident && d.best.label.isHealthy;

    final (IconData icon, Color color, String verdict) = !d.confident
        ? (Icons.help_outline, c.tertiary, s.diagNotSure)
        : healthy
            ? (Icons.check_circle_outline, c.primary, s.diagHealthy)
            : (Icons.warning_amber_rounded, c.error, s.diagLikely);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(verdict, style: t.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
                  if (d.confident)
                    Text(d.best.label.display, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 10),
          for (final g in d.top)
            _GuessBar(guess: g, threshold: d.threshold, highlight: identical(g, d.best) && d.confident, color: color),
          const SizedBox(height: 4),
          Text(
            s.diagThreshold('${(d.threshold * 100).round()}%'),
            style: t.labelSmall?.copyWith(color: c.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _GuessBar extends StatelessWidget {
  const _GuessBar({required this.guess, required this.threshold, required this.highlight, required this.color});
  final Guess guess;
  final double threshold;
  final bool highlight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                guess.label.display,
                style: t.bodySmall?.copyWith(fontWeight: highlight ? FontWeight.w700 : null),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(guess.percent, style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 4),
          SizedBox(
            height: 8,
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: guess.probability.clamp(0.0, 1.0),
                        color: highlight ? color : c.outline,
                        backgroundColor: c.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  // The confidence the app needs before it names a condition.
                  Positioned(
                    left: (box.maxWidth * threshold).clamp(0.0, box.maxWidth - 2),
                    top: -3,
                    bottom: -3,
                    child: Container(width: 2, color: c.onSurface),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
