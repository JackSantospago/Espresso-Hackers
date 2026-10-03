import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'strings.dart';

/// On-device preferences (just the UI language for now), saved as a small JSON
/// file next to the other app data — no extra plugin needed.
class AppSettings extends ChangeNotifier {
  AppLanguage _language = AppLanguage.en;
  AppLanguage get language => _language;
  S get strings => S.forLanguage(_language);

  static Future<File> _file() async =>
      File('${(await getApplicationDocumentsDirectory()).path}/settings.json');

  Future<void> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return;
      final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      _language = AppLanguage.values.firstWhere((l) => l.name == j['language'], orElse: () => AppLanguage.en);
    } catch (_) {/* keep defaults */}
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (language == _language) return;
    _language = language;
    notifyListeners();
    try {
      await (await _file()).writeAsString(jsonEncode({'language': language.name}));
    } catch (_) {/* the choice still applies for this session */}
  }
}

/// Makes [AppSettings] available below it; widgets that read it rebuild when
/// the language changes.
class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({super.key, required AppSettings settings, required super.child})
      : super(notifier: settings);

  static AppSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}

extension SettingsContext on BuildContext {
  /// The strings for the farmer's chosen language: `context.s.tabAsk`.
  S get s => SettingsScope.of(this).strings;
}
