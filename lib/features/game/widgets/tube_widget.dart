import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:aqua_sort/features/game/engine/game_engine.dart';
import 'package:aqua_sort/features/game/widgets/liquid_painter.dart';

/// Draws a single test tube with stacked colored water layers and realistic wobble effects.
class TubeWidget extends StatefulWidget {
  final Tube tube;
  final bool selected;
  final double tilt;
  final double topLayerFill;
  final bool showCap;
  final VoidCallback onTap;

  const TubeWidget({
    super.key, 
    required this.tube, 
    required this.selected, 
    required this.onTap,
    this.tilt = 0.0,
    this.topLayerFill = 1.0,
    this.showCap = true,
  });

  @override
  State<TubeWidget> createState() => _TubeWidgetState();
}

class _TubeWidgetState extends State<TubeWidget> with TickerProviderStateMixin {
  late final AnimationController _sel = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200));
  late final Animation<double> _lift = Tween(begin: 0.0, end: -14.0).animate(
      CurvedAnimation(parent: _sel, curve: Curves.easeOut));

  // Wobble animation for liquid settling
  late final AnimationController _wobbleCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));
  late final Animation<double> _wobble = SineCurve()
      .animate(CurvedAnimation(parent: _wobbleCtrl, curve: Curves.elasticOut));

  // Shake animation for invalid moves
  late final AnimationController _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350));
  late final Animation<double> _shake = ShakeCurve()
      .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.linear));

  void shake() {
    _shakeCtrl.forward(from: 0.0);
  }

  @override
  void didUpdateWidget(TubeWidget old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected) {
      widget.selected ? _sel.forward() : _sel.reverse();
    }
    // Trigger wobble if tube content changed (pour)
    if (widget.tube != old.tube) {
      _wobbleCtrl.forward(from: 0.0);
      
      // Trigger solved celebration if it just became solved AND full
      if (widget.tube.isSolved && !widget.tube.isEmpty && !old.tube.isSolved) {
          _triggerSolvedEffect();
      }
    }
  }

  void _triggerSolvedEffect() {
    // We can add a sound or a small "pop" overlay here
    debugPrint('Tube Solved!');
  }

  @override
  void dispose() { _sel.dispose(); _wobbleCtrl.dispose(); _shakeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = widget.tube.colors
        .where((c) => c >= 0)
        .map((c) => kTubeColors[c % kTubeColors.length])
        .toList();

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_lift, _wobble, _shake]),
        builder: (_, __) => Transform.translate(
          offset: Offset(_shake.value * 6, _lift.value),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                painter: _TubePainter(
                  tube: widget.tube, 
                  selected: widget.selected,
                  wobble: _wobble.value,
                  tilt: widget.tilt,
                  topLayerFill: widget.topLayerFill,
                  showCap: widget.showCap,
                  colors: colors,
                ),
                size: const Size(42, 130),
              ),
              // Solved sparkle effect
              if (widget.showCap && widget.tube.isSolved && !widget.tube.isEmpty && widget.tilt == 0 && widget.topLayerFill == 1.0)
                Positioned(
                  top: -20, left: 10,
                  child: _SparkleEffect(color: colors.last),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShakeCurve extends Animatable<double> {
  @override
  double transform(double t) {
    return math.sin(t * 3 * math.pi * 2);
  }
}

class SineCurve extends Animatable<double> {
  @override
  double transform(double t) {
    return math.sin(t * 5 * math.pi) * (1 - t);
  }
}

class _TubePainter extends CustomPainter {
  final Tube tube;
  final bool selected;
  final double wobble;
  final double tilt;
  final double topLayerFill;
  final bool showCap;
  final List<Color> colors;
  
  const _TubePainter({
    required this.tube, 
    required this.selected, 
    required this.wobble,
    required this.tilt,
    required this.topLayerFill,
    required this.showCap,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = w / 2;
    final lipH = h * 0.08;
    final bodyH = h - lipH;
    final slotH = bodyH / Tube.slots;

    // ── Tube body path ─────────────────────────────────────────────
    final tubePath = Path()
      ..moveTo(0, lipH) ..lineTo(0, h - r)
      ..arcToPoint(Offset(w, h - r), radius: Radius.circular(r), clockwise: false)
      ..lineTo(w, lipH) ..close();

    // ── Clip and draw liquid using LiquidPainter logic ────────────────
    canvas.save();
    canvas.clipPath(tubePath);

    // Dark empty background
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFF0D1F2D));

    // Delegate to LiquidPainter for the wavy surface
    final liquidPainter = LiquidPainter(
      colors: colors,
      wobble: wobble,
      tilt: tilt,
      topLayerFill: topLayerFill,
      capacity: Tube.slots,
    );
    liquidPainter.paint(canvas, size);

    // Inner shine override (re-applied over wavy liquid)
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.15, lipH + 4)
        ..quadraticBezierTo(w * 0.08, h * 0.55, w * 0.18, h * 0.75)
        ..lineTo(w * 0.30, h * 0.75)
        ..quadraticBezierTo(w * 0.25, h * 0.52, w * 0.28, lipH + 4)
        ..close(),
      Paint()..color = Colors.white.withOpacity(0.12),
    );
    canvas.restore();

    // ── Glow when selected ─────────────────────────────────────────
    if (selected) {
      canvas.drawPath(tubePath,
          Paint()
            ..style = PaintingStyle.stroke ..strokeWidth = 10
            ..color = const Color(0xFF00E5FF).withOpacity(0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8));
    }

    // ── Border ─────────────────────────────────────────────────────
    canvas.drawPath(tubePath,
        Paint()
          ..style = PaintingStyle.stroke ..strokeWidth = selected ? 2.0 : 1.5
          ..color = selected
              ? const Color(0xFF00E5FF)
              : Colors.white.withOpacity(0.45));

    // ── Lip ────────────────────────────────────────────────────────
    canvas.drawLine(Offset(0, lipH), Offset(w, lipH),
        Paint()..color = Colors.white.withOpacity(0.4) ..strokeWidth = 2);

    // ── Cap (Only if solved, full, and active) ──────────
    if (showCap && tube.isSolved && !tube.isEmpty && tilt == 0 && topLayerFill == 1.0) {
      _drawCap(canvas, size, lipH);
    }
  }

  void _drawCap(Canvas canvas, Size size, double lipH) {
    final w = size.width;
    final capH = lipH * 1.2;
    
    final capPath = Path()
      ..moveTo(-2, lipH + 2)
      ..lineTo(w + 2, lipH + 2)
      ..lineTo(w + 2, lipH - capH)
      ..quadraticBezierTo(w/2, lipH - capH - 8, -2, lipH - capH)
      ..close();

    // Metallic Gradient
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF455A64), const Color(0xFF90A4AE), const Color(0xFF37474F)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, lipH));

    canvas.drawPath(capPath, paint);
    
    // Cyber detail
    canvas.drawPath(capPath, Paint()..color = Colors.white24 ..style = PaintingStyle.stroke ..strokeWidth = 1);
    canvas.drawCircle(Offset(w/2, lipH - capH/2), 3, Paint()..color = const Color(0xFF00E5FF).withOpacity(0.8));
  }

  @override
  bool shouldRepaint(_TubePainter old) =>
      old.tube != tube || old.selected != selected || old.wobble != wobble;
}

class _SparkleEffect extends StatefulWidget {
  final Color color;
  const _SparkleEffect({required this.color});
  @override
  State<_SparkleEffect> createState() => _SparkleEffectState();
}

class _SparkleEffectState extends State<_SparkleEffect> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _SparklePainter(_ctrl.value, widget.color),
        size: const Size(30, 30),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double progress;
  final Color color;
  _SparklePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42);
    final paint = Paint()..color = Colors.white;
    
    for (int i = 0; i < 5; i++) {
        final double t = (progress + (i / 5)) % 1.0;
        final double radius = t * 15;
        final double angle = rand.nextDouble() * math.pi * 2;
        final double x = size.width / 2 + math.cos(angle) * radius;
        final double y = size.height / 2 + math.sin(angle) * radius;
        
        paint.color = color.withOpacity((1 - t) * 0.8);
        canvas.drawCircle(Offset(x, y), (1 - t) * 2.5, paint);
    }
  }
  @override bool shouldRepaint(_SparklePainter old) => old.progress != progress;
}
