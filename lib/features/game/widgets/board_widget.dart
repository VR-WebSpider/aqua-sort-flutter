import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../engine/game_engine.dart';
import 'tube_widget.dart';
import 'pouring_animation_overlay.dart';

class BoardWidget extends ConsumerStatefulWidget {
  final int playerIdx;
  const BoardWidget({super.key, required this.playerIdx});

  @override
  ConsumerState<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends ConsumerState<BoardWidget> {
  final List<GlobalKey> _tubeKeys = [];

  @override
  void initState() {
    super.initState();
    _initKeys(ref.read(gameProvider).playerStates[widget.playerIdx]!.tubes.length);
  }

  void _initKeys(int count) {
    if (_tubeKeys.length != count) {
      _tubeKeys.clear();
      _tubeKeys.addAll(List.generate(count, (_) => GlobalKey()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final state = gameState.playerStates[widget.playerIdx]!;
    final activePour = gameState.activePours[widget.playerIdx];

    // Ensure keys match tube count if difficulty changed
    _initKeys(state.tubes.length);

    return Stack(
      children: [
        Column(
          children: [
            // Stats Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statPill('Moves', state.moves.toString()),
                  _statPill('Time', _formatTime(state.seconds)),
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
                          // Trigger shake if invalid pour
                          final sel = state.selectedTube;
                          if (sel != null && sel != i) {
                            if (!GameEngine.canPour(state.tubes[sel], state.tubes[i])) {
                              (_tubeKeys[sel].currentState as dynamic)?.shake();
                            }
                          }
                          ref.read(gameProvider.notifier).selectTube(widget.playerIdx, i);
                        },
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
                    Image.asset('assets/webspider_logo.jpg', height: 40),
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
      ],
    );
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

  Widget _statPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
