import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';

class SuccessScreen extends ConsumerStatefulWidget {
  final String? title;
  final String? message;
  const SuccessScreen({super.key, this.title, this.message});
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

            // Badge (Image 3 Ref: Custom Purity Badge)
            SizedBox(
              width: 200, height: 200,
              child: Stack(alignment: Alignment.center, children: [
                // Outer serrated/glowing ring
                AnimatedBuilder(animation: _spin, builder: (_, __) =>
                  Transform.rotate(
                    angle: _spin.value * -3.14159 * 2,
                    child: Container(
                      width: 190, height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cyanGlow.withOpacity(0.2), width: 8),
                        boxShadow: [
                          BoxShadow(color: AppColors.cyanGlow.withOpacity(0.4), blurRadius: 40, spreadRadius: -5),
                          BoxShadow(color: const Color(0xFFD400FF).withOpacity(0.2), blurRadius: 30),
                        ],
                      ),
                    ),
                  )),

                // The Badge body from Ref 3
                Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF7B2FBE)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 130, height: 130,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF071B26),
                      ),
                      child: Stack(alignment: Alignment.center, children: [
                        // Glass test tube icon matching Ref 3
                        const Icon(Icons.science_outlined, color: Color(0xFF00E5FF), size: 70),
                        Positioned(
                          bottom: 30,
                          child: Container(
                            width: 60, height: 30,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF7B2FBE)]),
                              borderRadius: BorderRadius.circular(30).copyWith(
                                topLeft: const Radius.circular(5),
                                topRight: const Radius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 32),

            // Text (Image 3 Ref: Title and Subtext)
            Text(widget.title ?? 'Purity Check!', style: GoogleFonts.righteous(fontSize: 34, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Account Validated', style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
            const SizedBox(height: 24),
            Text(widget.message ?? 'Welcome to Aqua Sort!\nYour profile is verified.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 15, color: Colors.white70, height: 1.5)),

            const Spacer(),

            // Buttons (Image 3 Ref: Solid and Outlined)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(children: [
                GlowButton(
                  label: 'Go to Sort', 
                  onTap: () => context.go('/lobby'),
                  // Solid Cyan color already handled by GlowButton default
                ),
                const SizedBox(height: 12),
                GlowButton(
                  label: 'View Profile', 
                  outlined: true, 
                  onTap: () => context.push('/profile'),
                  // Outlined Black style already handled
                ),
              ]),
            ),
            const SizedBox(height: 35),
          ]),
        ),
      ),
    );
  }
}
