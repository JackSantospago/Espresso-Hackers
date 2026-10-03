import 'package:flutter/material.dart';

import 'core/app_settings.dart';
import 'services/model_setup.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/setup_screen.dart';
import 'ui/theme.dart';

class FieldAssistantApp extends StatelessWidget {
  const FieldAssistantApp({super.key, required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context) => SettingsScope(
        settings: settings,
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => MaterialApp(
            title: settings.strings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            home: const SetupGate(),
          ),
        ),
      );
}

/// Shows the one-time setup until both models are on disk, then the app.
class SetupGate extends StatefulWidget {
  const SetupGate({super.key});

  @override
  State<SetupGate> createState() => _SetupGateState();
}

class _SetupGateState extends State<SetupGate> {
  bool? _ready;

  @override
  void initState() {
    super.initState();
    ModelSetup.isReady().then((ok) {
      if (mounted) setState(() => _ready = ok);
    });
  }

  @override
  Widget build(BuildContext context) => switch (_ready) {
        null => const Scaffold(body: Center(child: CircularProgressIndicator())),
        true => const HomeShell(),
        false => SetupScreen(onDone: () => setState(() => _ready = true)),
      };
}
