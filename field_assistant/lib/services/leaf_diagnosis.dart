/// What the leaf photo check found. Plain Dart, no plugins: shared by the
/// on-device classifier and its web stub.
library;

import '../core/strings.dart';

class LeafLabel {
  const LeafLabel(this.id, this.crop, this.condition);
  final String id, crop, condition;

  bool get isHealthy => id.endsWith('__healthy');
  String get display => crop.isEmpty ? condition : '$crop – $condition';

  /// [display] in the farmer's language: "Kahawa – kutu ya majani".
  String localized(S s) => s.leafLabel(id, crop, condition);
}

class Guess {
  const Guess(this.label, this.probability);
  final LeafLabel label;
  final double probability;

  String get percent => '${(probability * 100).round()}%';
  @override
  String toString() => '${label.display} $percent';
}

class Diagnosis {
  const Diagnosis({
    required this.top,
    required this.threshold,
    required this.otherId,
    required this.millis,
  });

  /// Best guesses, most likely first (at most 3).
  final List<Guess> top;
  final double threshold;
  final String otherId;
  final int millis;

  Guess get best => top.first;
  bool get isOther => best.label.id == otherId;

  /// The fail-safe: name a condition only when the calibrated probability
  /// clears the threshold chosen in the notebook AND it is one of our crops.
  bool get confident => !isOther && best.probability >= threshold;

  Map<String, dynamic> toJson() => {
        'label': best.label.id,
        'probability': double.parse(best.probability.toStringAsFixed(3)),
        'confident': confident,
        'top': [
          for (final g in top) {'label': g.label.id, 'probability': double.parse(g.probability.toStringAsFixed(3))},
        ],
      };
}
