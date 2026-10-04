import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../services/assistant.dart';
import '../../services/weather_sync.dart';
import '../shared/farm_data.dart';
import '../chatbot/chat_screen.dart';
import '../grow/grow_screen.dart';
import '../help/help_screen.dart';
import '../sell/market_demo.dart';
import '../sell/sell_screen.dart';

/// Bottom navigation, always visible: Ask · Grow · Sell · Help.
/// Owns the [Assistant] so the model stays loaded while switching tabs, and the
/// [WeatherSync] so the farm's forecast refreshes whenever the phone is online.
/// Pass [assistant], [data] and [weather] to run the screens on fake data (main_preview.dart).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.assistant, this.data = const FarmData(), this.weather, this.initialTab = 0});
  final Assistant? assistant;
  final FarmData data;
  final WeatherSync? weather;
  final int initialTab;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  Assistant? _assistant;
  WeatherSync? _weather;
  late int _tab = widget.initialTab;

  /// Bumped on every tab change so Grow reloads its lists.
  int _visit = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = context.s;
    if (_assistant == null) {
      _assistant = widget.assistant ?? (Assistant(s)..load());
      _weather = widget.weather ?? (WeatherSync()..start());
    } else {
      _assistant!.strings = s; // language changed
    }
  }

  void _openSell() => setState(() {
        _tab = 2;
        _visit++;
      });

  /// "Ask about this" from another tab: go to the chat and ask.
  void _ask(String question) {
    setState(() => _tab = 0);
    if (_assistant!.canSend) _assistant!.send(question);
  }

  @override
  void dispose() {
    _assistant?.dispose();
    if (widget.weather == null) _weather?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final a = _assistant!;
    final weather = _weather!;
    final key = ValueKey('$_tab-$_visit');
    final Widget other = switch (_tab) {
      1 => GrowScreen(key: key, assistant: a, data: widget.data, weather: weather, onAsk: _ask),
      2 => SellScreen(key: key, onAsk: _ask),
      3 => HelpScreen(key: key, assistant: a),
      _ => const SizedBox.shrink(),
    };

    return Scaffold(
      // The chat stays mounted (offstage) so its text field and scroll survive tab switches.
      body: IndexedStack(index: _tab == 0 ? 0 : 1, children: [ChatScreen(assistant: a, onOpenSell: _openSell), other]),
      bottomNavigationBar: ListenableBuilder(
        listenable: Listenable.merge([a, weather, MarketDemo.instance]),
        builder: (context, _) => DecoratedBox(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
          child: NavigationBar(
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
              // Weather warnings show as "!", otherwise photos waiting for the officer.
              icon: Badge(
                isLabelVisible: weather.alerts.isNotEmpty || a.outboxCount > 0,
                label: Text(weather.alerts.isNotEmpty ? '!' : '${a.outboxCount}'),
                child: const Icon(Icons.grass_outlined),
              ),
              selectedIcon: const Icon(Icons.grass),
              label: s.tabGrow,
            ),
            NavigationDestination(
              // Open offers from buyers (demo marketplace).
              icon: Badge(
                isLabelVisible: MarketDemo.instance.offers.isNotEmpty,
                label: Text('${MarketDemo.instance.offers.length}'),
                child: const Icon(Icons.storefront_outlined),
              ),
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
      ),
    );
  }
}
