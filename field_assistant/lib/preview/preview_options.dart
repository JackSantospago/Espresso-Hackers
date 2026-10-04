import 'package:flutter/material.dart';

import '../core/strings.dart';

/// Preview options, read from the page URL so a link can open a given screen:
///   http://localhost:8080/?tab=grow&chat=demo&theme=dark&device=se&lang=sw
///   tab     ask | grow | sell | help
///   chat    demo  (start on a conversation with every kind of message)
///   theme   light | dark       device  iphone | se | android
///   lang    en | sw | fr       frame   off  (fill the window, no phone)
///   weather off  (start with weather not yet turned on)
abstract final class PreviewOptions {
  static final Map<String, String> _q = Uri.base.queryParameters;

  static const _tabs = ['ask', 'grow', 'sell', 'help'];
  static int get tab => _tabs.indexOf(_q['tab'] ?? 'ask').clamp(0, _tabs.length - 1);

  static bool get weatherOn => _q['weather'] != 'off';

  static bool get demoChat => (_q['chat'] ?? const String.fromEnvironment('PREVIEW_CHAT')) == 'demo';

  static bool get phoneFrame =>
      _q['frame'] != 'off' && const bool.fromEnvironment('PHONE_FRAME', defaultValue: true);

  static ThemeMode get theme => switch (_q['theme']) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static int get device => switch (_q['device']) {
        'se' => 1,
        'android' => 2,
        _ => 0,
      };

  static AppLanguage? get language => AppLanguage.values.where((l) => l.name == _q['lang']).firstOrNull;
}
