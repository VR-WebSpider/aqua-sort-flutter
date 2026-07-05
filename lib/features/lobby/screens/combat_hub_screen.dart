import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/features/game/providers/game_provider.dart';
import 'package:aqua_sort/features/game/engine/game_engine.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CombatHubScreen extends ConsumerStatefulWidget {
  const CombatHubScreen({super.key});

  @override
  ConsumerState<CombatHubScreen> createState() => _CombatHubScreenState();
}

class _CombatHubScreenState extends ConsumerState<CombatHubScreen> {
  Difficulty _localDifficulty = Difficulty.medium;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: aquaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AquaHeader(
                  onBack: () => context.go('/lobby'),
                  onHome: () => context.go('/lobby'),
                ),
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // ── Local Multiplayer Card ──────────────────────────────────────
                      _buildLocalMultiplayerCard(),
                      const SizedBox(height: 20),

                      // ── Online Multiplayer Card ─────────────────────────────────────
                      _buildOnlineMultiplayerCard(authState),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMBAT HUB',
          style: GoogleFonts.righteous(
            fontSize: 28,
            color: Colors.white,
            shadows: [const Shadow(color: AppColors.cyanGlow, blurRadius: 15)],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'SELECT YOUR BATTLE ARENA',
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.05);
  }

  Widget _buildLocalMultiplayerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.amber.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👥', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                'LOCAL DUEL',
                style: GoogleFonts.righteous(
                  fontSize: 20,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Text(
                  'SPLIT SCREEN',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Play head-to-head on the same device. Challenge a friend next to you in a real-time sorting race to see who sorts their tubes first.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'SELECT DIFFICULTY',
            style: GoogleFonts.righteous(
              fontSize: 11,
              color: Colors.white70,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: Difficulty.values.map((d) {
              final active = _localDifficulty == d;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: _difficultyChip(d, active),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          GlowButton(
            label: 'START LOCAL DUEL',
            icon: Icons.play_arrow_rounded,
            glowColor: Colors.amber,
            gradientColors: const [Color(0xFF8D6E63), Color(0xFFFFB300)],
            onTap: () {
              final authState = ref.read(authProvider);
              ref.read(gameArgsProvider.notifier).state = GameArgs(
                difficulty: _localDifficulty,
                playerCount: 2,
                isOnline: false,
                isGuest: authState.status == AuthStatus.guest,
              );
              context.go('/game');
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _buildOnlineMultiplayerCard(AuthState authState) {
    final isGuest = authState.status == AuthStatus.guest;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cyanGlow.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyanGlow.withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌐', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                'ONLINE ARENA',
                style: GoogleFonts.righteous(
                  fontSize: 20,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cyanGlow.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cyanGlow.withOpacity(0.3)),
                ),
                child: Text(
                  'MATCHMAKING',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: AppColors.cyanGlow,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Queue up for competitive matchmaking, host custom lobbies, challenge players in real-time, and win Purity rewards synced to the global server.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          GlowButton(
            label: isGuest ? 'SIGN IN FOR ONLINE ARENA' : 'ENTER ONLINE ARENA',
            icon: isGuest ? Icons.lock_outline_rounded : Icons.login_rounded,
            onTap: () {
              if (isGuest) {
                _showGuestSignInSheet();
              } else {
                context.push('/online-lobby');
              }
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _difficultyChip(Difficulty diff, bool active) {
    Color color;
    switch (diff) {
      case Difficulty.easy:
        color = Colors.greenAccent;
        break;
      case Difficulty.medium:
        color = AppColors.cyanGlow;
        break;
      case Difficulty.hard:
        color = Colors.orangeAccent;
        break;
      case Difficulty.expert:
        color = Colors.redAccent;
        break;
    }

    return GestureDetector(
      onTap: () => setState(() => _localDifficulty = diff),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : Colors.black12,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? color : Colors.white.withOpacity(0.1),
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          diff.label.toUpperCase(),
          style: GoogleFonts.righteous(
            fontSize: 10,
            color: active ? color : Colors.white60,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _showGuestSignInSheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'GuestLobby',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, _, __) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.deepNavy,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.cyanGlow.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyanGlow.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cyanGlow.withOpacity(0.1),
                      border: Border.all(color: AppColors.cyanGlow.withOpacity(0.3), width: 1.5),
                    ),
                    child: const Icon(Icons.lock_person_outlined, color: AppColors.cyanGlow, size: 36),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .scale(begin: const Offset(1, 1), end: const Offset(1.06, 1.06), duration: 2.seconds, curve: Curves.easeInOut),
                  const SizedBox(height: 24),
                  Text(
                    'AUTHENTICATION REQUIRED',
                    style: GoogleFonts.righteous(
                      fontSize: 18,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Online multiplayer is a premium feature. Register or sign in to your WebSpider Studios account to join matchmaking queue, challenge global players, and sync rewards.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  GlowButton(
                    label: 'CREATE ACCOUNT / SIGN IN',
                    icon: Icons.login_rounded,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/login');
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'BACK TO HUB',
                      style: GoogleFonts.outfit(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
