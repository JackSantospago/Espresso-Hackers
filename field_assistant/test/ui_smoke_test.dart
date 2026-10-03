// Renders the main screens with fake data (no models, no plugins) in every
// language, at a small-phone size, so layout overflows and missing strings
// show up in `flutter test` instead of on a farmer's phone.
import 'dart:typed_data';

import 'package:field_assistant/core/app_settings.dart';
import 'package:field_assistant/core/strings.dart';
import 'package:field_assistant/services/assistant.dart';
import 'package:field_assistant/services/leaf_classifier.dart';
import 'package:field_assistant/ui/screens/chat_screen.dart';
import 'package:field_assistant/ui/screens/help_screen.dart';
import 'package:field_assistant/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(AppSettings settings, Widget child) => SettingsScope(
      settings: settings,
      child: MaterialApp(theme: AppTheme.light(), home: child),
    );

Diagnosis _diagnosis({required double p}) => Diagnosis(
      top: [
        Guess(const LeafLabel('coffee__rust', 'Coffee', 'Leaf rust'), p),
        Guess(const LeafLabel('coffee__miner', 'Coffee', 'Leaf miner'), (1 - p) * 0.7),
        Guess(const LeafLabel('other', '', 'Other'), (1 - p) * 0.3),
      ],
      threshold: 0.6,
      otherId: 'other',
      millis: 120,
    );

Assistant _fakeConversation(S s) {
  final a = Assistant(s)..state = AssistantState.ready;
  a.turns.addAll([
    ChatTurn(s.suggestions.first, fromUser: true),
    ChatTurn('Old trees produce less. Prune in rotation.', fromUser: false)
      ..sources = ['coffee_sample.md']
      ..match = 0.42
      ..details = 'match 0.42',
    ChatTurn('What is the price of fertiliser?', fromUser: true),
    ChatTurn(s.notSure, fromUser: false)
      ..notSure = true
      ..warning = s.weakMatch
      ..match = 0.05,
    ChatTurn(s.photoDefaultQuestion, fromUser: true),
    ChatTurn('Leaf rust shows yellow-orange powder under the leaf.', fromUser: false)
      ..diagnosis = _diagnosis(p: 0.85)
      ..caution = s.photoCaution
      ..reviewPhoto = Uint8List(1)
      ..sources = ['coffee_sample.md'],
    ChatTurn(s.photoNotSure(s.photoNotSureOther), fromUser: false)
      ..diagnosis = _diagnosis(p: 0.4)
      ..notSure = true
      ..queued = true,
  ]);
  return a;
}

void main() {
  for (final lang in AppLanguage.values) {
    group(lang.nativeName, () {
      late AppSettings settings;
      setUp(() async {
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
