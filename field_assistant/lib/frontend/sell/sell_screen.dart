import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../shared/ui.dart';

/// "Sell": placeholder until there is a market feature. Deliberately shows no
/// prices; the assistant never invents numbers.
class SellScreen extends StatelessWidget {
  const SellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    const icons = [Icons.receipt_long_outlined, Icons.storefront_outlined, Icons.inventory_2_outlined];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            PageHeader(
              title: s.sellTitle,
              subtitle: s.sellSubtitle,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 0, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.secondary.withValues(alpha: 0.4)),
                  ),
                  child: Text(s.comingSoon, style: t.labelMedium?.copyWith(color: c.secondary)),
                ),
              ),
            ),
            GroupCard(children: [
              for (var i = 0; i < s.sellComing.length; i++)
                RowTile(icon: icons[i % icons.length], title: s.sellComing[i]),
            ]),
          ],
        ),
      ),
    );
  }
}
