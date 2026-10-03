# Team rules for Claude (read before changing anything)

Several people work on this repo at the same time, each with their own Claude session.
These rules keep their changes from colliding.

## Who owns what
- `field_assistant/lib/services/`: backend team. Frontend sessions never edit it.
- `field_assistant/lib/frontend/<page>/`: one owner per page.
  `chatbot/` = Jack · `sell/` = the Sell page owner. Ask the user which page is theirs if unclear,
  and stay inside it.
- Shared, touched by everyone: `frontend/shared/` (theme, language picker, farm_data),
  `frontend/shell/home_shell.dart` (bottom bar), `core/strings.dart`, `pubspec.yaml`.
  Keep edits there small and say so in your summary to the user.

## Workflow
1. Start of every task: `git pull --rebase` on the `frontend` branch (or your own branch off it).
2. Commit small and often; push right after a shared file changes, so others pull it quickly.
3. On a conflict: keep both sides' intent, never drop someone else's change silently; ask the user if unsure.
4. Before committing: `flutter analyze` and `flutter test` in `field_assistant/` must pass.

## Don'ts (these caused trouble before)
- Do not run `dart format` on folders or the whole project: it rewrites other people's files and
  creates conflicts. Format only the files you wrote from scratch, if at all.
- Do not rename or move shared files without asking the user.
- New text goes in `core/strings.dart` in all three languages (en, sw, fr), added next to your
  page's other fields (e.g. after the `// Sell` group) so two people rarely edit the same lines.
- Use `Theme.of(context).colorScheme` / `textTheme`, not hard-coded colors or font sizes.

## Seeing the UI
`cd field_assistant && flutter run -d web-server --web-port 8080 -t lib/main_preview.dart`, then
http://localhost:8080. URL options and the folder map: `field_assistant/lib/frontend/README.md`.
