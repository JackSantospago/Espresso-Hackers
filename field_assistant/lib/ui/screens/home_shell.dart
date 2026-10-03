import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../services/assistant.dart';
import 'chat_screen.dart';
import 'help_screen.dart';
import 'memory_screen.dart';
import 'outbox_screen.dart';

/// Bottom navigation: Ask · My farm · Officer · Help.
/// Owns the [Assistant] so the model stays loaded while switching tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  Assistant? _assistant;
  int _tab = 0;

  /// Bumped on every tab change so My farm / Officer reload their lists.
  int _visit = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = context.s;
    if (_assistant == null) {
      _assistant = Assistant(s)..load();
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
      1 => MemoryScreen(key: key, assistant: a),
      2 => OutboxScreen(key: key, assistant: a),
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
                isLabelVisible: a.memoryCount > 0,
                label: Text('${a.memoryCount}'),
                child: const Icon(Icons.agriculture_outlined),
              ),
              selectedIcon: const Icon(Icons.agriculture),
              label: s.tabFarm,
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: a.outboxCount > 0,
                label: Text('${a.outboxCount}'),
                child: const Icon(Icons.support_agent_outlined),
              ),
              selectedIcon: const Icon(Icons.support_agent),
              label: s.tabOfficer,
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
