import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_sort/features/profile/providers/premium_provider.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';

// Product IDs from the implementation plan
const String _kCoinPack100 = 'com.webspider.aqua.coins.100';
const String _kCoinPack500 = 'com.webspider.aqua.coins.500';
const String _kCoinPack1000 = 'com.webspider.aqua.coins.1000';
const String _kCoinPack3000 = 'com.webspider.aqua.coins.3000';
const String _kCoinPack5000 = 'com.webspider.aqua.coins.5000';

const String _kPremiumDaily = 'com.webspider.aqua.premium.daily';
const String _kPremiumWeekly = 'com.webspider.aqua.premium.weekly';
const String _kPremiumMonthly = 'com.webspider.aqua.premium.monthly';
const String _kPremiumQuarterly = 'com.webspider.aqua.premium.quarterly';
const String _kPremiumHalfYearly = 'com.webspider.aqua.premium.halfyearly';
const String _kPremiumYearly = 'com.webspider.aqua.premium.yearly';

const List<String> kProductIds = <String>[
  _kCoinPack100,
  _kCoinPack500,
  _kCoinPack1000,
  _kCoinPack3000,
  _kCoinPack5000,
  _kPremiumDaily,
  _kPremiumWeekly,
  _kPremiumMonthly,
  _kPremiumQuarterly,
  _kPremiumHalfYearly,
  _kPremiumYearly,
];

class IapService extends ChangeNotifier {
  final Ref _ref;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  bool isAvailable = false;
  List<ProductDetails> products = [];
  List<PurchaseDetails> purchases = [];
  String? errorMessage;
  bool isQuerying = false;
  bool isPurchasing = false;

  IapService(this._ref) {
    _initIap();
  }

  void _initIap() {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (Object error) {
      errorMessage = error.toString();
      isPurchasing = false;
      notifyListeners();
    });
    
    initStoreInfo();
  }

  Future<void> initStoreInfo() async {
    isQuerying = true;
    errorMessage = null;
    notifyListeners();

    isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      errorMessage = 'Store is not available.';
      isQuerying = false;
      notifyListeners();
      return;
    }

    final ProductDetailsResponse productDetailResponse =
        await _inAppPurchase.queryProductDetails(kProductIds.toSet());
    if (productDetailResponse.error != null) {
      errorMessage = productDetailResponse.error!.message;
      products = productDetailResponse.productDetails;
      isQuerying = false;
      notifyListeners();
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      errorMessage = 'No products found.';
      products = productDetailResponse.productDetails;
      isQuerying = false;
      notifyListeners();
      return;
    }

    products = productDetailResponse.productDetails;
    
    // In a real app, you would also verify previous purchases and restore them here
    await _inAppPurchase.restorePurchases();

    isQuerying = false;
    notifyListeners();
  }

  void buyProduct(ProductDetails product) {
    isPurchasing = true;
    errorMessage = null;
    notifyListeners();

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    // Determine if it's a subscription or a consumable
    if (product.id.contains('premium')) {
      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        isPurchasing = true;
        notifyListeners();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          errorMessage = purchaseDetails.error?.message ?? 'Purchase failed';
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            _deliverProduct(purchaseDetails);
          } else {
            _handleInvalidPurchase(purchaseDetails);
            return;
          }
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
        
        isPurchasing = false;
        notifyListeners();
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('purchases').add({
          'user_id': user.uid,
          'product_id': purchaseDetails.productID,
          'purchase_id': purchaseDetails.purchaseID,
          'transaction_date': purchaseDetails.transactionDate,
          'verification_data': purchaseDetails.verificationData.serverVerificationData,
          'status': purchaseDetails.status.name,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      return true;
    } catch (e) {
      debugPrint('Error recording purchase in Firestore: $e');
      return true;
    }
  }

  void _deliverProduct(PurchaseDetails purchaseDetails) {
    purchases.add(purchaseDetails);
    
    final productId = purchaseDetails.productID;
    if (productId.contains('premium')) {
      _ref.read(premiumProvider.notifier).setPremium(true);
    } else if (productId.contains('coins')) {
      final parts = productId.split('.');
      final amountStr = parts.last;
      final amount = int.tryParse(amountStr) ?? 0;
      if (amount > 0) {
        _ref.read(levelProvider.notifier).awardCoins(amount, 'iap_purchase');
      }
    }
    notifyListeners();
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    errorMessage = 'Purchase verification failed.';
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
