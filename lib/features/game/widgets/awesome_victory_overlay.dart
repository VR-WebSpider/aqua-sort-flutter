import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_sort/features/history/providers/history_provider.dart';
import 'package:aqua_sort/features/game/providers/game_provider.dart';
import 'package:aqua_sort/core/services/wallet_service.dart';

class AwesomeVictoryOverlay extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final int winnerIdx;
  const AwesomeVictoryOverlay({super.key, required this.onNext, this.winnerIdx = 0});

  @override
  ConsumerState<AwesomeVictoryOverlay> createState() => _AwesomeVictoryOverlayState();
}

class _AwesomeVictoryOverlayState extends ConsumerState<AwesomeVictoryOverlay>
    with TickerProviderStateMixin {
  bool _recorded = false;
  int _earnedCoins = 0;
  int _displayedCoins = 0;
  AnimationController? _coinCounterController;
  Animation<double>? _coinCounterAnim;
  late AnimationController _ribbonController;
  late Animation<Offset> _ribbonSlide;

  @override
  void initState() {
    super.initState();
    _ribbonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _ribbonSlide = Tween<Offset>(
      begin: const Offset(0, -2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ribbonController, curve: Curves.elasticOut));
    _ribbonController.forward();
  }

  @override
  void dispose() {
    _ribbonController.dispose();
    _coinCounterController?.dispose();
    super.dispose();
  }

  void _startCoinAnimation(int earned) {
    _earnedCoins = earned;
    _coinCounterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _coinCounterAnim = Tween<double>(begin: 0, end: earned.toDouble())
        .animate(CurvedAnimation(parent: _coinCounterController!, curve: Curves.easeOutCubic));

    _coinCounterAnim!.addListener(() {
      setState(() => _displayedCoins = _coinCounterAnim!.value.round());
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _coinCounterController?.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_recorded) {
      _recorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final game = ref.read(gameProvider);
        if (game.isSplitScreen) return; // Skip history and coins for local split screen duel

        final p0 = game.playerStates[0]!;
        final level = ref.read(levelProvider).currentLevel;

        // Record history entry
        ref.read(historyProvider.notifier).recordWin(
          level: level,
          moves: p0.moves,
          seconds: p0.seconds,
        );

        // Only reward if we are the winner (player 0)
        if (widget.winnerIdx == 0) {
          // Calculate and animate the earned coins
          final earned = WalletService.calculateLevelReward(
            level: level,
            moves: p0.moves,
            seconds: p0.seconds,
          );
          _startCoinAnimation(earned);
        }
      });
    }

    final game = ref.watch(gameProvider);
    final isSplit = game.isSplitScreen;
    final isVictory = widget.winnerIdx == 0;

    String outcomeText;
    Color ribbonColor;
    if (isSplit) {
      outcomeText = 'PLAYER ${widget.winnerIdx + 1} WINS!';
      ribbonColor = const Color(0xFFFF5252);
    } else {
      outcomeText = isVictory ? 'VICTORY!' : 'DEFEAT';
      ribbonColor = isVictory ? const Color(0xFFFF5252) : const Color(0xFF455A64);
    }

    final buttonColor = (isSplit || isVictory) ? const Color(0xFFFFD100) : AppColors.cyanGlow;
    final buttonTextColor = (isSplit || isVictory) ? const Color(0xFF5D4037) : Colors.white;
    final buttonLabel = isSplit ? 'LOBBY' : (isVictory ? 'NEXT' : 'RETRY');

    final levelProgress = ref.watch(levelProvider);
    final currentLevel = levelProgress.currentLevel;

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AWESOME Ribbon (slides in from top)
            SlideTransition(
              position: _ribbonSlide,
              child: SizedBox(
                width: 400,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 40, top: 40,
                      child: _RibbonTail(left: true),
                    ),
                    Positioned(
                      right: 40, top: 40,
                      child: _RibbonTail(left: false),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      decoration: BoxDecoration(
                        color: ribbonColor,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Text(
                        outcomeText,
                        style: GoogleFonts.righteous(
                          color: Colors.white,
                          fontSize: 36,
                          letterSpacing: 1.5,
                          shadows: [const Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Coin Earned Banner ──────────────────────────────────────────
            AnimatedOpacity(
              opacity: _earnedCoins > 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD700).withOpacity(0.15),
                      const Color(0xFFFFA000).withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Text(
                      '+$_displayedCoins',
                      style: GoogleFonts.righteous(
                        fontSize: 28,
                        color: const Color(0xFFFFD700),
                        letterSpacing: 1.5,
                        shadows: [BoxShadow(color: Colors.orange.withOpacity(0.6), blurRadius: 12)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'COINS',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.amber.withOpacity(0.8),
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Missions Container
            if (!isSplit) ...[
              Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2C3B).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [const BoxShadow(color: Colors.black54, blurRadius: 40, spreadRadius: 10)],
                ),
                child: Column(
                  children: [
                    _missionRow(
                      label: "Reach level 4",
                      current: currentLevel,
                      target: 4,
                    ),
                    const Divider(color: Colors.white10, height: 32),
                    _missionRow(
                      label: "Reach level 10",
                      current: currentLevel,
                      target: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
            ] else
              const SizedBox(height: 50),

            // NEXT Button
            GestureDetector(
              onTap: widget.onNext,
              child: Container(
                width: 260, height: 74,
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(37),
                  boxShadow: [
                    BoxShadow(color: (isSplit || isVictory) ? Colors.orange.withOpacity(0.4) : AppColors.cyanGlow.withOpacity(0.4), 
                      blurRadius: 15, offset: const Offset(0, 6)),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  buttonLabel,
                  style: GoogleFonts.righteous(fontSize: 32, letterSpacing: 2, color: buttonTextColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _missionRow({required String label, required int current, required int target}) {
    final double progress = (current / target).clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 18,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF81C784), Color(0xFF4CAF50)]),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$current/$target', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: const Icon(Icons.apps, color: Colors.cyanAccent, size: 30),
        ),
      ],
    );
  }
}

class _RibbonTail extends StatelessWidget {
  final bool left;
  const _RibbonTail({required this.left});
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: left ? -0.1 : 0.1,
      child: Container(
        width: 60, height: 35,
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
