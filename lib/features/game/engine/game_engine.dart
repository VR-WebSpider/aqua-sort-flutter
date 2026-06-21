import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:aqua_sort/core/services/economy_config.dart';

// ── Seeded RNG (matches vanilla JS LCG) ──────────────────────────────────────
class SeededRng {
  int _s;
  SeededRng(this._s);
  double next() {
    _s = (_s * 1664525 + 1013904223) & 0xFFFFFFFF;
    return _s / 0xFFFFFFFF;
  }
  int nextInt(int max) => (next() * max).floor();
}

// ── Color palette ─────────────────────────────────────────────────────────────


const List<Color> kTubeColors = [
  Color(0xFFFF007F), // Neon Magenta/Pink
  Color(0xFF00F5FF), // Electric Cyan
  Color(0xFF9DFF00), // Neon Lime Green
  Color(0xFFBD00FF), // Electric Purple/Violet
  Color(0xFF0066FF), // Electric Blue
  Color(0xFFFF6600), // Vibrant Neon Orange
  Color(0xFFFFEE00), // Electric Lemon Yellow
  Color(0xFFFF00E0), // Neon Pink
];

// ── Tube model ────────────────────────────────────────────────────────────────
class Tube {
  static const int slots = 4;
  final List<int> colors; // -1 = empty
  final bool isMystery;

  Tube(this.colors, {this.isMystery = false});
  Tube.empty() : colors = [-1, -1, -1, -1], isMystery = false;
  Tube.copy(Tube t) : colors = List.from(t.colors), isMystery = t.isMystery;

  int get topColor   => colors.lastWhere((c) => c >= 0, orElse: () => -1);
  int get freeSlots  => colors.where((c) => c < 0).length;
  bool get isEmpty   => colors.every((c) => c < 0);
  bool get isSolved  => isEmpty || (colors.where((c) => c >= 0).toSet().length == 1 && freeSlots == 0);

  int get topCount {
    final top = topColor; if (top < 0) return 0;
    int c = 0;
    for (int i = colors.length - 1; i >= 0 && colors[i] == top; i--) c++;
    return c;
  }
}

// ── Game state ────────────────────────────────────────────────────────────────
class GameState {
  final List<Tube> tubes;
  final int moves;
  final int seconds;
  final int maxMoves;
  final int maxSeconds;
  final int undosUsed;
  final bool won;
  final bool lost;
  final int? selectedTube;
  final List<GameState> history;

  const GameState({
    required this.tubes,
    this.moves = 0,
    this.seconds = 0,
    this.maxMoves = 50,
    this.maxSeconds = 120,
    this.undosUsed = 0,
    this.won = false,
    this.lost = false,
    this.selectedTube,
    this.history = const [],
  });

  bool get canUndo => history.isNotEmpty;
  int get movesLeft => maxMoves - moves;
  int get secondsLeft => maxSeconds - seconds;

  /// Whether a free undo is still available.
  bool get canFreeUndo =>
      history.isNotEmpty && undosUsed < EconomyConfig.freeUndoLimit;

  /// Whether the player must pay (coins/ads/premium) to undo.
  bool get needsPaidUndo =>
      history.isNotEmpty && undosUsed >= EconomyConfig.freeUndoLimit;

  /// Free undos remaining this round.
  int get freeUndosLeft =>
      (EconomyConfig.freeUndoLimit - undosUsed).clamp(0, EconomyConfig.freeUndoLimit);

  /// Create a copy with bonus seconds added (ad-recovery after time-out).
  GameState withBonusTime(int extraSeconds) => GameState(
    tubes: tubes,
    moves: moves,
    seconds: seconds,
    maxMoves: maxMoves,
    maxSeconds: maxSeconds + extraSeconds,
    undosUsed: undosUsed,
    won: won,
    lost: false,
    selectedTube: selectedTube,
    history: history,
  );

  /// Create a copy with bonus moves added (ad-recovery after move depletion).
  GameState withBonusMoves(int extraMoves) => GameState(
    tubes: tubes,
    moves: moves,
    seconds: seconds,
    maxMoves: maxMoves + extraMoves,
    maxSeconds: maxSeconds,
    undosUsed: undosUsed,
    won: won,
    lost: false,
    selectedTube: selectedTube,
    history: history,
  );
}

// ── Puzzle generator ──────────────────────────────────────────────────────────
class PuzzleGenerator {
  static GameState generate({required int level, required Difficulty difficulty, required int seed}) {
    final rng = SeededRng(seed);
    
    // Level 1 tutorial
    if (level == 1) {
      return GameState(
        tubes: [
          Tube([0, 0, -1, -1]),
          Tube([0, 0, -1, -1]),
        ],
        maxMoves: 20,
        maxSeconds: 60,
      );
    }
    
    // Level 2 can now be naturally generated as the tutorial is dynamic
    
    int colorCount;
    int emptyTubes = 2;

    // Linear scaling for early levels
    if (level == 2) {
      colorCount = 2;
      emptyTubes = 2;
    } else if (level <= 5) {
      colorCount = level;
      emptyTubes = 2;
    } else {
      // Standard difficulty after Level 5
      colorCount = difficulty.colorCount;
      emptyTubes = 2;
    }

    final totalTubes = colorCount + emptyTubes;
    final isSpecial = (level % 5 == 0);

    // Fill colors × 4 each, shuffle
    final pool = <int>[];
    for (int c = 0; c < colorCount; c++) {
      for (int s = 0; s < Tube.slots; s++) pool.add(c);
    }
    // Fisher-Yates
    for (int i = pool.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final t = pool[i]; pool[i] = pool[j]; pool[j] = t;
    }

    final tubes = <Tube>[];
    for (int t = 0; t < colorCount; t++) {
      tubes.add(Tube(pool.sublist(t * 4, t * 4 + 4), isMystery: isSpecial));
    }
    for (int e = 0; e < emptyTubes; e++) tubes.add(Tube.empty());

    return GameState(
      tubes: tubes,
      maxMoves: difficulty.maxMoves,
      maxSeconds: difficulty.maxSeconds,
    );
  }
}

// ── Move logic ────────────────────────────────────────────────────────────────
class GameEngine {
  static bool canPour(Tube from, Tube to) {
    if (from.isEmpty) return false;
    if (to.isEmpty) return true; // Check emptiness BEFORE isSolved
    if (to.isSolved) return false;
    return to.freeSlots > 0 && from.topColor == to.topColor;
  }

  static GameState pour(GameState state, int fromIdx, int toIdx) {
    if (state.lost || state.won) return state;
    
    final from = Tube.copy(state.tubes[fromIdx]);
    final to   = Tube.copy(state.tubes[toIdx]);
    if (!canPour(from, to)) return state;

    final color = from.topColor;
    while (from.topColor == color && to.freeSlots > 0) {
      final slot = to.colors.lastIndexOf(-1);
      to.colors[slot] = color;
      from.colors[from.colors.lastIndexOf(color)] = -1;
    }

    final newTubes = List<Tube>.from(state.tubes);
    newTubes[fromIdx] = from;
    newTubes[toIdx]   = to;
    final won = newTubes.every((t) => t.isSolved);
    
    final nextMoves = state.moves + 1;
    final lost = !won && nextMoves >= state.maxMoves;

    return GameState(
      tubes: newTubes,
      moves: nextMoves,
      seconds: state.seconds,
      maxMoves: state.maxMoves,
      maxSeconds: state.maxSeconds,
      undosUsed: state.undosUsed,
      won: won,
      lost: lost,
      history: [...state.history, state],
    );
  }

  static GameState undo(GameState state) {
    if (state.history.isEmpty) return state;
    final previous = state.history.last;
    return GameState(
      tubes: previous.tubes,
      moves: previous.moves,
      seconds: state.seconds, // Time carries forward
      maxMoves: state.maxMoves,
      maxSeconds: state.maxSeconds,
      undosUsed: state.undosUsed + 1,
      won: previous.won,
      lost: false, // Undo always removes lost condition from steps if they steps back from loss edge
      history: previous.history,
    );
  }

  static GameState tick(GameState state) {
    if (state.won || state.lost) return state;
    final nextSec = state.seconds + 1;
    final lost = nextSec >= state.maxSeconds;
    
    return GameState(
      tubes: state.tubes,
      moves: state.moves,
      seconds: nextSec,
      maxMoves: state.maxMoves,
      maxSeconds: state.maxSeconds,
      undosUsed: state.undosUsed,
      won: state.won,
      lost: lost,
      selectedTube: state.selectedTube,
      history: state.history,
    );
  }

  static int howManyCanPour(Tube from, Tube to) {
    if (!canPour(from, to)) return 0;
    return math.min(from.topCount, to.freeSlots);
  }
}

// ── Difficulty config ─────────────────────────────────────────────────────────
enum Difficulty { easy, medium, hard, expert }

extension DifficultyExt on Difficulty {
  String get label => ['Easy','Medium','Hard','Expert'][index];
  int get colorCount => [4, 6, 7, 8][index];
  String get icon => ['🌊','💧','🌀','⚡'][index];
  int get maxMoves => [50, 70, 90, 110][index];
  int get maxSeconds => [180, 240, 300, 360][index];
  Color get color => [
    const Color(0xFF26C6DA), const Color(0xFF42A5F5),
    const Color(0xFFAB47BC), const Color(0xFFEF5350),
  ][index];
}
