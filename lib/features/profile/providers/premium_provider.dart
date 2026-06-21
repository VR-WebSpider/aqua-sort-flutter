import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the player has a premium subscription.
///
/// Backed by SharedPreferences for now. Swap for RevenueCat / StoreKit
/// when in-app purchases are integrated.
class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('is_premium') ?? false;
  }

  /// Stub: call this after a successful IAP purchase.
  Future<void> setPremium(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', value);
  }

  bool get isPremium => state;
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>(
  (ref) => PremiumNotifier(),
);
