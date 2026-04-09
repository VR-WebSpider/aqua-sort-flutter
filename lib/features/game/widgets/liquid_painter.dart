import 'dart:math' as math;
import 'package:flutter/material.dart';

class LiquidPainter extends CustomPainter {
  final List<Color> colors;
  final double wobble; // Current displacement of the wave (-1.0 to 1.0)
  final double tilt;   // Tilt angle of the surface
  final double topLayerFill; // 0.0 to 1.0 (0.0=empty segment, 1.0=full segment)
  final int capacity;

  LiquidPainter({
    required this.colors,
    required this.wobble,
    this.tilt = 0.0,
    this.topLayerFill = 1.0,
    this.capacity = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;

    final double layerHeight = size.height / capacity;
    final double width = size.width;

    final double w = size.width;
    final double h = size.height;

    for (int i = 0; i < colors.length; i++) {
      final Color color = colors[i];
      final bool isTop = (i == colors.length - 1);
      final double currentLayerHeight = isTop ? layerHeight * topLayerFill : layerHeight;

      final double layerCenterY = h - (i * layerHeight) - (currentLayerHeight / 2);

      // ── Premium Gradient Logic ──────────────────────────────────────────
      // Use a horizontal gradient to simulate light hitting the curved glass
      final Paint paint = Paint()
        ..shader = LinearGradient(
          colors: [
            color.withOpacity(0.85),
            color,
            color.withOpacity(0.9),
            color.withOpacity(0.7),
          ],
          stops: const [0.0, 0.4, 0.6, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(-w, -currentLayerHeight/2, w * 2, currentLayerHeight))
        ..style = PaintingStyle.fill;

      canvas.save();
      
      // Move to the center of this layer
      canvas.translate(w / 2, layerCenterY);
      
      // Rotate back to counter the tube's tilt
      canvas.rotate(-tilt);

      final double rectW = w * 4;
      final double rectH = currentLayerHeight;

      const int segments = 20;

      if (isTop) {
        final Path wavyPath = Path();
        wavyPath.moveTo(-rectW / 2, rectH / 2);
        wavyPath.lineTo(rectW / 2, rectH / 2);
        
        final double segmentWidth = rectW / segments;
        for (int j = segments; j >= 0; j--) {
          final double x = -rectW / 2 + (j * segmentWidth);
          final double t = j / segments;
          final double waveY = -rectH / 2 + (math.sin(t * math.pi * 4) * 5.0 * wobble);
          wavyPath.lineTo(x, waveY);
        }
        wavyPath.close();
        canvas.drawPath(wavyPath, paint);

        // Surface highlight
        _drawSurfaceHighlight(canvas, -rectH / 2, rectW, wobble);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: rectW, height: rectH), paint);
      }

      // Add a small specular highlight on the left
      canvas.drawRect(
        Rect.fromLTWH(-w/2 + 3, -rectH/2, 4, rectH),
        Paint()..color = Colors.white.withOpacity(0.12)
      );

      canvas.restore();
    }
  }

  void _drawSurfaceHighlight(Canvas canvas, double topY, double width, double wobble) {
    final Paint surfacePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    
    final Path surfacePath = Path();
    const int segments = 40; // Smoother for the wide rect
    final double segmentWidth = width / segments;

    for (int i = 0; i <= segments; i++) {
      final double x = -width / 2 + (i * segmentWidth);
      final double t = i / segments;
      final double waveY = topY + (math.sin(t * math.pi * 4) * 5.0 * wobble);
      
      if (i == 0) surfacePath.moveTo(x, waveY);
      else surfacePath.lineTo(x, waveY);
    }
    canvas.drawPath(surfacePath, surfacePaint);
  }

  void _drawTopLayer(Canvas canvas, Paint paint, Offset offset, Size size, double bottom) {
    final Path path = Path();
    path.moveTo(0, bottom);
    path.lineTo(0, offset.dy);

    // Create a wave effect at the surface
    const int segments = 20;
    final double segmentWidth = size.width / segments;
    
    for (int i = 0; i <= segments; i++) {
      final double x = i * segmentWidth;
      // Sine wave for wobble
      final double y = offset.dy + (math.sin((i / segments) * math.pi * 2) * 4.0 * wobble);
      // Add tilt factor
      final double tiltY = y + ((i / segments - 0.5) * size.width * math.tan(tilt));
      
      path.lineTo(x, tiltY);
    }

    path.lineTo(size.width, bottom);
    path.close();

    canvas.drawPath(path, paint);

    // Add a gloss/reflection at the surface
    final Paint surfacePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    
    // Draw the same curve but just as a stroke for the surface highlight
    final Path surfacePath = Path();
    surfacePath.moveTo(0, offset.dy + (math.sin(0) * 4.0 * wobble) + (-0.5 * size.width * math.tan(tilt)));
    for (int i = 1; i <= segments; i++) {
      final double x = i * segmentWidth;
      final double y = offset.dy + (math.sin((i / segments) * math.pi * 2) * 4.0 * wobble);
      final double tiltY = y + ((i / segments - 0.5) * size.width * math.tan(tilt));
      surfacePath.lineTo(x, tiltY);
    }
    canvas.drawPath(surfacePath, surfacePaint);
  }

  @override
  bool shouldRepaint(covariant LiquidPainter oldDelegate) {
    return oldDelegate.wobble != wobble || oldDelegate.tilt != tilt || oldDelegate.colors != colors;
  }
}
