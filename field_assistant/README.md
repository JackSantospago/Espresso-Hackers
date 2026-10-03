# Field Assistant (Flutter) — on-device LLM + RAG + memory, Android & iOS

Everything runs on the phone after a one-time model download:
- LLM: Qwen3 0.6B (.litertlm, ~0.6 GB) via Google LiteRT-LM — switch to Gemma 4 E2B in `lib/config.dart`
- Embeddings: EmbeddingGemma 300M (multilingual, gated) or Gecko 110M (English, ungated, used when no HF token)
- Vector store: sqlite-vec on device — holds knowledge passages AND memories (`kind` = doc | memory)
- Library: flutter_edge_ai (the renamed flutter_gemma), MIT. Platform folders taken from its RAG codelab.
- Leaf photo check: MobileNetV3 classifier (~4 MB TFLite, `tflite_flutter`) for coffee / bean / maize leaves + `other`.
  The LLM only explains a result when the classifier is confident; otherwise "not sure" + send-to-officer outbox.

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

## Leaf photo check
1. Train: open `../training/leaf_classifier.ipynb` in Colab (T4 GPU) → Run all (~30–45 min).
2. Unzip the download; copy `leaf_classifier.tflite` + `leaf_classifier.json` into `assets/models/`.
3. `flutter pub get && flutter run --release`. The camera button sits left of the text field.
   iOS release/archive builds: if you hit "symbol not found" from TensorFlowLite, set
   Runner → Build Settings → Strip Style to **Non-Global Symbols** (tflite_flutter README).

Flow: photo → on-device classifier (background isolate) → temperature-scaled probability
- below the threshold from the json, or label `other` → fixed "I can't tell" + photo tips, no LLM
- healthy → fixed answer (no LLM)
- confident disease → RAG lookup for that condition + LLM explanation, always "confirm with your extension officer"
Every photo answer has "Send to extension officer": consent dialog → photo shrunk to ~60 KB and saved in an outbox,
uploaded when there is signal (`--dart-define=OUTBOX_URL=https://…`, multipart POST: photo, note, model_guess).
No URL set = photos stay on the phone (demo). The outbox screen (tray icon) lists, sends or deletes them.

Files: `lib/leaf_classifier.dart` (model + preprocessing), `lib/outbox.dart` (store-and-forward + screen),
photo flow in `lib/chat_page.dart`. Disease explanations need sourced passages in `assets/knowledge/`
(one per condition the model knows) — without them the LLM correctly answers "not sure".
