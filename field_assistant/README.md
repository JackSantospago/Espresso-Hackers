# Field Assistant (Flutter) — on-device LLM + RAG + memory, Android & iOS

Everything runs on the phone after a one-time model download:
- LLM: Qwen3 0.6B (.litertlm, ~0.6 GB) via Google LiteRT-LM — switch to Gemma 4 E2B in `lib/config.dart`
- Embeddings: EmbeddingGemma 300M (multilingual, gated) or Gecko 110M (English, ungated, used when no HF token)
- Vector store: sqlite-vec on device — holds knowledge passages AND memories (`kind` = doc | memory)
- Library: flutter_edge_ai (the renamed flutter_gemma), MIT. Platform folders taken from its RAG codelab.

## Run it (≈15 min + download)
1. `flutter --version` must be ≥ 3.47 (`flutter upgrade` otherwise).
2. Optional but recommended (multilingual embeddings): log in to huggingface.co, open
   https://huggingface.co/litert-community/embeddinggemma-300m and accept the licence,
   then create a read token (Settings → Access Tokens).
3. `cd field_assistant && flutter pub get`
4. iPhone: `open ios/Runner.xcworkspace` → Runner target → Signing & Capabilities → pick your Team.
   If signing complains about "Extended Virtual Addressing" / "Increased Memory Limit" (free personal team),
   delete those keys from `ios/Runner/Runner.entitlements` (fine for Qwen3 0.6B).
   iPhone needs Developer Mode on (Settings → Privacy & Security).
5. Plug in the phone, then:
   `flutter run --release --dart-define=HF_TOKEN=hf_xxx`   (omit the define to use Gecko)
6. Tap "Download & set up" once (needs internet). After that, turn on airplane mode — it still works.
7. Android: same command with an Android phone (USB debugging on). Requires Android 11+ (API 30), arm64.

## Where things are
- `lib/config.dart`  model choices, confidence threshold
- `lib/brain.dart`   chunking/indexing of `assets/knowledge/*.md|txt`, retrieval, memory upsert/forget
- `lib/chat_page.dart` prompt, grounded answer + "not sure — ask a person" fail-safe, memory extraction, memory screen
- `assets/knowledge/` drop your sourced documents here (blank-line-separated paragraphs become passages)

## Offline / side-loading story
`installModel(...).fromFile(path)` / `.fromAsset(path)` install from a file copied by SD card, Bluetooth or a
co-op laptop instead of the network — swap `.fromNetwork(...)` in `lib/main.dart`.
