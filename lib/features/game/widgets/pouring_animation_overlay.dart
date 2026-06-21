import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:aqua_sort/features/game/providers/game_provider.dart';
import 'package:aqua_sort/features/game/widgets/tube_widget.dart';
import 'package:aqua_sort/features/game/engine/game_engine.dart';

import 'package:audioplayers/audioplayers.dart';

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
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    // Dynamic duration: 300 (flight) + 150 (tilt) + (count * 300) (pour) + 150 (return)
    final int pourDuration = math.max(500, widget.pour.count * 300);
    final int totalDuration = 300 + 150 + pourDuration + 150;
    
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: totalDuration));
    
    final double d = totalDuration.toDouble();
    _flight = CurvedAnimation(parent: _ctrl, curve: Interval(0.0, 300 / d, curve: Curves.easeInOut));
    _tilt   = CurvedAnimation(parent: _ctrl, curve: Interval(300 / d, 450 / d, curve: Curves.easeIn));
    _stream = CurvedAnimation(parent: _ctrl, curve: Interval(450 / d, (450 + pourDuration) / d));

    bool hasStartedPourSound = false;

    _ctrl.addListener(() {
      // Trigger sound when tilting reaches 80% (when liquid starts spilling)
      if (!hasStartedPourSound && _tilt.value > 0.8) {
        AudioService.instance.playPour().then((player) {
          _audioPlayer = player;
        });
        hasStartedPourSound = true;
      }
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    AudioService.instance.stopPour(_audioPlayer);
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
        while (sourceColors.length < 4) sourceColors.add(-1);

        final destBaseColors = widget.destTube.colors.where((c) => c >= 0).toList();
        final destCurrentVolume = (destBaseColors.length.toDouble() + currentPoured).clamp(0.0, 4.0);
        final destTopFill = (destCurrentVolume > 0 && destCurrentVolume % 1.0 == 0) ? 1.0 : (destCurrentVolume % 1.0);
        final List<int> destColors = [...destBaseColors];
        while (destColors.length < destCurrentVolume.ceil()) destColors.add(widget.pour.color);
        while (destColors.length < 4) destColors.add(-1);

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
              key: const ValueKey('dest_tube_wrapper'),
              left: widget.endOffset.dx,
              top: widget.endOffset.dy,
              child: TubeWidget(
                key: const ValueKey('dest_tube'),
                tube: Tube(destColors),
                selected: false,
                onTap: () {},
                topLayerFill: destTopFill,
                showCap: false,
                isReceiving: _stream.value > 0.0 && _stream.value < 1.0,
              ),
            ),

            // Liquid Stream
            if (_stream.value > 0.0 && _stream.value < 1.0)
              _buildStream(currentPos, tiltAngle, isLeft, destCurrentVolume),

            // Moving Tube
            Positioned(
              key: const ValueKey('source_tube_wrapper'),
              left: currentPos.dx,
              top: currentPos.dy,
              child: Transform.rotate(
                angle: tiltAngle,
                alignment: pivot,
                child: TubeWidget(
                  key: const ValueKey('source_tube'),
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

  Widget _buildStream(Offset currentPos, double tiltAngle, bool isLeft, double destCurrentVolume) {
    // Spout is at x=0 (left) or x=42 (right)
    final spoutX = currentPos.dx + (isLeft ? 0 : 42);
    final spoutY = currentPos.dy;
    
    // Pour into center of destination
    final destX = widget.endOffset.dx + 21;
    
    // The stream goes all the way down to the destination liquid surface!
    const double h = 130.0;
    final double destLiquidY = widget.endOffset.dy + h - (destCurrentVolume * (h / 4.0));
    // Clamp so it stays within the tube body and doesn't overshoot the bottom curve
    final destY = destLiquidY.clamp(widget.endOffset.dy + 10.4, widget.endOffset.dy + h - 3.0);

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
    // 1. Draw a clean, straight glowing outer border (soft glow)
    final Paint glowPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    
    canvas.drawLine(from, to, glowPaint);

    // 2. Draw the solid central vertical stream
    final Paint streamPaint = Paint()
      ..color = color
      ..strokeWidth = 4.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(from, to, streamPaint);

    // 3. Draw a thin, glossy core reflection on the stream
    final Paint corePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(from, to, corePaint);

    // 4. Draw splash/repulsion particles at the impact point (to)
    final math.Random rand = math.Random(1337);
    final Paint particlePaint = Paint()..style = PaintingStyle.fill;
    
    for (int i = 0; i < 12; i++) {
      final double phase = (progress * 8.0 + (i / 12.0)) % 1.0;
      final double angle = -math.pi / 2 + (rand.nextDouble() - 0.5) * 1.5;
      final double speed = 4.0 + rand.nextDouble() * 6.0;
      
      final double px = to.dx + math.cos(angle) * speed * phase * 12;
      final double py = to.dy + math.sin(angle) * speed * phase * 14 + 0.5 * 25.0 * phase * phase;
      
      final double size = (rand.nextDouble() * 2.8 + 1.0) * (1.0 - phase);
      if (size > 0.1) {
        particlePaint.color = color.withOpacity((1.0 - phase) * 0.85);
        canvas.drawCircle(Offset(px, py), size, particlePaint);
        canvas.drawCircle(Offset(px, py), size * 0.45, Paint()..color = Colors.white.withOpacity((1.0 - phase) * 0.95));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StreamPainter oldDelegate) => true;
}
