import 'package:flutter_edge_ai/flutter_edge_ai.dart';

/// Only needed for gated Hugging Face models (EmbeddingGemma, Gemma 3 1B).
///   flutter run --dart-define=HF_TOKEN=hf_xxx
const hfToken = String.fromEnvironment('HF_TOKEN');

/// Retrieval score below which an answer is flagged "check with a person".
/// Watch the `match` number under each answer and tune.
const kConfidenceThreshold = 0.2;

class LlmChoice {
  const LlmChoice({
    required this.label,
    required this.url,
    required this.fileName,
    required this.modelType,
    required this.sizeLabel,
    required this.backend,
  });
  final String label, url, fileName, sizeLabel;
  final ModelType modelType;
  final PreferredBackend backend;
}

abstract final class Llms {
  /// Smallest, ungated, multilingual (100+ languages). Best fit for low-end phones.
  static const qwen3 = LlmChoice(
    label: 'Qwen3 0.6B',
    url: 'https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/Qwen3-0.6B.litertlm',
    fileName: 'Qwen3-0.6B.litertlm',
    modelType: ModelType.qwen3,
    sizeLabel: '0.6 GB',
    backend: PreferredBackend.cpu,
  );

  /// Much better answers, multilingual, ungated — but 2.6 GB and wants 6 GB+ RAM.
  static const gemma4 = LlmChoice(
    label: 'Gemma 4 E2B',
    url: 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
    fileName: 'gemma-4-E2B-it.litertlm',
    modelType: ModelType.gemma4,
    sizeLabel: '2.6 GB',
    backend: PreferredBackend.gpu,
  );
}

/// <<< Change this one line to switch models. >>>
const activeLlm = Llms.gemma4;

class EmbedderChoice {
  const EmbedderChoice({
    required this.label,
    required this.modelUrl,
    required this.tokenizerUrl,
    required this.fileName,
    required this.sizeLabel,
    required this.gated,
  });
  final String label, modelUrl, tokenizerUrl, fileName, sizeLabel;
  final bool gated;
}

abstract final class Embedders {
  /// Multilingual (100+ languages). Gated: accept the licence on Hugging Face
  /// once, then run with --dart-define=HF_TOKEN=...
  static const embeddingGemma = EmbedderChoice(
    label: 'EmbeddingGemma 300M',
    modelUrl: 'https://huggingface.co/litert-community/embeddinggemma-300m/resolve/main/embeddinggemma-300M_seq256_mixed-precision.tflite',
    tokenizerUrl: 'https://huggingface.co/litert-community/embeddinggemma-300m/resolve/main/sentencepiece.model',
    fileName: 'embeddinggemma-300M_seq256_mixed-precision.tflite',
    sizeLabel: '0.2 GB',
    gated: true,
  );

  /// English only, but ungated — use if you have no HF token yet.
  static const gecko = EmbedderChoice(
    label: 'Gecko 110M (English)',
    modelUrl: 'https://huggingface.co/litert-community/Gecko-110m-en/resolve/main/Gecko_256_quant.tflite',
    tokenizerUrl: 'https://huggingface.co/litert-community/Gecko-110m-en/resolve/main/sentencepiece.model',
    fileName: 'Gecko_256_quant.tflite',
    sizeLabel: '0.1 GB',
    gated: false,
  );
}

/// Without a token we fall back to the ungated English embedder.
const activeEmbedder = hfToken == '' ? Embedders.gecko : Embedders.embeddingGemma;
