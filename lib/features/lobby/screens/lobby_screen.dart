import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:aqua_sort/features/game/engine/game_engine.dart';
import 'package:aqua_sort/features/game/providers/game_provider.dart';
import 'package:go_router/go_router.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});
  @override ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  Difficulty _diff = Difficulty.easy;
  int _players = 1;
  bool _isOnline = false;

  void _showComingSoonDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ComingSoon',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.deepNavy,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.cyanGlow, width: 2),
              boxShadow: [
                BoxShadow(color: AppColors.cyanGlow.withOpacity(0.3), blurRadius: 40, spreadRadius: 5),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.public_outlined, size: 80, color: AppColors.cyanGlow).animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 2.seconds, color: Colors.white24)
                    .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), curve: Curves.easeInOut),
                  const SizedBox(height: 24),
                  Text(
                    'GLOBAL DOMINATION AWAITS!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.righteous(
                      fontSize: 24,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "We're currently calibrating the hyper-servers for real-time sorting battles. Soon you'll face off against the world's best sorters for exclusive seasonal rewards and the Title of Grand Alchemist.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GlowButton(
                    label: 'I AM READY',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ).animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack).fadeIn(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      body: aquaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AquaHeader(
                    onBack: () => context.go('/lobby'),
                    onHome: () => context.go('/lobby'),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [BoxShadow(color: AppColors.cyanGlow.withOpacity(0.2), blurRadius: 20)],
                            ),
                            child: Image.asset('assets/studio_logo_white.png', height: 100),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('WebSpider Studios', 
                          style: GoogleFonts.righteous(fontSize: 12, color: AppColors.tealAccent.withOpacity(0.6), letterSpacing: 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Welcome,',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    user?.displayName ?? 'Sorter',
                    style: GoogleFonts.righteous(
                      fontSize: 36,
                      color: Colors.white,
                      shadows: [
                        const Shadow(color: AppColors.cyanGlow, blurRadius: 20),
                      ],
                    ),
                  ),
                  if (auth.status == AuthStatus.guest)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber.withOpacity(0.15), Colors.amber.withOpacity(0.05)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1),
                          boxShadow: [
                              BoxShadow(color: Colors.amber.withOpacity(0.05), blurRadius: 10)
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.amber.withOpacity(0.9)),
                                  children: [
                                    const TextSpan(text: 'Guest Mode: '),
                                    TextSpan(text: 'LOGIN TO SAVE ', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.amber)),
                                    const TextSpan(text: 'your progress!'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 100,
                              child: GlowButton(
                                label: 'SIGN IN',
                                onTap: () => context.go('/login'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  
                  // Player Count
                  Text('Mode', style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12, runSpacing: 12,
                    children: [
                      _choiceChip('Solo', _players == 1, () => setState(() => _players = 1)),
                      _choiceChip('Local Multiplayer', _players == 2 && !_isOnline, () {
                        setState(() {
                          _players = 2;
                          _isOnline = false;
                        });
                      }),
                      _choiceChip('Online Multiplayer', _isOnline, () {
                        context.go('/multiplayer');
                      }),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Difficulty
                  Text('Difficulty', style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: Difficulty.values.map((d) => _choiceChip(
                      d.label, _diff == d, () => setState(() => _diff = d),
                      icon: d.icon,
                    )).toList(),
                  ),
  
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.water_drop_outlined, size: 60, color: AppColors.cyanGlow),
                        const SizedBox(height: 16),
                        Text(
                          'Ready to Sort?',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        GlowButton(
                          label: 'START GAME',
                          onTap: () {
                            ref.read(gameArgsProvider.notifier).state = GameArgs(
                              difficulty: _diff,
                              playerCount: _players,
                              isGuest: auth.status == AuthStatus.guest,
                              isOnline: _players > 1 && _isOnline,
                            );
                            context.go('/game');
                          },
                        ),
                        const SizedBox(height: 12),
                        GlowButton(
                          label: 'GLOBAL LEADERBOARD',
                          outlined: true,
                          icon: Icons.emoji_events_outlined,
                          onTap: () => context.push('/leaderboard'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _choiceChip(String label, bool active, VoidCallback onTap, {String? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: active ? AppColors.tealAccent.withOpacity(0.15) : AppColors.inputBg,
          border: Border.all(color: active ? AppColors.tealAccent : AppColors.inputBorder, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Text(icon), const SizedBox(width: 8)],
            Text(label, style: GoogleFonts.outfit(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textMuted,
            )),
          ],
        ),
      ),
    );
  }
}
