import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';
import 'package:aqua_sort/features/lobby/widgets/level_map_widget.dart';
import 'package:aqua_sort/features/game/providers/game_provider.dart';
import 'package:aqua_sort/features/game/engine/game_engine.dart';

class CampaignScreen extends ConsumerWidget {
  const CampaignScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(levelProvider);
    
    return Scaffold(
      body: Stack(
        children: [
          // ── Background: Cyber Sunset Scenic ──────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF030D1A), Color(0xFF0D2535), Color(0xFF264653)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // ── The Level Tube ──────────────────────────────────────────────────
          const LevelMapTube(),
          
          // ── Header UI ──────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _iconBtn(Icons.settings, () => context.push('/profile')),
                  _coinsPill(progress.coins),
                ],
              ),
            ),
          ),
          
          // ── Bottom UI ──────────────────────────────────────────────────────
          Positioned(
            bottom: 40,
            left: 0, right: 0,
            child: Column(
              children: [
                GlowButton(
                  label: 'START LEVEL ${progress.currentLevel}',
                  onTap: () {
                    // Start game with progressive difficulty
                    final diff = progress.currentLevel < 5 ? Difficulty.easy : 
                                 progress.currentLevel < 15 ? Difficulty.medium : Difficulty.hard;
                    ref.read(gameArgsProvider.notifier).state = GameArgs(
                      difficulty: diff,
                      playerCount: 1,
                    );
                    context.go('/game');
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Navigation Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _navBtn(Icons.palette_outlined, false, () {}),
                    _navBtn(Icons.home_rounded, true, () {}),
                    _navBtn(Icons.emoji_events_outlined, false, () => context.push('/leaderboard')),
                    _navBtn(Icons.people_outline, false, () => context.push('/lobby-v1')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white.withOpacity(0.8)),
        onPressed: onTap,
      ),
    );
  }

  Widget _coinsPill(int coins) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('ðŸ’°', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(coins.toString(), style: GoogleFonts.righteous(color: Colors.white, fontSize: 16)),
          const SizedBox(width: 8),
          const Icon(Icons.add_circle, color: Colors.amber, size: 18),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? AppColors.cyanGlow.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon, 
          color: active ? AppColors.cyanGlow : Colors.white.withOpacity(0.4),
          size: 30,
        ),
      ),
    );
  }
}
