# Field Assistant (Flutter) — on-device LLM + RAG + memory, Android & iOS

Everything runs on the phone after a one-time model download:
- LLM: Qwen3 0.6B (.litertlm, ~0.6 GB) via Google LiteRT-LM — switch to Gemma 4 E2B in `lib/core/config.dart`
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
```
lib/
  main.dart                  engine init (LiteRT-LM, embedder, sqlite-vec) → runApp
  app.dart                   MaterialApp, theme, SetupGate (setup screen until models are on disk)
  core/
    config.dart              model choices, confidence threshold, OUTBOX_URL
    strings.dart             all UI text: English, Kiswahili, Français (add a language = add one S(...))
    app_settings.dart        chosen language (saved on the phone), `context.s` accessor
  services/                  no widgets in here
    assistant.dart           Assistant controller: prompts, grounded answers, "not sure — ask a person"
                             fail-safes, photo flow, memory extraction, save-for-review
    brain.dart               chunking/indexing of assets/knowledge, retrieval, memory upsert/forget
    leaf_classifier.dart     on-device TFLite leaf model + preprocessing
    outbox.dart              store-and-forward queue for the extension officer
    model_setup.dart         one-time model download + knowledge indexing
  ui/
    theme.dart               light/dark theme
    screens/                 setup, home_shell (bottom nav), chat, memory ("My farm"),
                             outbox ("Officer"), help (language, how it works, privacy, limits)
    widgets/                 message_bubble, diagnosis_card, composer, language_picker
test/ui_smoke_test.dart      renders the screens with fake data in every language (`flutter test`)
assets/knowledge/            drop your sourced documents here (blank-line-separated paragraphs become passages)
```

## Front end
- First launch: language choice (English / Kiswahili / Français), the three promises (private, honest,
  you decide), then the one-time download with progress.
- **Ask**: tap-to-ask suggestions and a big "Check a leaf photo" card; answers stream in. Each answer shows
  its sources and match strength. Fail-safes are visible blocks, not buried text: a "Not sure — ask a person"
  tag, a weak-match warning, and a "confirm before spraying" caution on photo answers. The photo check shows
  a diagnosis card with the top-3 guesses and the confidence the app needs before it names a disease.
- **My farm**: everything the assistant remembers, each fact deletable, plus "Forget everything".
- **Officer**: photos queued for the extension officer, with status, delete and "Send now".
- **Help**: language, how it works, where the data lives, what the assistant cannot do, and model info.
- The UI language also sets the language of the fixed answers and the "not sure" sentence. The LLM answers
  in the language of the question.

## Offline / side-loading story
`installModel(...).fromFile(path)` / `.fromAsset(path)` install from a file copied by SD card, Bluetooth or a
co-op laptop instead of the network — swap `.fromNetwork(...)` in `lib/services/model_setup.dart`.

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

Files: `lib/services/leaf_classifier.dart` (model + preprocessing), `lib/services/outbox.dart` (store-and-forward),
photo flow in `lib/services/assistant.dart`, screen in `lib/ui/screens/outbox_screen.dart`. Disease explanations need sourced passages in `assets/knowledge/`
(one per condition the model knows) — without them the LLM correctly answers "not sure".
