import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:aqua_sort/features/game/providers/game_provider.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';
import 'package:aqua_sort/features/game/engine/game_engine.dart';
import 'package:aqua_sort/features/game/engine/tutorial_discovery.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';

class InteractiveTutorialOverlay extends ConsumerWidget {
  final Map<int, Offset> tubePositions;
  final Function(int) onAllowedTap;

  const InteractiveTutorialOverlay({
    super.key,
    required this.tubePositions,
    required this.onAllowedTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelState = ref.watch(levelProvider);
    final currentLevel = levelState.currentLevel;
    
    // Only show for level 1 and 2
    if (currentLevel > 2) return const SizedBox.shrink();

    final gameState = ref.watch(gameProvider);
    final playerState = gameState.playerStates[0]!; // Single player tutorial
    final selectedIdx = playerState.selectedTube;

    final move = TutorialDiscovery.findMove(currentLevel, playerState.tubes);
    if (move == null) return const SizedBox.shrink();

    int? targetTubeIdx;
    String instruction = "";

    if (currentLevel == 1) {
      if (selectedIdx == null) {
          targetTubeIdx = move.from;
          instruction = "Tap a bottle";
      } else if (selectedIdx == move.from) {
          targetTubeIdx = move.to;
          instruction = "Tap to Pour Water";
      }
    } else if (currentLevel == 2) {
      if (selectedIdx == null) {
          targetTubeIdx = move.from;
          instruction = "Only SAME COLOR water can be poured on top of each other";
      } else if (selectedIdx == move.from) {
          targetTubeIdx = move.to;
          instruction = "Tap matching color to pour";
      }
    }

    if (targetTubeIdx == null || !tubePositions.containsKey(targetTubeIdx)) {
      return const SizedBox.shrink();
    }

    final targetPos = tubePositions[targetTubeIdx]!;

    return Stack(
      children: [
        // Instruction Bubble at bottom
        Positioned(
          bottom: 100,
          left: 40,
          right: 40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: Text(
              instruction,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).moveY(begin: 20, end: 0),
        ),

        // Ripple Pointer
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          left: targetPos.dx + 21 - 25, // Center on tube (42 width / 2) - half ripple size
          top: targetPos.dy + 30, // Position on the lower part of the tube
          child: RipplePointer(key: ValueKey('ripple_$targetTubeIdx')),
        ),
      ],
    );
  }
}

class RipplePointer extends StatefulWidget {
  const RipplePointer({super.key});
  @override
  State<RipplePointer> createState() => _RipplePointerState();
}

class _RipplePointerState extends State<RipplePointer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this, 
    duration: const Duration(seconds: 2),
  )..repeat();

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          _ring(_ctrl.value),
          _ring((_ctrl.value + 0.5) % 1.0),
          Container(
            width: 10, height: 10,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.white54, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double val) {
    return Container(
      width: 50 * val, height: 50 * val,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity((1 - val).clamp(0, 1)), 
          width: 2,
        ),
      ),
    );
  }
}
