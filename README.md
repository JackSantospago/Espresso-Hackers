# Espresso-Hackers

Hack-Nation × World Bank **Small AI for Development**, Challenge 04, **Agriculture** track.

An offline field assistant for smallholder coffee farmers like Noor: she asks questions in her own
language and checks leaf photos, and everything runs on the phone after a one-time download. Answers come
only from sourced extension material stored on the device. When the app is not sure, it says so and points
her to her extension officer or cooperative. Photos go to an officer only when she chooses to send them,
and they wait on the phone until there is signal.

## Repository layout
| Path | What it is |
| --- | --- |
| [`field_assistant/`](field_assistant/) | The Flutter app (Android & iOS): on-device LLM + RAG + memory + leaf photo check. Setup and run instructions are in its [README](field_assistant/README.md). |
| [`field_assistant/lib/`](field_assistant/lib/) | `core/` config & translations · `services/` AI logic (no UI) · `ui/` screens and widgets |
| [`field_assistant/assets/knowledge/`](field_assistant/assets/knowledge/) | Sourced farming guides the assistant answers from |
| [`training/leaf_classifier.ipynb`](training/leaf_classifier.ipynb) | Colab notebook that trains the ~4 MB MobileNetV3 leaf classifier |

## Quick start
```bash
cd field_assistant
flutter pub get
flutter run --release --dart-define=HF_TOKEN=hf_xxx   # omit the token to use the English-only embedder
flutter test                                          # UI smoke tests, no models needed
```
