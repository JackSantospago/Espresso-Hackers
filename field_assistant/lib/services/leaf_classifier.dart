import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'leaf_diagnosis.dart';

// The result types live in leaf_diagnosis.dart (no plugins) so code that only
// shows results can also build for the web; see leaf_classifier_stub.dart.
export 'leaf_diagnosis.dart';

/// Both files come out of `training/leaf_classifier.ipynb`.
const kLeafModelAsset = 'assets/models/leaf_classifier.tflite';
const kLeafMetaAsset = 'assets/models/leaf_classifier.json';

/// On-device leaf classifier (MobileNetV3, ~4 MB TFLite). Fully offline.
///
/// The model outputs logits; probabilities are `softmax(logits / temperature)`
/// with the temperature and threshold written by the training notebook into
/// `leaf_classifier.json`, so retraining never needs a code change.
class LeafClassifier {
  LeafClassifier._(this._interpreter, this.labels, this.inputSize, this.temperature, this.threshold, this.otherId);

  final Interpreter _interpreter;
  final List<LeafLabel> labels;
  final int inputSize;
  final double temperature, threshold;
  final String otherId;

  static LeafClassifier? _instance;

  /// Why the model is unavailable (usually: files not copied into assets/models yet).
  static Object? loadError;

  /// Returns null (and sets [loadError]) when the model files are missing or broken,
  /// so the rest of the app keeps working without the photo feature.
  static Future<LeafClassifier?> load() async {
    if (_instance != null) return _instance;
    try {
      final meta = jsonDecode(await rootBundle.loadString(kLeafMetaAsset)) as Map<String, dynamic>;
      final labels = [
        for (final l in meta['labels'] as List)
          LeafLabel(l['id'] as String, l['crop'] as String, l['condition'] as String),
      ];
      final size = meta['input_size'] as int;

      final interpreter = await Interpreter.fromAsset(kLeafModelAsset, options: InterpreterOptions()..threads = 2);
      interpreter.allocateTensors();
      final inShape = interpreter.getInputTensor(0).shape;
      final outShape = interpreter.getOutputTensor(0).shape;
      if (inShape.join(',') != '1,$size,$size,3' || outShape.join(',') != '1,${labels.length}') {
        interpreter.close();
        throw StateError('Model shapes $inShape → $outShape do not match leaf_classifier.json');
      }
      loadError = null;
      return _instance = LeafClassifier._(
        interpreter,
        labels,
        size,
        (meta['temperature'] as num).toDouble(),
        (meta['threshold'] as num).toDouble(),
        meta['other_label'] as String? ?? 'other',
      );
    } catch (e) {
      loadError = e;
      return null;
    }
  }

  /// Classifies one photo (JPEG/PNG bytes). Decoding, resizing and inference
  /// run on a background isolate so the UI does not freeze. Not re-entrant:
  /// the caller must wait for one call to finish before starting the next.
  Future<Diagnosis> classify(Uint8List photo) async {
    final sw = Stopwatch()..start();
    final logits = await _inferInBackground(photo, _interpreter.address, inputSize, labels.length);

    // Temperature-scaled softmax.
    final scaled = [for (final z in logits) z / temperature];
    final maxZ = scaled.reduce(math.max);
    final exps = [for (final z in scaled) math.exp(z - maxZ)];
    final sum = exps.fold<double>(0, (a, b) => a + b);
    final guesses = [for (var i = 0; i < labels.length; i++) Guess(labels[i], exps[i] / sum)]
      ..sort((a, b) => b.probability.compareTo(a.probability));

    return Diagnosis(
      top: guesses.take(3).toList(),
      threshold: threshold,
      otherId: otherId,
      millis: sw.elapsedMilliseconds,
    );
  }

  // Static so the isolate closure captures only these sendable values.
  static Future<Float32List> _inferInBackground(Uint8List photo, int address, int size, int classes) =>
      Isolate.run(() {
        final input = preprocess(photo, size);
        final output = Float32List(classes);
        Interpreter.fromAddress(address, allocated: true).run(input.buffer, output.buffer);
        return output;
      });

  /// Same preprocessing as the notebook (`app_like`): EXIF orientation →
  /// center square crop → resize → RGB floats 0..255, NHWC.
  /// (MobileNetV3 in Keras normalises inside the model.)
  static Float32List preprocess(Uint8List photo, int size) {
    final decoded = img.decodeImage(photo);
    if (decoded == null) throw const FormatException('Could not read this photo.');
    final square = img.copyResizeCropSquare(
      img.bakeOrientation(decoded),
      size: size,
      interpolation: img.Interpolation.average,
    );
    final out = Float32List(size * size * 3);
    var i = 0;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final p = square.getPixel(x, y);
        out[i++] = (p.rNormalized * 255).toDouble();
        out[i++] = (p.gNormalized * 255).toDouble();
        out[i++] = (p.bNormalized * 255).toDouble();
      }
    }
    return out;
  }
}
