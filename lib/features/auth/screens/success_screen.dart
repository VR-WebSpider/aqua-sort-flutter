import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';

class SuccessScreen extends ConsumerStatefulWidget {
  const SuccessScreen({super.key});
  @override ConsumerState<SuccessScreen> createState() => _SuccessState();
}

class _SuccessState extends ConsumerState<SuccessScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();

  @override void dispose() { _spin.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: aquaBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(22),
              child: AquaHeader(onBack: () => context.go('/'))),
            const Spacer(),

            // â”€â”€ Badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            SizedBox(
              width: 190, height: 190,
              child: Stack(alignment: Alignment.center, children: [
                // Rotating outer ring
                AnimatedBuilder(animation: _spin, builder: (_, __) =>
                  Transform.rotate(
                    angle: _spin.value * 3.14159 * 2,
                    child: Container(
                      width: 190, height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const SweepGradient(colors: [
                          AppColors.cyanGlow, Color(0xFF7B2FBE), AppColors.cyanGlow,
                        ]),
                        boxShadow: [BoxShadow(color: AppColors.cyanGlow.withOpacity(0.4), blurRadius: 24, spreadRadius: 2)],
                      ),
                    ),
                  )),

                // Inner badge body
                Container(
                  width: 164, height: 164,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [Color(0xFF0D2535), Color(0xFF051925)]),
                  ),
                ),

                // Studio Logo inside badge
                Column(mainAxisSize: MainAxisSize.min, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [BoxShadow(color: AppColors.cyanGlow.withOpacity(0.3), blurRadius: 10)],
                      ),
                      child: Image.asset('assets/webspider_logo.jpg', width: 64, height: 64),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.check_circle, size: 24, color: AppColors.success),
                ]),
              ]),
            ),
            const SizedBox(height: 28),

            // â”€â”€ Text â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Text('Purity Check!', style: GoogleFonts.righteous(fontSize: 32, color: Colors.white,
                shadows: [const Shadow(color: AppColors.cyanGlow, blurRadius: 22)])),
            const SizedBox(height: 6),
            Text('Account Validated', style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.cyanGlow)),
            const SizedBox(height: 12),
            Text('Welcome to Aqua Sort!\nYour profile is verified.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),

            const Spacer(),

            // â”€â”€ Buttons â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(children: [
                GlowButton(label: 'Go to Sort', icon: Icons.sports_esports_outlined, onTap: () => context.go('/lobby')),
                const SizedBox(height: 12),
                GlowButton(label: 'View Profile', outlined: true, onTap: () => context.push('/profile')),
              ]),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}
