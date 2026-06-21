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
  final double sizeMult;
  _Firework(this.pos, this.color, this.delay, this.sizeMult);
}

class _CelebrationPainter extends CustomPainter {
  final double progress;
  late final List<_Firework> fireworks;

  _CelebrationPainter(this.progress) {
    final rand = math.Random(123);
    fireworks = List.generate(20, (i) => _Firework(
      Offset(rand.nextDouble(), rand.nextDouble()),
      [AppColors.cyanGlow, AppColors.tealAccent, Colors.yellow, Colors.orange, Colors.purpleAccent, Colors.pinkAccent][rand.nextInt(6)],
      rand.nextDouble(),
      0.5 + rand.nextDouble(),
    ));
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var fw in fireworks) {
      final double t = (progress + fw.delay) % 1.0;
      if (t > 0.8) continue; // Explosion lifecycle
      
      final double burstProgress = t / 0.8;
      final center = Offset(fw.pos.dx * size.width, (fw.pos.dy * size.height) + (burstProgress * 40)); // Add gravity fall
      
      final int particleCount = (30 * fw.sizeMult).toInt();
      for (int i = 0; i < particleCount; i++) {
        final double angle = (i / particleCount) * math.pi * 2;
        // Exponential expansion for "snap"
        final double speed = (i % 3 == 0) ? 1.2 : 0.8;
        final double radius = math.pow(burstProgress, 0.6) * 100 * speed * fw.sizeMult;
        
        final x = center.dx + math.cos(angle) * radius;
        final y = center.dy + math.sin(angle) * radius;
        
        final paint = Paint()
          ..color = fw.color.withOpacity((1 - burstProgress).clamp(0, 1))
          ..style = PaintingStyle.fill;

        // Draw particle with glow
        canvas.drawCircle(Offset(x, y), (1 - burstProgress) * 3 * fw.sizeMult, paint);
        
        if (burstProgress < 0.3) {
           canvas.drawCircle(Offset(x, y), (1 - burstProgress) * 6 * fw.sizeMult, 
             paint..color = fw.color.withOpacity((1 - burstProgress) * 0.3)
             ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        }
      }
    }
  }

  @override bool shouldRepaint(_CelebrationPainter old) => old.progress != progress;
}
