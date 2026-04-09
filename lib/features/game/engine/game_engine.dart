import 'dart:math' as math;
import 'package:flutter/material.dart';

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
  Color(0xFFEF5350), // Red
  Color(0xFF42A5F5), // Blue
  Color(0xFF66BB6A), // Green
  Color(0xFFFFEE58), // Yellow
  Color(0xFFAB47BC), // Purple
  Color(0xFFFF7043), // Orange
  Color(0xFF26C6DA), // Cyan
  Color(0xFFEC407A), // Pink
];

// ── Tube model ────────────────────────────────────────────────────────────────
class Tube {
  static const int slots = 4;
  final List<int> colors; // -1 = empty

  Tube(this.colors);
  Tube.empty() : colors = [-1, -1, -1, -1];
  Tube.copy(Tube t) : colors = List.from(t.colors);

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
  final bool won;
  final int? selectedTube;
  final List<GameState> history;

  const GameState({
    required this.tubes, this.moves = 0, this.seconds = 0,
    this.won = false, this.selectedTube, this.history = const [],
  });

  bool get canUndo => history.isNotEmpty;
}

// ── Puzzle generator ──────────────────────────────────────────────────────────
class PuzzleGenerator {
  static GameState generate({required int colorCount, required int seed}) {
    final rng = SeededRng(seed);
    final emptyTubes = 2;
    final totalTubes = colorCount + emptyTubes;

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
      tubes.add(Tube(pool.sublist(t * 4, t * 4 + 4)));
    }
    for (int e = 0; e < emptyTubes; e++) tubes.add(Tube.empty());

    return GameState(tubes: tubes);
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

    return GameState(
      tubes: newTubes, moves: state.moves + 1,
      seconds: state.seconds, won: won,
      history: [...state.history, state],
    );
  }

  static GameState undo(GameState state) =>
      state.history.isNotEmpty ? state.history.last : state;

  static GameState tick(GameState state) =>
      GameState(tubes: state.tubes, moves: state.moves,
          seconds: state.seconds + 1, won: state.won,
          selectedTube: state.selectedTube, history: state.history);
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
  Color get color => [
    const Color(0xFF26C6DA), const Color(0xFF42A5F5),
    const Color(0xFFAB47BC), const Color(0xFFEF5350),
  ][index];
}
