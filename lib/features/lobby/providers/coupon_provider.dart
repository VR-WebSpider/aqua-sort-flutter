import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';

class CouponState {
  final bool isLoading;
  final String? error;
  final int? coinsAwarded;

  CouponState({this.isLoading = false, this.error, this.coinsAwarded});

  CouponState copyWith({bool? isLoading, String? error, int? coinsAwarded}) {
    return CouponState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      coinsAwarded: coinsAwarded,
    );
  }
}

class CouponNotifier extends StateNotifier<CouponState> {
  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CouponNotifier(this._ref) : super(CouponState());

  Future<void> redeemCoupon(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      state = CouponState(error: 'Code cannot be empty');
      return;
    }

    state = CouponState(isLoading: true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('You must be signed in to redeem coupons');
      }

      // 1. Check coupon validity in Firestore
      final couponDoc = await _firestore.collection('coupons').doc(cleanCode).get();

      if (!couponDoc.exists || couponDoc.data() == null) {
        throw Exception('Invalid coupon code');
      }

      final data = couponDoc.data()!;
      final bool isActive = data['is_active'] as bool? ?? false;
      final int coinsReward = (data['coin_reward'] as num?)?.toInt() ?? 0;
      final Timestamp? expirationTimestamp = data['expiration'] as Timestamp?;

      if (!isActive) {
        throw Exception('This coupon is no longer active');
      }

      if (expirationTimestamp != null) {
        if (expirationTimestamp.toDate().isBefore(DateTime.now())) {
          throw Exception('This coupon has expired');
        }
      }

      // 2. Check if already redeemed
      final redemptionDoc = await _firestore
          .collection('coupon_redemptions')
          .doc('${user.uid}_$cleanCode')
          .get();

      if (redemptionDoc.exists) {
        throw Exception('You have already redeemed this coupon');
      }

      // 3. Log redemption in Firestore
      await _firestore.collection('coupon_redemptions').doc('${user.uid}_$cleanCode').set({
        'user_id': user.uid,
        'coupon_code': cleanCode,
        'redeemed_at': FieldValue.serverTimestamp(),
      });

      // 4. Update the user's coins locally & sync
      await _ref.read(levelProvider.notifier).awardCoins(
        coinsReward, 
        'coupon_redeem', 
        metadata: {'coupon_code': cleanCode},
      );

      state = CouponState(coinsAwarded: coinsReward);
    } catch (e) {
      final msg = e.toString().replaceAll('Exception:', '').trim();
      state = CouponState(error: msg);
    }
  }
}

final couponProvider = StateNotifierProvider<CouponNotifier, CouponState>((ref) {
  return CouponNotifier(ref);
});
