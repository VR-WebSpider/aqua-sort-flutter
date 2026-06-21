import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> userData;
  const VerificationScreen({super.key, required this.userData});
  @override ConsumerState<VerificationScreen> createState() => _VerState();
}

class _VerState extends ConsumerState<VerificationScreen> with TickerProviderStateMixin {
  late final AnimationController _prog = AnimationController(vsync: this, duration: const Duration(seconds: 3))
    ..addStatusListener((s) { if (s == AnimationStatus.completed) _nav(); });
  late final AnimationController _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override void initState() { super.initState(); _prog.forward(); }
  @override void dispose()  { _prog.dispose(); _glow.dispose(); super.dispose(); }

  void _nav() { 
    if (mounted) {
      context.go('/success'); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center, radius: 1.2,
            colors: [Color(0xFF030D1A), Color(0xFF00121E), Color(0xFF000A12)],
          ),
        ),
        child: Stack(children: [
          // Circuit-board overlay
          CustomPaint(size: MediaQuery.of(context).size, painter: _CircuitPainter()),

          Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Title (Image 2 Ref: Neon Glow)
            AnimatedBuilder(animation: _glow, builder: (_, __) =>
              Text('Validating Purity...',
                style: GoogleFonts.righteous(
                  fontSize: 32,
                  foreground: Paint()
                    ..shader = LinearGradient(colors: [
                      AppColors.cyanGlow.withOpacity(0.7 + _glow.value * 0.3),
                      const Color(0xFFD400FF), // Purple neon
                      AppColors.tealAccent,
                    ]).createShader(const Rect.fromLTWH(0, 0, 320, 50)),
                  shadows: [
                    Shadow(color: AppColors.cyanGlow.withOpacity(0.5), blurRadius: 25),
                    Shadow(color: const Color(0xFFD400FF).withOpacity(0.4), blurRadius: 15),
                  ],
                ),
              )),
            const SizedBox(height: 40),

            // Rainbow progress bar (Image 2 Ref)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: AnimatedBuilder(animation: _prog, builder: (_, __) =>
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: AppColors.cyanGlow.withOpacity(0.15), blurRadius: 12, spreadRadius: 1)
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _prog.value,
                      backgroundColor: Colors.black26,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent),
                    ).animate().custom(
                      duration: const Duration(seconds: 3),
                      builder: (context, value, child) => Container(
                        width: MediaQuery.of(context).size.width * _prog.value,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF7B2FBE), Color(0xFFD400FF), Color(0xFF00E5FF)],
                            stops: [0.0, 0.35, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                )),
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(animation: _prog, builder: (_, __) =>
              Text('${(_prog.value * 100).toInt()}% PURITY',
                  style: GoogleFonts.outfit(
                      color: AppColors.cyanGlow.withOpacity(0.8), 
                      fontSize: 12, 
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold))),
          ])),
        ]),
      ),
    );
  }
}

class _CircuitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF00B4CC).withOpacity(0.06)..strokeWidth = 1;
    final rng = math.Random(3);
    for (int i = 0; i < 20; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawLine(Offset(x, y), Offset(x + rng.nextDouble() * 80 - 40, y + rng.nextDouble() * 80 - 40), paint);
      canvas.drawCircle(Offset(x, y), 2, paint..color = const Color(0xFF00E5FF).withOpacity(0.08));
    }
  }
  @override bool shouldRepaint(_) => false;
}
