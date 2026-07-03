import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';
import 'economy_config.dart';

/// --------------------------------------------------------------------------
/// AdService - Google Mobile Ads wrapper for Aqua Sort
/// --------------------------------------------------------------------------
class AdService {
  static final AdService instance = AdService._();
  AdService._();

  bool _initialized = false;
  bool isPremium = false;

  // Interstitial
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoaded = false;
  int _levelsSinceLastInterstitial = 0;
  DateTime? _lastInterstitialTime;

  // Rewarded
  RewardedAd? _rewardedAd;
  bool _isRewardedLoaded = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    debugPrint('[AdService] Initialized');
    loadInterstitial();
    _loadRewarded();
  }

  BannerAd createBannerAd() {
    final ad = BannerAd(
      adUnitId: AdConfig.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => debugPrint('[AdService] Banner loaded'),
        onAdFailedToLoad: (ad, err) {
          debugPrint('[AdService] Banner failed: ');
          ad.dispose();
        },
      ),
    );
    ad.load();
    return ad;
  }

  void loadInterstitial() {
    if (isPremium) return;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
          ad.setImmersiveMode(true);
          debugPrint('[AdService] Interstitial loaded');
        },
        onAdFailedToLoad: (err) {
          _isInterstitialLoaded = false;
          debugPrint('[AdService] Interstitial failed: ');
        },
      ),
    );
  }

  bool get _canShowInterstitial {
    if (!_isInterstitialLoaded || _interstitialAd == null) return false;
    if (_levelsSinceLastInterstitial < EconomyConfig.interstitialMinLevels) return false;
    if (_lastInterstitialTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialTime!).inSeconds;
      if (elapsed < EconomyConfig.interstitialMinSeconds) return false;
    }
    return true;
  }

  void recordLevelComplete() {
    _levelsSinceLastInterstitial++;
    debugPrint('[AdService] Levels since last interstitial: ');
  }

  Future<void> showInterstitialIfReady() async {
    if (isPremium || !_canShowInterstitial) {
      debugPrint('[AdService] Interstitial not ready or user is premium');
      return;
    }

    final completer = Completer<void>();

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialLoaded = false;
        _levelsSinceLastInterstitial = 0;
        _lastInterstitialTime = DateTime.now();
        loadInterstitial();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialLoaded = false;
        loadInterstitial();
        if (!completer.isCompleted) completer.complete();
      },
    );

    await _interstitialAd!.show();
    return completer.future;
  }

  void _loadRewarded() {
    if (isPremium) return;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoaded = true;
          debugPrint('[AdService] Rewarded loaded');
        },
        onAdFailedToLoad: (err) {
          _isRewardedLoaded = false;
          debugPrint('[AdService] Rewarded failed: ');
        },
      ),
    );
  }

  Future<int?> showRewardedAd(BuildContext context) async {
    if (isPremium) return null;
    if (!_isRewardedLoaded || _rewardedAd == null) {
      _loadRewarded();
      return null;
    }

    final completer = Completer<int?>();
    int? rewardAmount;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedLoaded = false;
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(rewardAmount);
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedLoaded = false;
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(null);
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (_, reward) {
        rewardAmount = EconomyConfig.adRewardCoins;
        debugPrint('[AdService] Reward earned: ${reward.amount}');
      },
    );

    return completer.future;
  }
}
