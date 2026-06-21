import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:aqua_sort/features/game/engine/game_engine.dart';
import 'package:aqua_sort/features/game/widgets/liquid_painter.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/core/services/audio_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';

/// Draws a single test tube with stacked colored water layers and realistic wobble effects.
class TubeWidget extends ConsumerStatefulWidget {
  final Tube tube;
  final bool selected;
  final double tilt;
  final double topLayerFill;
  final bool showCap;
  final VoidCallback onTap;
  final bool isReceiving;

  const TubeWidget({
    super.key, 
    required this.tube, 
    required this.selected, 
    required this.onTap,
    this.tilt = 0.0,
    this.topLayerFill = 1.0,
    this.showCap = true,
    this.isReceiving = false,
  });

  @override
  ConsumerState<TubeWidget> createState() => _TubeWidgetState();
}

class _TubeWidgetState extends ConsumerState<TubeWidget> with TickerProviderStateMixin {
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

  // Idle animation for continuous fluid wave
  late final AnimationController _idleCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 4))..repeat();

  late final AnimationController _capCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350));
  
  bool _showBurst = false;

  void shake() {
    _shakeCtrl.forward(from: 0.0);
  }

  @override
  void initState() {
    super.initState();
    if (widget.tube.isSolved && !widget.tube.isEmpty) {
      _capCtrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(TubeWidget old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected) {
      widget.selected ? _sel.forward() : _sel.reverse();
    }
    


    // Compare color lists to see if actual content changed
    bool colorsChanged = false;
    for (int i = 0; i < 4; i++) {
      if (widget.tube.colors[i] != old.tube.colors[i]) {
        colorsChanged = true;
        break;
      }
    }

    // Wobble only when not receiving (settling down) or when receiving stops
    final bool stoppedReceiving = !widget.isReceiving && old.isReceiving;
    if ((colorsChanged && !widget.isReceiving) || stoppedReceiving) {
      _wobbleCtrl.forward(from: 0.0);
    }

    if (colorsChanged) {
      // Trigger solved celebration if it just became solved AND full AND showCap is enabled
      if (widget.showCap && widget.tube.isSolved && !widget.tube.isEmpty && (!old.tube.isSolved || old.tube.isEmpty)) {
        _triggerSolvedEffect();
      } else if ((!widget.tube.isSolved || widget.tube.isEmpty) && (old.tube.isSolved && !old.tube.isEmpty)) {
        _capCtrl.value = 0.0;
      }
    }
  }

  void _triggerSolvedEffect() {
    setState(() {
      _showBurst = true;
    });

    _capCtrl.forward(from: 0.0);

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted && widget.tube.isSolved && !widget.tube.isEmpty) {
        AudioService.instance.playLidClosing();
      }
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _showBurst = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _sel.dispose();
    _wobbleCtrl.dispose();
    _shakeCtrl.dispose();
    _idleCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeSkinId = ref.watch(levelProvider.select((p) => p.activeSkinId));
    
    final rawColors = widget.tube.colors.where((c) => c >= 0).toList();
    final List<Color> colors = [];
    
    for (int i = 0; i < rawColors.length; i++) {
        if (widget.tube.isMystery && i < rawColors.length - 1) {
            // "Frosted Fog" mystery effect
            colors.add(const Color(0xFF101C26).withOpacity(0.85)); 
        } else {
            colors.add(kTubeColors[rawColors[i] % kTubeColors.length]);
        }
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_lift, _wobble, _shake, _idleCtrl, _capCtrl]),
        builder: (_, __) {
          // Add visual repulsion high-frequency vibration jitter if receiving liquid
          double jitterX = 0.0;
          double jitterY = 0.0;
          if (widget.isReceiving) {
            final double t = DateTime.now().millisecondsSinceEpoch / 18.0;
            jitterX = math.sin(t) * 0.8;
            jitterY = math.cos(t * 1.35) * 0.6;
          }

          return Transform.translate(
            offset: Offset(_shake.value * 6 + jitterX, _lift.value + jitterY),
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
                    activeSkinId: activeSkinId,
                    idleValue: _idleCtrl.value,
                    isReceiving: widget.isReceiving,
                    capProgress: _capCtrl.value,
                  ),
                  size: const Size(42, 130),
                ),
                // Solved sparkle effect (only show after cap closes)
                if (widget.showCap && widget.tube.isSolved && !widget.tube.isEmpty && widget.tilt == 0 && widget.topLayerFill == 1.0 && _capCtrl.value == 1.0)
                  Positioned(
                    top: -20, left: 10,
                    child: _SparkleEffect(color: colors.last),
                  ),
                // Solved burst particle effect
                if (_showBurst)
                  Positioned(
                    top: -120,
                    left: -39,
                    child: _SolvedBurstEffect(color: colors.last),
                  ),
              ],
            ),
          );
        },
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
  final String activeSkinId;
  final double idleValue;
  final bool isReceiving;
  final double capProgress;
  
  const _TubePainter({
    required this.tube, 
    required this.selected, 
    required this.wobble,
    required this.tilt,
    required this.topLayerFill,
    required this.showCap,
    required this.colors,
    required this.activeSkinId,
    required this.idleValue,
    required this.isReceiving,
    required this.capProgress,
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
      idleValue: idleValue,
      isReceiving: isReceiving,
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
    Color borderColor = Colors.white.withOpacity(0.45);
    Color glowColor = const Color(0xFF00E5FF);
    
    switch (activeSkinId) {
       case 'cyber_neon': 
          borderColor = AppColors.cyanGlow.withOpacity(0.6);
          glowColor = AppColors.cyanGlow;
          break;
       case 'toxic_slime':
          borderColor = Colors.greenAccent.withOpacity(0.6);
          glowColor = Colors.greenAccent;
          break;
       case 'solar_flare':
          borderColor = Colors.orangeAccent.withOpacity(0.6);
          glowColor = Colors.orangeAccent;
          break;
       case 'void_matter':
          borderColor = Colors.purpleAccent.withOpacity(0.6);
          glowColor = Colors.purpleAccent;
          break;
    }

    if (selected) {
      canvas.drawPath(tubePath,
          Paint()
            ..style = PaintingStyle.stroke ..strokeWidth = 10
            ..color = glowColor.withOpacity(0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8));
    }

    // ── Border ─────────────────────────────────────────────────────
    canvas.drawPath(tubePath,
        Paint()
          ..style = PaintingStyle.stroke ..strokeWidth = selected ? 2.0 : 1.5
          ..color = selected ? glowColor : borderColor);

    // ── Lip ────────────────────────────────────────────────────────
    canvas.drawLine(Offset(0, lipH), Offset(w, lipH),
        Paint()..color = Colors.white.withOpacity(0.4) ..strokeWidth = 2);

    // ── Cap (Only if solved, full, and active) ──────────
    if (showCap && tube.isSolved && !tube.isEmpty && tilt == 0 && topLayerFill == 1.0) {
      _drawCap(canvas, size, lipH, colors.last, capProgress);
    }
  }

  void _drawCap(Canvas canvas, Size size, double lipH, Color liquidColor, double progress) {
    final w = size.width;
    final capH = lipH * 1.2;
    
    final double offsetY = -20.0 * (1.0 - progress);
    final double opacity = progress.clamp(0.0, 1.0);
    
    final capPath = Path()
      ..moveTo(-2, lipH + 2 + offsetY)
      ..lineTo(w + 2, lipH + 2 + offsetY)
      ..lineTo(w + 2, lipH - capH + offsetY)
      ..quadraticBezierTo(w/2, lipH - capH - 8 + offsetY, -2, lipH - capH + offsetY)
      ..close();

    // Metallic Gradient
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF455A64).withOpacity(opacity), 
          const Color(0xFF90A4AE).withOpacity(opacity), 
          const Color(0xFF37474F).withOpacity(opacity)
        ],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, offsetY, w, lipH));

    canvas.drawPath(capPath, paint);
    
    // Cyber detail
    canvas.drawPath(
      capPath, 
      Paint()
        ..color = Colors.white24.withOpacity(opacity * 0.24) 
        ..style = PaintingStyle.stroke 
        ..strokeWidth = 1
    );
    canvas.drawCircle(
      Offset(w/2, lipH - capH/2 + offsetY), 
      3, 
      Paint()..color = liquidColor.withOpacity(opacity * 0.8)
    );
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

// ── Solved burst particles celebration effect ────────────────────

class _Particle {
  final double dx;
  final double dy;
  final double size;
  final double rotationSpeed;
  final Color color;
  final double delay;

  _Particle({
    required this.dx,
    required this.dy,
    required this.size,
    required this.rotationSpeed,
    required this.color,
    required this.delay,
  });
}

class _SolvedBurstEffect extends StatefulWidget {
  final Color color;
  const _SolvedBurstEffect({required this.color});

  @override
  State<_SolvedBurstEffect> createState() => _SolvedBurstEffectState();
}

class _SolvedBurstEffectState extends State<_SolvedBurstEffect> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    
    final rand = math.Random();
    for (int i = 0; i < 18; i++) {
      final double angle = -math.pi / 2 + (rand.nextDouble() - 0.5) * 0.9;
      final double speed = 3.5 + rand.nextDouble() * 5.0;
      _particles.add(_Particle(
        dx: math.cos(angle) * speed,
        dy: math.sin(angle) * speed,
        size: 3.0 + rand.nextDouble() * 4.5,
        rotationSpeed: (rand.nextDouble() - 0.5) * 4.0,
        color: rand.nextDouble() > 0.35 ? widget.color : Colors.white,
        delay: rand.nextDouble() * 0.15,
      ));
    }

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _BurstPainter(progress: _ctrl.value, particles: _particles),
          size: const Size(120, 150),
        );
      },
    );
  }
}

class _BurstPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  _BurstPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final double centerX = size.width / 2;
    final double centerY = size.height - 20;

    for (final p in particles) {
      if (progress < p.delay) continue;
      
      final double t = (progress - p.delay) / (1.0 - p.delay);
      if (t <= 0.0 || t >= 1.0) continue;

      final double x = centerX + p.dx * t * 15;
      final double y = centerY + p.dy * t * 25 + 0.5 * 18 * t * t;

      final double alpha = (1.0 - t).clamp(0.0, 1.0);
      paint.color = p.color.withOpacity(alpha);
      
      if (p.size > 5.2) {
        final double s = p.size * (1.0 - t * 0.5);
        final Path starPath = Path()
          ..moveTo(x, y - s)
          ..lineTo(x + s * 0.3, y - s * 0.3)
          ..lineTo(x + s, y)
          ..lineTo(x + s * 0.3, y + s * 0.3)
          ..lineTo(x, y + s)
          ..lineTo(x - s * 0.3, y + s * 0.3)
          ..lineTo(x - s, y)
          ..lineTo(x - s * 0.3, y - s * 0.3)
          ..close();
        canvas.drawPath(starPath, paint);
      } else {
        canvas.drawCircle(Offset(x, y), p.size * (1.0 - t * 0.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) => true;
}
