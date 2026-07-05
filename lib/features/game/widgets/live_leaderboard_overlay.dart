import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/features/leaderboard/providers/leaderboard_provider.dart';
import 'package:aqua_sort/features/leaderboard/models/score_entry.dart';
import 'package:aqua_sort/core/services/audio_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LiveLeaderboardOverlay extends ConsumerStatefulWidget {
  final VoidCallback onContinue;

  const LiveLeaderboardOverlay({
    super.key,
    required this.onContinue,
  });

  @override
  ConsumerState<LiveLeaderboardOverlay> createState() => _LiveLeaderboardOverlayState();
}

class _LiveLeaderboardOverlayState extends ConsumerState<LiveLeaderboardOverlay> {
  bool _audioPlayed = false;

  @override
  void initState() {
    super.initState();
    _playFanfare();
  }

  void _playFanfare() async {
    if (!_audioPlayed) {
      _audioPlayed = true;
      await AudioService.instance.playMiniCelebration();
    }
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardStreamProvider);
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final String currentUsername = currentUser?.displayName ?? 'Guest Sorter';

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.82),
      body: Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 340,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.deepNavy.withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.tealAccent.withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.tealAccent.withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Dynamic live status ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 800.ms),
                    const SizedBox(width: 8),
                    Text(
                      'LIVE LEADERBOARD SYNC',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'STAGE COMPLETE',
                  style: GoogleFonts.righteous(
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Stream data ──────────────────────────────────────────────────
                Flexible(
                  child: leaderboardAsync.when(
                    data: (scores) {
                      // Take top 7 for dialogue height safety
                      final displayList = scores.take(7).toList();
                      if (displayList.isEmpty) {
                        return Center(
                          child: Text(
                            'No scores yet. Start sorting!',
                            style: GoogleFonts.outfit(color: AppColors.textSecondary),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final entry = displayList[index];
                          final rank = index + 1;
                          final isMe = (currentUser?.id != null && entry.userId == currentUser!.id) ||
                                       (entry.username == currentUsername);

                          return _buildRankEntry(entry, rank, isMe)
                              .animate()
                              .fadeIn(delay: (60 * index).ms, duration: 300.ms)
                              .slideY(begin: 0.1, curve: Curves.easeOut);
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.cyanGlow),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        'Failed to load live rankings.',
                        style: GoogleFonts.outfit(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Continue action ──────────────────────────────────────────────
                GlowButton(
                  label: 'CONTINUE',
                  icon: Icons.navigate_next_rounded,
                  onTap: widget.onContinue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankEntry(ScoreEntry entry, int rank, bool isMe) {
    final isTop3 = rank <= 3;
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe 
            ? AppColors.tealAccent.withOpacity(0.15) 
            : isTop3 ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe 
              ? AppColors.tealAccent 
              : isTop3 ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.06),
          width: isMe ? 1.5 : 1.0,
        ),
        boxShadow: isMe ? [
          BoxShadow(
            color: AppColors.tealAccent.withOpacity(0.1),
            blurRadius: 10,
          )
        ] : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              medal ?? '#$rank',
              style: GoogleFonts.righteous(
                fontSize: 13,
                color: isMe ? Colors.white : isTop3 ? Colors.white70 : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isMe ? '${entry.username} (YOU)' : entry.username,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                color: isMe ? Colors.white : Colors.whitee70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.moves} Moves',
                style: GoogleFonts.righteous(
                  fontSize: 12,
                  color: AppColors.cyanGlow,
                ),
              ),
              Text(
                _formatTime(entry.seconds),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on Colors {
  static const Color whitee70 = Colors.white70;
}
