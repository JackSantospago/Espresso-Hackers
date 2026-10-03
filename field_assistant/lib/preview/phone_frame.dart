import 'package:flutter/material.dart';

import 'preview_options.dart';

/// A phone the preview can be shown in: screen size in logical pixels and the
/// system insets (status bar, home bar) the app sees on the real device.
class PreviewDevice {
  const PreviewDevice(
    this.name,
    this.size,
    this.insets, {
    required this.platform,
    this.screenRadius = 0,
    this.island = false,
  });

  final String name;
  final Size size;
  final EdgeInsets insets;
  final TargetPlatform platform;
  final double screenRadius;
  final bool island;
}

const previewDevices = [
  PreviewDevice(
    'iPhone 16',
    Size(393, 852),
    EdgeInsets.only(top: 59, bottom: 34),
    platform: TargetPlatform.iOS,
    screenRadius: 47,
    island: true,
  ),
  PreviewDevice('iPhone SE', Size(375, 667), EdgeInsets.only(top: 20), platform: TargetPlatform.iOS),
  PreviewDevice(
    'Small Android',
    Size(360, 740),
    EdgeInsets.only(top: 24, bottom: 16),
    platform: TargetPlatform.android,
    screenRadius: 18,
  ),
];

/// Draws the app inside a phone (bezel, status bar, Dynamic Island, home bar)
/// at the device's real size, scaled to fit the browser window. Use it as
/// `MaterialApp.builder` so dialogs and snackbars stay inside the screen.
class PhoneFrame extends StatefulWidget {
  const PhoneFrame({super.key, required this.child, required this.themeMode});
  final Widget child;
  final ValueNotifier<ThemeMode> themeMode;

  @override
  State<PhoneFrame> createState() => _PhoneFrameState();
}

class _PhoneFrameState extends State<PhoneFrame> {
  static const _bezel = 12.0;
  var _device = previewDevices[PreviewOptions.device];

  @override
  Widget build(BuildContext context) {
    final d = _device;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final phone = SizedBox(
      width: d.size.width + 2 * _bezel,
      height: d.size.height + 2 * _bezel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(d.screenRadius + _bezel),
          boxShadow: const [BoxShadow(blurRadius: 30, color: Color(0x40000000), offset: Offset(0, 12))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(_bezel),
          child: ClipRRect(borderRadius: BorderRadius.circular(d.screenRadius), child: _screen(context, d)),
        ),
      ),
    );

    return Material(
      color: dark ? const Color(0xFF2B2B2B) : const Color(0xFFE6E6E6),
      child: Column(
        children: [
          _controls(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FittedBox(child: phone),
            ),
          ),
        ],
      ),
    );
  }

  Widget _screen(BuildContext context, PreviewDevice d) {
    final mq = MediaQuery.of(context);
    final c = Theme.of(context).colorScheme;
    return MediaQuery(
      data: mq.copyWith(
        size: d.size,
        padding: d.insets,
        viewPadding: d.insets,
        viewInsets: EdgeInsets.zero,
        textScaler: TextScaler.noScaling,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(platform: d.platform),
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            // Status bar: drawn over the app, inside the top inset like on the phone.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: d.insets.top,
              child: IgnorePointer(
                child: _StatusBar(device: d, color: c.onSurface),
              ),
            ),
            if (d.island)
              Positioned(
                top: 11,
                left: (d.size.width - 126) / 2,
                child: Container(
                  width: 126,
                  height: 37,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                ),
              ),
            if (d.insets.bottom >= 20)
              Positioned(
                bottom: 8,
                left: (d.size.width - 134) / 2,
                child: IgnorePointer(
                  child: Container(
                    width: 134,
                    height: 5,
                    decoration: BoxDecoration(color: c.onSurface, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _controls(BuildContext context) {
    // What is on screen now (the starting mode follows the browser).
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final d in previewDevices)
            ChoiceChip(label: Text(d.name), selected: d == _device, onSelected: (_) => setState(() => _device = d)),
          ChoiceChip(
            avatar: Icon(dark ? Icons.dark_mode : Icons.light_mode, size: 18),
            label: Text(dark ? 'Dark' : 'Light'),
            selected: false,
            onSelected: (_) => widget.themeMode.value = dark ? ThemeMode.light : ThemeMode.dark,
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.device, required this.color});
  final PreviewDevice device;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ios = device.platform == TargetPlatform.iOS;
    final big = device.insets.top > 40;
    final style = TextStyle(
      color: color,
      fontSize: big ? 17 : 13,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none,
    );
    final iconSize = big ? 18.0 : 14.0;
    return Padding(
      // With a Dynamic Island the time and icons sit either side of it.
      padding: EdgeInsets.symmetric(horizontal: big ? 34 : 14),
      child: Row(
        children: [
          Text(ios ? '9:41' : '09:41', style: style),
          const Spacer(),
          Icon(Icons.signal_cellular_alt, size: iconSize, color: color),
          const SizedBox(width: 4),
          Icon(Icons.wifi, size: iconSize, color: color),
          const SizedBox(width: 4),
          Icon(ios ? Icons.battery_full : Icons.battery_6_bar, size: iconSize + 2, color: color),
        ],
      ),
    );
  }
}
