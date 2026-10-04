import 'package:flutter/material.dart';

import 'open_link.dart';
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
    this.keyboard = 300,
  });

  final String name;
  final Size size;
  final EdgeInsets insets;
  final TargetPlatform platform;
  final double screenRadius;
  final bool island;

  /// Height of the on-screen keyboard (with its suggestion bar) on this phone.
  final double keyboard;
}

const previewDevices = [
  PreviewDevice(
    'iPhone', // iPhone 16
    Size(393, 852),
    EdgeInsets.only(top: 59, bottom: 34),
    platform: TargetPlatform.iOS,
    screenRadius: 47,
    island: true,
    keyboard: 336,
  ),
  PreviewDevice(
    'Android', // a small Android phone
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

  /// A text field has focus, so the phone would show its keyboard.
  bool _typing = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocus);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() {
    final typing = FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null;
    if (typing != _typing && mounted) setState(() => _typing = typing);
  }

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
      color: dark ? const Color(0xFF2B2B2B) : const Color(0xFFECEBE7),
      child: Column(
        children: [
          _controls(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: FittedBox(child: phone),
            ),
          ),
          const _DemoNote(),
        ],
      ),
    );
  }

  Widget _screen(BuildContext context, PreviewDevice d) {
    final mq = MediaQuery.of(context);
    final c = Theme.of(context).colorScheme;
    return MediaQuery(
      // With the keyboard up the app sees it as a bottom inset, like on the phone.
      data: mq.copyWith(
        size: d.size,
        padding: _typing ? d.insets.copyWith(bottom: 0) : d.insets,
        viewPadding: d.insets,
        viewInsets: EdgeInsets.only(bottom: _typing ? d.keyboard : 0),
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
            if (_typing)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: d.keyboard,
                child: _Keyboard(device: d, dark: Theme.of(context).brightness == Brightness.dark),
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

/// Under the phone: this online preview has no AI model, the app does.
class _DemoNote extends StatelessWidget {
  const _DemoNote();

  static const _readme = 'https://github.com/JackSantospago/Espresso-Hackers#readme';

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          decoration: BoxDecoration(color: c.tertiaryContainer, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(Icons.info_outline, color: c.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This is a simplified online version that does not have access to the AI model and only serves '
                'demonstration purposes. If you want the full capabilities, please download the app. '
                'Instructions are in the README.',
                style: t.bodySmall?.copyWith(color: c.onTertiaryContainer),
              ),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: () => openLink(_readme),
              style: TextButton.styleFrom(foregroundColor: c.onTertiaryContainer),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('README'),
            ),
          ]),
        ),
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

/// A drawing of the phone's keyboard, so the preview shows the real layout
/// while typing. You type with the computer keyboard; "return" hides it.
class _Keyboard extends StatelessWidget {
  const _Keyboard({required this.device, required this.dark});
  final PreviewDevice device;
  final bool dark;

  static const _rows = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF2B2B2D) : const Color(0xFFD3D6DC);
    final key = dark ? const Color(0xFF6B6B6E) : Colors.white;
    final special = dark ? const Color(0xFF47474A) : const Color(0xFFAEB3BC);
    final ink = dark ? Colors.white : Colors.black;
    final homeArea = device.insets.bottom >= 20;
    TextStyle label(double size) =>
        TextStyle(color: ink, fontSize: size, decoration: TextDecoration.none, fontWeight: FontWeight.w400);

    Widget cap(Widget child, {Color? color, int flex = 10}) => Expanded(
          flex: flex,
          child: Container(
            height: 42,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color ?? key,
              borderRadius: BorderRadius.circular(5),
              boxShadow: const [BoxShadow(color: Color(0x55000000), offset: Offset(0, 1))],
            ),
            child: child,
          ),
        );
    Widget letters(String row) => Row(children: [for (final ch in row.split('')) cap(Text(ch, style: label(22)))]);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // taps on the keyboard never reach the app below
      child: Container(
        color: bg,
        child: Column(children: [
          // Suggestion bar.
          SizedBox(
            height: 44,
            child: Row(children: [
              for (final (i, w) in ['I', 'The', 'My'].indexed) ...[
                if (i > 0) Container(width: 1, height: 24, color: special),
                Expanded(child: Center(child: Text(w, style: label(16)))),
              ],
            ]),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                letters(_rows[0]),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: letters(_rows[1])),
                Row(children: [
                  cap(Icon(Icons.arrow_upward_rounded, color: ink, size: 22), color: special, flex: 14),
                  const SizedBox(width: 8),
                  for (final ch in _rows[2].split('')) cap(Text(ch, style: label(22))),
                  const SizedBox(width: 8),
                  cap(Icon(Icons.backspace_outlined, color: ink, size: 20), color: special, flex: 14),
                ]),
                Row(children: [
                  cap(Text('123', style: label(16)), color: special, flex: 24),
                  cap(Text('space', style: label(16)), flex: 60),
                  Expanded(
                    flex: 24,
                    child: GestureDetector(
                      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                      child: Row(children: [cap(Text('return', style: label(16)), color: special)]),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
          if (homeArea)
            SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Row(children: [
                  Icon(Icons.language_rounded, color: ink.withValues(alpha: 0.7), size: 24),
                  const Spacer(),
                  Icon(Icons.mic_none_rounded, color: ink.withValues(alpha: 0.7), size: 24),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}
