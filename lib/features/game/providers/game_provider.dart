import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/game_engine.dart';
import 'package:aqua_sort/core/services/audio_service.dart';
import 'package:aqua_sort/features/leaderboard/providers/leaderboard_provider.dart';
import 'package:aqua_sort/features/leaderboard/models/score_entry.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';

// ── Game args (passed from lobby) ─────────────────────────────────────────────
class GameArgs {
  final Difficulty difficulty;
  final int playerCount;
  final bool isGuest;
  final bool isOnline;
  const GameArgs({
    required this.difficulty, 
    required this.playerCount, 
    this.isGuest = false,
    this.isOnline = false,
  });
}

final gameArgsProvider = StateProvider<GameArgs>(
  (_) => const GameArgs(difficulty: Difficulty.easy, playerCount: 1, isOnline: false),
);

class ActivePour {
  final int fromIdx;
  final int toIdx;
  final int color;
  final int count;
  const ActivePour({required this.fromIdx, required this.toIdx, required this.color, required this.count});
}

// ── Active game state (Supports Multi-player) ──────────────────────────────────
class MultiGameState {
  final Map<int, GameState> playerStates;
  final Map<int, ActivePour?> activePours;
  final bool isSplitScreen;

  const MultiGameState({
    required this.playerStates, 
    this.activePours = const {}, 
    this.isSplitScreen = false
  });

  factory MultiGameState.init(int players, Difficulty diff, int seed) {
    final Map<int, GameState> states = {};
    for (int i = 0; i < players; i++) {
        states[i] = PuzzleGenerator.generate(colorCount: diff.colorCount, seed: seed);
    }
    return MultiGameState(playerStates: states, activePours: {}, isSplitScreen: players > 1);
  }

  MultiGameState copyWith({Map<int, GameState>? states, Map<int, ActivePour?>? pours}) {
    return MultiGameState(
      playerStates: states ?? playerStates,
      activePours: pours ?? activePours,
      isSplitScreen: isSplitScreen,
    );
  }
}

class GameNotifier extends StateNotifier<MultiGameState> {
  final Ref ref;
  Timer? _timer;

  GameNotifier(this.ref) : super(const MultiGameState(playerStates: {}));

  void startGame(GameArgs args) {
    _timer?.cancel();
    final seed = DateTime.now().millisecondsSinceEpoch;
    state = MultiGameState.init(args.playerCount, args.difficulty, seed);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final newStates = <int, GameState>{};
      state.playerStates.forEach((idx, s) {
        if (!s.won) {
          newStates[idx] = GameEngine.tick(s);
        } else {
          newStates[idx] = s;
        }
      });
      state = state.copyWith(states: newStates);
    });
  }

  void selectTube(int playerIdx, int tubeIdx) {
    final playerState = state.playerStates[playerIdx];
    final activePour = state.activePours[playerIdx];
    if (playerState == null || playerState.won || activePour != null) return;

    final sel = playerState.selectedTube;
    AudioService.instance.playClick();

    if (sel == null) {
      if (playerState.tubes[tubeIdx].isEmpty) return;
      _updatePlayerState(playerIdx, GameState(
        tubes: playerState.tubes, moves: playerState.moves, seconds: playerState.seconds,
        won: playerState.won, selectedTube: tubeIdx, history: playerState.history));
    } else if (sel == tubeIdx) {
      _updatePlayerState(playerIdx, GameState(tubes: playerState.tubes, moves: playerState.moves,
          seconds: playerState.seconds, won: playerState.won, history: playerState.history));
    } else {
      // ── START POUR ANIMATION ─────────────────────────────────────────────
      if (GameEngine.canPour(playerState.tubes[sel], playerState.tubes[tubeIdx])) {
        final count = GameEngine.howManyCanPour(playerState.tubes[sel], playerState.tubes[tubeIdx]);
        final color = playerState.tubes[sel].topColor;
        final newPours = Map<int, ActivePour?>.from(state.activePours);
        newPours[playerIdx] = ActivePour(fromIdx: sel, toIdx: tubeIdx, color: color, count: count);
        state = state.copyWith(pours: newPours);
        
        // Finalize logic AFTER dynamic animation delay: 700ms base + 300ms per segment
        final duration = 700 + (count * 300);
        Future.delayed(Duration(milliseconds: duration + 100), () => finalizePour(playerIdx));
      } else {
        // Invalid pour: blink/shake handled in UI, just deselect
        _updatePlayerState(playerIdx, GameState(tubes: playerState.tubes, moves: playerState.moves,
            seconds: playerState.seconds, won: playerState.won, history: playerState.history));
      }
    }
  }

  void finalizePour(int playerIdx) {
    final playerState = state.playerStates[playerIdx];
    final activePour = state.activePours[playerIdx];
    if (playerState == null || activePour == null) return;

    final newState = GameEngine.pour(playerState, activePour.fromIdx, activePour.toIdx);
    
    // Clear animation state
    final newPours = Map<int, ActivePour?>.from(state.activePours);
    newPours[playerIdx] = null;
    
    final newStates = Map<int, GameState>.from(state.playerStates);
    newStates[playerIdx] = newState;
    
    state = MultiGameState(playerStates: newStates, activePours: newPours, isSplitScreen: state.isSplitScreen);

    if (newState.won) {
        AudioService.instance.playWin();
        _syncScore(playerIdx, newState);
    }
  }

  void _updatePlayerState(int playerIdx, GameState newState) {
    final newStates = Map<int, GameState>.from(state.playerStates);
    newStates[playerIdx] = newState;
    state = state.copyWith(states: newStates);
  }

  void _syncScore(int playerIdx, GameState gameState) {
      final auth = ref.read(authProvider);
      final args = ref.read(gameArgsProvider);
      
      final entry = ScoreEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: auth.user?.username ?? (playerIdx == 0 ? 'Sorter' : 'Player ${playerIdx + 1}'),
        moves: gameState.moves,
        seconds: gameState.seconds,
        difficulty: args.difficulty.label,
        timestamp: DateTime.now(),
      );

      ref.read(leaderboardProvider.notifier).saveScore(entry);
  }

  void undo(int playerIdx) {
    final playerState = state.playerStates[playerIdx];
    if (playerState == null) return;
    
    final newState = GameEngine.undo(playerState);
    final newPlayerStates = Map<int, GameState>.from(state.playerStates);
    newPlayerStates[playerIdx] = newState;
    state = MultiGameState(playerStates: newPlayerStates, isSplitScreen: state.isSplitScreen);
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
}

final gameProvider = StateNotifierProvider<GameNotifier, MultiGameState>(
  (ref) => GameNotifier(ref),
);
