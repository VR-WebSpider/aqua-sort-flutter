import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/score_entry.dart';

class LeaderboardNotifier extends StateNotifier<List<ScoreEntry>> {
  LeaderboardNotifier() : super([]) {
    _loadLocal();
  }

  static const String _storageKey = 'global_leaderboard';

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_storageKey);
    if (data != null) {
      state = data.map((item) => ScoreEntry.fromJson(jsonDecode(item))).toList();
    }
  }

  Future<void> saveScore(ScoreEntry entry) async {
    // ☁️ Simulated Cloud Sync Delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    final newState = [...state, entry];
    // Sort by moves (lower is better), then by seconds (lower is better)
    newState.sort((a, b) {
        int res = a.moves.compareTo(b.moves);
        if (res == 0) return a.seconds.compareTo(b.seconds);
        return res;
    });

    state = newState.take(100).toList(); // Keep top 100
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state.map((e) => jsonEncode(e.toJson())).toList());
  }

  List<ScoreEntry> getByDifficulty(String diff) {
    return state.where((e) => e.difficulty == diff).toList();
  }
}

final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier, List<ScoreEntry>>((ref) {
  return LeaderboardNotifier();
});
