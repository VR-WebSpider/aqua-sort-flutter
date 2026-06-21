import 'package:games_services/games_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

class GameServicesManager {
  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;

  /// Attempt a silent sign-in on startup (Android only for now)
  Future<void> init() async {
    if (!Platform.isAndroid) return;
    try {
      await GamesServices.signIn();
      _isSignedIn = true;
    } catch (e) {
      _isSignedIn = false;
    }
  }

  /// Show native Play Games Leaderboard
  Future<void> showLeaderboard({String iosLeaderboardID = '', String androidLeaderboardID = ''}) async {
    try {
      await GamesServices.showLeaderboards(
        iOSLeaderboardID: iosLeaderboardID,
        androidLeaderboardID: androidLeaderboardID,
      );
    } catch (_) {}
  }

  /// Submit score to Play Games Leaderboard
  Future<void> submitScore({
    required int score,
    String iosLeaderboardID = '',
    String androidLeaderboardID = '',
  }) async {
    try {
      await GamesServices.submitScore(
        score: Score(
          iOSLeaderboardID: iosLeaderboardID,
          androidLeaderboardID: androidLeaderboardID,
          value: score,
        ),
      );
    } catch (_) {}
  }

  /// Show native Achievements UI
  Future<void> showAchievements() async {
    try {
      await GamesServices.showAchievements();
    } catch (_) {}
  }

  /// Unlock an achievement
  Future<void> unlockAchievement({String iosID = '', String androidID = ''}) async {
    try {
      await GamesServices.unlock(
        achievement: Achievement(
          androidID: androidID,
          iOSID: iosID,
        ),
      );
    } catch (_) {}
  }

  /// Increment an achievement (for tiered achievements like "Sort 100 levels")
  Future<void> incrementAchievement({String iosID = '', String androidID = '', int steps = 1}) async {
    try {
      await GamesServices.increment(
        achievement: Achievement(
          androidID: androidID,
          iOSID: iosID,
          steps: steps,
        ),
      );
    } catch (_) {}
  }
}

final gameServicesProvider = Provider<GameServicesManager>((ref) {
  final manager = GameServicesManager();
  // We can't await here, but internal state will update when ready
  manager.init();
  return manager;
});
