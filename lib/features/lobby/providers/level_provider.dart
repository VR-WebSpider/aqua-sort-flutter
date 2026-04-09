import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LevelProgress {
  final int currentLevel;
  final int coins;
  final Set<int> unlockedLevels;

  LevelProgress({
    required this.currentLevel,
    required this.coins,
    required this.unlockedLevels,
  });

  LevelProgress copyWith({int? currentLevel, int? coins, Set<int>? unlockedLevels}) {
    return LevelProgress(
      currentLevel: currentLevel ?? this.currentLevel,
      coins: coins ?? this.coins,
      unlockedLevels: unlockedLevels ?? this.unlockedLevels,
    );
  }
}

class LevelNotifier extends StateNotifier<LevelProgress> {
  LevelNotifier() : super(LevelProgress(currentLevel: 1, coins: 16, unlockedLevels: {1})) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getInt('current_level') ?? 1;
    final coins = prefs.getInt('coins') ?? 16;
    final unlocked = (prefs.getStringList('unlocked') ?? ['1']).map(int.parse).toSet();
    state = LevelProgress(currentLevel: level, coins: coins, unlockedLevels: unlocked);
  }

  Future<void> completeLevel(int level) async {
    final next = level + 1;
    final newUnlocked = Set<int>.from(state.unlockedLevels)..add(next);
    final newCoins = state.coins + 10;
    
    state = state.copyWith(currentLevel: next, coins: newCoins, unlockedLevels: newUnlocked);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_level', next);
    await prefs.setInt('coins', newCoins);
    await prefs.setStringList('unlocked', newUnlocked.map((e) => e.toString()).toList());
  }
}

final levelProvider = StateNotifierProvider<LevelNotifier, LevelProgress>((ref) => LevelNotifier());
