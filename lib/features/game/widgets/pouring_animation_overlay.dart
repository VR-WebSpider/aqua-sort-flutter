import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:aqua_sort/features/game/providers/game_provider.dart';
import 'package:aqua_sort/features/game/widgets/tube_widget.dart';
import 'package:aqua_sort/features/game/engine/game_engine.dart';
import 'package:aqua_sort/features/game/widgets/liquid_painter.dart';

import 'package:aqua_sort/core/services/audio_service.dart';

class PouringAnimationOverlay extends StatefulWidget {
  final ActivePour pour;
  final Offset startOffset;
  final Offset endOffset;
  final Tube sourceTube;
  final Tube destTube;

  const PouringAnimationOverlay({
    super.key,
    required this.pour,
    required this.startOffset,
    required this.endOffset,
    required this.sourceTube,
    required this.destTube,
  });

  @override
  State<PouringAnimationOverlay> createState() => _PouringAnimationOverlayState();
}

class _PouringAnimationOverlayState extends State<PouringAnimationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _flight;
  late Animation<double> _tilt;
  late Animation<double> _stream;

  @override
  void initState() {
    super.initState();
    // Dynamic duration: 300 (flight) + 150 (tilt) + (count * 300) (pour) + 150 (return)
    final int pourDuration = widget.pour.count * 300;
    final int totalDuration = 300 + 150 + pourDuration + 150;
    
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: totalDuration));
    
    final double d = totalDuration.toDouble();
    _flight = CurvedAnimation(parent: _ctrl, curve: Interval(0.0, 300 / d, curve: Curves.easeInOut));
    _tilt   = CurvedAnimation(parent: _ctrl, curve: Interval(300 / d, 450 / d, curve: Curves.easeIn));
    _stream = CurvedAnimation(parent: _ctrl, curve: Interval(450 / d, (450 + pourDuration) / d));

    _ctrl.forward();
    
    // Sync sound to tilt start
    Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) AudioService.instance.playPour();
    });

    // Stop sound when pouring ends
    Future.delayed(Duration(milliseconds: 450 + pourDuration), () {
        if (mounted) AudioService.instance.stopPour();
    });
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
        final p = _stream.value; // 0.0 -> 1.0 during the pour phase
        final totalToPour = widget.pour.count.toDouble();
        final currentPoured = p * totalToPour;

        // ── SOURCE/DEST LIQUID CALCULATIONS ────────────────────────────────
        final sourceBaseColors = widget.sourceTube.colors.where((c) => c >= 0).toList();
        final sourceCurrentVolume = (sourceBaseColors.length.toDouble() - currentPoured).clamp(0.0, 4.0);
        final sourceTopFill = (sourceCurrentVolume > 0 && sourceCurrentVolume % 1.0 == 0) ? 1.0 : (sourceCurrentVolume % 1.0);
        final sourceColors = sourceBaseColors.take(sourceCurrentVolume.ceil()).toList();

        final destBaseColors = widget.destTube.colors.where((c) => c >= 0).toList();
        final destCurrentVolume = (destBaseColors.length.toDouble() + currentPoured).clamp(0.0, 4.0);
        final destTopFill = (destCurrentVolume > 0 && destCurrentVolume % 1.0 == 0) ? 1.0 : (destCurrentVolume % 1.0);
        final List<int> destColors = [...destBaseColors];
        while (destColors.length < destCurrentVolume.ceil()) destColors.add(widget.pour.color);

        // ── DYNAMIC TILT LOGIC ──────────────────────────────────────────────
        final bool isLeft = widget.endOffset.dx < widget.startOffset.dx;
        final double direction = isLeft ? -1.0 : 1.0;
        final pivot = isLeft ? Alignment.topLeft : Alignment.topRight;

        // Destination spout should align with destination center (center is at +21)
        // Spout is at tube edge (0 for left, 42 for right)
        // For Right Tilt: targetPos = dest - 42 + 21 = dest - 21
        // For Left Tilt:  targetPos = dest - 0 + 21  = dest + 21
        final targetPos = widget.endOffset + Offset(isLeft ? 21 : -21, -65);
        final currentPos = Offset.lerp(widget.startOffset, targetPos, _flight.value)!;
        final double tiltAngle = _tilt.value * 1.3 * direction;
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Destination Tube
            Positioned(
              left: widget.endOffset.dx,
              top: widget.endOffset.dy,
              child: TubeWidget(
                tube: Tube(destColors),
                selected: false,
                onTap: () {},
                topLayerFill: destTopFill,
                showCap: false,
              ),
            ),

            // Liquid Stream
            if (_stream.value > 0.05 && _stream.value < 0.98)
              _buildStream(currentPos, tiltAngle, isLeft),

            // Moving Tube
            Positioned(
              left: currentPos.dx,
              top: currentPos.dy,
              child: Transform.rotate(
                angle: tiltAngle,
                alignment: pivot,
                child: TubeWidget(
                  tube: Tube(sourceColors), 
                  selected: false,
                  tilt: tiltAngle,
                  onTap: () {},
                  topLayerFill: sourceTopFill,
                  showCap: false,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStream(Offset currentPos, double tiltAngle, bool isLeft) {
    // Spout is at x=0 (left) or x=42 (right)
    final spoutX = currentPos.dx + (isLeft ? 0 : 42);
    final spoutY = currentPos.dy;
    
    // Pour into center of destination
    final destX = widget.endOffset.dx + 21;
    final destY = widget.endOffset.dy + 8;

    return CustomPaint(
      painter: _StreamPainter(
        from: Offset(spoutX, spoutY),
        to: Offset(destX, destY),
        color: kTubeColors[widget.pour.color],
        progress: _stream.value,
      ),
    );
  }
}

class _StreamPainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final Color color;
  final double progress;

  _StreamPainter({required this.from, required this.to, required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Stream thickness pulses slightly
    final thickness = 5.0 + (math.sin(progress * 20) * 1.0);

    // Main stream
    canvas.drawLine(from, to, paint..strokeWidth = thickness);
    
    // Outer Glow
    canvas.drawLine(from, to, paint
      ..color = color.withOpacity(0.4)
      ..strokeWidth = thickness + 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      
    // Inner core
    canvas.drawLine(from, to, paint
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = thickness * 0.4
      ..maskFilter = null);
  }

  @override
  bool shouldRepaint(covariant _StreamPainter oldDelegate) => true;
}
