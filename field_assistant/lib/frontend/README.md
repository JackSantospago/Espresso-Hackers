# Frontend

All screens and widgets of the app, one folder per page. Nothing in here talks to the
models directly: pages get their data from `services/` through `Assistant` and
`shared/farm_data.dart`, so the UI can be built and previewed without the backend.

```
frontend/
  chatbot/     "Ask" tab: the chat (chat_screen.dart) and its widgets
               (composer, message_bubble, diagnosis_card, potato_mascot)
  grow/        "Grow" tab: Weather (weather_screen, weather_widgets), My farm (memory_screen),
               Guides, Officer (outbox_screen)
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
small Android, light/dark) with fake data from `../preview/`. If `-d chrome` does not open,
use `flutter run -d web-server --web-port 8080 -t lib/main_preview.dart` and open
http://localhost:8080.

Options go in the page URL, so a link can open a given screen (handy for the demo):
`http://localhost:8080/?tab=grow&theme=dark&device=se&lang=sw`

| option | values |
| --- | --- |
| `tab` | `ask` · `grow` · `sell` · `help` |
| `chat` | `demo`: start on a conversation with every kind of message |
| `theme` | `light` · `dark` |
| `device` | `iphone` · `se` · `android` |
| `lang` | `en` · `sw` · `fr` |
| `frame` | `off`: fill the window, no phone |
| `weather` | `off`: start with weather not turned on (fake forecast otherwise, from `preview/fake_data.dart`) |

## Design
`shared/theme.dart` holds the whole look: cream background, white cards with hairline
borders, forest green (brand), coffee-cherry (leaf photo, possible disease), amber
("check with a person"). Fonts: Fraunces for headings, Inter for text, bundled in
`assets/fonts/` so they work offline. Use `Theme.of(context).colorScheme` and `textTheme`
instead of hard-coded colors and sizes, so every page stays consistent in light and dark.

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

Frontend work happens on the `frontend` branch and is merged into `main` for demos and
releases. The preview-only code (`main_preview.dart`, `preview/`, `web/`, and the web
stand-in `services/leaf_classifier_stub.dart`) is never used by the phone app, which starts
from `main.dart`.
