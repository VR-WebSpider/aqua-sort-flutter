import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/wave_painter.dart';
import 'package:aqua_sort/features/auth/widgets/floating_tube.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_error_dialog.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override ConsumerState<SplashScreen> createState() => _SplashState();
}

class _SplashState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _wave  = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  late final AnimationController _fade  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  late final Animation<double> _floatAnim = CurvedAnimation(parent: _float, curve: Curves.easeInOut);
  late final Animation<double> _fadeAnim  = CurvedAnimation(parent: _fade,  curve: Curves.easeOut);

  @override void dispose() { _wave.dispose(); _float.dispose(); _fade.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(children: [
        // ── Background ────────────────────────────────
        aquaBackground(),

        // ── Bubbles ───────────────────────────────────
        ..._bubbles(size),

        // ── Floating tubes ────────────────────────────
        AnimatedBuilder(animation: _floatAnim, builder: (_, __) {
          final dy = _floatAnim.value * 14;
          return Stack(children: [
            _tube(-22, size.height * 0.15 + dy,  200, AppColors.tubeA, 0.28),
            _tube(size.width - 80, size.height * 0.10 - dy * 0.7, 165, AppColors.tubeB, -0.22),
            _tube(size.width - 55, size.height * 0.34 + dy * 0.5, 115, AppColors.tubeC, -0.12),
          ]);
        }),

        // ── Waves ─────────────────────────────────────
        Positioned(bottom: 0, left: 0, right: 0, height: size.height * 0.62,
          child: AnimatedBuilder(
            animation: _wave,
            builder: (_, __) => CustomPaint(painter: WavePainter(_wave.value)),
          )),

        // ── Content ───────────────────────────────────
        FadeTransition(opacity: _fadeAnim, child: _content(context, size)),
      ]),
    );
  }

  Widget _tube(double l, double t, double h, List<Color> c, double angle) => Positioned(
    left: l, top: t,
    child: Transform.rotate(angle: angle, child: FloatingTube(height: h, colors: c)),
  );

  List<Widget> _bubbles(Size size) {
    final rng = math.Random(7);
    return List.generate(14, (i) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.65;
      final r = rng.nextDouble() * 3.5 + 1.5;
      return Positioned(left: x, top: y,
        child: AnimatedBuilder(animation: _floatAnim, builder: (_, __) =>
          Transform.translate(
            offset: Offset(0, -7 * _floatAnim.value * (i.isOdd ? 1 : 0.5)),
            child: Container(width: r * 2, height: r * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyanGlow.withOpacity(0.10 + rng.nextDouble() * 0.12),
                border: Border.all(color: AppColors.cyanGlow.withOpacity(0.25), width: 0.6),
              )),
          )));
    });
  }

  Widget _content(BuildContext context, Size size) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Logo
            Image.asset(
              'assets/studio_logo_white.png',
              width: 220,
              height: 220,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.rocket_launch, size: 80, color: Colors.white24),
            ),
            const SizedBox(height: 28),

            // Title
            Text('Aqua Sort',
              style: GoogleFonts.righteous(
                fontSize: 64, color: Colors.white,
                shadows: [
                  const Shadow(color: AppColors.cyanGlow, blurRadius: 28, offset: Offset(0, 2)),
                  const Shadow(color: AppColors.cyanGlow, blurRadius: 60),
                ],
              )),
            const SizedBox(height: 6),
            Text('by WebSpider Studios',
              style: GoogleFonts.righteous(
                  fontSize: 14, color: AppColors.textSecondary,
                  fontWeight: FontWeight.w300, letterSpacing: 3)),

            const SizedBox(height: 40),

            // Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
              child: Column(children: [
                GlowButton(
                  label: 'Play as Guest', 
                  outlined: true,
                  loading: ref.watch(authProvider).isLoading,
                  onTap: () async {
                    try {
                      await ref.read(authProvider.notifier).setGuest();
                    } catch (e) {
                      if (context.mounted) {
                        AquaErrorDialog.show(context, e);
                      }
                    }
                  },
                ),
                const SizedBox(height: 14),
                GlowButton(label: 'Secure Login', icon: Icons.lock_outline,
                    onTap: () => context.go('/login')),
              ]),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
