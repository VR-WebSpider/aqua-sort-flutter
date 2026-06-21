import 'package:aqua_sort/features/game/engine/game_engine.dart';

class TutorialDiscovery {
  static TutorialMove? findMove(int level, List<Tube> tubes) {
    if (level == 1) {
      // Find ANY legal move
      for (int i = 0; i < tubes.length; i++) {
        for (int j = 0; j < tubes.length; j++) {
          if (i == j) continue;
          if (GameEngine.canPour(tubes[i], tubes[j])) {
            return TutorialMove(i, j);
          }
        }
      }
    } else if (level == 2) {
      // RULE: Prioritize color-on-color to teach the rule
      for (int i = 0; i < tubes.length; i++) {
        for (int j = 0; j < tubes.length; j++) {
          if (i == j) continue;
          if (GameEngine.canPour(tubes[i], tubes[j]) && !tubes[j].isEmpty) {
            return TutorialMove(i, j);
          }
        }
      }
      // FALLBACK: Pour into empty if no color match exists
      for (int i = 0; i < tubes.length; i++) {
        for (int j = 0; j < tubes.length; j++) {
          if (i == j) continue;
          if (GameEngine.canPour(tubes[i], tubes[j])) {
            return TutorialMove(i, j);
          }
        }
      }
    }
    return null;
  }
}

class TutorialMove {
  final int from;
  final int to;
  TutorialMove(this.from, this.to);
}
