import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/strings.dart';

/// Language chips, shown on the setup screen and in Help.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final l in AppLanguage.values)
          ChoiceChip(
            label: Text(l.nativeName),
            selected: settings.language == l,
            onSelected: (_) => settings.setLanguage(l),
          ),
      ],
    );
  }
}

/// Compact language switch for app bars.
class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    return PopupMenuButton<AppLanguage>(
      tooltip: context.s.language,
      icon: const Icon(Icons.translate),
      initialValue: settings.language,
      onSelected: settings.setLanguage,
      itemBuilder: (context) => [
        for (final l in AppLanguage.values)
          CheckedPopupMenuItem(value: l, checked: settings.language == l, child: Text(l.nativeName)),
      ],
    );
  }
}
