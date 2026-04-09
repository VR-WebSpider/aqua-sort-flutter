import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({super.key});

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          painter: _CelebrationPainter(_ctrl.value),
          size: MediaQuery.of(context).size,
        ),
      ),
    );
  }
}

class _Firework {
  final Offset pos;
  final Color color;
  final double delay;
  _Firework(this.pos, this.color, this.delay);
}

class _CelebrationPainter extends CustomPainter {
  final double progress;
  late final List<_Firework> fireworks;

  _CelebrationPainter(this.progress) {
    final rand = math.Random(123);
    fireworks = List.generate(15, (i) => _Firework(
      Offset(rand.nextDouble(), rand.nextDouble()),
      [AppColors.cyanGlow, AppColors.tealAccent, Colors.yellow, Colors.orange, Colors.purpleAccent][rand.nextInt(5)],
      rand.nextDouble(),
    ));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var fw in fireworks) {
      final double t = (progress + fw.delay) % 1.0;
      if (t > 0.6) continue; // Explosion lifecycle
      
      final double burstProgress = t / 0.6;
      final center = Offset(fw.pos.dx * size.width, fw.pos.dy * size.height);
      
      for (int i = 0; i < 12; i++) {
        final double angle = (i / 12) * math.pi * 2;
        final double radius = burstProgress * 60;
        final x = center.dx + math.cos(angle) * radius;
        final y = center.dy + math.sin(angle) * radius;
        
        paint.color = fw.color.withOpacity(1 - burstProgress);
        canvas.drawCircle(Offset(x, y), (1 - burstProgress) * 4, paint);
      }
    }
  }

  @override bool shouldRepaint(_CelebrationPainter old) => old.progress != progress;
}
