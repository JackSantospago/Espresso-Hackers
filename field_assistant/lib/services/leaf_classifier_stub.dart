import 'dart:typed_data';

import 'leaf_diagnosis.dart';

export 'leaf_diagnosis.dart';

/// Web stand-in for [LeafClassifier] (tflite_flutter needs dart:ffi, which the
/// web does not have). Picked by conditional imports only on the web, so phone
/// builds always use leaf_classifier.dart. [load] reports "not installed".
class LeafClassifier {
  LeafClassifier._();

  List<LeafLabel> get labels => const [];

  static Object? loadError;

  static Future<LeafClassifier?> load() async {
    loadError = UnsupportedError('The leaf photo check does not run in the browser.');
    return null;
  }

  Future<Diagnosis> classify(Uint8List photo) => throw UnsupportedError('No leaf model in the browser.');
}
