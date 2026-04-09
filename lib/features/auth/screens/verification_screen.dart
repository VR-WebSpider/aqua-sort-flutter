import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';

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
      ref.read(authProvider.notifier).login(
        widget.userData['firstName'],
        lastName: widget.userData['lastName'],
        displayName: widget.userData['displayName'],
      );
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
            // Title
            AnimatedBuilder(animation: _glow, builder: (_, __) =>
              Text('Validating Purity...',
                style: GoogleFonts.righteous(
                  fontSize: 30,
                  foreground: Paint()
                    ..shader = LinearGradient(colors: [
                      AppColors.cyanGlow.withOpacity(0.6 + _glow.value * 0.4),
                      AppColors.tealAccent,
                    ]).createShader(const Rect.fromLTWH(0, 0, 300, 50)),
                  shadows: [Shadow(color: AppColors.cyanGlow.withOpacity(0.4 + _glow.value * 0.3), blurRadius: 22)],
                ),
              )),
            const SizedBox(height: 36),

            // Rainbow progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: AnimatedBuilder(animation: _prog, builder: (_, __) =>
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _prog.value,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF1A3040),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color.lerp(AppColors.cyanGlow, const Color(0xFF7B2FBE), _prog.value)!,
                    ),
                  ),
                )),
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(animation: _prog, builder: (_, __) =>
              Text('${(_prog.value * 100).toInt()}%',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14))),
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
