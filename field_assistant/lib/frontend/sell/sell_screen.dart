import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/harvest.dart';
import '../chatbot/widgets/potato_mascot.dart';
import '../shared/harvest_widgets.dart';
import '../shared/ui.dart';
import 'market_demo.dart';

/// "Sell": a fair, transparent marketplace, seen by the grower. The app is
/// offline, so buyers' offers arrive in an inbox whenever the phone has signal.
/// The page shows the season as a ring (sold / still to sell); the inbox
/// (top right) holds the offers, each compared with the market; accepting one
/// closes the inbox and the ring fills in.
/// DEMO: the data comes from [MarketDemo] (no marketplace backend yet), and the
/// page says so with a "Demo" tag.
class SellScreen extends StatefulWidget {
  const SellScreen({super.key, this.market, this.onAsk});

  /// Defaults to the app-wide demo marketplace.
  final MarketDemo? market;

  /// Ask the assistant (switches to the chat): used for the harvest forecast.
  final void Function(String question)? onAsk;

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  MarketDemo get _m => widget.market ?? MarketDemo.instance;

  @override
  void initState() {
    super.initState();
    _m.forecastSeen();
  }

  /// The inbox; returns the offer the farmer accepted, if any.
  Future<void> _openInbox() async {
    final accepted = await showModalBottomSheet<BuyerOffer>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _Inbox(market: _m),
    );
    if (accepted == null || !mounted) return;
    _m.accept(accepted);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.s.saleAgreed(accepted.buyer))));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _m,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              PageHeader(
                title: s.tabSell,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  const _DemoTag(),
                  const SizedBox(width: 4),
                  IconButton(
                    key: const ValueKey('sell-inbox'),
                    tooltip: s.offersTitle,
                    onPressed: _openInbox,
                    icon: Badge(
                      isLabelVisible: _m.offers.isNotEmpty,
                      label: Text('${_m.offers.length}'),
                      child: const Icon(Icons.inbox_outlined),
                    ),
                  ),
                ]),
              ),
              _hero(context),
              const SizedBox(height: 16),
              // Transparency: the reference every offer is compared with.
              GroupCard(children: [
                RowTile(
                  icon: Icons.show_chart_rounded,
                  title: s.marketPrice,
                  trailing: Text('${price(_m.referencePrice)}/kg',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 24),
              ..._history(context),
              const SizedBox(height: 24),
              SectionLabel(s.tipsTitle),
              GroupCard(children: [
                for (final (i, tip) in s.sellTips.indexed)
                  RowTile(
                    icon: const [Icons.compare_arrows_rounded, Icons.scale_outlined, Icons.receipt_long_outlined][i % 3],
                    title: tip,
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  /// The season at a glance. Before a forecast: one line and "Ask the assistant".
  Widget _hero(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final f = _m.forecast;
    if (f == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            const PotatoMascot(size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.askHarvestTitle, style: t.titleMedium),
                if (widget.onAsk != null) ...[
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    onPressed: () => widget.onAsk!(s.harvestQuestion),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                    child: Text(s.askNow),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      );
    }
    Widget legend(Color color, String label, int kg) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant))),
            // Shrinks a little rather than overflow on small phones / long labels.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text('${groupDigits(kg)} kg', style: t.titleMedium),
              ),
            ),
          ]),
        );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showWorking(f),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
          child: Column(children: [
            Row(children: [
              HarvestRing(
                size: 128,
                total: _m.seasonBase,
                sold: _m.soldKg,
                offered: 0,
                center: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${groupDigits(_m.seasonBase)} kg', style: t.titleLarge?.copyWith(fontSize: 18)),
                  Text(s.thisSeason, style: t.labelSmall?.copyWith(color: c.onSurfaceVariant)),
                ]),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(children: [
                  legend(c.primary, s.soldKg, _m.soldKg),
                  legend(c.surfaceContainerHighest, s.toSellKg, _m.toSellKg),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            Text(readyText(context, f), style: t.bodyMedium?.copyWith(color: c.primary, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  void _showWorking(HarvestForecast f) => showModalBottomSheet<void>(
        context: context,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              Text(kgRange(f), style: Theme.of(context).textTheme.headlineSmall),
              Text(readyText(context, f), style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 18),
              MonthStrip(forecast: f),
              const SizedBox(height: 18),
              HarvestWorking(forecast: f),
            ]),
          ),
        ),
      );

  /// Every sale this season, newest first, with the season total in the title.
  List<Widget> _history(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return [
      SectionLabel(_m.sales.isEmpty ? s.salesHistory : '${s.salesHistory} · ${money(_m.seasonTotal)}'),
      GroupCard(children: [
        if (_m.sales.isEmpty) RowTile(icon: Icons.receipt_long_outlined, title: s.noSalesYet),
        for (final sale in _m.sales)
          RowTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: c.surfaceContainerHigh,
              child: Text(_initials(sale.buyer), style: t.labelLarge?.copyWith(color: c.onSurface)),
            ),
            title: sale.buyer,
            titleStyle: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            subtitle: '${_m.saleKg(sale)} kg · ${price(sale.pricePerKg)}/kg',
            trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
              Text(money(_m.saleTotal(sale)), style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                sale.paid ? s.statusPaid : s.pickupIn(sale.pickupInDays!),
                style: t.labelSmall?.copyWith(color: sale.paid ? c.primary : c.secondary, fontWeight: FontWeight.w600),
              ),
            ]),
          ),
      ]),
    ];
  }
}

/// The offers inbox: filled whenever the phone was last online. Tapping an
/// offer shows it in full; accepting closes the inbox and returns the offer.
class _Inbox extends StatelessWidget {
  const _Inbox({required this.market});
  final MarketDemo market;

  Future<void> _view(BuildContext context, BuyerOffer o) async {
    final choice = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OfferSheet(offer: o, market: market),
    );
    if (!context.mounted) return;
    if (choice == true) Navigator.pop(context, o); // close the inbox; the Sell page accepts it
    if (choice == false) market.decline(o);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: ListenableBuilder(
        listenable: market,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Text(s.offersTitle, style: t.headlineSmall),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
              child: Row(children: [
                Icon(Icons.sync_rounded, size: 16, color: c.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(child: Text(s.offersSynced, style: t.bodySmall)),
              ]),
            ),
            GroupCard(children: [
              if (market.offers.isEmpty) RowTile(icon: Icons.inbox_outlined, title: s.noOffers),
              for (final o in market.offers)
                RowTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: c.surfaceContainerHigh,
                    child: Text(_initials(o.buyer), style: t.labelLarge?.copyWith(color: c.onSurface)),
                  ),
                  title: o.buyer,
                  titleStyle: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  subtitle: '${market.offerKg(o)} kg',
                  trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                    Text('${price(o.pricePerKg)}/kg', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    FairnessTag(pct: market.vsMarket(o)),
                  ]),
                  onTap: () => _view(context, o),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// "10% above market" in green, "10% below market" in amber.
class FairnessTag extends StatelessWidget {
  const FairnessTag({super.key, required this.pct, this.onDark = false});
  final int pct;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final good = pct >= 0;
    final color = onDark ? (good ? c.inversePrimary : const Color(0xFFF2C46B)) : (good ? c.primary : c.tertiary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: onDark ? 0.18 : 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        context.s.vsMarket(pct),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DemoTag extends StatelessWidget {
  const _DemoTag();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: c.outline)),
      child: Text(context.s.demoTag, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.onSurfaceVariant)),
    );
  }
}

String _initials(String name) => name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join().toUpperCase();

/// The full offer: who, how much, how it compares, what the farmer receives,
/// how she is paid. Returns true (accept) or false (decline).
class _OfferSheet extends StatelessWidget {
  const _OfferSheet({required this.offer, required this.market});
  final BuyerOffer offer;
  final MarketDemo market;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    Widget line(String label, String value, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Expanded(child: Text(label, style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant))),
            Text(value, style: strong ? t.titleLarge : t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          ]),
        );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(offer.buyer, style: t.headlineSmall),
          const SizedBox(height: 6),
          Wrap(spacing: 10, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            if (offer.verified)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.verified_rounded, size: 16, color: c.primary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(s.verifiedBuyer, style: t.bodySmall?.copyWith(color: c.primary, fontWeight: FontWeight.w600)),
                ),
              ]),
            Text(s.ratingSales(offer.rating.toStringAsFixed(1), offer.sales), style: t.bodySmall),
          ]),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 6),
          line(s.quantity, '${market.offerKg(offer)} kg'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(children: [
              Expanded(child: Text(s.pricePerKg, style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant))),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(price(offer.pricePerKg), style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                FairnessTag(pct: market.vsMarket(offer)),
              ]),
            ]),
          ),
          line(s.pickupIn(offer.pickupInDays), s.kmAway(offer.km)),
          const SizedBox(height: 6),
          const Divider(),
          line(s.youReceive, money(market.offerTotal(offer)), strong: true),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.phone_iphone_rounded, size: 16, color: c.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text('${s.payment}: ${s.paymentOnPickup}', style: t.bodySmall)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.check_rounded, size: 16, color: c.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(s.noFees, style: t.bodySmall?.copyWith(color: c.primary, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: Text(s.decline),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s.acceptOffer)),
            ),
          ]),
        ]),
      ),
    );
  }
}
