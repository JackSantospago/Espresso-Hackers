import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../services/assistant.dart';
import '../shared/farm_data.dart';
import '../chatbot/chat_screen.dart';
import '../grow/grow_screen.dart';
import '../help/help_screen.dart';
import '../sell/sell_screen.dart';

/// Bottom navigation, always visible: Ask · Grow · Sell · Help.
/// Owns the [Assistant] so the model stays loaded while switching tabs.
/// Pass [assistant] and [data] to run the screens on fake data (main_preview.dart).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.assistant, this.data = const FarmData()});
  final Assistant? assistant;
  final FarmData data;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  Assistant? _assistant;
  int _tab = 0;

  /// Bumped on every tab change so Grow reloads its lists.
  int _visit = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = context.s;
    if (_assistant == null) {
      _assistant = widget.assistant ?? (Assistant(s)..load());
    } else {
      _assistant!.strings = s; // language changed
    }
  }

  @override
  void dispose() {
    _assistant?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final a = _assistant!;
    final key = ValueKey('$_tab-$_visit');
    final Widget other = switch (_tab) {
      1 => GrowScreen(key: key, assistant: a, data: widget.data),
      2 => SellScreen(key: key),
      3 => HelpScreen(key: key, assistant: a),
      _ => const SizedBox.shrink(),
    };

    return Scaffold(
      // The chat stays mounted (offstage) so its text field and scroll survive tab switches.
      body: IndexedStack(index: _tab == 0 ? 0 : 1, children: [ChatScreen(assistant: a), other]),
      bottomNavigationBar: ListenableBuilder(
        listenable: a,
        builder: (context, _) => NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() {
            _tab = i;
            _visit++;
          }),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline),
              selectedIcon: const Icon(Icons.chat_bubble),
              label: s.tabAsk,
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: a.outboxCount > 0,
                label: Text('${a.outboxCount}'),
                child: const Icon(Icons.eco_outlined),
              ),
              selectedIcon: const Icon(Icons.eco),
              label: s.tabGrow,
            ),
            NavigationDestination(
              icon: const Icon(Icons.storefront_outlined),
              selectedIcon: const Icon(Icons.storefront),
              label: s.tabSell,
            ),
            NavigationDestination(
              icon: const Icon(Icons.help_outline),
              selectedIcon: const Icon(Icons.help),
              label: s.tabHelp,
            ),
          ],
        ),
      ),
    );
  }
}
