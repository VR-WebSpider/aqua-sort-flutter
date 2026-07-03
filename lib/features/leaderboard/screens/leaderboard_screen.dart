import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:aqua_sort/features/game/engine/game_engine.dart';
import 'package:aqua_sort/core/services/game_services.dart';
import '../providers/leaderboard_provider.dart';
import '../models/score_entry.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:aqua_sort/core/widgets/ad_banner_widget.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardState();
}

class _LeaderboardState extends ConsumerState<LeaderboardScreen> {
  Difficulty _filter = Difficulty.easy;

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardStreamProvider);
    
    return Scaffold(
      body: aquaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AquaHeader(onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: 16),
                
                // Live Status Indicator
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('LIVE GLOBAL SYNC', style: GoogleFonts.outfit(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ],
                ).animate().fadeIn(),
                const SizedBox(height: 8),

                leaderboardAsync.when(
                  data: (scores) {
                    final filtered = scores.where((s) => s.difficulty.toLowerCase().contains(_filter.label.toLowerCase()) || _filter == Difficulty.easy).toList();
                    return Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPurityProgress(scores.length),
                          const SizedBox(height: 24),
                          Text('Global Rankings', style: GoogleFonts.outfit(
                            fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white,
                            shadows: [const Shadow(color: AppColors.cyanGlow, blurRadius: 15)],
                          )).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                          const SizedBox(height: 16),
                          
                          // Difficulty Filter
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: Difficulty.values.map((d) {
                                final active = _filter == d;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _filterChip(d.label, active, () => setState(() => _filter = d)),
                                );
                              }).toList(),
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          
                          const SizedBox(height: 24),
                          
                          Expanded(
                            child: filtered.isEmpty 
                              ? _buildEmpty()
                              : ListView.builder(
                                  itemCount: filtered.length,
                                  itemBuilder: (context, i) => _buildEntry(filtered[i], i + 1)
                                    .animate()
                                    .fadeIn(delay: (50 * i).ms, duration: 400.ms)
                                    .slideY(begin: 0.1, curve: Curves.easeOut),
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.cyanGlow))),
                  error: (e, _) => Expanded(child: Center(child: Text('Sync Error: $e', style: const TextStyle(color: Colors.redAccent)))),
                ),
                const SizedBox(height: 12),
                const AdBannerWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPurityProgress(int totalScores) {
    final double progress = (totalScores / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Text('GLOBAL PURITY', style: GoogleFonts.righteous(fontSize: 10, color: AppColors.tealAccent, letterSpacing: 1.2)),
             Text('${(progress * 100).toInt()}%', style: GoogleFonts.righteous(fontSize: 10, color: Colors.white70)),
           ],
         ),
         const SizedBox(height: 6),
         Stack(
           children: [
             Container(height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
             AnimatedContainer(
               duration: 1.seconds,
               height: 4, 
               width: MediaQuery.of(context).size.width * 0.8 * progress,
               decoration: BoxDecoration(
                 color: AppColors.cyanGlow, 
                 borderRadius: BorderRadius.circular(2),
                 boxShadow: [BoxShadow(color: AppColors.cyanGlow.withOpacity(0.5), blurRadius: 4)],
               ),
             ),
           ],
         ),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildEntry(ScoreEntry entry, int rank) {
    final isTop3 = rank <= 3;
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isTop3 ? AppColors.tealAccent.withOpacity(0.12) : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isTop3 ? AppColors.tealAccent : Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(medal ?? '#$rank', style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, color: isTop3 ? Colors.white : AppColors.textMuted)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(entry.username, style: GoogleFonts.outfit(
              fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.moves} Moves', style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.cyanGlow)),
              Text(_formatTime(entry.seconds), style: GoogleFonts.outfit(
                fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('No scores yet for this level', style: GoogleFonts.outfit(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.tealAccent : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: GoogleFonts.outfit(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: active ? Colors.black : Colors.white70)),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }
}
