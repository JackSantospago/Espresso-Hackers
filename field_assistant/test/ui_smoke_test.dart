// Renders the main screens with fake data (no models, no plugins) in every
// language, at a small-phone size, so layout overflows and missing strings
// show up in `flutter test` instead of on a farmer's phone.
import 'dart:io';

import 'package:field_assistant/core/app_settings.dart';
import 'package:field_assistant/core/strings.dart';
import 'package:field_assistant/frontend/grow/grow_screen.dart';
import 'package:field_assistant/frontend/grow/guides_screen.dart';
import 'package:field_assistant/frontend/shared/guides.dart';
import 'package:field_assistant/preview/fake_data.dart';
import 'package:field_assistant/preview/preview_assistant.dart';
import 'package:field_assistant/services/assistant.dart';
import 'package:field_assistant/frontend/chatbot/chat_screen.dart';
import 'package:field_assistant/frontend/help/help_screen.dart';
import 'package:field_assistant/frontend/sell/sell_screen.dart';
import 'package:field_assistant/frontend/shared/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(AppSettings settings, Widget child) => SettingsScope(
      settings: settings,
      child: MaterialApp(theme: AppTheme.light(), home: child),
    );

Assistant _fakeConversation(S s) => Assistant(s)
  ..state = AssistantState.ready
  ..turns.addAll(fakeConversation(s));

void main() {
  test('guides parse the knowledge file format (title, sections, sources)', () {
    final text = File('assets/knowledge/coffee_leaf_rust.md').readAsStringSync();
    final g = parseGuides(text, 'coffee_leaf_rust.md').single;
    expect(g.title, 'Coffee leaf rust');
    expect(g.crop, GuideCrop.coffee);
    expect(g.summary, isNotEmpty);
    expect(g.sections, isNotEmpty);
    expect(g.sections.map((x) => x.heading), contains('Symptoms'));
    expect(g.sections.every((x) => x.sources.isNotEmpty), isTrue, reason: 'every paragraph ends with (Source: …)');
    expect(g.sections.any((x) => x.text.contains('(Source:')), isFalse);
  });

  for (final lang in AppLanguage.values) {
    group(lang.nativeName, () {
      late AppSettings settings;
      setUp(() async {
        rootBundle.clear(); // cached asset futures from an earlier test never complete in this one
        settings = AppSettings();
        await settings.setLanguage(lang); // file write fails quietly in tests; the choice still applies
      });

      testWidgets('chat shows a full conversation without overflow', (tester) async {
        // Narrow like a small phone, tall so the lazy list builds every bubble.
        tester.view.physicalSize = const Size(360, 4000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final a = _fakeConversation(settings.strings);
        await tester.pumpWidget(_wrap(settings, ChatScreen(assistant: a)));
        await tester.pump();
        expect(find.text(settings.strings.askPerson), findsWidgets);
        expect(find.text(settings.strings.sendToOfficer), findsOneWidget);
        expect(find.text(settings.strings.queuedNote), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('empty chat shows the welcome suggestions', (tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final a = Assistant(settings.strings)..state = AssistantState.ready;
        await tester.pumpWidget(_wrap(settings, ChatScreen(assistant: a)));
        await tester.pump();
        expect(find.text(settings.strings.welcomeTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('grow overview, a guide and the note dialog work', (tester) async {
        tester.view.physicalSize = const Size(360, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final s = settings.strings;
        final data = PreviewFarmData();
        String? asked;
        await tester.pumpWidget(_wrap(
          settings,
          GrowScreen(assistant: PreviewAssistant(s, data), data: data, onAsk: (q) => asked = q),
        ));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200))); // guides load from assets
        await tester.pumpAndSettle();
        expect(find.text(s.farmTitle), findsOneWidget);
        // The fake farm grows coffee, so coffee guides (from assets/knowledge/) come first.
        final first = tester.widget<GuideTile>(find.byType(GuideTile).first).guide;
        expect(first.crop, GuideCrop.coffee);

        // Open a guide and ask about it.
        await tester.tap(find.text(first.title));
        await tester.pumpAndSettle();
        await tester.tap(find.text(s.askAboutThis));
        await tester.pumpAndSettle();
        expect(asked, s.askAbout(first.title));

        // Add a note: it shows up in Your farm.
        await tester.tap(find.text(s.addNote));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'I planted 50 new trees on the lower plot.');
        await tester.tap(find.text(s.save));
        await tester.pumpAndSettle();
        expect(find.text('I planted 50 new trees on the lower plot.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('sell screen renders', (tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_wrap(settings, const SellScreen()));
        await tester.pump();
        expect(find.text(settings.strings.sellTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('help screen renders', (tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_wrap(settings, HelpScreen(assistant: Assistant(settings.strings))));
        await tester.pump();
        expect(find.text(settings.strings.helpTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
