import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../services/assistant.dart';
import '../farm_data.dart';
import 'memory_screen.dart';
import 'outbox_screen.dart';

/// "Grow": what the app knows about the farm, and the photos waiting for the
/// extension officer, as two tabs.
class GrowScreen extends StatelessWidget {
  const GrowScreen({super.key, required this.assistant, this.data = const FarmData()});
  final Assistant assistant;
  final FarmData data;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.tabGrow),
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.agriculture_outlined), text: s.tabFarm),
              Tab(
                icon: ListenableBuilder(
                  listenable: assistant,
                  builder: (context, _) => Badge(
                    isLabelVisible: assistant.outboxCount > 0,
                    label: Text('${assistant.outboxCount}'),
                    child: const Icon(Icons.support_agent_outlined),
                  ),
                ),
                text: s.tabOfficer,
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MemoryScreen(assistant: assistant, data: data, embedded: true),
            OutboxScreen(assistant: assistant, data: data, embedded: true),
          ],
        ),
      ),
    );
  }
}
