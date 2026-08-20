import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PremiumNotifier extends StateNotifier<bool> {
  final Ref _ref;

  PremiumNotifier(this._ref) : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getBool('is_premium') ?? false;
    
    final authState = _ref.read(authProvider);
    final cloud = authState.user?.isPremium ?? false;
    
    state = local || cloud;
  }

  Future<void> setPremium(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', value);
    
    final authState = _ref.read(authProvider);
    if (authState.user != null && authState.user!.id != 'guest') {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(authState.user!.id)
            .set({'is_premium': value}, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  void syncFromAuth(bool cloudValue) {
    if (state != cloudValue) {
      state = cloudValue;
    }
  }

  bool get isPremium => state;
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  final authState = ref.watch(authProvider);
  final isPremiumCloud = authState.user?.isPremium ?? false;
  final notifier = PremiumNotifier(ref);
  
  if (isPremiumCloud) {
    notifier.syncFromAuth(true);
  }
  return notifier;
});
