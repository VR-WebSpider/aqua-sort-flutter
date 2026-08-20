import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../engine/game_engine.dart';
import '../engine/tutorial_discovery.dart';
import '../../lobby/providers/level_provider.dart';
import 'tube_widget.dart';
import 'pouring_animation_overlay.dart';
import 'interactive_tutorial_overlay.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'dart:async';


class BoardWidget extends ConsumerStatefulWidget {
  final int playerIdx;
  const BoardWidget({super.key, required this.playerIdx});

  @override
  ConsumerState<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends ConsumerState<BoardWidget> {
  Timer? _hintTimer;
  final List<GlobalKey> _tubeKeys = [];
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _initKeys(ref.read(gameProvider).playerStates[widget.playerIdx]!.tubes.length);
    _resetHintTimer();  }

  void _initKeys(int count) {
    if (_tubeKeys.length != count) {
      _tubeKeys.clear();
      _tubeKeys.addAll(List.generate(count, (_) => GlobalKey()));
    }
  }

  // Resets inactivity hint timer
  void _resetHintTimer() {
    _hintTimer?.cancel();

    // Only schedule hint if game is actively playing
    final gameState = ref.read(gameProvider);
    if (gameState.status != GameStatus.playing) return;

    _hintTimer = Timer(const Duration(seconds: 12), () async {
      final hint = await ref.read(gameProvider.notifier).requestHint(widget.playerIdx);
      if (hint != null) {
        final idx = hint.from;
        if (idx < _tubeKeys.length) {
          (_tubeKeys[idx].currentState as dynamic)?.shake();
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final state = gameState.playerStates[widget.playerIdx]!;
    final activePour = gameState.activePours[widget.playerIdx];

    // Ensure keys match tube count if difficulty changed
    _initKeys(state.tubes.length);

    return RotatedBox(
      quarterTurns: _isFlipped ? 2 : 0,
      child: Stack(
        children: [
          Column(
            children: [
              // ── HUD: Time Left | Moves Left | Undo ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // Time Left pill
                    _TimerPill(secondsLeft: state.secondsLeft, maxSeconds: state.maxSeconds),
                    const SizedBox(width: 8),
                    // Moves Left pill
                    _MovesPill(movesLeft: state.movesLeft, maxMoves: state.maxMoves),
                    const Spacer(),
                    // Undo button with badge
                    _UndoButton(
                      freeUndosLeft: state.freeUndosLeft,
                      canUndo: state.canUndo,
                      onTap: () {
                          ref.read(gameProvider.notifier).requestUndo(widget.playerIdx, context);
                          _resetHintTimer();
                        },
                    ),
                    if (gameState.isSplitScreen) ...[
                      const SizedBox(width: 8),
                      _FlipButton(
                        isFlipped: _isFlipped,
                        onTap: () => setState(() => _isFlipped = !_isFlipped),
                      ),
                    ] else if (!gameState.isOnline) ...[
                      const SizedBox(width: 8),
                      _PauseButton(
                        onTap: () => ref.read(gameProvider.notifier).pauseGame(context),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Tubes Grid
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: List.generate(state.tubes.length, (i) {
                      final isSource = activePour?.fromIdx == i;
                      final isDest   = activePour?.toIdx == i;
                      
                      return Opacity(
                        opacity: (isSource || isDest) ? 0.0 : 1.0, 
                        child: TubeWidget(
                          key: _tubeKeys[i],
                          tube: state.tubes[i],
                          selected: state.selectedTube == i,
                          onTap: () {
                            // Interactive Tutorial Locking
                            final level = ref.read(levelProvider).currentLevel;
                            if (level <= 2) {
                              final target = _getTutorialTarget(level, state.selectedTube);
                              if (target != null && target != i) return; 
                            }

                            // Trigger shake if invalid pour
                            final sel = state.selectedTube;
                            if (sel != null && sel != i) {
                              if (!GameEngine.canPour(state.tubes[sel], state.tubes[i])) {
                                (_tubeKeys[sel].currentState as dynamic)?.shake();
                              }
                            }
                            ref.read(gameProvider.notifier).selectTube(widget.playerIdx, i);
                          _resetHintTimer();                        },
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Brand Watermark
              Opacity(
                opacity: 0.3,
                child: Center(
                  child: Column(
                    children: [
                      Image.asset('assets/studio_logo_white.png', height: 40),
                      const SizedBox(height: 2),
                      Text('WebSpider Studios', 
                        style: GoogleFonts.righteous(fontSize: 8, color: AppColors.tealAccent, letterSpacing: 1.5)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

          // ── ANIMATION OVERLAY ──────────────────────────────────────────────────
          if (activePour != null)
             _buildPouringOverlay(activePour),

          // ── INTERACTIVE TUTORIAL ────────────────────────────────────────────────
          if (state.tubes.isNotEmpty)
            InteractiveTutorialOverlay(
              tubePositions: _getVisibleTubePositions(),
              onAllowedTap: (idx) => ref.read(gameProvider.notifier).selectTube(widget.playerIdx, idx),
            ),
        ],
      ),
    );
  }

  Map<int, Offset> _getVisibleTubePositions() {
    final Map<int, Offset> positions = {};
    for (int i = 0; i < _tubeKeys.length; i++) {
        positions[i] = _getTubePos(_tubeKeys[i]);
    }
    return positions;
  }

  int? _getTutorialTarget(int level, int? selectedIdx) {
    final state = ref.read(gameProvider).playerStates[widget.playerIdx]!;
    final tubes = state.tubes;

    final move = TutorialDiscovery.findMove(level, tubes);
    if (move == null) return null;

    if (selectedIdx == null) return move.from;
    if (selectedIdx == move.from) return move.to;
    return move.from; // Reset to source if they select something else
  }

  Widget _buildPouringOverlay(ActivePour pour) {
    final gameState = ref.read(gameProvider);
    final state = gameState.playerStates[widget.playerIdx]!;

    // Safety check for keys
    if (_tubeKeys.length <= pour.fromIdx || _tubeKeys.length <= pour.toIdx) {
      return const SizedBox.shrink();
    }

    final start = _getTubePos(_tubeKeys[pour.fromIdx]);
    final end   = _getTubePos(_tubeKeys[pour.toIdx]);

    return PouringAnimationOverlay(
      key: ValueKey('pour_${pour.fromIdx}_${pour.toIdx}'),
      pour: pour,
      startOffset: start,
      endOffset: end,
      sourceTube: state.tubes[pour.fromIdx],
      destTube: state.tubes[pour.toIdx],
    );
  }

  Offset _getTubePos(GlobalKey key) {
    final rb = key.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return Offset.zero;
    final boardBox = context.findRenderObject() as RenderBox;
    return boardBox.globalToLocal(rb.localToGlobal(Offset.zero));
  }
@override
void dispose() {
  _hintTimer?.cancel();
  super.dispose();
}
}

// ── HUD Widgets ─────────────────────────────────────────────────────────────

/// Countdown timer pill with color warnings.
class _TimerPill extends StatelessWidget {
  final int secondsLeft;
  final int maxSeconds;
  const _TimerPill({required this.secondsLeft, required this.maxSeconds});

  @override
  Widget build(BuildContext context) {
    final Color accent;
    if (secondsLeft <= 10) {
      accent = const Color(0xFFFF5252);
    } else if (secondsLeft <= 30) {
      accent = const Color(0xFFFFAB40);
    } else {
      accent = AppColors.tealAccent;
    }

    final m = secondsLeft ~/ 60;
    final s = secondsLeft % 60;
    final timeStr = '$m:${s.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: accent),
          const SizedBox(width: 5),
          Text(timeStr,
              style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
        ],
      ),
    );
  }
}

/// Moves-left pill with color warnings.
class _MovesPill extends StatelessWidget {
  final int movesLeft;
  final int maxMoves;
  const _MovesPill({required this.movesLeft, required this.maxMoves});

  @override
  Widget build(BuildContext context) {
    final Color accent;
    if (movesLeft <= 5) {
      accent = const Color(0xFFFF5252);
    } else if (movesLeft <= 10) {
      accent = const Color(0xFFFFAB40);
    } else {
      accent = Colors.white70;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_vert_rounded, size: 14, color: accent),
          const SizedBox(width: 5),
          Text('$movesLeft',
              style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
          const SizedBox(width: 3),
          Text('left',
              style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }
}

/// Undo button with free-undo badge.
class _UndoButton extends StatelessWidget {
  final int freeUndosLeft;
  final bool canUndo;
  final VoidCallback onTap;

  const _UndoButton({
    required this.freeUndosLeft,
    required this.canUndo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = freeUndosLeft <= 0;
    final badgeColor = freeUndosLeft >= 2
        ? AppColors.success
        : freeUndosLeft == 1
            ? const Color(0xFFFFAB40)
            : const Color(0xFFFF5252);

    return GestureDetector(
      onTap: canUndo ? onTap : null,
      child: AnimatedOpacity(
        opacity: canUndo ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLocked
                  ? Colors.white.withOpacity(0.1)
                  : AppColors.tealAccent.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.undo_rounded,
                size: 16,
                color: isLocked ? Colors.white38 : AppColors.tealAccent,
              ),
              const SizedBox(width: 6),
              // Badge showing free undos or lock
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLocked ? Colors.white10 : badgeColor.withOpacity(0.2),
                  border: Border.all(color: isLocked ? Colors.white12 : badgeColor, width: 1.5),
                ),
                child: Center(
                  child: isLocked
                      ? const Icon(Icons.lock, size: 10, color: Colors.white38)
                      : Text('$freeUndosLeft',
                          style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badgeColor)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PauseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.tealAccent.withOpacity(0.3),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pause_rounded,
              size: 16,
              color: AppColors.tealAccent,
            ),
          ],
        ),
      ),
    );
  }
}

class _FlipButton extends StatelessWidget {
  final bool isFlipped;
  final VoidCallback onTap;

  const _FlipButton({
    required this.isFlipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFlipped ? AppColors.tealAccent : Colors.white10,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.screen_rotation_rounded,
              size: 16,
              color: isFlipped ? AppColors.tealAccent : Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}
