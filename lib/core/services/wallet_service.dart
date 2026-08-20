import 'package:cloud_firestore/cloud_firestore.dart';

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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchWallet(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }
      return null;
    } catch (_) {
      return null;
    }
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
      final userRef = _firestore.collection('users').doc(userId);
      
      final newBalance = await _firestore.runTransaction<int>((transaction) async {
        final snapshot = await transaction.get(userRef);
        final currentCoins = (snapshot.data()?['coins'] as num?)?.toInt() ?? 0;
        final updatedCoins = currentCoins + amount;
        
        transaction.set(userRef, {
          'coins': updatedCoins,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return updatedCoins;
      });

      await _logTransaction(
        userId: userId,
        type: 'credit',
        amount: amount,
        reason: reason,
        metadata: metadata,
      );

      return newBalance;
    } catch (e) {
      return null;
    }
  }

  /// Update any WebSpider currency type in Cloud Firestore.
  /// Returns the new balance on success, or null on failure.
  Future<int?> updateWebSpiderCurrency({
    required String userId,
    required String currencyType,
    required int amount,
    required String reason,
    String gameId = 'aqua_sort',
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final fieldName = 'webspider_${currencyType.toLowerCase()}_coins';

      final newBalance = await _firestore.runTransaction<int>((transaction) async {
        final snapshot = await transaction.get(userRef);
        final current = (snapshot.data()?[fieldName] as num?)?.toInt() ?? 0;
        final updated = current + amount;

        transaction.set(userRef, {
          fieldName: updated,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return updated;
      });

      await _logTransaction(
        userId: userId,
        type: amount >= 0 ? 'credit' : 'debit',
        amount: amount.abs(),
        reason: '$reason ($currencyType)',
        metadata: {'game_id': gameId, 'currency_type': currencyType},
      );

      return newBalance;
    } catch (e) {
      return null;
    }
  }

  /// Claim the daily streak reward atomically.
  /// Returns a Map containing the claim results.
  Future<Map<String, dynamic>?> claimDailyReward({required String userId}) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      
      final result = await _firestore.runTransaction<Map<String, dynamic>>((transaction) async {
        final snapshot = await transaction.get(userRef);
        final data = snapshot.data() ?? {};
        
        final lastClaimTimestamp = (data['last_daily_claim_at'] as Timestamp?)?.toDate();
        final now = DateTime.now();

        if (lastClaimTimestamp != null) {
          final difference = now.difference(lastClaimTimestamp);
          // If claimed less than 20 hours ago, cooldown is active
          if (difference.inHours < 20) {
            return {
              'success': false,
              'reason': 'cooldown_active',
              'next_available_in_hours': 20 - difference.inHours,
            };
          }
        }

        int currentStreak = (data['daily_streak_count'] as num?)?.toInt() ?? 0;
        // If last claim was more than 48 hours ago, reset streak
        if (lastClaimTimestamp != null && now.difference(lastClaimTimestamp).inHours > 48) {
          currentStreak = 0;
        }

        final nextStreak = (currentStreak % 7) + 1;
        final totalClaims = ((data['total_daily_claims'] as num?)?.toInt() ?? 0) + 1;

        // Reward tiers based on streak day
        final int rewardCoins = CoinReward.dailyClaim * nextStreak;
        final int currentCoins = (data['coins'] as num?)?.toInt() ?? 0;

        transaction.set(userRef, {
          'coins': currentCoins + rewardCoins,
          'daily_streak_count': nextStreak,
          'total_daily_claims': totalClaims,
          'last_daily_claim_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return {
          'success': true,
          'streak_count': nextStreak,
          'total_claims': totalClaims,
          'reward_amount': rewardCoins,
          'new_coins': currentCoins + rewardCoins,
        };
      });

      return result;
    } catch (e) {
      return null;
    }
  }

  /// Claim a lifetime milestone reward chest.
  Future<Map<String, dynamic>?> claimMilestoneReward({
    required String userId,
    required String milestoneId,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      final result = await _firestore.runTransaction<Map<String, dynamic>>((transaction) async {
        final snapshot = await transaction.get(userRef);
        final data = snapshot.data() ?? {};
        final claimed = List<String>.from(data['claimed_milestones'] ?? []);

        if (claimed.contains(milestoneId)) {
          return {'success': false, 'reason': 'already_claimed'};
        }

        claimed.add(milestoneId);
        final int bonusCoins = 150;
        final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;

        transaction.set(userRef, {
          'coins': currentCoins + bonusCoins,
          'claimed_milestones': claimed,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return {
          'success': true,
          'milestone_id': milestoneId,
          'bonus_coins': bonusCoins,
          'new_coins': currentCoins + bonusCoins,
        };
      });

      return result;
    } catch (e) {
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

  /// Spend coins and mark skin as owned.
  Future<bool> purchaseSkin({
    required String userId,
    required String skinId,
    required int price,
    required List<String> currentOwnedSkins,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      return await _firestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(userRef);
        final data = snapshot.data() ?? {};
        final coins = (data['coins'] as num?)?.toInt() ?? 0;
        final owned = List<String>.from(data['owned_skins'] ?? ['default']);

        if (coins < price || owned.contains(skinId)) return false;

        owned.add(skinId);
        transaction.set(userRef, {
          'coins': coins - price,
          'owned_skins': owned,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return true;
      });
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
      await _firestore.collection('transactions').add({
        'user_id': userId,
        'type': type,
        'amount': amount,
        'reason': reason,
        'metadata': metadata ?? {},
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-fatal audit log
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
