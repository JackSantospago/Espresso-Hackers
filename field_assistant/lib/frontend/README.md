# Frontend

All screens and widgets of the app, one folder per page. Nothing in here talks to the
models directly: pages get their data from `services/` through `Assistant` and
`shared/farm_data.dart`, so the UI can be built and previewed without the backend.

```
frontend/
  chatbot/     "Ask" tab: the chat (chat_screen.dart) and its widgets
               (composer, message_bubble, diagnosis_card, potato_mascot)
  grow/        "Grow" tab: My farm (memory_screen) + Officer (outbox_screen)
  sell/        "Sell" tab: placeholder page, to be designed
  help/        "Help" tab
  setup/       first launch: language, promises, model download
  shell/       home_shell.dart: the bottom bar (Ask · Grow · Sell · Help)
  shared/      used by several pages: theme.dart (colors), language_picker.dart,
               farm_data.dart (what Grow reads/changes; the preview swaps in fakes)
```

Text the farmer sees lives in `../core/strings.dart` (English, Kiswahili, French).
Add a field to `S` and fill it in all three languages; the compiler points at any you miss.

## See it in the browser (no models needed)
```bash
cd field_assistant
flutter run -d chrome -t lib/main_preview.dart
```
`r` hot reload, `R` restart. The app shows inside a phone frame (iPhone 16 / iPhone SE /
small Android, light/dark) with fake data from `../preview/`. Add
`--dart-define=PREVIEW_CHAT=demo` to start on a conversation with every kind of message,
or `--dart-define=PHONE_FRAME=false` to fill the window. If `-d chrome` does not open,
use `flutter run -d web-server --web-port 8080 -t lib/main_preview.dart` and open
http://localhost:8080.

## Working together
- Work on the `frontend` branch, or a branch off it (`frontend-sell`, …) merged back into `frontend`.
- Stay inside your page folder where you can. `shared/`, `shell/` and `core/strings.dart`
  are touched by everyone: keep those edits small, pull right before you change them,
  and push soon after.
- New page: add `frontend/<page>/<page>_screen.dart`, then a tab in `shell/home_shell.dart`.
- Before pushing: `flutter analyze` and `flutter test` (renders the screens in every
  language at small-phone width).
- Do not change `lib/services/` here; that is the backend team's. If a page needs new
  data, put a fake in `../preview/` for now and note what the real one should return.

The `frontend` branch is not merged into `main` directly: it carries preview-only code
(`main_preview.dart`, `preview/`, a web stand-in for the leaf classifier). When the UI is
ready, the `frontend/` folder is brought into `main` and wired to the real backend.
