import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/game_engine.dart';
import 'package:aqua_sort/core/services/audio_service.dart';
import 'package:aqua_sort/core/services/wallet_service.dart';
import 'package:aqua_sort/core/services/economy_config.dart';
import 'package:aqua_sort/core/services/ad_service.dart';
import 'package:aqua_sort/features/leaderboard/providers/leaderboard_provider.dart';
import 'package:aqua_sort/features/leaderboard/models/score_entry.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';
import 'package:aqua_sort/features/lobby/providers/multiplayer_provider.dart';
import 'package:aqua_sort/features/profile/providers/premium_provider.dart';
import 'package:aqua_sort/features/game/widgets/undo_gate_sheet.dart';
import 'package:aqua_sort/features/profile/widgets/premium_purchase_dialog.dart';
import 'package:aqua_sort/features/game/widgets/game_tutorial_dialogs.dart';
import 'package:aqua_sort/features/game/widgets/pause_dialogs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum GameStatus { waiting, starting, playing, paused, finished }

// ── Game args (passed from lobby) ─────────────────────────────────────────────
class GameArgs {
  final Difficulty difficulty;
  final int playerCount;
  final bool isGuest;
  final bool isOnline;
  final String? roomId;
  final int? seed;

  const GameArgs({
    required this.difficulty, 
    required this.playerCount, 
    this.isGuest = false,
    this.isOnline = false,
    this.roomId,
    this.seed,
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
  final bool isOnline;
  final GameStatus status;
  final int? winnerIdx;
  final int countdown;
  final int pausesUsed;

  const MultiGameState({
    required this.playerStates, 
    this.activePours = const {}, 
    this.isSplitScreen = false,
    this.isOnline = false,
    this.status = GameStatus.playing,
    this.winnerIdx,
    this.countdown = 0,
    this.pausesUsed = 0,
  });

  factory MultiGameState.init(int players, Difficulty diff, int level, int seed, {bool isOnline = false}) {
    final Map<int, GameState> states = {};
    for (int i = 0; i < players; i++) {
        states[i] = PuzzleGenerator.generate(level: level, difficulty: diff, seed: seed);
    }
    return MultiGameState(
      playerStates: states, 
      activePours: {}, 
      isSplitScreen: players > 1, 
      isOnline: isOnline,
      status: isOnline ? GameStatus.waiting : GameStatus.playing,
      pausesUsed: 0,
    );
  }

  MultiGameState copyWith({
    Map<int, GameState>? states, 
    Map<int, ActivePour?>? pours,
    GameStatus? status,
    int? winnerIdx,
    int? countdown,
    int? pausesUsed,
  }) {
    return MultiGameState(
      playerStates: states ?? playerStates,
      activePours: pours ?? activePours,
      isSplitScreen: isSplitScreen,
      isOnline: isOnline,
      status: status ?? this.status,
      winnerIdx: winnerIdx ?? this.winnerIdx,
      countdown: countdown ?? this.countdown,
      pausesUsed: pausesUsed ?? this.pausesUsed,
    );
  }
}

class GameNotifier extends StateNotifier<MultiGameState> {
  final Ref ref;
  Timer? _timer;
  RealtimeChannel? _gameChannel;

  GameNotifier(this.ref) : super(const MultiGameState(playerStates: {}));

  void startGame(GameArgs args) {
    _timer?.cancel();
    _gameChannel?.unsubscribe();
    
    final seed = args.seed ?? DateTime.now().millisecondsSinceEpoch;
    final progress = ref.read(levelProvider);
    
    state = MultiGameState.init(args.playerCount, args.difficulty, progress.currentLevel, seed, isOnline: args.isOnline);
    
    if (args.isOnline && args.roomId != null) {
      _setupNetwork(args.roomId!);
    } else {
      _startTickTimer();
    }
  }

  void _startTickTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status != GameStatus.playing) return;

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

  void _setupNetwork(String roomId) {
    final auth = ref.read(authProvider);
    _gameChannel = Supabase.instance.client.channel('match_$roomId');

    _gameChannel!.onBroadcast(event: 'move', callback: (payload) {
      final String senderId = payload['sender_id'];
      if (senderId == auth.user!.id) return;

      final int remotePlayerIdx = 1; 
      final tubesData = (payload['tubes'] as List).map((t) => List<int>.from(t)).toList();
      
      final remoteState = GameState(
        tubes: tubesData.map((t) => Tube(t)).toList(),
        moves: payload['moves'],
        seconds: payload['seconds'],
        won: payload['won'],
        history: [], 
      );

      _updatePlayerState(remotePlayerIdx, remoteState);
      
      if (remoteState.won && state.status != GameStatus.finished) {
         state = state.copyWith(status: GameStatus.finished, winnerIdx: 1);
         final args = ref.read(gameArgsProvider);
         if (args.roomId != null) {
           ref.read(multiplayerProvider.notifier).updateRoomStatus(args.roomId!, 'finished');
         }
      }
    }).onBroadcast(event: 'ready', callback: (payload) {
      // When both players are here, start the countdown
      if (state.status == GameStatus.waiting) {
        _startCountdown();
      }
    }).subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        // Broadcast that we are here
        _gameChannel!.send(
          type: 'broadcast' as dynamic,
          event: 'ready',
          payload: {'sender_id': auth.user!.id},
        );
      }
    });
  }

  void _startCountdown() async {
    state = state.copyWith(status: GameStatus.starting, countdown: 3);
    
    for (int i = 3; i > 0; i--) {
      state = state.copyWith(countdown: i);
      await Future.delayed(const Duration(seconds: 1));
    }
    
    state = state.copyWith(status: GameStatus.playing);
    _startTickTimer();
  }

  void selectTube(int playerIdx, int tubeIdx) {
    if (state.status != GameStatus.playing) return;
    
    // Online check: can only move your own tubes (idx 0)
    if (state.isOnline && playerIdx != 0) return;

    final playerState = state.playerStates[playerIdx];
    final activePour = state.activePours[playerIdx];
    if (playerState == null || playerState.won || activePour != null) return;

    final sel = playerState.selectedTube;
    AudioService.instance.playTubeClick();

    if (sel == null) {
      if (playerState.tubes[tubeIdx].isEmpty) return;
      _updatePlayerState(playerIdx, GameState(
        tubes: playerState.tubes, moves: playerState.moves, seconds: playerState.seconds,
        won: playerState.won, selectedTube: tubeIdx, history: playerState.history));
    } else if (sel == tubeIdx) {
      _updatePlayerState(playerIdx, GameState(tubes: playerState.tubes, moves: playerState.moves,
          seconds: playerState.seconds, won: playerState.won, history: playerState.history));
    } else {
      if (GameEngine.canPour(playerState.tubes[sel], playerState.tubes[tubeIdx])) {
        final count = GameEngine.howManyCanPour(playerState.tubes[sel], playerState.tubes[tubeIdx]);
        final color = playerState.tubes[sel].topColor;
        final newPours = Map<int, ActivePour?>.from(state.activePours);
        newPours[playerIdx] = ActivePour(fromIdx: sel, toIdx: tubeIdx, color: color, count: count);
        state = state.copyWith(pours: newPours);
        final pourDuration = (count * 300 > 500) ? count * 300 : 500;
        final duration = 600 + pourDuration;
        Future.delayed(Duration(milliseconds: duration + 200), () => finalizePour(playerIdx));
      } else {
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
    
    final newPours = Map<int, ActivePour?>.from(state.activePours);
    newPours[playerIdx] = null;
    
    final newStates = Map<int, GameState>.from(state.playerStates);
    newStates[playerIdx] = newState;
    
    state = state.copyWith(states: newStates, pours: newPours);

    // Broadcast update if online
    if (state.isOnline && playerIdx == 0) {
      _broadcastMove(newState);
    }

    if (newState.won) {
        AudioService.instance.playWin();
        if (state.status != GameStatus.finished) {
           state = state.copyWith(status: GameStatus.finished, winnerIdx: playerIdx);
           final args = ref.read(gameArgsProvider);
           if (args.roomId != null) {
              ref.read(multiplayerProvider.notifier).updateRoomStatus(args.roomId!, 'finished');
           }
        }
        _syncScore(playerIdx, newState);
        _rewardPlayer(newState);
    }
  }

  void _broadcastMove(GameState gameState) {
    if (_gameChannel == null) return;
    final auth = ref.read(authProvider);

    _gameChannel!.send(
      type: 'broadcast' as dynamic,
      event: 'move',
      payload: {
        'sender_id': auth.user!.id,
        'moves': gameState.moves,
        'seconds': gameState.seconds,
        'won': gameState.won,
        'tubes': gameState.tubes.map((t) => t.colors).toList(),
      },
    );
  }

  void _updatePlayerState(int playerIdx, GameState newState) {
    final newStates = Map<int, GameState>.from(state.playerStates);
    newStates[playerIdx] = newState;
    state = state.copyWith(states: newStates);
  }

  void _syncScore(int playerIdx, GameState gameState) {
      final args = ref.read(gameArgsProvider);
      ref.read(leaderboardNotifierProvider.notifier).recordScore(
        moves: gameState.moves,
        seconds: gameState.seconds,
        difficulty: args.difficulty.label,
      );
  }

  /// Calculates dynamic reward and writes it to the cloud wallet.
  void _rewardPlayer(GameState gameState) {
      final args = ref.read(gameArgsProvider);
      // Only reward the primary player in single-player or online modes
      if (args.playerCount > 1 && !args.isOnline) return;

      final progress = ref.read(levelProvider);
      final level = progress.currentLevel;

      // Advance level progress (unlocks next level, local prefs)
      ref.read(levelProvider.notifier).completeLevel(level);

      // Calculate and award dynamic coin reward
      final reward = WalletService.calculateLevelReward(
        level: level,
        moves: gameState.moves,
        seconds: gameState.seconds,
      );

      ref.read(levelProvider.notifier).awardCoins(
        reward,
        'level_complete',
        metadata: {
          'level': level,
          'moves': gameState.moves,
          'seconds': gameState.seconds,
        },
      );
  }

  /// Direct undo (always executes — no gating). Used internally.
  void _performUndo(int playerIdx) {
    final playerState = state.playerStates[playerIdx];
    if (playerState == null) return;
    
    final newState = GameEngine.undo(playerState);
    _updatePlayerState(playerIdx, newState);
    
    if (state.isOnline && playerIdx == 0) {
      _broadcastMove(newState);
    }
  }

  /// Public undo with economy gating.
  /// First 2 undos are free. Beyond that requires Spider Coins, ads, or premium.
  Future<void> requestUndo(int playerIdx, BuildContext context) async {
    if (state.isOnline && playerIdx != 0) return;
    final playerState = state.playerStates[playerIdx];
    if (playerState == null || !playerState.canUndo) return;

    // Free undo path
    if (playerState.canFreeUndo) {
      _performUndo(playerIdx);
      return;
    }

    // Premium users get unlimited undos
    final isPremium = ref.read(premiumProvider);
    if (isPremium) {
      _performUndo(playerIdx);
      return;
    }

    // First time running out of free undos tutorial
    final progress = ref.read(levelProvider);
    if (!progress.undoTutorialSeen) {
      final oldStatus = state.status;
      state = state.copyWith(status: GameStatus.paused);
      
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const UndoTutorialDialog(),
        );
        await ref.read(levelProvider.notifier).markUndoTutorialSeen();
      }
      state = state.copyWith(status: oldStatus);
    }

    // Show undo gate bottom sheet
    final coins = progress.coins;
    final goldCoins = progress.spiderGoldCoins;
    final copperCoins = progress.spiderCopperCoins;
    final result = await showModalBottomSheet<UndoGateResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UndoGateSheet(
        playerCoins: coins,
        spiderGoldCoins: goldCoins,
        spiderCopperCoins: copperCoins,
        isPremium: isPremium,
      ),
    );

    if (result == null || result == UndoGateResult.cancelled) return;

    switch (result) {
      case UndoGateResult.usedGold:
        await ref.read(levelProvider.notifier).awardWebSpiderCurrency('gold', -5, 'undo_purchase');
        _performUndo(playerIdx);
        break;
      case UndoGateResult.usedCopper:
        await ref.read(levelProvider.notifier).awardWebSpiderCurrency('copper', -50, 'undo_purchase');
        _performUndo(playerIdx);
        break;
      case UndoGateResult.watchedAd:
        if (!context.mounted) return;
        final reward = await AdService.instance.showRewardedAd(context);
        if (reward != null) {
          await ref.read(levelProvider.notifier).awardWebSpiderCurrency('gold', 10, 'ad_reward_spider_coins');
          // Auto-undo if they now have enough Gold Coins
          final updatedGoldCoins = ref.read(levelProvider).spiderGoldCoins;
          if (updatedGoldCoins >= 5) {
            await ref.read(levelProvider.notifier).awardWebSpiderCurrency('gold', -5, 'undo_purchase');
            _performUndo(playerIdx);
          }
        }
        break;
      case UndoGateResult.goPremium:
        if (!context.mounted) return;
        final purchased = await PremiumPurchaseDialog.show(context);
        if (purchased) {
          _performUndo(playerIdx);
        }
        break;
      default:
        break;
    }
  }

  /// Pauses the game (timer and interactions).
  /// First 2 pauses are free. Subsequent pauses require Spider Coins, Ads, or Premium.
  Future<void> pauseGame(BuildContext context) async {
    if (state.status != GameStatus.playing) return;
    if (state.isOnline || state.isSplitScreen) return; // Pausing not allowed in multiplayer/online

    final isPremium = ref.read(premiumProvider);

    // If free pauses (2) are exhausted and they are not premium, show the Pause Gate Dialog.
    if (state.pausesUsed >= 2 && !isPremium) {
      if (!context.mounted) return;
      
      final oldStatus = state.status;
      state = state.copyWith(status: GameStatus.paused);

      final currentProgress = ref.read(levelProvider);
      final result = await showDialog<PauseGateResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PauseGateDialog(
          spiderGoldCoins: currentProgress.spiderGoldCoins,
          spiderBrassCoins: currentProgress.spiderBrassCoins,
        ),
      );

      if (result == null || result == PauseGateResult.cancelled) {
        state = state.copyWith(status: oldStatus);
        return;
      }

      switch (result) {
        case PauseGateResult.usedGold:
          await ref.read(levelProvider.notifier).awardWebSpiderCurrency('gold', -2, 'pause_purchase');
          break;
        case PauseGateResult.usedBrass:
          await ref.read(levelProvider.notifier).awardWebSpiderCurrency('brass', -20, 'pause_purchase');
          break;
        case PauseGateResult.watchedAd:
          final reward = await AdService.instance.showRewardedAd(context);
          if (reward == null) {
            state = state.copyWith(status: oldStatus);
            return;
          }
          await ref.read(levelProvider.notifier).awardWebSpiderCurrency('gold', 10, 'ad_reward_spider_coins');
          break;
        case PauseGateResult.goPremium:
          final purchased = await PremiumPurchaseDialog.show(context);
          if (!purchased) {
            state = state.copyWith(status: oldStatus);
            return;
          }
          break;
        default:
          state = state.copyWith(status: oldStatus);
          return;
      }
    }

    // Increment pauses used
    state = state.copyWith(
      status: GameStatus.paused,
      pausesUsed: state.pausesUsed + 1,
    );

    // Show the main Pause Dialog
    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PauseDialog(
          pausesUsed: state.pausesUsed,
          isPremium: isPremium,
        ),
      );
      resumeGame();
    }
  }

  void resumeGame() {
    if (state.status == GameStatus.paused) {
      state = state.copyWith(status: GameStatus.playing);
    }
  }

  /// Pauses the game timer temporarily for tutorials or other system overlays
  void pauseForTutorial() {
    if (state.status == GameStatus.playing) {
      state = state.copyWith(status: GameStatus.paused);
    }
  }

  /// Resumes the game timer after tutorials are dismissed
  void resumeFromTutorial() {
    if (state.status == GameStatus.paused) {
      state = state.copyWith(status: GameStatus.playing);
    }
  }

  /// Legacy undo (kept for backward compatibility / online play).
  void undo(int playerIdx) {
    if (state.isOnline && playerIdx != 0) return;
    _performUndo(playerIdx);
  }

  /// Grant bonus time after watching an ad on time-out loss.
  void grantBonusTime(int playerIdx) {
    final playerState = state.playerStates[playerIdx];
    if (playerState == null) return;
    _updatePlayerState(
      playerIdx,
      playerState.withBonusTime(EconomyConfig.adBonusSeconds),
    );
  }

  /// Grant bonus moves after watching an ad on moves-depleted loss.
  void grantBonusMoves(int playerIdx) {
    final playerState = state.playerStates[playerIdx];
    if (playerState == null) return;
    _updatePlayerState(
      playerIdx,
      playerState.withBonusMoves(EconomyConfig.adBonusMoves),
    );
  }

  /// Award coins from watching an ad (can be called from UI directly).
  Future<void> rewardAdCoins(BuildContext context) async {
    final reward = await AdService.instance.showRewardedAd(context);
    if (reward != null) {
      await ref.read(levelProvider.notifier).awardCoins(reward, 'ad_reward');
    }
  }

  @override
  void dispose() { 
    _timer?.cancel(); 
    _gameChannel?.unsubscribe();
    super.dispose(); 
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, MultiGameState>(
  (ref) => GameNotifier(ref),
);
