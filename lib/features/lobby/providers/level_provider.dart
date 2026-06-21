import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/core/services/wallet_service.dart';

/// LevelProgress only tracks game-state fields that don't need server sync:
/// - currentLevel, unlockedLevels, activeSkinId, tutorialSeen
///
/// Coin balance and ownedSkins are the source of truth from [authProvider]
/// (Supabase-backed). LevelProgress still exposes them for convenience via
/// a passthrough from the auth state, but writes go through [WalletService].
class LevelProgress {
  final int currentLevel;
  final int coins; // mirrored from authProvider for convenience
  final Set<int> unlockedLevels;
  final String activeSkinId;
  final Set<String> ownedSkinIds; // mirrored from authProvider
  final bool tutorialSeen;
  final bool undoTutorialSeen;
  final bool specialLevelTutorialSeen;
  final bool isLoaded;
  
  final int spiderBrassCoins;
  final int spiderCopperCoins;
  final int spiderSilverCoins;
  final int spiderGoldCoins;
  final int spiderDiamondCoins;
  final int spiderJadeCoins;
  final int spiderObsidianCoins;

  // ── Daily Reward & Streak ─────────────────────────────────────────────
  final DateTime? lastDailyClaimAt;
  final int dailyStreakCount;
  final int totalDailyClaims;
  final Set<String> claimedMilestones;

  LevelProgress({
    required this.currentLevel,
    required this.coins,
    int? spiderCoins,
    this.spiderBrassCoins = 100,
    this.spiderCopperCoins = 200,
    this.spiderSilverCoins = 50,
    int? spiderGoldCoins,
    this.spiderDiamondCoins = 0,
    this.spiderJadeCoins = 0,
    this.spiderObsidianCoins = 0,
    required this.unlockedLevels,
    this.activeSkinId = 'default',
    this.ownedSkinIds = const {'default'},
    this.tutorialSeen = false,
    this.undoTutorialSeen = false,
    this.specialLevelTutorialSeen = false,
    this.isLoaded = false,
    this.lastDailyClaimAt,
    this.dailyStreakCount = 0,
    this.totalDailyClaims = 0,
    this.claimedMilestones = const {},
  })  : spiderGoldCoins = spiderGoldCoins ?? spiderCoins ?? 10;

  int get spiderCoins => spiderGoldCoins;

  LevelProgress copyWith({
    int? currentLevel,
    int? coins,
    int? spiderCoins,
    Set<int>? unlockedLevels,
    String? activeSkinId,
    Set<String>? ownedSkinIds,
    bool? tutorialSeen,
    bool? undoTutorialSeen,
    bool? specialLevelTutorialSeen,
    bool? isLoaded,
    int? spiderBrassCoins,
    int? spiderCopperCoins,
    int? spiderSilverCoins,
    int? spiderGoldCoins,
    int? spiderDiamondCoins,
    int? spiderJadeCoins,
    int? spiderObsidianCoins,
    DateTime? lastDailyClaimAt,
    int? dailyStreakCount,
    int? totalDailyClaims,
    Set<String>? claimedMilestones,
  }) {
    return LevelProgress(
      currentLevel: currentLevel ?? this.currentLevel,
      coins: coins ?? this.coins,
      unlockedLevels: unlockedLevels ?? this.unlockedLevels,
      activeSkinId: activeSkinId ?? this.activeSkinId,
      ownedSkinIds: ownedSkinIds ?? this.ownedSkinIds,
      tutorialSeen: tutorialSeen ?? this.tutorialSeen,
      undoTutorialSeen: undoTutorialSeen ?? this.undoTutorialSeen,
      specialLevelTutorialSeen: specialLevelTutorialSeen ?? this.specialLevelTutorialSeen,
      isLoaded: isLoaded ?? this.isLoaded,
      spiderBrassCoins: spiderBrassCoins ?? this.spiderBrassCoins,
      spiderCopperCoins: spiderCopperCoins ?? this.spiderCopperCoins,
      spiderSilverCoins: spiderSilverCoins ?? this.spiderSilverCoins,
      spiderGoldCoins: spiderGoldCoins ?? this.spiderGoldCoins ?? spiderCoins,
      spiderDiamondCoins: spiderDiamondCoins ?? this.spiderDiamondCoins,
      spiderJadeCoins: spiderJadeCoins ?? this.spiderJadeCoins,
      spiderObsidianCoins: spiderObsidianCoins ?? this.spiderObsidianCoins,
      lastDailyClaimAt: lastDailyClaimAt ?? this.lastDailyClaimAt,
      dailyStreakCount: dailyStreakCount ?? this.dailyStreakCount,
      totalDailyClaims: totalDailyClaims ?? this.totalDailyClaims,
      claimedMilestones: claimedMilestones ?? this.claimedMilestones,
    );
  }
}

class LevelNotifier extends StateNotifier<LevelProgress> {
  final Ref _ref;

  LevelNotifier(this._ref)
      : super(LevelProgress(
          currentLevel: 1,
          coins: 0,
          spiderBrassCoins: 100,
          spiderCopperCoins: 200,
          spiderSilverCoins: 50,
          spiderGoldCoins: 10,
          spiderDiamondCoins: 0,
          spiderJadeCoins: 0,
          spiderObsidianCoins: 0,
          unlockedLevels: {1},
        )) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getInt('current_level') ?? 1;
    final unlockedList = prefs.getStringList('unlocked') ?? ['1'];
    final unlocked = unlockedList.isEmpty ? {1} : unlockedList.map(int.parse).toSet();
    if (!unlocked.contains(1)) unlocked.add(1);

    final activeSkin = prefs.getString('active_skin') ?? 'default';
    final tutorialSeen = prefs.getBool('tutorial_seen') ?? false;
    
    // Load local Spider Coins balances (for guests/offline play)
    final localBrass = prefs.getInt('webspider_brass_coins') ?? 100;
    final localCopper = prefs.getInt('webspider_copper_coins') ?? 200;
    final localSilver = prefs.getInt('webspider_silver_coins') ?? 50;
    final localGold = prefs.getInt('webspider_gold_coins') ?? prefs.getInt('webspider_coins') ?? 10;
    final localDiamond = prefs.getInt('webspider_diamond_coins') ?? 0;
    final localJade = prefs.getInt('webspider_jade_coins') ?? 0;
    final localObsidian = prefs.getInt('webspider_obsidian_coins') ?? 0;

    // Load local daily reward tracking
    final localLastClaimStr = prefs.getString('last_daily_claim_at');
    final localLastClaim = localLastClaimStr != null ? DateTime.tryParse(localLastClaimStr) : null;
    final localStreak = prefs.getInt('daily_streak_count') ?? 0;
    final localTotalClaims = prefs.getInt('total_daily_claims') ?? 0;
    final localClaimedMilestonesList = prefs.getStringList('claimed_milestones') ?? [];
    final localClaimedMilestones = localClaimedMilestonesList.toSet();

    final undoTutorialSeen = prefs.getBool('undo_tutorial_seen') ?? false;
    final specialLevelTutorialSeen = prefs.getBool('special_level_tutorial_seen') ?? false;

    // Pull wallet from auth state (Supabase-backed)
    final authState = _ref.read(authProvider);
    final cloudCoins = authState.user?.coins ?? 0;
    final cloudOwnedSkins = authState.user?.ownedSkins ?? {'default'};

    final cloudBrass = authState.user?.webspiderBrassCoins ?? localBrass;
    final cloudCopper = authState.user?.webspiderCopperCoins ?? localCopper;
    final cloudSilver = authState.user?.webspiderSilverCoins ?? localSilver;
    final cloudGold = authState.user?.webspiderGoldCoins ?? localGold;
    final cloudDiamond = authState.user?.webspiderDiamondCoins ?? localDiamond;
    final cloudJade = authState.user?.webspiderJadeCoins ?? localJade;
    final cloudObsidian = authState.user?.webspiderObsidianCoins ?? localObsidian;

    final cloudLastClaim = authState.user?.lastDailyClaimAt ?? localLastClaim;
    final cloudStreak = authState.user?.dailyStreakCount ?? localStreak;
    final cloudTotalClaims = authState.user?.totalDailyClaims ?? localTotalClaims;
    final cloudClaimedMilestones = authState.user?.claimedMilestones ?? localClaimedMilestones;

    state = LevelProgress(
      currentLevel: level,
      coins: cloudCoins,
      unlockedLevels: unlocked,
      activeSkinId: activeSkin,
      ownedSkinIds: cloudOwnedSkins,
      tutorialSeen: tutorialSeen,
      undoTutorialSeen: undoTutorialSeen,
      specialLevelTutorialSeen: specialLevelTutorialSeen,
      isLoaded: true,
      spiderBrassCoins: cloudBrass,
      spiderCopperCoins: cloudCopper,
      spiderSilverCoins: cloudSilver,
      spiderGoldCoins: cloudGold,
      spiderDiamondCoins: cloudDiamond,
      spiderJadeCoins: cloudJade,
      spiderObsidianCoins: cloudObsidian,
      lastDailyClaimAt: cloudLastClaim,
      dailyStreakCount: cloudStreak,
      totalDailyClaims: cloudTotalClaims,
      claimedMilestones: cloudClaimedMilestones,
    );
  }

  /// Called by authProvider after a wallet refresh so the UI rebuilds.
  void syncWalletFromAuth() {
    final authState = _ref.read(authProvider);
    final cloudCoins = authState.user?.coins ?? state.coins;
    final cloudOwnedSkins = authState.user?.ownedSkins ?? state.ownedSkinIds;
    state = state.copyWith(
      coins: cloudCoins, 
      ownedSkinIds: cloudOwnedSkins,
      spiderBrassCoins: authState.user?.webspiderBrassCoins ?? state.spiderBrassCoins,
      spiderCopperCoins: authState.user?.webspiderCopperCoins ?? state.spiderCopperCoins,
      spiderSilverCoins: authState.user?.webspiderSilverCoins ?? state.spiderSilverCoins,
      spiderGoldCoins: authState.user?.webspiderGoldCoins ?? state.spiderGoldCoins,
      spiderDiamondCoins: authState.user?.webspiderDiamondCoins ?? state.spiderDiamondCoins,
      spiderJadeCoins: authState.user?.webspiderJadeCoins ?? state.spiderJadeCoins,
      spiderObsidianCoins: authState.user?.webspiderObsidianCoins ?? state.spiderObsidianCoins,
      lastDailyClaimAt: authState.user?.lastDailyClaimAt ?? state.lastDailyClaimAt,
      dailyStreakCount: authState.user?.dailyStreakCount ?? state.dailyStreakCount,
      totalDailyClaims: authState.user?.totalDailyClaims ?? state.totalDailyClaims,
      claimedMilestones: authState.user?.claimedMilestones ?? state.claimedMilestones,
    );
  }

  Future<void> markTutorialSeen() async {
    state = state.copyWith(tutorialSeen: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_seen', true);
  }

  Future<void> markUndoTutorialSeen() async {
    state = state.copyWith(undoTutorialSeen: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('undo_tutorial_seen', true);
  }

  Future<void> markSpecialLevelTutorialSeen() async {
    state = state.copyWith(specialLevelTutorialSeen: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('special_level_tutorial_seen', true);
  }

  Future<void> equipSkin(String skinId) async {
    state = state.copyWith(activeSkinId: skinId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_skin', skinId);
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = LevelProgress(currentLevel: 1, coins: 0, spiderCoins: 10, unlockedLevels: {1});
  }

  /// Purchase a skin. Writes to Supabase via WalletService;
  /// on success, refreshes the auth wallet so every listener rebuilds.
  Future<bool> purchaseSkin(String skinId, int price) async {
    final authState = _ref.read(authProvider);
    if (state.ownedSkinIds.contains(skinId)) return false;

    final isGuest = authState.status == AuthStatus.guest;

    if (isGuest) {
      // Guest: local-only purchase (no persistence)
      if (state.coins < price) return false;
      final newOwned = Set<String>.from(state.ownedSkinIds)..add(skinId);
      state = state.copyWith(coins: state.coins - price, ownedSkinIds: newOwned);
      return true;
    }

    final userId = authState.user!.id;
    final success = await WalletService.instance.purchaseSkin(
      userId: userId,
      skinId: skinId,
      price: price,
      currentOwnedSkins: state.ownedSkinIds.toList(),
    );

    if (success) {
      await _ref.read(authProvider.notifier).refreshWallet();
      syncWalletFromAuth();
    }

    return success;
  }

  /// Award coins for completing a level. Writes to Supabase for authenticated
  /// users; falls back to local-only for guests.
  Future<void> completeLevel(int level) async {
    final next = level + 1;
    final newUnlocked = Set<int>.from(state.unlockedLevels)..add(next);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_level', next);
    await prefs.setStringList('unlocked', newUnlocked.map((e) => e.toString()).toList());

    // Update level progress immediately (coins updated after cloud confirm)
    state = state.copyWith(currentLevel: next, unlockedLevels: newUnlocked);

    final authState = _ref.read(authProvider);
    final isGuest = authState.status == AuthStatus.guest;

    // Calculate dynamic reward
    // (moves/seconds not available here; game_provider passes them separately)
    final reward = (level % 5 == 0)
        ? CoinReward.milestoneBonus + CoinReward.levelBase
        : CoinReward.levelBase;

    if (isGuest) {
      state = state.copyWith(coins: state.coins + reward);
      return;
    }

    final userId = authState.user!.id;
    final newBalance = await WalletService.instance.awardCoins(
      userId: userId,
      amount: reward,
      reason: 'level_complete',
      metadata: {'level': level},
    );

    if (newBalance != null) {
      await _ref.read(authProvider.notifier).refreshWallet();
      syncWalletFromAuth();
    }
  }

  /// Award a calculated coin reward (called from game_provider with moves+time).
  Future<void> awardCoins(int amount, String reason, {Map<String, dynamic>? metadata}) async {
    final authState = _ref.read(authProvider);
    final isGuest = authState.status == AuthStatus.guest;

    if (isGuest) {
      state = state.copyWith(coins: state.coins + amount);
      return;
    }

    final userId = authState.user!.id;
    final newBalance = await WalletService.instance.awardCoins(
      userId: userId,
      amount: amount,
      reason: reason,
      metadata: metadata,
    );

    if (newBalance != null) {
      await _ref.read(authProvider.notifier).refreshWallet();
      syncWalletFromAuth();
    }
  }

  /// Award or deduct any WebSpider currency locally (SharedPreferences) and in the cloud.
  Future<void> awardWebSpiderCurrency(String currencyType, int amount, String reason) async {
    final prefs = await SharedPreferences.getInstance();
    final authState = _ref.read(authProvider);
    final isGuest = authState.status == AuthStatus.guest;

    int currentBalance = 0;
    switch (currencyType) {
      case 'brass': currentBalance = state.spiderBrassCoins; break;
      case 'copper': currentBalance = state.spiderCopperCoins; break;
      case 'silver': currentBalance = state.spiderSilverCoins; break;
      case 'gold': currentBalance = state.spiderGoldCoins; break;
      case 'diamond': currentBalance = state.spiderDiamondCoins; break;
      case 'jade': currentBalance = state.spiderJadeCoins; break;
      case 'obsidian': currentBalance = state.spiderObsidianCoins; break;
    }

    final newLocal = (currentBalance + amount).clamp(0, 9999999);
    await prefs.setInt('webspider_${currencyType}_coins', newLocal);

    if (isGuest) {
      _updateLocalBalanceState(currencyType, newLocal);
      return;
    }

    final userId = authState.user!.id;
    final newBalance = await WalletService.instance.updateWebSpiderCurrency(
      userId: userId,
      currencyType: currencyType,
      amount: amount,
      reason: reason,
    );

    if (newBalance != null) {
      await _ref.read(authProvider.notifier).refreshWallet();
      syncWalletFromAuth();
    } else {
      _updateLocalBalanceState(currencyType, newLocal);
    }
  }

  void _updateLocalBalanceState(String currencyType, int value) {
    switch (currencyType) {
      case 'brass': state = state.copyWith(spiderBrassCoins: value); break;
      case 'copper': state = state.copyWith(spiderCopperCoins: value); break;
      case 'silver': state = state.copyWith(spiderSilverCoins: value); break;
      case 'gold': state = state.copyWith(spiderGoldCoins: value); break;
      case 'diamond': state = state.copyWith(spiderDiamondCoins: value); break;
      case 'jade': state = state.copyWith(spiderJadeCoins: value); break;
      case 'obsidian': state = state.copyWith(spiderObsidianCoins: value); break;
    }
  }

  /// Legacy helper to award or deduct gold coins (representing Spider Coins).
  Future<void> awardSpiderCoins(int amount, String reason) async {
    await awardWebSpiderCurrency('gold', amount, reason);
  }

  /// Exchange between WebSpider currencies or from regular coins.
  Future<bool> exchangeCurrency({
    required String fromType, // 'coins' (regular), 'brass', 'copper', etc.
    required String toType,   // 'brass', 'copper', etc.
    required int fromAmount,
    required int toAmount,
  }) async {
    final authState = _ref.read(authProvider);
    final isGuest = authState.status == AuthStatus.guest;

    int fromBalance = 0;
    if (fromType == 'coins') {
      fromBalance = state.coins;
    } else {
      switch (fromType) {
        case 'brass': fromBalance = state.spiderBrassCoins; break;
        case 'copper': fromBalance = state.spiderCopperCoins; break;
        case 'silver': fromBalance = state.spiderSilverCoins; break;
        case 'gold': fromBalance = state.spiderGoldCoins; break;
        case 'diamond': fromBalance = state.spiderDiamondCoins; break;
        case 'jade': fromBalance = state.spiderJadeCoins; break;
        case 'obsidian': fromBalance = state.spiderObsidianCoins; break;
      }
    }

    if (fromBalance < fromAmount || fromAmount <= 0 || toAmount <= 0) return false;

    if (isGuest) {
      final prefs = await SharedPreferences.getInstance();
      
      // Debit from
      if (fromType == 'coins') {
        state = state.copyWith(coins: state.coins - fromAmount);
      } else {
        final newFromLocal = fromBalance - fromAmount;
        await prefs.setInt('webspider_${fromType}_coins', newFromLocal);
        _updateLocalBalanceState(fromType, newFromLocal);
      }

      // Credit to
      int toBalance = 0;
      switch (toType) {
        case 'brass': toBalance = state.spiderBrassCoins; break;
        case 'copper': toBalance = state.spiderCopperCoins; break;
        case 'silver': toBalance = state.spiderSilverCoins; break;
        case 'gold': toBalance = state.spiderGoldCoins; break;
        case 'diamond': toBalance = state.spiderDiamondCoins; break;
        case 'jade': toBalance = state.spiderJadeCoins; break;
        case 'obsidian': toBalance = state.spiderObsidianCoins; break;
      }
      final newToLocal = toBalance + toAmount;
      await prefs.setInt('webspider_${toType}_coins', newToLocal);
      _updateLocalBalanceState(toType, newToLocal);

      return true;
    }

    final userId = authState.user!.id;

    // Debit
    if (fromType == 'coins') {
      final success = await WalletService.instance.awardCoins(
        userId: userId,
        amount: -fromAmount,
        reason: 'currency_exchange_debit',
        metadata: {'exchange_to': toType, 'amount': toAmount},
      );
      if (success == null) return false;
    } else {
      final success = await WalletService.instance.updateWebSpiderCurrency(
        userId: userId,
        currencyType: fromType,
        amount: -fromAmount,
        reason: 'currency_exchange_debit',
      );
      if (success == null) return false;
    }

    // Credit
    final successCredit = await WalletService.instance.updateWebSpiderCurrency(
      userId: userId,
      currencyType: toType,
      amount: toAmount,
      reason: 'currency_exchange_credit',
    );

    if (successCredit != null) {
      await _ref.read(authProvider.notifier).refreshWallet();
      syncWalletFromAuth();
      return true;
    }

    // Rollback debit on failure
    if (fromType == 'coins') {
      await WalletService.instance.awardCoins(
        userId: userId,
        amount: fromAmount,
        reason: 'currency_exchange_rollback',
      );
    } else {
      await WalletService.instance.updateWebSpiderCurrency(
        userId: userId,
        currencyType: fromType,
        amount: fromAmount,
        reason: 'currency_exchange_rollback',
      );
    }

    return false;
  }

  /// Exchange regular coins for Spider Coins (50 regular coins = 10 Gold Coins).
  Future<bool> exchangeCoinsForSpiderCoins(int regularCoinsAmount) async {
    if (state.coins < regularCoinsAmount || regularCoinsAmount <= 0) return false;
    
    final spiderAward = (regularCoinsAmount ~/ 50) * 10;
    if (spiderAward <= 0) return false;

    return exchangeCurrency(
      fromType: 'coins',
      toType: 'gold',
      fromAmount: regularCoinsAmount,
      toAmount: spiderAward,
    );
  }

  /// Claim the daily streak reward atomically (cloud or guest local fallback).
  Future<Map<String, dynamic>> claimDailyReward() async {
    final authState = _ref.read(authProvider);
    final isGuest = authState.status == AuthStatus.guest;

    if (!isGuest) {
      final userId = authState.user!.id;
      final result = await WalletService.instance.claimDailyReward(userId: userId);
      if (result != null && result['success'] == true) {
        await _ref.read(authProvider.notifier).refreshWallet();
        syncWalletFromAuth();
        return result;
      }
      return result ?? {'success': false, 'message': 'Failed to claim daily reward.'};
    }

    // Guest local fallback
    final now = DateTime.now();
    if (state.lastDailyClaimAt != null) {
      final diff = now.difference(state.lastDailyClaimAt!);
      if (diff < const Duration(hours: 24)) {
        final remaining = const Duration(hours: 24) - diff;
        return {
          'success': false,
          'message': 'Reward not ready yet.',
          'seconds_remaining': remaining.inSeconds,
          'streak_count': state.dailyStreakCount,
          'total_claims': state.totalDailyClaims,
        };
      }
    }

    // Calculate streak
    int newStreak = 1;
    if (state.lastDailyClaimAt != null && now.difference(state.lastDailyClaimAt!) < const Duration(hours: 48)) {
      if (state.dailyStreakCount >= 7) {
        newStreak = 1;
      } else {
        newStreak = state.dailyStreakCount + 1;
      }
    }

    final newTotalClaims = state.totalDailyClaims + 1;

    // Rewards mapping
    String rewardType;
    int rewardAmount;
    switch (newStreak) {
      case 1: rewardType = 'copper'; rewardAmount = 50; break;
      case 2: rewardType = 'copper'; rewardAmount = 100; break;
      case 3: rewardType = 'brass'; rewardAmount = 20; break;
      case 4: rewardType = 'brass'; rewardAmount = 50; break;
      case 5: rewardType = 'silver'; rewardAmount = 10; break;
      case 6: rewardType = 'silver'; rewardAmount = 20; break;
      case 7: rewardType = 'gold'; rewardAmount = 5; break;
      default: rewardType = 'copper'; rewardAmount = 50;
    }

    // Update guest balance
    await awardWebSpiderCurrency(rewardType, rewardAmount, 'daily_claim_streak_day_$newStreak');

    // Save tracking details
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_daily_claim_at', now.toIso8601String());
    await prefs.setInt('daily_streak_count', newStreak);
    await prefs.setInt('total_daily_claims', newTotalClaims);

    // Update state
    state = state.copyWith(
      lastDailyClaimAt: now,
      dailyStreakCount: newStreak,
      totalDailyClaims: newTotalClaims,
    );

    int newBalance = 0;
    switch (rewardType) {
      case 'brass': newBalance = state.spiderBrassCoins; break;
      case 'copper': newBalance = state.spiderCopperCoins; break;
      case 'silver': newBalance = state.spiderSilverCoins; break;
      case 'gold': newBalance = state.spiderGoldCoins; break;
      case 'diamond': newBalance = state.spiderDiamondCoins; break;
      case 'jade': newBalance = state.spiderJadeCoins; break;
      case 'obsidian': newBalance = state.spiderObsidianCoins; break;
    }

    return {
      'success': true,
      'message': 'Claimed successfully!',
      'streak_count': newStreak,
      'total_claims': newTotalClaims,
      'reward_type': rewardType,
      'reward_amount': rewardAmount,
      'new_balance': newBalance,
    };
  }

  /// Claim a cumulative milestone reward (cloud or guest local fallback).
  Future<Map<String, dynamic>> claimMilestoneReward(String milestoneId) async {
    final authState = _ref.read(authProvider);
    final isGuest = authState.status == AuthStatus.guest;

    if (!isGuest) {
      final userId = authState.user!.id;
      final result = await WalletService.instance.claimMilestoneReward(userId: userId, milestoneId: milestoneId);
      if (result != null && result['success'] == true) {
        await _ref.read(authProvider.notifier).refreshWallet();
        syncWalletFromAuth();
        return result;
      }
      return result ?? {'success': false, 'message': 'Failed to claim milestone reward.'};
    }

    // Guest local fallback
    if (state.claimedMilestones.contains(milestoneId)) {
      return {'success': false, 'message': 'Milestone already claimed.'};
    }

    int reqClaims = 10;
    String r1Type = 'jade'; int r1Amt = 10;
    String r2Type = 'silver'; int r2Amt = 5;

    if (milestoneId == 'milestone_25') {
      reqClaims = 25;
      r1Type = 'diamond'; r1Amt = 5;
      r2Type = 'silver'; r2Amt = 20;
    } else if (milestoneId == 'milestone_50') {
      reqClaims = 50;
      r1Type = 'obsidian'; r1Amt = 2;
      r2Type = 'gold'; r2Amt = 10;
    } else if (milestoneId != 'milestone_10') {
      return {'success': false, 'message': 'Invalid milestone ID.'};
    }

    if (state.totalDailyClaims < reqClaims) {
      return {'success': false, 'message': 'Milestone requirement not met.'};
    }

    // Award guest coins
    await awardWebSpiderCurrency(r1Type, r1Amt, 'milestone_claim_$milestoneId');
    await awardWebSpiderCurrency(r2Type, r2Amt, 'milestone_claim_$milestoneId');

    // Save tracking details
    final newClaimed = Set<String>.from(state.claimedMilestones)..add(milestoneId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('claimed_milestones', newClaimed.toList());

    // Update state
    state = state.copyWith(claimedMilestones: newClaimed);

    return {
      'success': true,
      'message': 'Milestone reward claimed!',
      'claimed_milestones': newClaimed.toList(),
      'reward1_type': r1Type,
      'reward1_amount': r1Amt,
      'reward2_type': r2Type,
      'reward2_amount': r2Amt,
    };
  }
}

final levelProvider = StateNotifierProvider<LevelNotifier, LevelProgress>(
  (ref) => LevelNotifier(ref),
);
