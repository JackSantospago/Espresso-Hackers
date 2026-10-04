import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The assistant's face: a potato in a straw hat holding a hoe.
/// Drawn in code (no image files). With [animate] it bobs gently, used while
/// the assistant is thinking.
class PotatoMascot extends StatefulWidget {
  const PotatoMascot({super.key, this.size = 120, this.animate = false});
  final double size;
  final bool animate;

  @override
  State<PotatoMascot> createState() => _PotatoMascotState();
}

class _PotatoMascotState extends State<PotatoMascot> with SingleTickerProviderStateMixin {
  late final _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _bob.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PotatoMascot old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_bob.isAnimating) _bob.repeat(reverse: true);
    if (!widget.animate && _bob.isAnimating) _bob.animateTo(0);
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _bob,
    builder: (context, child) {
      final t = Curves.easeInOut.transform(_bob.value);
      return Transform.translate(
        offset: Offset(0, -widget.size * 0.04 * t),
        child: Transform.rotate(angle: (t - 0.5) * 0.08 * (widget.animate ? 1 : 0), child: child),
      );
    },
    child: CustomPaint(size: Size.square(widget.size), painter: const _PotatoPainter()),
  );
}

class _PotatoPainter extends CustomPainter {
  const _PotatoPainter();

  static const _skin = Color(0xFFD4A06A);
  static const _skinDark = Color(0xFFA8733F);
  static const _outline = Color(0xFF6B4423);
  static const _straw = Color(0xFFEBC56B);
  static const _strawDark = Color(0xFFB98B35);
  static const _band = Color(0xFF1E5A46);
  static const _wood = Color(0xFF8B5E34);
  static const _metal = Color(0xFF9AA5AE);

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 200 × 200 grid, scaled to the widget size.
    canvas.scale(size.width / 200, size.height / 200);
    final outline = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Paint fill(Color c) => Paint()..color = c;

    // Hoe handle (behind the body), then its blade.
    canvas.drawLine(
      const Offset(158, 186),
      const Offset(178, 36),
      Paint()
        ..color = _wood
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    final blade = Path()
      ..moveTo(174, 34)
      ..lineTo(198, 40)
      ..lineTo(195, 56)
      ..lineTo(177, 47)
      ..close();
    canvas
      ..drawPath(blade, fill(_metal))
      ..drawPath(blade, outline..strokeWidth = 2.5);
    outline.strokeWidth = 3;

    // Feet.
    for (final x in [82.0, 118.0]) {
      final foot = Rect.fromCenter(center: Offset(x, 186), width: 24, height: 11);
      canvas
        ..drawOval(foot, fill(_skinDark))
        ..drawOval(foot, outline);
    }

    // Left arm (waving a little).
    canvas.drawLine(const Offset(52, 128), const Offset(34, 140), outline..strokeWidth = 6);
    outline.strokeWidth = 3;

    // Body: a lumpy potato.
    final body = Path()
      ..moveTo(100, 64)
      ..cubicTo(146, 60, 160, 104, 154, 138)
      ..cubicTo(148, 172, 120, 184, 96, 182)
      ..cubicTo(62, 180, 44, 154, 47, 120)
      ..cubicTo(50, 84, 70, 65, 100, 64)
      ..close();
    canvas
      ..drawPath(
        body,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.4),
            radius: 0.9,
            colors: [Color(0xFFE6BC88), _skin, _skinDark],
            stops: [0, 0.6, 1],
          ).createShader(const Rect.fromLTWH(46, 62, 110, 122)),
      )
      ..drawPath(body, outline);

    // Potato "eyes" (the spots).
    for (final (x, y, r) in [(70.0, 150.0, 3.5), (136.0, 152.0, 3.0), (128.0, 98.0, 2.5), (62.0, 104.0, 2.5)]) {
      canvas.drawCircle(Offset(x, y), r, fill(_skinDark));
    }

    // Hands: left one, and the right one holding the hoe.
    canvas.drawLine(const Offset(150, 128), const Offset(166, 118), outline..strokeWidth = 6);
    outline.strokeWidth = 3;
    for (final c in [const Offset(32, 142), const Offset(168, 116)]) {
      canvas
        ..drawCircle(c, 7.5, fill(_skin))
        ..drawCircle(c, 7.5, outline);
    }

    // Face.
    for (final x in [86.0, 116.0]) {
      canvas
        ..drawOval(Rect.fromCenter(center: Offset(x, 114), width: 10, height: 13), fill(const Color(0xFF2B1B10)))
        ..drawCircle(Offset(x + 2, 110), 2.2, fill(Colors.white));
    }
    final cheek = fill(const Color(0x55E5736B));
    canvas
      ..drawOval(Rect.fromCenter(center: const Offset(73, 130), width: 14, height: 8), cheek)
      ..drawOval(Rect.fromCenter(center: const Offset(129, 130), width: 14, height: 8), cheek);
    final smile = Path()
      ..moveTo(89, 130)
      ..quadraticBezierTo(101, 143, 113, 130);
    canvas.drawPath(smile, outline);

    // Straw hat: brim, crown, band.
    final brim = Rect.fromCenter(center: const Offset(100, 72), width: 128, height: 26);
    canvas
      ..drawOval(brim, fill(_straw))
      ..drawOval(brim, outline..color = _strawDark);
    final crown = Path()
      ..moveTo(70, 72)
      ..cubicTo(68, 44, 82, 32, 100, 32)
      ..cubicTo(118, 32, 132, 44, 130, 72)
      ..close();
    canvas
      ..drawPath(crown, fill(_straw))
      ..drawPath(crown, outline);
    canvas.save();
    canvas.clipPath(crown);
    canvas.drawRect(const Rect.fromLTWH(60, 58, 80, 9), fill(_band));
    canvas.restore();
    // A few straw lines on the brim.
    final weave = Paint()
      ..color = _strawDark.withValues(alpha: 0.6)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final a = math.pi * (0.15 + i * 0.12);
      canvas.drawLine(
        Offset(100 + 52 * math.cos(a + math.pi), 72 + 9 * math.sin(a)),
        Offset(100 + 60 * math.cos(a + math.pi), 72 + 11 * math.sin(a)),
        weave,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
