import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameRecord {
  final int level;
  final int moves;
  final int seconds;
  final DateTime date;

  GameRecord({required this.level, required this.moves, required this.seconds, required this.date});

  Map<String, dynamic> toJson() => {
    'level': level,
    'moves': moves,
    'seconds': seconds,
    'date': date.toIso8601String(),
  };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
    level: json['level'],
    moves: json['moves'],
    seconds: json['seconds'],
    date: DateTime.parse(json['date']),
  );
}

class HistoryNotifier extends StateNotifier<List<GameRecord>> {
  HistoryNotifier() : super([]) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('game_history') ?? [];
    state = data.map((e) => GameRecord.fromJson(jsonDecode(e))).toList().reversed.toList();
  }

  Future<void> recordWin({required int level, required int moves, required int seconds}) async {
    final record = GameRecord(level: level, moves: moves, seconds: seconds, date: DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList('game_history') ?? [];
    current.add(jsonEncode(record.toJson()));
    
    // Keep last 50 games
    if (current.length > 50) current.removeAt(0);
    
    await prefs.setStringList('game_history', current);
    await _load();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('game_history');
    state = [];
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, List<GameRecord>>((ref) => HistoryNotifier());
