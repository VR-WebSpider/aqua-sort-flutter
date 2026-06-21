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

      // Specular 3D cylinder gradient
      final Paint paint = Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(color, Colors.black, 0.12)!, 
            color,                                   
            Color.lerp(color, Colors.white, 0.28)!,  
            color,                                   
            Color.lerp(color, Colors.black, 0.08)!, 
          ],
          stops: const [0.0, 0.25, 0.35, 0.65, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTRB(-w / 2, 0, w / 2, h))
        ..style = PaintingStyle.fill;

      // Note: We do NOT rotate the canvas. Drawing directly in the tube's local vertical
      // space and tilting the surface lines mathematically using `- math.tan(tilt) * x`
      // guarantees that the left/right edges of the surface always align perfectly 
      // with the actual tube walls (-w/2 and w/2). This prevents the meniscus from
      // clipping away near the bottom of the tube (eliminating the "tilted paper triangle" bug).
      canvas.save();
      canvas.translate(w / 2, 0);

      final Path layerPath = Path();
      const int steps = 30;
      final double stepWidth = w / steps;

      // 1. Top boundary (left to right)
      if (isTop) {
        for (int j = 0; j <= steps; j++) {
          final double x = -w / 2 + (j * stepWidth);
          final double normX = x / (w / 2);
          
          final double meniscusY = -3.2 * math.pow(normX, 4);
          final double idleWave = math.sin(x * waveFreq + timePhase) * 1.5;
          final double wobbleWave = math.sin(x * waveFreq * 1.2 + wobble * 5.0) * 4.0 * wobble;
          final double ripple = isReceiving
              ? math.sin(x.abs() * 0.45 - timePhase * 3.5) * 3.5 / (1.0 + x.abs() * 0.08)
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

      // 2. Bottom boundary (right to left)
      if (seg.startIdx == 0) {
        layerPath.lineTo(w / 2, h + 20);
        layerPath.lineTo(-w / 2, h + 20);
      } else {
        layerPath.lineTo(w / 2, bottomY - math.tan(tilt) * (w / 2));
        layerPath.lineTo(-w / 2, bottomY - math.tan(tilt) * (-w / 2));
      }

      layerPath.close();
      canvas.drawPath(layerPath, paint);

      // 3. Glowing top surface outline (only for the top layer)
      if (isTop) {
        final Paint surfacePaint = Paint()
          ..color = Colors.white.withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;

        final Path surfacePath = Path();
        for (int j = 0; j <= steps; j++) {
          final double x = -w / 2 + (j * stepWidth);
          final double normX = x / (w / 2);
          final double meniscusY = -3.2 * math.pow(normX, 4);
          final double idleWave = math.sin(x * waveFreq + timePhase) * 1.5;
          final double wobbleWave = math.sin(x * waveFreq * 1.2 + wobble * 5.0) * 4.0 * wobble;
          final double ripple = isReceiving
              ? math.sin(x.abs() * 0.45 - timePhase * 3.5) * 3.5 / (1.0 + x.abs() * 0.08)
              : 0.0;

          final double y = topY - math.tan(tilt) * x + idleWave + wobbleWave + meniscusY + ripple;

          if (j == 0) {
            surfacePath.moveTo(x, y);
          } else {
            surfacePath.lineTo(x, y);
          }
        }
        canvas.drawPath(surfacePath, surfacePaint);

        // 4. Splash particles at impact point
        if (isReceiving) {
          final math.Random splashRand = math.Random(DateTime.now().millisecondsSinceEpoch ~/ 90);
          final Paint bubblePaint = Paint()..style = PaintingStyle.fill;

          for (int j = 0; j < 4; j++) {
            final double sx = (splashRand.nextDouble() - 0.5) * 12.0;
            final double sy = topY - splashRand.nextDouble() * 10.0;
            final double size = splashRand.nextDouble() * 2.0 + 0.8;

            bubblePaint.color = Colors.white.withOpacity(splashRand.nextDouble() * 0.6 + 0.4);
            canvas.drawCircle(Offset(sx, sy), size, bubblePaint);

            final double dx = (splashRand.nextDouble() - 0.5) * 18.0;
            final double dy = topY - splashRand.nextDouble() * 8.0;
            canvas.drawCircle(Offset(dx, dy), size * 0.6, Paint()
              ..color = color.withOpacity(splashRand.nextDouble() * 0.5 + 0.3)
              ..style = PaintingStyle.fill);
          }
        }
      }

      _drawSparkles(canvas, color, topY, bottomY, w, timePhase);

      canvas.restore();
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
