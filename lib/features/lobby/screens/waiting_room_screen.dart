import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:aqua_sort/features/lobby/providers/multiplayer_provider.dart';
import 'package:aqua_sort/features/game/providers/game_provider.dart';
import 'package:aqua_sort/features/game/engine/game_engine.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WaitingRoomScreen extends ConsumerStatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  ConsumerState<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends ConsumerState<WaitingRoomScreen> {
  Difficulty _parseDifficulty(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return Difficulty.easy;
      case 'medium':
        return Difficulty.medium;
      case 'hard':
        return Difficulty.hard;
      case 'expert':
        return Difficulty.expert;
      default:
        return Difficulty.medium;
    }
  }

  Color _getDifficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return Colors.greenAccent;
      case 'medium':
        return AppColors.cyanGlow;
      case 'hard':
        return Colors.orangeAccent;
      default:
        return AppColors.tealAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final multiState = ref.watch(multiplayerProvider);
    final room = multiState.myRoom;

    // Handle game starting/matched state
    if (multiState.matchmakingStatus == MatchmakingStatus.matched && room != null && room.status == 'playing') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(gameArgsProvider.notifier).state = GameArgs(
          difficulty: _parseDifficulty(room.difficulty),
          playerCount: 2,
          isOnline: true,
          roomId: room.id,
          seed: room.seed,
        );
        context.go('/game');
      });
      return const Scaffold(
        backgroundColor: AppColors.deepNavy,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.cyanGlow),
        ),
      );
    }

    // Handle room cancellation or error
    if (room == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/online-lobby');
      });
      return const Scaffold(
        backgroundColor: AppColors.deepNavy,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.cyanGlow),
        ),
      );
    }

    final isChallenge = room.challengedUserId != null;
    final displayId = room.id.length >= 8 ? room.id.substring(0, 8).toUpperCase() : room.id.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: aquaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                AquaHeader(
                  onBack: () async {
                    await ref.read(multiplayerProvider.notifier).stopMatchmaking();
                    if (mounted) context.go('/online-lobby');
                  },
                ),
                const Spacer(flex: 1),
                
                // Pulsing animation for matchmaking
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulsing rings
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cyanGlow.withOpacity(0.2), width: 2),
                      ),
                    ).animate(onPlay: (c) => c.repeat())
                     .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.4, 1.4), duration: 2.seconds, curve: Curves.easeOut)
                     .fadeOut(duration: 2.seconds, curve: Curves.easeOut),
                    
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.tealAccent.withOpacity(0.3), width: 1.5),
                      ),
                    ).animate(onPlay: (c) => c.repeat())
                     .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.6, 1.6), delay: 800.ms, duration: 2.seconds, curve: Curves.easeOut)
                     .fadeOut(duration: 2.seconds, curve: Curves.easeOut),

                    // Inner scanning ring
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black38,
                        border: Border.all(color: AppColors.cyanGlow.withOpacity(0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyanGlow.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.wifi_tethering_rounded,
                          size: 56,
                          color: AppColors.cyanGlow,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Status Texts
                Text(
                  isChallenge ? 'CHALLENGE INITIATED' : 'WAITING FOR OPPONENT',
                  style: GoogleFonts.righteous(
                    fontSize: 24,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      const Shadow(color: AppColors.cyanGlow, blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isChallenge
                      ? 'Waiting for player to accept the duel...'
                      : 'Searching for a match in the Cyber Sea...',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(flex: 1),
                
                // Room Metadata Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ROOM ID',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            displayId,
                            style: GoogleFonts.righteous(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'DIFFICULTY',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(room.difficulty).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _getDifficultyColor(room.difficulty).withOpacity(0.4)),
                            ),
                            child: Text(
                              room.difficulty.toUpperCase(),
                              style: GoogleFonts.righteous(
                                fontSize: 11,
                                color: _getDifficultyColor(room.difficulty),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'HOST',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${room.hostUsername ?? "You"} (LV ${room.hostLevel})',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Cancel Matchmaking
                SizedBox(
                  width: 220,
                  child: GlowButton(
                    label: 'CANCEL',
                    glowColor: Colors.redAccent,
                    gradientColors: const [Color(0xFF5A1A24), Colors.redAccent],
                    onTap: () async {
                      await ref.read(multiplayerProvider.notifier).stopMatchmaking();
                      if (mounted) context.go('/online-lobby');
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
