import 'package:supabase_flutter/supabase_flutter.dart';

/// All coin denominations used across the game.
class CoinReward {
  static const int levelBase = 30;
  static const int movesBonus = 10; // per "efficiency" bracket
  static const int timeBonus = 10; // per "speed" bracket
  static const int milestoneBonus = 50; // every 5th level
  static const int dailyClaim = 50;
}

class WalletService {
  static final WalletService instance = WalletService._();
  WalletService._();

  final SupabaseClient _db = Supabase.instance.client;

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchWallet(String userId) async {
    return await _db
        .from('profiles')
        .select('coins, owned_skins')
        .eq('id', userId)
        .maybeSingle();
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Award coins to the player and log the transaction.
  /// Returns the new coin balance, or null on failure.
  Future<int?> awardCoins({
    required String userId,
    required int amount,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Atomic increment via RPC (or manual read-modify-write)
      final profile = await _db
          .from('profiles')
          .select('coins')
          .eq('id', userId)
          .single();

      final current = (profile['coins'] as num?)?.toInt() ?? 0;
      final newBalance = current + amount;

      await _db.from('profiles').update({'coins': newBalance}).eq('id', userId);

      await _logTransaction(
        userId: userId,
        type: 'credit',
        amount: amount,
        reason: reason,
        metadata: metadata,
      );

      return newBalance;
    } catch (_) {
      return null;
    }
  }

  /// Update any WebSpider currency type in the cloud database via RPC.
  /// Returns the new balance on success, or null on failure.
  Future<int?> updateWebSpiderCurrency({
    required String userId,
    required String currencyType,
    required int amount,
    required String reason,
    String gameId = 'aqua_sort',
  }) async {
    try {
      final response = await _db.rpc(
        'update_webspider_currency_v1',
        params: {
          'p_user_id': userId,
          'p_currency_type': currencyType,
          'p_amount': amount,
          'p_reason': reason,
          'p_game_id': gameId,
        },
      );
      return (response as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  /// Claim the daily streak reward atomically.
  /// Returns a Map containing the claim results (success, streak_count, reward_type, reward_amount, etc.).
  Future<Map<String, dynamic>?> claimDailyReward({required String userId}) async {
    try {
      final response = await _db.rpc(
        'claim_daily_reward_v1',
        params: {
          'p_user_id': userId,
        },
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return null;
    } catch (e) {
      print('Error claiming daily reward: $e');
      return null;
    }
  }

  /// Claim a lifetime milestone reward chest.
  /// Returns a Map containing the claim results (success, claimed_milestones, rewards, etc.).
  Future<Map<String, dynamic>?> claimMilestoneReward({
    required String userId,
    required String milestoneId,
  }) async {
    try {
      final response = await _db.rpc(
        'claim_milestone_reward_v1',
        params: {
          'p_user_id': userId,
          'p_milestone_id': milestoneId,
        },
      );
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return null;
    } catch (e) {
      print('Error claiming milestone reward: $e');
      return null;
    }
  }

  /// Legacy wrapper to award/deduct WebSpider Coins (maps to Gold coins).
  Future<int?> awardWebSpiderCoins({
    required String userId,
    required int amount,
    required String reason,
    String gameId = 'aqua_sort',
  }) async {
    return updateWebSpiderCurrency(
      userId: userId,
      currencyType: 'gold',
      amount: amount,
      reason: reason,
      gameId: gameId,
    );
  }

  /// Spend coins and mark skin as owned. Server-side guards via RLS.
  /// Returns true on success, false on insufficient funds or already owned.
  Future<bool> purchaseSkin({
    required String userId,
    required String skinId,
    required int price,
    required List<String> currentOwnedSkins,
  }) async {
    try {
      final profile = await _db
          .from('profiles')
          .select('coins, owned_skins')
          .eq('id', userId)
          .single();

      final coins = (profile['coins'] as num?)?.toInt() ?? 0;
      final owned = List<String>.from(profile['owned_skins'] ?? []);

      if (coins < price || owned.contains(skinId)) return false;

      final newBalance = coins - price;
      owned.add(skinId);

      await _db.from('profiles').update({
        'coins': newBalance,
        'owned_skins': owned,
      }).eq('id', userId);

      await _logTransaction(
        userId: userId,
        type: 'debit',
        amount: price,
        reason: 'skin_purchase',
        metadata: {'skin_id': skinId},
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _logTransaction({
    required String userId,
    required String type,
    required int amount,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _db.from('transactions').insert({
        'user_id': userId,
        'type': type,
        'amount': amount,
        'reason': reason,
        'metadata': metadata ?? {},
      });
    } catch (_) {
      // Non-fatal; audit log failure should not break the game.
    }
  }

  /// Calculate total reward for completing a level.
  static int calculateLevelReward({
    required int level,
    required int moves,
    required int seconds,
  }) {
    int reward = CoinReward.levelBase;

    // Moves efficiency bonus (fewer moves = more coins)
    if (moves <= 10) {
      reward += CoinReward.movesBonus * 3;
    } else if (moves <= 20) {
      reward += CoinReward.movesBonus * 2;
    } else if (moves <= 35) {
      reward += CoinReward.movesBonus;
    }

    // Speed bonus
    if (seconds <= 30) {
      reward += CoinReward.timeBonus * 3;
    } else if (seconds <= 60) {
      reward += CoinReward.timeBonus * 2;
    } else if (seconds <= 120) {
      reward += CoinReward.timeBonus;
    }

    // Milestone bonus
    if (level % 5 == 0) reward += CoinReward.milestoneBonus;

    return reward;
  }
}
