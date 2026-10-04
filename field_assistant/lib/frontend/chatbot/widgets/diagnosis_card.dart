import 'package:flutter/material.dart';

import '../../../core/app_settings.dart';
import '../../../services/leaf_diagnosis.dart';

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
            : (Icons.warning_amber_rounded, c.secondary, s.diagLikely);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        border: Border.all(color: c.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(verdict, style: t.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
                  if (d.confident)
                    Text(d.best.label.localized(s), style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
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
                guess.label.localized(context.s),
                style: t.bodySmall?.copyWith(fontWeight: highlight ? FontWeight.w700 : null),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(guess.percent, style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 4),
          SizedBox(
            height: 6,
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
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
                    top: -4,
                    bottom: -4,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(color: c.onSurfaceVariant, borderRadius: BorderRadius.circular(1)),
                    ),
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
