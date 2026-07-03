/// Centralized game economy constants.
/// Single source of truth — every coin value in the game references this file.
class EconomyConfig {
  // ── Undo System ───────────────────────────────────────────────────────
  /// Number of free undo moves per level attempt.
  static const int freeUndoLimit = 2;

  /// Coin cost for each extra undo beyond the free limit.
  static const int undoCoinCost = 30;

  // ── Ad Rewards ────────────────────────────────────────────────────────
  /// Coins awarded for watching a single rewarded ad.
  static const int adRewardCoins = 15;

  /// Minimum cooldown between rewarded ads (seconds).
  static const int adCooldownSeconds = 30;

  // ── Loss Recovery ─────────────────────────────────────────────────────
  /// Extra seconds granted when watching an ad after time-out loss.
  static const int adBonusSeconds = 30;

  /// Extra moves granted when watching an ad after moves-depleted loss.
  static const int adBonusMoves = 5;

  // ── Interstitial Frequency Caps ───────────────────────────────────────
  /// Minimum number of levels completed before an interstitial may be shown.
  static const int interstitialMinLevels = 3;

  /// Minimum seconds between consecutive interstitial impressions (5 minutes).
  static const int interstitialMinSeconds = 300;
}
