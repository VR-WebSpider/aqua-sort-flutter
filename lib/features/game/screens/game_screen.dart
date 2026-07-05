import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/game/providers/game_provider.dart';
import 'package:aqua_sort/features/game/engine/game_engine.dart';
import 'package:aqua_sort/features/game/widgets/board_widget.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:aqua_sort/features/game/widgets/celebration_overlay.dart';
import 'package:aqua_sort/features/game/widgets/awesome_victory_overlay.dart';
import 'package:aqua_sort/core/services/audio_service.dart';
import 'package:aqua_sort/core/services/ad_service.dart';
import 'package:aqua_sort/core/services/economy_config.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aqua_sort/features/profile/providers/premium_provider.dart';
import 'package:aqua_sort/features/profile/widgets/premium_purchase_dialog.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';
import 'package:aqua_sort/features/game/widgets/game_tutorial_dialogs.dart';
import 'package:aqua_sort/core/widgets/ad_banner_widget.dart';
import 'package:aqua_sort/features/game/widgets/live_leaderboard_overlay.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _showCelebration = false;
  bool _showLost = false;
  bool _specialLevelTutorialChecked = false;
  bool _showLiveLeaderboard = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final args = ref.read(gameArgsProvider);
      if (args.playerCount > 1 && !args.isOnline) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
      ref.read(gameProvider.notifier).startGame(args);
    });
  }

  @override
  void dispose() {
    AudioService.instance.stopAll();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final progress = ref.watch(levelProvider);
    final args = ref.watch(gameArgsProvider);

    if (progress.isLoaded && !_specialLevelTutorialChecked && args.playerCount == 1 && !args.isOnline) {
      _specialLevelTutorialChecked = true;
      final isSpecialLevel = progress.currentLevel % 5 == 0;
      if (isSpecialLevel && !progress.specialLevelTutorialSeen) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          ref.read(gameProvider.notifier).pauseForTutorial();
          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const SpecialLevelTutorialDialog(),
            );
            await ref.read(levelProvider.notifier).markSpecialLevelTutorialSeen();
            ref.read(gameProvider.notifier).resumeFromTutorial();
          }
        });
      }
    }

    // Check for win and show overlay
    // Only trigger win overlay once upon transition to won=true
    // Trigger win overlay when game status changes to finished
    ref.listen(gameProvider.select((s) => s.status), (prev, next) {
      if (next == GameStatus.finished && prev != GameStatus.finished) {
        setState(() => _showCelebration = true);
      }
    });

    // Trigger lost overlay when any player loses
    ref.listen(
      gameProvider.select((s) => s.playerStates[0]?.lost ?? false),
      (prev, next) {
        if (next == true && prev != true) {
          setState(() => _showLost = true);
        }
      },
    );

    return Scaffold(
      body: Stack(
        children: [
          aquaBackground(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Global Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: AquaHeader(
                      onBack: () {
                        AudioService.instance.stopAll();
                        context.go('/lobby');
                      },
                      onHome: () {
                        AudioService.instance.stopAll();
                        context.go('/lobby');
                      },
                    ),
                  ),
                  
                  Expanded(
                    child: game.isSplitScreen
                        ? _buildSplitLayout(game)
                        : BoardWidget(playerIdx: 0),
                  ),
                  const SafeArea(
                    top: false,
                    child: AdBannerWidget(),
                  ),
                ],
              ),
            ),
          ),
          if (game.status == GameStatus.paused)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ),
          if (_showCelebration) ...[
            CelebrationOverlay(),
            AwesomeVictoryOverlay(
              winnerIdx: game.winnerIdx ?? 0,
              onNext: () {
                setState(() {
                  _showCelebration = false;
                  _showLiveLeaderboard = true;
                });
              },
            ),
          ],
          
          if (_showLiveLeaderboard)
            LiveLeaderboardOverlay(
              onContinue: () async {
                AudioService.instance.stopAll();
                AdService.instance.recordLevelComplete();
                await AdService.instance.showInterstitialIfReady();
                if (mounted) {
                  context.go('/lobby');
                }
              },
            ),
          
          // ── Game Over Overlay ─────────────────────────────────────────────
          if (_showLost)
            _buildGameOverOverlay(game),

          // ── Waiting Overlay ───────────────────────────────────────────────
          if (game.status == GameStatus.waiting)
            _buildWaitingOverlay(),

          // ── Countdown Overlay ─────────────────────────────────────────────
          if (game.status == GameStatus.starting)
            _buildCountdownOverlay(game.countdown),
        ],
      ),
    );
  }

  Widget _buildWaitingOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.radar_rounded, color: AppColors.cyanGlow, size: 80)
                .animate(onPlay: (c) => c.repeat())
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.seconds)
                .then()
                .scale(begin: const Offset(1.2, 1.2), end: const Offset(0.8, 0.8), duration: 1.seconds),
            const SizedBox(height: 24),
            Text(
              'WAITING FOR OPPONENT',
              style: GoogleFonts.righteous(fontSize: 24, color: Colors.white, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'Establishing secure connection...',
              style: GoogleFonts.outfit(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay(int count) {
    return Container(
      color: Colors.black45,
      child: Center(
        child: Text(
          count == 0 ? 'GO!' : count.toString(),
          key: ValueKey(count),
          style: GoogleFonts.righteous(
            fontSize: 120,
            color: count == 0 ? AppColors.tealAccent : Colors.white,
            shadows: [const Shadow(color: AppColors.cyanGlow, blurRadius: 40)],
          ),
        ).animate().scale(begin: const Offset(2, 2), end: const Offset(1, 1)).fadeOut(delay: 800.ms),
      ),
    );
  }

  Widget _buildSplitLayout(MultiGameState game) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return Row(
            children: [
              const Expanded(child: BoardWidget(playerIdx: 0)),
              Container(width: 2, color: Colors.white.withOpacity(0.1)),
              const Expanded(child: BoardWidget(playerIdx: 1)),
            ],
          );
        }
        return Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 2)),
                ),
                child: const BoardWidget(playerIdx: 1),
              ),
            ),
            const Expanded(child: BoardWidget(playerIdx: 0)),
          ],
        );
      },
    );
  }
  void _showWinOverlay(int playerIdx, GameState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.deepNavy,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.tealAccent),
            boxShadow: [BoxShadow(color: AppColors.cyanGlow.withOpacity(0.3), blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text('Purity Achieved!', style: GoogleFonts.righteous(fontSize: 28, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Player ${playerIdx + 1} Wins!', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('Moves', state.moves.toString()),
                  _stat('Time', '${state.seconds}s'),
                ],
              ),
              const SizedBox(height: 32),
              GlowButton(label: 'Global Rankings', outlined: true, onTap: () {
                  Navigator.of(context).pop();
                  context.push('/leaderboard');
              }),
              const SizedBox(height: 12),
              GlowButton(
                  label: 'HOME', 
                  icon: Icons.home_outlined,
                  onTap: () {
                    AudioService.instance.stopAll();
                    context.go('/lobby');
                  }),
            ],
          ),
        ),
      ),
    ).then((_) {
      // Release resources when win overlay is closed
      setState(() => _showCelebration = false);
    });
  }

  Widget _stat(String label, String value) {
      return Column(children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ]);
  }

  Widget _buildGameOverOverlay(MultiGameState game) {
    final p0 = game.playerStates[0];
    if (p0 == null) return const SizedBox.shrink();

    final isTimeOut = p0.secondsLeft <= 0;
    final title = isTimeOut ? "TIME'S UP!" : 'NO MOVES LEFT!';
    final icon = isTimeOut ? Icons.timer_off_rounded : Icons.block_rounded;
    final adLabel = isTimeOut
        ? 'Watch Ad for +${EconomyConfig.adBonusSeconds}s'
        : 'Watch Ad for +${EconomyConfig.adBonusMoves} Moves';

    final isPremium = ref.watch(premiumProvider);

    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.deepNavy,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.error.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(color: AppColors.error.withOpacity(0.15), blurRadius: 30),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.error, size: 56),
              const SizedBox(height: 16),
              Text(title,
                  style: GoogleFonts.righteous(
                      fontSize: 28, color: Colors.white, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text(
                isTimeOut
                    ? 'You ran out of time!'
                    : 'You ran out of moves!',
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // SECTION 1: REVIVE
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white10)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'REVIVE & CONTINUE',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary.withOpacity(0.6),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Colors.white10)),
                ],
              ),
              const SizedBox(height: 16),

              if (isPremium) ...[
                GlowButton(
                  label: isTimeOut
                      ? 'Premium Revive (+${EconomyConfig.adBonusSeconds}s)'
                      : 'Premium Revive (+${EconomyConfig.adBonusMoves} Moves)',
                  icon: Icons.workspace_premium_rounded,
                  glowColor: Colors.purpleAccent,
                  gradientColors: const [Color(0xFF8E24AA), Color(0xFFD81B60)],
                  onTap: () {
                    final notifier = ref.read(gameProvider.notifier);
                    if (isTimeOut) {
                      notifier.grantBonusTime(0);
                    } else {
                      notifier.grantBonusMoves(0);
                    }
                    setState(() => _showLost = false);
                  },
                ),
              ] else ...[
                // Watch Ad for recovery
                GlowButton(
                  label: adLabel,
                  icon: Icons.smart_display_rounded,
                  onTap: () async {
                    final reward = await AdService.instance.showRewardedAd(context);
                    if (reward != null) {
                      final notifier = ref.read(gameProvider.notifier);
                      if (isTimeOut) {
                        notifier.grantBonusTime(0);
                      } else {
                        notifier.grantBonusMoves(0);
                      }
                      setState(() => _showLost = false);
                    }
                  },
                ),
                const SizedBox(height: 12),
                
                // Go Premium
                GlowButton(
                  label: 'Go Premium (Instant Revive)',
                  icon: Icons.workspace_premium_rounded,
                  glowColor: Colors.purpleAccent,
                  gradientColors: const [Color(0xFF8E24AA), Color(0xFFD81B60)],
                  onTap: () async {
                    final purchased = await PremiumPurchaseDialog.show(context);
                    if (purchased) {
                      final notifier = ref.read(gameProvider.notifier);
                      if (isTimeOut) {
                        notifier.grantBonusTime(0);
                      } else {
                        notifier.grantBonusMoves(0);
                      }
                      setState(() => _showLost = false);
                    }
                  },
                ),
              ],
              const SizedBox(height: 24),

              // SECTION 2: RESTART
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white10)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'START OVER',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted.withOpacity(0.6),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Colors.white10)),
                ],
              ),
              const SizedBox(height: 16),

              // Retry
              GlowButton(
                label: 'RETRY',
                icon: Icons.refresh_rounded,
                outlined: true,
                onTap: () {
                  setState(() => _showLost = false);
                  final args = ref.read(gameArgsProvider);
                  ref.read(gameProvider.notifier).startGame(args);
                },
              ),
              const SizedBox(height: 20),

              // Home
              GestureDetector(
                onTap: () {
                  AudioService.instance.stopAll();
                  context.go('/lobby');
                },
                child: Text('Go Home',
                    style: GoogleFonts.outfit(
                        color: AppColors.textMuted, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
