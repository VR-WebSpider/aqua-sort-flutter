import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_sort/features/game/engine/game_engine.dart';

void main() {
  test('GameSolver can solve a simple 2-color layout (Level 2 representation)', () {
    // Tube 0: [Pink, Cyan, -1, -1] -> [0, 1, -1, -1]
    // Tube 1: [Pink, Cyan, Cyan, Cyan] -> [0, 1, 1, 1]
    // Tube 2: [Pink, Pink, -1, -1] -> [0, 0, -1, -1]
    // Tube 3: [-1, -1, -1, -1] -> [-1, -1, -1, -1]
    final tubes = [
      Tube([0, 1, -1, -1]),
      Tube([0, 1, 1, 1]),
      Tube([0, 0, -1, -1]),
      Tube.empty(),
    ];

    final path = GameSolver.solve(tubes);
    expect(path, isNotNull);
    expect(path!.isNotEmpty, isTrue);
    
    // The path should successfully solve the tubes
    List<Tube> state = List.from(tubes);
    for (final move in path) {
      expect(GameEngine.canPour(state[move.from], state[move.to]), isTrue);
      // Simulate pour
      final from = Tube.copy(state[move.from]);
      final to = Tube.copy(state[move.to]);
      final color = from.topColor;
      while (from.topColor == color && to.freeSlots > 0) {
        final slot = to.colors.lastIndexOf(-1);
        to.colors[slot] = color;
        from.colors[from.colors.lastIndexOf(color)] = -1;
      }
      state[move.from] = from;
      state[move.to] = to;
    }

    expect(state.every((t) => t.isSolved), isTrue);
  });
}
