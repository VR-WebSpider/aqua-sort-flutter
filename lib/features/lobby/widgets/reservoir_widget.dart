import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import '../providers/activity_provider.dart';

class ReservoirBackground extends ConsumerWidget {
  const ReservoirBackground({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(activityProvider);
    
    return Stack(
      children: [
        // ── Base Gradient (Dynamic clarity) ──────────────────────────────────
        _DynamicBase(purity: activity.purity),
        
        // ── Volumetric Particles ─────────────────────────────────────────────
        _ReservoirParticles(purity: activity.purity),
        
        // ── Surface Waves ───────────────────────────────────────────────────
        _ReservoirWaves(purity: activity.purity),
      ],
    );
  }
}

class _DynamicBase extends StatelessWidget {
  final double purity;
  const _DynamicBase({required this.purity});

  @override
  Widget build(BuildContext context) {
    // Pure water is bright teal, murky is deep navy/black
    final Color top = Color.lerp(const Color(0xFF030D1A), const Color(0xFF0D2535), purity)!;
    final Color bottom = Color.lerp(const Color(0xFF0D1F2D), AppColors.deepNavy, purity)!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [top, bottom],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _ReservoirParticles extends StatefulWidget {
  final double purity;
  const _ReservoirParticles({required this.purity});
  @override
  State<_ReservoirParticles> createState() => _ReservoirParticlesState();
}

class _ReservoirParticlesState extends State<_ReservoirParticles> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => CustomPaint(
        painter: _ParticlePainter(_ctrl.value, widget.purity),
        size: Size.infinite,
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final double purity;
  _ParticlePainter(this.progress, this.purity);

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42);
    final int count = (20 + (purity * 40)).toInt();
    final paint = Paint()..color = Colors.white.withOpacity(0.1 + (0.2 * purity));

    for (int i = 0; i < count; i++) {
        final double x = rand.nextDouble() * size.width;
        final double baseY = rand.nextDouble() * size.height;
        // Float upwards
        final double y = (baseY - (progress * size.height)) % size.height;
        final double s = rand.nextDouble() * 2 + 0.5;
        
        // Shimmer
        paint.color = Colors.white.withOpacity((0.05 + 0.15 * purity) * (math.sin(progress * 10 + i) + 1) / 2);
        canvas.drawCircle(Offset(x, y), s, paint);
        
        if (purity > 0.7 && i % 5 == 0) {
            // Add a small glow to some particles
            canvas.drawCircle(Offset(x, y), s * 3, paint..color = AppColors.cyanGlow.withOpacity(0.05));
        }
    }
  }
  @override bool shouldRepaint(_ParticlePainter old) => old.progress != progress || old.purity != purity;
}

class _ReservoirWaves extends StatefulWidget {
  final double purity;
  const _ReservoirWaves({required this.purity});
  @override
  State<_ReservoirWaves> createState() => _ReservoirWavesState();
}

class _ReservoirWavesState extends State<_ReservoirWaves> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Positioned.fill(
        child: CustomPaint(
          painter: _WavePainter(_ctrl.value, widget.purity),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double purity;
  _WavePainter(this.progress, this.purity);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.cyanGlow.withOpacity(0.15 * purity), Colors.transparent],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, 150))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    for (double x = 0; x <= w; x += 10) {
        final double y = 40 + math.sin((x / w * 2 * math.pi) + (progress * 2 * math.pi)) * 10;
        path.lineTo(x, y);
    }
    path.lineTo(w, 0);
    path.close();
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(_WavePainter old) => old.progress != progress;
}
