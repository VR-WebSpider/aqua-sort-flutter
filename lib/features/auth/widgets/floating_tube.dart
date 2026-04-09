import 'package:flutter/material.dart';

/// Holographic rainbow test-tube drawn with CustomPainter.
class FloatingTube extends StatelessWidget {
  final double height;
  final List<Color> colors;
  final double fill; // 0–1

  const FloatingTube({super.key, required this.height, required this.colors, this.fill = 0.72});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _TubePainter(colors, fill), size: Size(height * 0.3, height));
}

class _TubePainter extends CustomPainter {
  final List<Color> colors;
  final double fill;
  const _TubePainter(this.colors, this.fill);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, r = w / 2;
    final lip = h * 0.10;

    // ── tube shape ──────────────────────────────────────
    final tube = Path()
      ..moveTo(0, lip) ..lineTo(0, h - r)
      ..arcToPoint(Offset(w, h - r), radius: Radius.circular(r), clockwise: false)
      ..lineTo(w, lip) ..close();

    // clip then fill liquid
    canvas.save();
    canvas.clipPath(tube);

    // dark empty top
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * (1 - fill)),
        Paint()..color = const Color(0xFF041520).withOpacity(0.9));

    // liquid gradient
    canvas.drawRect(
      Rect.fromLTWH(0, h * (1 - fill), w, h * fill),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // shine highlight
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.15, lip + 4)
        ..quadraticBezierTo(w * 0.08, h * 0.45, w * 0.18, h * 0.7)
        ..lineTo(w * 0.30, h * 0.7)
        ..quadraticBezierTo(w * 0.25, h * 0.42, w * 0.28, lip + 4)
        ..close(),
      Paint()..color = Colors.white.withOpacity(0.22),
    );
    canvas.restore();

    // outer glow
    canvas.drawPath(tube,
        Paint()
          ..style = PaintingStyle.stroke ..strokeWidth = 8
          ..color = colors.first.withOpacity(0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10));

    // border
    canvas.drawPath(tube,
        Paint()..style = PaintingStyle.stroke ..strokeWidth = 1.5 ..color = Colors.white.withOpacity(0.55));

    // lip cap
    canvas.drawLine(Offset(0, lip), Offset(w, lip),
        Paint()..color = Colors.white.withOpacity(0.45) ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_TubePainter old) => old.fill != fill || old.colors != colors;
}
