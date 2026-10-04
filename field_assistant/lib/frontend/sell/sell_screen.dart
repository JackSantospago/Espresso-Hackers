import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/harvest.dart';
import '../chatbot/widgets/potato_mascot.dart';
import '../shared/harvest_widgets.dart';
import '../shared/ui.dart';
import 'market_demo.dart';

/// "Sell": a fair, transparent marketplace, seen by the grower. Buyers make
/// offers; each shows how it compares with the market reference, what the
/// farmer receives and how she is paid. Accepted offers become sale records.
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

  /// The offer shown in the slide-in card, until the farmer acts on it.
  BuyerOffer? _alert;
  bool _alertIn = false;

  /// Highlight the harvest card if the forecast is new since the last visit.
  late final bool _forecastIsNew = _m.forecastNew;

  @override
  void initState() {
    super.initState();
    _m.forecastSeen();
    // Like a ride-hailing app: the newest offer slides in a moment after opening.
    if (!_m.offerAlertSeen && _m.offers.isNotEmpty) {
      _m.offerAlertSeen = true;
      _alert = _m.offers.first;
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _alertIn = true);
      });
    }
  }

  void _dismissAlert() => setState(() => _alertIn = false);

  void _decline(BuyerOffer o) {
    if (identical(o, _alert)) _dismissAlert();
    _m.decline(o);
  }

  void _accept(BuyerOffer o) {
    if (identical(o, _alert)) _dismissAlert();
    _m.accept(o);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.s.saleAgreed(o.buyer))));
  }

  Future<void> _view(BuyerOffer o) async {
    if (identical(o, _alert)) _dismissAlert();
    final choice = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OfferSheet(offer: o, market: _m),
    );
    if (choice == true) _accept(o);
    if (choice == false) _decline(o);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          ListenableBuilder(
            listenable: _m,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                PageHeader(title: s.sellTitle, trailing: const _DemoTag()),
                ..._harvest(context),
                const SizedBox(height: 24),
                ..._offers(context),
                const SizedBox(height: 24),
                ..._sales(context),
                const SizedBox(height: 24),
                SectionLabel(s.tipsTitle),
                GroupCard(children: [
                  for (final (i, tip) in s.sellTips.indexed)
                    RowTile(icon: const [Icons.compare_arrows_rounded, Icons.scale_outlined, Icons.receipt_long_outlined][i % 3], title: tip),
                ]),
              ],
            ),
          ),
          if (_alert != null)
            Positioned(
              left: 12,
              right: 12,
              top: 8,
              child: IgnorePointer(
                ignoring: !_alertIn,
                child: AnimatedSlide(
                offset: _alertIn ? Offset.zero : const Offset(0, -1.6),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _alertIn ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: _OfferAlert(
                    offer: _alert!,
                    market: _m,
                    onView: () => _view(_alert!),
                    onDecline: () => _decline(_alert!),
                  ),
                ),
              ),
              ),
            ),
        ]),
      ),
    );
  }

  /// The season at a glance: how much will grow (from the chat's forecast) and
  /// how much of it is already sold, on offer, or still to sell.
  List<Widget> _harvest(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final f = _m.forecast;
    if (f == null) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const PotatoMascot(size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.askHarvestTitle, style: t.titleMedium),
                  const SizedBox(height: 2),
                  Text(s.askHarvestBody, style: t.bodySmall),
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
        ),
      ];
    }
    return [
      SectionLabel(s.harvestTitle, action: s.howWorked, onAction: () => _showWorking(f)),
      Card(
        shape: _forecastIsNew
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: c.primary, width: 1.5))
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(kgRange(f), style: t.headlineSmall)),
              const EstimateTag(),
            ]),
            const SizedBox(height: 2),
            Text(readyText(context, f), style: t.bodyMedium?.copyWith(color: c.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            HarvestBar(total: f.kgMid, sold: _m.soldKg, offered: _m.offeredKg),
            const SizedBox(height: 12),
            HarvestLegend(sold: _m.soldKg, offered: _m.offeredKg, toSell: _m.toSellKg),
          ]),
        ),
      ),
    ];
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

  List<Widget> _offers(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return [
      SectionLabel(s.offersTitle),
      if (_m.offers.isEmpty)
        GroupCard(children: [RowTile(icon: Icons.inbox_outlined, title: s.noOffers)])
      else
        GroupCard(children: [
          for (final o in _m.offers)
            RowTile(
              icon: o.verified ? Icons.verified_outlined : Icons.storefront_outlined,
              iconColor: o.verified ? c.primary : null,
              title: o.buyer,
              titleStyle: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              subtitle: '${o.kg} kg · ${s.pickupIn(o.pickupInDays)}',
              trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                Text('${money(o.pricePerKg)}/kg', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                FairnessTag(pct: _m.vsMarket(o)),
              ]),
              onTap: () => _view(o),
            ),
        ]),
      // Transparency: the reference every offer is compared with.
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
        child: Row(children: [
          Icon(Icons.show_chart_rounded, size: 16, color: c.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(s.marketRef(money(_m.referencePrice)), style: t.bodySmall)),
        ]),
      ),
    ];
  }

  List<Widget> _sales(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return [
      // The kilos are in the harvest bar above; here the money and each sale.
      SectionLabel('${s.salesTitle} · ${money(_m.seasonTotal)}'),
      GroupCard(children: [
        for (final sale in _m.sales)
          RowTile(
            icon: sale.paid ? Icons.check_circle_outline_rounded : Icons.local_shipping_outlined,
            iconColor: sale.paid ? c.primary : c.secondary,
            title: sale.buyer,
            subtitle: '${sale.kg} kg · ${money(sale.pricePerKg)}/kg · '
                '${sale.paid ? s.statusPaid : s.pickupIn(sale.pickupInDays!)}',
            trailing: Text(money(sale.total), style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
      ]),
    ];
  }
}

/// "+9% vs market" in green, "−9% vs market" in amber.
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

/// The slide-in card for a new offer: dark, compact, two actions.
class _OfferAlert extends StatelessWidget {
  const _OfferAlert({required this.offer, required this.market, required this.onView, required this.onDecline});
  final BuyerOffer offer;
  final MarketDemo market;
  final VoidCallback onView, onDecline;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final ink = c.onInverseSurface;
    final soft = ink.withValues(alpha: 0.7);
    return Material(
      color: c.inverseSurface,
      elevation: 8,
      shadowColor: Colors.black45,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: c.inversePrimary, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                [s.newOffer, if (offer.expiresInHours != null) s.expiresIn(offer.expiresInHours!)].join(' · '),
                style: t.labelMedium?.copyWith(color: soft),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: c.inversePrimary,
              child: Text(_initials(offer.buyer), style: t.labelLarge?.copyWith(color: c.onPrimaryContainer)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.wantsKg(offer.buyer, offer.kg), style: t.titleMedium?.copyWith(color: ink)),
                const SizedBox(height: 4),
                Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text('${money(offer.pricePerKg)}/kg', style: t.bodyMedium?.copyWith(color: ink, fontWeight: FontWeight.w700)),
                  FairnessTag(pct: market.vsMarket(offer), onDark: true),
                ]),
                const SizedBox(height: 4),
                Text('${s.pickupIn(offer.pickupInDays)} · ${s.kmAway(offer.km)}', style: t.bodySmall?.copyWith(color: soft)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextButton(
                onPressed: onDecline,
                style: TextButton.styleFrom(foregroundColor: ink, minimumSize: const Size.fromHeight(44)),
                child: Text(s.decline),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: onView,
                style: FilledButton.styleFrom(
                  backgroundColor: ink,
                  foregroundColor: c.inverseSurface,
                  minimumSize: const Size.fromHeight(44),
                ),
                child: Text(s.view),
              ),
            ),
          ]),
        ]),
      ),
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
          line(s.quantity, '${offer.kg} kg'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(children: [
              Expanded(child: Text(s.pricePerKg, style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant))),
              FairnessTag(pct: market.vsMarket(offer)),
              const SizedBox(width: 8),
              Text(money(offer.pricePerKg), style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            ]),
          ),
          line(s.pickupIn(offer.pickupInDays), s.kmAway(offer.km)),
          const SizedBox(height: 6),
          const Divider(),
          line(s.youReceive, money(offer.total), strong: true),
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
