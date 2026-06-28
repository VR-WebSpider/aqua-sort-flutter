import 'package:aqua_sort/features/game/engine/game_engine.dart';

class TutorialDiscovery {
  static TutorialMove? findMove(int level, List<Tube> tubes) {
    if (level <= 2) {
      final path = GameSolver.solve(tubes);
      if (path != null && path.isNotEmpty) {
        return path.first;
      }
    }
    return null;
  }
}
