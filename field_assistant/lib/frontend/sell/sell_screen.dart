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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // Hero.
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.secondaryContainer, c.surfaceContainerLowest],
              ),
              border: Border.all(color: c.outlineVariant),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.storefront_outlined, size: 28, color: c.onSecondary),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.secondary.withValues(alpha: 0.3)),
                  ),
                  child: Text(s.comingSoon, style: t.labelMedium?.copyWith(color: c.secondary)),
                ),
              ]),
              const SizedBox(height: 18),
              Text(s.sellIntro, style: t.titleLarge?.copyWith(fontSize: 20, height: 1.3)),
            ]),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < s.sellComing.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(color: c.primaryContainer, borderRadius: BorderRadius.circular(12)),
                      child: Icon(icons[i % icons.length], size: 20, color: c.onPrimaryContainer),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(s.sellComing[i], style: t.bodyLarge)),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
