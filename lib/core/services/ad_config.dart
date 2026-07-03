import 'package:flutter/foundation.dart';

/// ══════════════════════════════════════════════════════════════════════════
/// Ad Configuration — Centralized AdMob Unit IDs
/// ══════════════════════════════════════════════════════════════════════════
///
/// HOW TO GO LIVE:
///   1. Reactivate your AdMob account at https://admob.google.com
///   2. Create an Android app in AdMob for Aqua Sort
///   3. Create ad units: Banner, Interstitial, Rewarded
///   4. Replace the strings in [_realAndroid*] constants below
///   5. Update the AndroidManifest.xml App ID (already marked with TODO)
///   6. Set [_forceTestIds] to false
///
class AdConfig {
  AdConfig._();

  // ── Toggle ──────────────────────────────────────────────────────────────
  /// Force test IDs even in release builds (for internal testing).
  /// Set to false when you're ready to monetise with real ads.
  static const bool _forceTestIds = true;

  static bool get _useTestIds => kDebugMode || _forceTestIds;

  // ── Google Official Test IDs (Android) ──────────────────────────────────
  static const String _testBanner       = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewarded     = 'ca-app-pub-3940256099942544/5224354917';

  // ── Your Real Ad Unit IDs (Android) ─────────────────────────────────────
  // TODO: Replace these with your real AdMob ad unit IDs once account is reactivated
  static const String _realAndroidBanner       = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _realAndroidInterstitial = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _realAndroidRewarded     = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  // ── Public Accessors ─────────────────────────────────────────────────────
  static String get bannerUnitId       => _useTestIds ? _testBanner       : _realAndroidBanner;
  static String get interstitialUnitId => _useTestIds ? _testInterstitial : _realAndroidInterstitial;
  static String get rewardedUnitId     => _useTestIds ? _testRewarded     : _realAndroidRewarded;
}
