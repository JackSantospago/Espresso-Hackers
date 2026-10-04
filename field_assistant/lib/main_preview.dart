// UI preview: the real screens on fake data. No models, no engine init, no
// setup gate, so it runs in Chrome with hot reload:
//   flutter run -d chrome -t lib/main_preview.dart
// The app is drawn inside a phone frame (iPhone 16 / iPhone SE / small Android).
// URL options open a given screen, e.g. http://localhost:8080/?tab=grow&theme=dark
// (all options: lib/preview/preview_options.dart).
// The phone app still starts from lib/main.dart.
import 'package:flutter/material.dart';

import 'core/app_settings.dart';
import 'preview/phone_frame.dart';
import 'preview/preview_options.dart';
import 'preview/preview_assistant.dart';
import 'preview/preview_weather.dart';
import 'frontend/shell/home_shell.dart';
import 'frontend/shared/theme.dart';

/// Light / dark switch in the frame's toolbar (follows the browser until used).
final _themeMode = ValueNotifier(PreviewOptions.theme);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.load(); // no files on the web: stays English, the picker still works
  final lang = PreviewOptions.language;
  if (lang != null) await settings.setLanguage(lang);
  runApp(PreviewApp(settings: settings));
}

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key, required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context) => SettingsScope(
        settings: settings,
        child: ListenableBuilder(
          listenable: Listenable.merge([settings, _themeMode]),
          builder: (context, _) => MaterialApp(
            title: '${settings.strings.appName} (preview)',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _themeMode.value,
            builder: PreviewOptions.phoneFrame ? (context, child) => PhoneFrame(themeMode: _themeMode, child: child!) : null,
            home: const _PreviewHome(),
          ),
        ),
      );
}

class _PreviewHome extends StatefulWidget {
  const _PreviewHome();

  @override
  State<_PreviewHome> createState() => _PreviewHomeState();
}

class _PreviewHomeState extends State<_PreviewHome> {
  final _data = PreviewFarmData();
  final _weather = PreviewWeather(on: PreviewOptions.weatherOn);
  PreviewAssistant? _assistant;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _assistant ??= PreviewAssistant(context.s, _data);
  }

  @override
  Widget build(BuildContext context) =>
      HomeShell(assistant: _assistant, data: _data, weather: _weather, initialTab: PreviewOptions.tab);
}
