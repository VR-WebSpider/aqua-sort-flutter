import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/game/providers/game_provider.dart';
import 'package:aqua_sort/features/game/engine/game_engine.dart';
import 'package:aqua_sort/features/game/widgets/board_widget.dart';
import 'package:aqua_sort/features/auth/widgets/aqua_widgets.dart';
import 'package:aqua_sort/features/game/widgets/celebration_overlay.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _showCelebration = false;
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);

    // Check for win and show overlay
    // Only trigger win overlay once upon transition to won=true
    ref.listen(gameProvider, (prev, next) {
      final winningIdx = next.playerStates.entries
          .where((e) => e.value.won)
          .map((e) => e.key)
          .firstOrNull;

      final prevWon = prev?.playerStates[winningIdx]?.won ?? false;

      if (winningIdx != null && !prevWon) {
        setState(() => _showCelebration = true);
        _showWinOverlay(winningIdx, next.playerStates[winningIdx]!);
      }
    });

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
                      onBack: () => context.go('/lobby'),
                      onHome: () => context.go('/lobby'),
                    ),
                  ),
                  
                  Expanded(
                    child: game.isSplitScreen
                        ? _buildSplitLayout(game)
                        : BoardWidget(playerIdx: 0),
                  ),
                ],
              ),
            ),
          ),
          if (_showCelebration)
            const CelebrationOverlay(),
        ],
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
                  onTap: () => context.go('/lobby')),
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
}
