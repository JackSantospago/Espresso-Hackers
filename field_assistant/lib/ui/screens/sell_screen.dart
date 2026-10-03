import 'package:flutter/material.dart';

import '../../core/app_settings.dart';

/// "Sell": placeholder until there is a market feature. Deliberately shows no
/// prices; the assistant never invents numbers.
class SellScreen extends StatelessWidget {
  const SellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    const icons = [Icons.receipt_long_outlined, Icons.groups_outlined, Icons.inventory_2_outlined];
    return Scaffold(
      appBar: AppBar(title: Text(s.tabSell)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: c.secondaryContainer,
              child: Icon(Icons.storefront_outlined, size: 40, color: c.onSecondaryContainer),
            ),
          ),
          const SizedBox(height: 20),
          Text(s.sellIntro, textAlign: TextAlign.center, style: t.titleMedium),
          const SizedBox(height: 20),
          for (var i = 0; i < s.sellComing.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: Icon(icons[i % icons.length], color: c.primary),
                  title: Text(s.sellComing[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
