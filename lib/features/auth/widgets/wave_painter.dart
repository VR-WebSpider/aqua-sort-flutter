import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';

/// Animated 4-layer underwater wave â€” attach to an AnimationController(repeat).
class WavePainter extends CustomPainter {
  final double t; // 0 â†’ 1, repeating
  const WavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _wave(canvas, size, phase: t * math.pi * 2,             amp: 22, yRatio: 0.82, color: AppColors.wave1, opacity: 0.95);
    _wave(canvas, size, phase: -t * math.pi * 2 * 0.8,      amp: 18, yRatio: 0.68, color: AppColors.wave2, opacity: 0.85);
    _wave(canvas, size, phase: t * math.pi * 2 * 0.6,       amp: 14, yRatio: 0.54, color: AppColors.wave3, opacity: 0.75);
    _wave(canvas, size, phase: -t * math.pi * 2 * 0.45,     amp: 11, yRatio: 0.40, color: AppColors.wave4, opacity: 0.60);
  }

  void _wave(Canvas canvas, Size size,
      {required double phase, required double amp,
       required double yRatio, required Color color, required double opacity}) {
    final paint = Paint()..color = color.withOpacity(opacity);
    final baseY  = size.height * yRatio;
    final path   = Path()..moveTo(0, size.height)..lineTo(0, baseY);
    for (double x = 0; x <= size.width; x++) {
      path.lineTo(x, baseY + amp * math.sin(x / size.width * math.pi * 2.6 + phase));
    }
    path..lineTo(size.width, size.height)..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter old) => old.t != t;
}
