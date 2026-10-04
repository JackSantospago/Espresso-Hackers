import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/harvest.dart';

/// "1,200".
String groupDigits(int n) => n.abs().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// "800–1,200 kg".
String kgRange(HarvestForecast f) => '${groupDigits(f.kgLow)}–${groupDigits(f.kgHigh)} kg';

/// "Ready Oct → Dec".
String readyText(BuildContext context, HarvestForecast f) {
  final s = context.s;
  return s.readyWindow(s.monthsShort[f.readyFrom.month - 1], s.monthsShort[f.readyTo.month - 1]);
}

/// One bar for the whole harvest: sold (deep green), open offers (light green),
/// still to sell (grey). Animates when an offer is accepted or declined.
class HarvestBar extends StatelessWidget {
  const HarvestBar({super.key, required this.total, required this.sold, required this.offered});
  final int total, sold, offered;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final whole = total <= 0 ? 1 : total;
    final soldF = (sold / whole).clamp(0.0, 1.0);
    final offeredF = (offered / whole).clamp(0.0, 1.0 - soldF);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 16,
        child: LayoutBuilder(
          builder: (context, box) => Stack(children: [
            Positioned.fill(child: ColoredBox(color: c.surfaceContainerHighest)),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              left: 0,
              top: 0,
              bottom: 0,
              width: box.maxWidth * (soldF + offeredF),
              child: ColoredBox(color: c.primary.withValues(alpha: 0.3)),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              left: 0,
              top: 0,
              bottom: 0,
              width: box.maxWidth * soldF,
              child: ColoredBox(color: c.primary),
            ),
          ]),
        ),
      ),
    );
  }
}

/// The three numbers under the bar: big kg, small label, colour key.
class HarvestLegend extends StatelessWidget {
  const HarvestLegend({super.key, required this.sold, required this.offered, required this.toSell});
  final int sold, offered, toSell;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    Widget item(Color color, String label, int kg) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              Flexible(child: Text(label, style: t.labelMedium?.copyWith(color: c.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 2),
            Text('${groupDigits(kg)} kg', style: t.titleMedium),
          ]),
        );
    return Row(children: [
      item(c.primary, s.soldKg, sold),
      item(c.primary.withValues(alpha: 0.3), s.offeredKg, offered),
      item(c.surfaceContainerHighest, s.toSellKg, toSell),
    ]);
  }
}

/// When it ripens: one small bar per month, tallest at the peak.
class MonthStrip extends StatelessWidget {
  const MonthStrip({super.key, required this.forecast});
  final HarvestForecast forecast;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final top = forecast.byMonth.map((m) => m.$2).fold<int>(1, (a, b) => b > a ? b : a);
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      for (final (month, kg) in forecast.byMonth)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${groupDigits(kg)} kg', style: t.labelSmall?.copyWith(color: c.onSurfaceVariant)),
              const SizedBox(height: 4),
              Container(
                height: 6 + 34 * kg / top,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.2 + 0.5 * kg / top),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text(s.monthsShort[month.month - 1], style: t.labelMedium),
            ]),
          ),
        ),
    ]);
  }
}

/// "How I worked it out": the two formula lines and where the figures come from.
class HarvestWorking extends StatelessWidget {
  const HarvestWorking({super.key, required this.forecast});
  final HarvestForecast forecast;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final i = forecast.inputs;
    String n(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();
    Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 16, color: c.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: t.bodySmall?.copyWith(color: c.onSurface))),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.howWorked, style: t.labelMedium?.copyWith(color: c.onSurfaceVariant)),
      line(Icons.park_outlined, '${s.treesTimesYield(i.trees, n(kCherryKgPerTreeLow), n(kCherryKgPerTreeHigh))} = ${kgRange(forecast)}'),
      line(Icons.event_outlined, s.floweredRipe(s.monthsLong[i.floweredMonth - 1], kMonthsToRipeLow, kMonthsToRipeHigh)),
      const SizedBox(height: 6),
      Text(s.harvestSources, style: t.labelSmall?.copyWith(color: c.onSurfaceVariant)),
    ]);
  }
}

/// The forecast as it appears in a chat answer.
class HarvestCard extends StatelessWidget {
  const HarvestCard({super.key, required this.forecast, this.onOpenSell});
  final HarvestForecast forecast;
  final VoidCallback? onOpenSell;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(s.harvestTitle, style: t.labelLarge?.copyWith(color: c.onSurfaceVariant))),
          const EstimateTag(),
        ]),
        const SizedBox(height: 6),
        Text(kgRange(forecast), style: t.headlineSmall),
        const SizedBox(height: 2),
        Text(readyText(context, forecast), style: t.bodyMedium?.copyWith(color: c.primary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        MonthStrip(forecast: forecast),
        const SizedBox(height: 14),
        const Divider(),
        const SizedBox(height: 8),
        HarvestWorking(forecast: forecast),
        if (onOpenSell != null) ...[
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: onOpenSell,
            icon: const Icon(Icons.storefront_outlined, size: 20),
            label: Text(s.seeInSell),
          ),
        ],
      ]),
    );
  }
}

class EstimateTag extends StatelessWidget {
  const EstimateTag({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: c.outline)),
      child: Text(context.s.harvestEstimate, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.onSurfaceVariant)),
    );
  }
}

/// The harvest as a ring (like Apple's activity rings): sold (deep green),
/// open offers (light green), still to sell (grey track). [center] sits inside.
/// Animates when an offer is accepted or declined.
class HarvestRing extends StatelessWidget {
  const HarvestRing({
    super.key,
    required this.total,
    required this.sold,
    required this.offered,
    required this.center,
    this.size = 150,
  });
  final int total, sold, offered;
  final Widget center;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final whole = total <= 0 ? 1 : total;
    final soldF = (sold / whole).clamp(0.0, 1.0);
    final offeredF = (offered / whole).clamp(0.0, 1.0 - soldF);
    return TweenAnimationBuilder<Offset>(
      tween: Tween(end: Offset(soldF, offeredF)),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => CustomPaint(
        size: Size.square(size),
        painter: _RingPainter(
          sold: v.dx,
          offered: v.dy,
          soldColor: c.primary,
          offeredColor: c.primary.withValues(alpha: 0.32),
          trackColor: c.surfaceContainerHighest,
        ),
        child: child,
      ),
      child: SizedBox.square(dimension: size, child: Center(child: center)),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.sold,
    required this.offered,
    required this.soldColor,
    required this.offeredColor,
    required this.trackColor,
  });
  final double sold, offered;
  final Color soldColor, offeredColor, trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    Paint p(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    const start = -1.5707963267948966; // 12 o'clock
    const full = 6.283185307179586;
    canvas.drawArc(arc, 0, full, false, p(trackColor));
    canvas.drawArc(arc, start + sold * full, offered * full, false, p(offeredColor));
    canvas.drawArc(arc, start, sold * full, false, p(soldColor));
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.sold != sold || old.offered != offered;
}
