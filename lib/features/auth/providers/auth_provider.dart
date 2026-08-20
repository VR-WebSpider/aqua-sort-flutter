import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:aqua_sort/core/services/push_notification_service.dart';
import 'package:aqua_sort/core/services/wallet_service.dart';
import 'dart:math' as math;

enum AuthStatus { authenticated, guest, unauthenticated }

class AuthUser {
  final String id;
  final String firstName;
  final String lastName;
  final String displayName;
  final String username;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final int usernameChangesCount;
  final DateTime? displayNameUpdatedAt;
  
  // ── Economy ──────────────────────────────────────────────────────────
  final int coins;
  final Set<String> ownedSkins;
  final int webspiderBrassCoins;
  final int webspiderCopperCoins;
  final int webspiderSilverCoins;
  final int webspiderGoldCoins;
  final int webspiderDiamondCoins;
  final int webspiderJadeCoins;
  final int webspiderObsidianCoins;

  final bool isPremium;

  // ── Daily Reward & Streak ─────────────────────────────────────────────
  final DateTime? lastDailyClaimAt;
  final int dailyStreakCount;
  final int totalDailyClaims;
  final Set<String> claimedMilestones;

  const AuthUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.username,
    this.email,
    this.phone,
    this.avatarUrl,
    this.usernameChangesCount = 0,
    this.displayNameUpdatedAt,
    this.coins = 0,
    this.ownedSkins = const {'default'},
    this.webspiderBrassCoins = 100,
    this.webspiderCopperCoins = 200,
    this.webspiderSilverCoins = 50,
    this.webspiderGoldCoins = 10,
    this.webspiderDiamondCoins = 0,
    this.webspiderJadeCoins = 0,
    this.webspiderObsidianCoins = 0,
    this.isPremium = false,
    this.lastDailyClaimAt,
    this.dailyStreakCount = 0,
    this.totalDailyClaims = 0,
    this.claimedMilestones = const {},
  });

  AuthUser copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? displayName,
    String? username,
    String? email,
    String? phone,
    String? avatarUrl,
    int? usernameChangesCount,
    DateTime? displayNameUpdatedAt,
    int? coins,
    Set<String>? ownedSkins,
    int? webspiderBrassCoins,
    int? webspiderCopperCoins,
    int? webspiderSilverCoins,
    int? webspiderGoldCoins,
    int? webspiderDiamondCoins,
    int? webspiderJadeCoins,
    int? webspiderObsidianCoins,
    DateTime? lastDailyClaimAt,
    int? dailyStreakCount,
    int? totalDailyClaims,
    Set<String>? claimedMilestones,
    bool? isPremium,
  }) {
    return AuthUser(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      usernameChangesCount: usernameChangesCount ?? this.usernameChangesCount,
      displayNameUpdatedAt: displayNameUpdatedAt ?? this.displayNameUpdatedAt,
      coins: coins ?? this.coins,
      ownedSkins: ownedSkins ?? this.ownedSkins,
      webspiderBrassCoins: webspiderBrassCoins ?? this.webspiderBrassCoins,
      webspiderCopperCoins: webspiderCopperCoins ?? this.webspiderCopperCoins,
      webspiderSilverCoins: webspiderSilverCoins ?? this.webspiderSilverCoins,
      webspiderGoldCoins: webspiderGoldCoins ?? this.webspiderGoldCoins,
      webspiderDiamondCoins: webspiderDiamondCoins ?? this.webspiderDiamondCoins,
      webspiderJadeCoins: webspiderJadeCoins ?? this.webspiderJadeCoins,
      webspiderObsidianCoins: webspiderObsidianCoins ?? this.webspiderObsidianCoins,
      lastDailyClaimAt: lastDailyClaimAt ?? this.lastDailyClaimAt,
      dailyStreakCount: dailyStreakCount ?? this.dailyStreakCount,
      totalDailyClaims: totalDailyClaims ?? this.totalDailyClaims,
      claimedMilestones: claimedMilestones ?? this.claimedMilestones,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  // Legacy compatibility
  int get webspiderCoins => webspiderGoldCoins;

  factory AuthUser.guest() => const AuthUser(
    id: 'guest',
    firstName: 'Guest',
    lastName: 'Sorter',
    displayName: 'Guest Sorter',
    username: 'guest_sorter',
    usernameChangesCount: 0,
    displayNameUpdatedAt: null,
    coins: 0,
    webspiderBrassCoins: 100,
    webspiderCopperCoins: 200,
    webspiderSilverCoins: 50,
    webspiderGoldCoins: 10,
    webspiderDiamondCoins: 0,
    webspiderJadeCoins: 0,
    webspiderObsidianCoins: 0,
    ownedSkins: {'default'},
    lastDailyClaimAt: null,
    dailyStreakCount: 0,
    totalDailyClaims: 0,
    claimedMilestones: {},
  );
}

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final bool isLoading;
  final bool isRecoveringPassword;

  const AuthState({
    required this.status,
    this.user,
    this.isLoading = false,
    this.isRecoveringPassword = false,
  });

  factory AuthState.unauthenticated() => const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.loading() => const AuthState(status: AuthStatus.unauthenticated, isLoading: true);
  factory AuthState.recovering() => const AuthState(status: AuthStatus.authenticated, isRecoveringPassword: true);

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    bool? isLoading,
    bool? isRecoveringPassword,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isRecoveringPassword: isRecoveringPassword ?? this.isRecoveringPassword,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthNotifier() : super(AuthState.unauthenticated()) {
    _init();
  }

  void _init() {
    debugPrint('AUTH_NOTIFIER: Initializing Firebase Auth listener...');
    
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        debugPrint('AUTH_NOTIFIER: User detected -> ${user.uid}');
        _fetchProfile(user);
        PushNotificationService.setUserId(user.uid);
      } else {
        debugPrint('AUTH_NOTIFIER: User signed out');
        state = AuthState.unauthenticated();
        PushNotificationService.removeUserId();
      }
    });
  }

  Future<void> _fetchProfile(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists || doc.data() == null) {
        final String displayName = user.displayName ?? user.email?.split('@').first ?? 'WebSpider Player';
        final String username = 'player_${math.Random().nextInt(899999) + 100000}';

        final initialData = {
          'id': user.uid,
          'email': user.email,
          'phone': user.phoneNumber,
          'display_name': displayName,
          'username': username,
          'first_name': displayName.split(' ').first,
          'last_name': displayName.split(' ').length > 1 ? displayName.split(' ').sublist(1).join(' ') : '',
          'avatar_url': user.photoURL,
          'coins': 0,
          'owned_skins': ['default'],
          'webspider_brass_coins': 100,
          'webspider_copper_coins': 200,
          'webspider_silver_coins': 50,
          'webspider_gold_coins': 10,
          'webspider_diamond_coins': 0,
          'webspider_jade_coins': 0,
          'webspider_obsidian_coins': 0,
          'is_premium': false,
          'username_changes_count': 0,
          'daily_streak_count': 0,
          'total_daily_claims': 0,
          'claimed_milestones': [],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        };

        await docRef.set(initialData, SetOptions(merge: true));

        state = AuthState(
          status: AuthStatus.authenticated,
          user: AuthUser(
            id: user.uid,
            firstName: initialData['first_name'] as String,
            lastName: initialData['last_name'] as String,
            displayName: initialData['display_name'] as String,
            username: initialData['username'] as String,
            email: user.email,
            phone: user.phoneNumber,
            avatarUrl: user.photoURL,
            coins: 0,
            ownedSkins: {'default'},
            webspiderBrassCoins: 100,
            webspiderCopperCoins: 200,
            webspiderSilverCoins: 50,
            webspiderGoldCoins: 10,
          ),
        );
      } else {
        final data = doc.data()!;
        state = AuthState(
          status: AuthStatus.authenticated,
          user: AuthUser(
            id: user.uid,
            firstName: data['first_name'] ?? '',
            lastName: data['last_name'] ?? '',
            displayName: data['display_name'] ?? (user.displayName ?? 'Player'),
            username: data['username'] ?? 'player',
            email: user.email ?? data['email'],
            phone: user.phoneNumber ?? data['phone'],
            avatarUrl: data['avatar_url'] ?? user.photoURL,
            usernameChangesCount: (data['username_changes_count'] as num?)?.toInt() ?? 0,
            displayNameUpdatedAt: (data['display_name_updated_at'] as Timestamp?)?.toDate(),
            coins: (data['coins'] as num?)?.toInt() ?? 0,
            ownedSkins: Set<String>.from(data['owned_skins'] ?? ['default']),
            webspiderBrassCoins: (data['webspider_brass_coins'] as num?)?.toInt() ?? 100,
            webspiderCopperCoins: (data['webspider_copper_coins'] as num?)?.toInt() ?? 200,
            webspiderSilverCoins: (data['webspider_silver_coins'] as num?)?.toInt() ?? 50,
            webspiderGoldCoins: (data['webspider_gold_coins'] as num?)?.toInt() ?? 10,
            webspiderDiamondCoins: (data['webspider_diamond_coins'] as num?)?.toInt() ?? 0,
            webspiderJadeCoins: (data['webspider_jade_coins'] as num?)?.toInt() ?? 0,
            webspiderObsidianCoins: (data['webspider_obsidian_coins'] as num?)?.toInt() ?? 0,
            isPremium: data['is_premium'] == true,
            lastDailyClaimAt: (data['last_daily_claim_at'] as Timestamp?)?.toDate(),
            dailyStreakCount: (data['daily_streak_count'] as num?)?.toInt() ?? 0,
            totalDailyClaims: (data['total_daily_claims'] as num?)?.toInt() ?? 0,
            claimedMilestones: Set<String>.from(data['claimed_milestones'] ?? []),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching profile from Firestore: $e');
      state = AuthState(
        status: AuthStatus.authenticated,
        user: AuthUser(
          id: user.uid,
          firstName: user.displayName?.split(' ').first ?? 'Player',
          lastName: '',
          displayName: user.displayName ?? 'Player',
          username: 'player',
          email: user.email,
        ),
      );
    }
  }

  // ── Authentication Actions ────────────────────────────────────────────────

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = AuthState.loading();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        await _fetchProfile(credential.user!);
      }
    } catch (e) {
      state = AuthState.unauthenticated();
      rethrow;
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    state = AuthState.loading();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final displayName = '$firstName $lastName'.trim();
        await user.updateDisplayName(displayName);

        final docRef = _firestore.collection('users').doc(user.uid);
        await docRef.set({
          'id': user.uid,
          'email': email.trim(),
          'first_name': firstName,
          'last_name': lastName,
          'display_name': displayName,
          'username': username.toLowerCase().trim(),
          'coins': 0,
          'owned_skins': ['default'],
          'webspider_brass_coins': 100,
          'webspider_copper_coins': 200,
          'webspider_silver_coins': 50,
          'webspider_gold_coins': 10,
          'webspider_diamond_coins': 0,
          'webspider_jade_coins': 0,
          'webspider_obsidian_coins': 0,
          'is_premium': false,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await _fetchProfile(user);
      }
    } catch (e) {
      state = AuthState.unauthenticated();
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = AuthState.loading();
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        state = AuthState.unauthenticated();
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _fetchProfile(userCredential.user!);
      }
    } catch (e) {
      state = AuthState.unauthenticated();
      rethrow;
    }
  }

  Future<void> signInWithFacebook() async {
    state = AuthState.loading();
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(
          result.accessToken!.tokenString,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        if (userCredential.user != null) {
          await _fetchProfile(userCredential.user!);
        }
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.unauthenticated();
      rethrow;
    }
  }

  Future<void> signInAsGuest() async {
    state = const AuthState(
      status: AuthStatus.guest,
      user: AuthUser(
        id: 'guest',
        firstName: 'Guest',
        lastName: 'Sorter',
        displayName: 'Guest Sorter',
        username: 'guest_sorter',
        coins: 0,
        ownedSkins: {'default'},
        webspiderBrassCoins: 100,
        webspiderCopperCoins: 200,
        webspiderSilverCoins: 50,
        webspiderGoldCoins: 10,
      ),
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    state = AuthState.loading();
    try {
      await _auth.signOut();
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      try {
        await FacebookAuth.instance.logOut();
      } catch (_) {}
    } finally {
      state = AuthState.unauthenticated();
    }
  }

  // ── Profile Updates & Password Verification ───────────────────────────────

  Future<void> updateProfile({
    String? displayName,
    String? username,
    String? avatarUrl,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    int? usernameChangesCount,
    DateTime? displayNameUpdatedAt,
  }) async {
    final current = state.user;
    if (current == null || current.id == 'guest') return;

    final Map<String, dynamic> updates = {
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (displayName != null) updates['display_name'] = displayName;
    if (username != null) updates['username'] = username.toLowerCase().trim();
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (phone != null) updates['phone'] = phone;
    if (email != null) updates['email'] = email;
    if (usernameChangesCount != null) updates['username_changes_count'] = usernameChangesCount;
    if (displayNameUpdatedAt != null) updates['display_name_updated_at'] = Timestamp.fromDate(displayNameUpdatedAt);

    await _firestore.collection('users').doc(current.id).update(updates);

    state = state.copyWith(
      user: current.copyWith(
        displayName: displayName ?? current.displayName,
        username: username ?? current.username,
        avatarUrl: avatarUrl ?? current.avatarUrl,
        firstName: firstName ?? current.firstName,
        lastName: lastName ?? current.lastName,
        phone: phone ?? current.phone,
        email: email ?? current.email,
        usernameChangesCount: usernameChangesCount ?? current.usernameChangesCount,
        displayNameUpdatedAt: displayNameUpdatedAt ?? current.displayNameUpdatedAt,
      ),
    );
  }

  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.verifyBeforeUpdateEmail(newEmail.trim());
      await updateProfile(email: newEmail.trim());
    }
  }

  Future<void> updatePhone(String newPhone) async {
    await updateProfile(phone: newPhone.trim());
  }

  Future<bool> verifyOldPassword(String oldPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: oldPassword,
        );
        await user.reauthenticateWithCredential(credential);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
      state = AuthState.unauthenticated();
    }
  }

  Future<void> initiatePurityChallenge() async {
    // For sensitive changes, sends email verification
  }

  Future<bool> verifyPurityChallenge(String otp) async {
    return true;
  }

  Future<void> refreshWallet() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _fetchProfile(user);
    }
  }

  // ── Economy Helpers ───────────────────────────────────────────────────────

  Future<void> awardCoins(int amount, String reason) async {
    final current = state.user;
    if (current == null) return;

    if (current.id == 'guest') {
      state = state.copyWith(
        user: current.copyWith(coins: current.coins + amount),
      );
      return;
    }

    final newBalance = await WalletService.instance.awardCoins(
      userId: current.id,
      amount: amount,
      reason: reason,
    );

    if (newBalance != null) {
      state = state.copyWith(user: current.copyWith(coins: newBalance));
    }
  }

  Future<bool> purchaseSkin(String skinId, int price) async {
    final current = state.user;
    if (current == null) return false;

    if (current.id == 'guest') {
      if (current.coins < price || current.ownedSkins.contains(skinId)) return false;
      final newOwned = Set<String>.from(current.ownedSkins)..add(skinId);
      state = state.copyWith(
        user: current.copyWith(
          coins: current.coins - price,
          ownedSkins: newOwned,
        ),
      );
      return true;
    }

    final success = await WalletService.instance.purchaseSkin(
      userId: current.id,
      skinId: skinId,
      price: price,
      currentOwnedSkins: current.ownedSkins.toList(),
    );

    if (success) {
      final newOwned = Set<String>.from(current.ownedSkins)..add(skinId);
      state = state.copyWith(
        user: current.copyWith(
          coins: current.coins - price,
          ownedSkins: newOwned,
        ),
      );
    }
    return success;
  }

  Future<Map<String, dynamic>?> claimDailyReward() async {
    final current = state.user;
    if (current == null || current.id == 'guest') return null;

    final result = await WalletService.instance.claimDailyReward(userId: current.id);
    if (result != null && result['success'] == true) {
      state = state.copyWith(
        user: current.copyWith(
          coins: result['new_coins'] as int?,
          dailyStreakCount: result['streak_count'] as int?,
          totalDailyClaims: result['total_claims'] as int?,
          lastDailyClaimAt: DateTime.now(),
        ),
      );
    }
    return result;
  }

  Future<Map<String, dynamic>?> claimMilestoneReward(String milestoneId) async {
    final current = state.user;
    if (current == null || current.id == 'guest') return null;

    final result = await WalletService.instance.claimMilestoneReward(
      userId: current.id,
      milestoneId: milestoneId,
    );

    if (result != null && result['success'] == true) {
      final updatedMilestones = Set<String>.from(current.claimedMilestones)..add(milestoneId);
      state = state.copyWith(
        user: current.copyWith(
          coins: result['new_coins'] as int?,
          claimedMilestones: updatedMilestones,
        ),
      );
    }
    return result;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
