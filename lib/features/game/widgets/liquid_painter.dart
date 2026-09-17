import 'dart:math' as math;
import 'package:flutter/material.dart';

class LiquidSegment {
  final Color color;
  final int startIdx; // inclusive bottom layer index
  final int endIdx;   // inclusive top layer index
  LiquidSegment({required this.color, required this.startIdx, required this.endIdx});
}

class LiquidPainter extends CustomPainter {
  final List<Color> colors;
  final double wobble; // Current displacement of the wave (-1.0 to 1.0)
  final double tilt;   // Tilt angle of the surface
  final double topLayerFill; // 0.0 to 1.0 (0.0=empty segment, 1.0=full segment)
  final int capacity;
  final double idleValue; // 0.0 to 1.0 continuous value for idle wave flow
  final bool isReceiving; // whether the tube is receiving liquid

  LiquidPainter({
    required this.colors,
    required this.wobble,
    this.tilt = 0.0,
    this.topLayerFill = 1.0,
    this.capacity = 4,
    this.idleValue = 0.0,
    this.isReceiving = false,
  });

  // Groups adjacent identical colors so they blend/merge seamlessly
  List<LiquidSegment> _groupColors(List<Color> colors) {
    if (colors.isEmpty) return [];
    
    final List<LiquidSegment> segments = [];
    Color currentColor = colors[0];
    int startIdx = 0;
    
    for (int i = 1; i < colors.length; i++) {
      if (colors[i] != currentColor) {
        segments.add(LiquidSegment(color: currentColor, startIdx: startIdx, endIdx: i - 1));
        currentColor = colors[i];
        startIdx = i;
      }
    }
    segments.add(LiquidSegment(color: currentColor, startIdx: startIdx, endIdx: colors.length - 1));
    return segments;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;

    final double layerHeight = size.height / capacity;
    final double w = size.width;
    final double h = size.height;

    final double timePhase = idleValue * 2 * math.pi;
    final double waveFreq = 2 * math.pi / w; // Exactly one wave cycle across tube width

    final List<LiquidSegment> segments = _groupColors(colors);

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final Color color = seg.color;
      final bool isTop = (seg.endIdx == colors.length - 1);
      
      final double currentLayerHeight = isTop 
          ? layerHeight * topLayerFill 
          : layerHeight;
          
      final double topY = h - (seg.endIdx * layerHeight) - currentLayerHeight;
      final double bottomY = h - (seg.startIdx * layerHeight);

      // Specular 3D cylinder gradient with vibrant aquatic illumination
      final Paint paint = Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(color, Colors.black, 0.14)!, 
            color,                                   
            Color.lerp(color, Colors.white, 0.35)!,  
            color,                                   
            Color.lerp(color, Colors.black, 0.10)!, 
          ],
          stops: const [0.0, 0.22, 0.36, 0.68, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTRB(-w / 2, 0, w / 2, h))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(w / 2, 0);

      final Path layerPath = Path();
      const int steps = 36;
      final double stepWidth = w / steps;

      // 1. Top boundary with dynamic dual-harmonic wave meniscus
      if (isTop) {
        for (int j = 0; j <= steps; j++) {
          final double x = -w / 2 + (j * stepWidth);
          final double normX = x / (w / 2);
          
          final double meniscusY = -3.5 * math.pow(normX, 4);
          final double idleWave = math.sin(x * waveFreq + timePhase) * 1.6 + math.cos(x * waveFreq * 2.0 - timePhase * 1.5) * 0.4;
          final double wobbleWave = math.sin(x * waveFreq * 1.2 + wobble * 5.0) * 4.5 * wobble;
          final double ripple = isReceiving
              ? math.sin(x.abs() * 0.50 - timePhase * 4.0) * 4.0 / (1.0 + x.abs() * 0.08)
              : 0.0;

          final double y = topY - math.tan(tilt) * x + idleWave + wobbleWave + meniscusY + ripple;

          if (j == 0) {
            layerPath.moveTo(x, y);
          } else {
            layerPath.lineTo(x, y);
          }
        }
      } else {
        layerPath.moveTo(-w / 2, topY - math.tan(tilt) * (-w / 2));
        layerPath.lineTo(w / 2, topY - math.tan(tilt) * (w / 2));
      }

      // 2. Bottom boundary
      if (seg.startIdx == 0) {
        layerPath.lineTo(w / 2, h + 20);
        layerPath.lineTo(-w / 2, h + 20);
      } else {
        layerPath.lineTo(w / 2, bottomY - math.tan(tilt) * (w / 2));
        layerPath.lineTo(-w / 2, bottomY - math.tan(tilt) * (-w / 2));
      }

      layerPath.close();
      canvas.drawPath(layerPath, paint);

      // 3. Glowing top surface shimmer outline
      if (isTop) {
        final Paint surfacePaint = Paint()
          ..color = Colors.white.withOpacity(0.42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;

        final Path surfacePath = Path();
        for (int j = 0; j <= steps; j++) {
          final double x = -w / 2 + (j * stepWidth);
          final double normX = x / (w / 2);
          final double meniscusY = -3.5 * math.pow(normX, 4);
          final double idleWave = math.sin(x * waveFreq + timePhase) * 1.6 + math.cos(x * waveFreq * 2.0 - timePhase * 1.5) * 0.4;
          final double wobbleWave = math.sin(x * waveFreq * 1.2 + wobble * 5.0) * 4.5 * wobble;
          final double ripple = isReceiving
              ? math.sin(x.abs() * 0.50 - timePhase * 4.0) * 4.0 / (1.0 + x.abs() * 0.08)
              : 0.0;

          final double y = topY - math.tan(tilt) * x + idleWave + wobbleWave + meniscusY + ripple;

          if (j == 0) {
            surfacePath.moveTo(x, y);
          } else {
            surfacePath.lineTo(x, y);
          }
        }
        canvas.drawPath(surfacePath, surfacePaint);

        // 4. Splash & Foam particles at fluid impact point
        if (isReceiving) {
          final math.Random splashRand = math.Random(DateTime.now().millisecondsSinceEpoch ~/ 80);
          final Paint bubblePaint = Paint()..style = PaintingStyle.fill;

          for (int j = 0; j < 6; j++) {
            final double sx = (splashRand.nextDouble() - 0.5) * 14.0;
            final double sy = topY - splashRand.nextDouble() * 12.0;
            final double bSize = splashRand.nextDouble() * 2.4 + 0.8;

            bubblePaint.color = Colors.white.withOpacity(splashRand.nextDouble() * 0.65 + 0.35);
            canvas.drawCircle(Offset(sx, sy), bSize, bubblePaint);

            final double dx = (splashRand.nextDouble() - 0.5) * 20.0;
            final double dy = topY - splashRand.nextDouble() * 10.0;
            canvas.drawCircle(Offset(dx, dy), bSize * 0.6, Paint()
              ..color = color.withOpacity(splashRand.nextDouble() * 0.6 + 0.4)
              ..style = PaintingStyle.fill);
          }
        }
      }

      // 5. Rising buoyant micro-bubbles inside liquid columns
      _drawRisingBubbles(canvas, color, topY, bottomY, w, timePhase);

      // 6. Ambient shimmer sparkles
      _drawSparkles(canvas, color, topY, bottomY, w, timePhase);

      canvas.restore();
    }
  }

  void _drawRisingBubbles(Canvas canvas, Color color, double topY, double bottomY, double w, double timePhase) {
    final double height = bottomY - topY;
    if (height <= 8) return;

    final math.Random rand = math.Random(color.value ^ 0x3F);
    const int bubbleCount = 4;

    final Paint bubbleGlow = Paint()
      ..color = Colors.white.withOpacity(0.20)
      ..style = PaintingStyle.fill;
    
    final Paint bubbleBorder = Paint()
      ..color = Colors.white.withOpacity(0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (int i = 0; i < bubbleCount; i++) {
      final double seed = rand.nextDouble();
      final double speed = 0.8 + seed * 1.2;
      final double cycleProgress = ((timePhase * speed / (2 * math.pi)) + (i * 0.25)) % 1.0;
      
      final double y = bottomY - (cycleProgress * height);
      final double sway = math.sin(timePhase * 2.0 + (i * 1.8)) * 3.0;
      final double x = (-w / 2 + 6) + (seed * (w - 12)) + sway;
      final double radius = 0.9 + seed * 1.3;

      if (y >= topY + 2 && y <= bottomY - 2) {
        canvas.drawCircle(Offset(x, y), radius, bubbleGlow);
        canvas.drawCircle(Offset(x, y), radius, bubbleBorder);
      }
    }
  }

  void _drawSparkles(Canvas canvas, Color color, double topY, double bottomY, double w, double timePhase) {
    final double height = bottomY - topY;
    if (height <= 0) return;

    final math.Random rand = math.Random(color.value);
    final int sparkleCount = (w * height / 140).ceil().clamp(2, 6);

    final Paint sparklePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

    for (int i = 0; i < sparkleCount; i++) {
      final double x = -w / 2 + rand.nextDouble() * w;
      final double y = topY + rand.nextDouble() * height;

      final double shimmer = (math.sin(timePhase * 1.5 + (i * 1.5)) + 1) / 2;
      if (shimmer > 0.55) {
        final double s = rand.nextDouble() * 2.2 * shimmer + 0.4;
        canvas.drawCircle(Offset(x, y), s, sparklePaint..color = Colors.white.withOpacity(0.24 * shimmer));
        canvas.drawCircle(Offset(x, y), s * 0.4, Paint()..color = Colors.white.withOpacity(0.55 * shimmer));
      }
    }
  }

  @override
  bool shouldRepaint(covariant LiquidPainter oldDelegate) {
    return true; 
  }
}
