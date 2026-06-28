import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
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
  final SupabaseClient _supabase = Supabase.instance.client;

  AuthNotifier() : super(AuthState.unauthenticated()) {
    _init();
  }

  void _init() {
    debugPrint('AUTH_NOTIFIER: Initializing...');
    
    // 1. Scan URL for recovery hint (Web Only)
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.toString().contains('type=recovery') || uri.queryParameters['type'] == 'recovery') {
        debugPrint('RECOVERY HINT DETECTED');
        state = AuthState.recovering();
      }
    }

    // 2. Listen to Supabase Auth Changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      debugPrint('AUTH EVENT: $event');

      if (event == AuthChangeEvent.passwordRecovery) {
        debugPrint('AUTH_NOTIFIER: Password Recovery Event Detected');
        state = AuthState.recovering();
      } else if ((event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) && session != null) {
        _fetchProfile(session.user.id, session.user.email, session.user.phone);
      } else if (event == AuthChangeEvent.signedOut) {
        state = AuthState.unauthenticated();
      }
    });

    // 3. Listen to AppLinks (For Deep Linking on Mobile & Desktop)
    if (!kIsWeb) {
      debugPrint('AUTH_NOTIFIER: Initializing AppLinks listener...');
      AppLinks().uriLinkStream.listen((uri) {
        debugPrint('AUTH_NOTIFIER: Deep Link Received: $uri');
        if (uri.toString().contains('type=recovery') || uri.queryParameters['type'] == 'recovery' || uri.fragment.contains('type=recovery')) {
          debugPrint('AUTH_NOTIFIER: RECOVERY LINK DETECTED via Deep Link!');
          state = AuthState.recovering();
        }
      });
      
      // Also check for initial link (if app was opened by the link)
      AppLinks().getInitialLink().then((uri) {
        if (uri != null) {
          debugPrint('AUTH_NOTIFIER: Initial Deep Link: $uri');
          if (uri.toString().contains('type=recovery') || uri.queryParameters['type'] == 'recovery' || uri.fragment.contains('type=recovery')) {
            state = AuthState.recovering();
          }
        }
      });
    }

    // 4. Initial Session Check
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _fetchProfile(session.user.id, session.user.email, session.user.phone);
    }
  }

  Future<void> signInWithSocial(OAuthProvider provider) async {
    state = AuthState.loading();
    try {
      await _supabase.auth.signInWithOAuth(
        provider,
        redirectTo: 'com.webspider.aquasort.mobile://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      state = AuthState.unauthenticated();
      rethrow;
    }
  }

  Future<void> _fetchProfile(String userId, String? email, String? phone) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _supabase
          .from('profiles')
          .select('username, username_changes_count, display_name_updated_at, first_name, last_name, display_name, avatar_url, coins, owned_skins, phone, webspider_brass_coins, webspider_copper_coins, webspider_silver_coins, webspider_gold_coins, webspider_diamond_coins, webspider_jade_coins, webspider_obsidian_coins, last_daily_claim_at, daily_streak_count, total_daily_claims, claimed_milestones')
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        String displayName = data['display_name'] ?? '';
        if (displayName.isEmpty) {
          final randomNum = math.Random().nextInt(90000) + 10000;
          displayName = 'SpiderPlayer_$randomNum';
          try {
            await _supabase.from('profiles').update({'display_name': displayName}).eq('id', userId);
          } catch (e) {
            debugPrint('Error auto-setting display name: $e');
          }
        }

        String username = data['username'] ?? '';
        if (username.isEmpty) {
          username = displayName.toLowerCase().replaceAll(RegExp(r'\s+'), '');
          try {
            await _supabase.from('profiles').update({'username': username}).eq('id', userId);
          } catch (e) {
            debugPrint('Error auto-setting username: $e');
          }
        }

        final ownedRaw = data['owned_skins'];
        final ownedSkins = ownedRaw != null
            ? Set<String>.from(ownedRaw as List)
            : <String>{'default'};

        final milestoneRaw = data['claimed_milestones'];
        final claimedMilestones = milestoneRaw != null
            ? Set<String>.from(milestoneRaw as List)
            : <String>{};

        final bool isGuestUser = _supabase.auth.currentUser?.isAnonymous ?? false;
        state = state.copyWith(
          status: isGuestUser ? AuthStatus.guest : AuthStatus.authenticated,
          isLoading: false,
          user: AuthUser(
            id: userId,
            firstName: data['first_name'] ?? '',
            lastName: data['last_name'] ?? '',
            displayName: displayName,
            username: username,
            email: email,
            phone: data['phone'] ?? phone,
            avatarUrl: data['avatar_url'],
            usernameChangesCount: (data['username_changes_count'] as num?)?.toInt() ?? 0,
            displayNameUpdatedAt: data['display_name_updated_at'] != null 
                ? DateTime.parse(data['display_name_updated_at'].toString()) 
                : null,
            coins: (data['coins'] as num?)?.toInt() ?? 0,
            webspiderBrassCoins: (data['webspider_brass_coins'] as num?)?.toInt() ?? 100,
            webspiderCopperCoins: (data['webspider_copper_coins'] as num?)?.toInt() ?? 200,
            webspiderSilverCoins: (data['webspider_silver_coins'] as num?)?.toInt() ?? 50,
            webspiderGoldCoins: (data['webspider_gold_coins'] as num?)?.toInt() ?? 10,
            webspiderDiamondCoins: (data['webspider_diamond_coins'] as num?)?.toInt() ?? 0,
            webspiderJadeCoins: (data['webspider_jade_coins'] as num?)?.toInt() ?? 0,
            webspiderObsidianCoins: (data['webspider_obsidian_coins'] as num?)?.toInt() ?? 0,
            ownedSkins: ownedSkins,
            lastDailyClaimAt: data['last_daily_claim_at'] != null 
                ? DateTime.parse(data['last_daily_claim_at'].toString()) 
                : null,
            dailyStreakCount: (data['daily_streak_count'] as num?)?.toInt() ?? 0,
            totalDailyClaims: (data['total_daily_claims'] as num?)?.toInt() ?? 0,
            claimedMilestones: claimedMilestones,
          ),
        );
      } else {
        // Create initial profile if missing
        final randomNum = math.Random().nextInt(90000) + 10000;
        final randomName = 'SpiderPlayer_$randomNum';
        await _supabase.from('profiles').insert({
          'id': userId,
          'first_name': '',
          'last_name': '',
          'display_name': randomName,
          'username': randomName.toLowerCase(),
          'coins': 0,
          'owned_skins': ['default'],
          'phone': phone,
        });
        _fetchProfile(userId, email, phone);
      }
    } catch (e) {
      state = AuthState.unauthenticated();
    }
  }

  /// Refresh the wallet balance from Supabase (call after any transaction).
  Future<void> refreshWallet() async {
    final userId = state.user?.id;
    if (userId == null || userId == 'guest') return;
    try {
      final data = await _supabase
          .from('profiles')
          .select('coins, owned_skins, webspider_brass_coins, webspider_copper_coins, webspider_silver_coins, webspider_gold_coins, webspider_diamond_coins, webspider_jade_coins, webspider_obsidian_coins, last_daily_claim_at, daily_streak_count, total_daily_claims, claimed_milestones')
          .eq('id', userId)
          .single();

      final ownedRaw = data['owned_skins'];
      final ownedSkins = ownedRaw != null
          ? Set<String>.from(ownedRaw as List)
          : <String>{'default'};

      final milestoneRaw = data['claimed_milestones'];
      final claimedMilestones = milestoneRaw != null
          ? Set<String>.from(milestoneRaw as List)
          : <String>{};

      final newUser = state.user!.copyWith(
        coins: (data['coins'] as num?)?.toInt() ?? 0,
        ownedSkins: ownedSkins,
        webspiderBrassCoins: (data['webspider_brass_coins'] as num?)?.toInt() ?? 100,
        webspiderCopperCoins: (data['webspider_copper_coins'] as num?)?.toInt() ?? 200,
        webspiderSilverCoins: (data['webspider_silver_coins'] as num?)?.toInt() ?? 50,
        webspiderGoldCoins: (data['webspider_gold_coins'] as num?)?.toInt() ?? 10,
        webspiderDiamondCoins: (data['webspider_diamond_coins'] as num?)?.toInt() ?? 0,
        webspiderJadeCoins: (data['webspider_jade_coins'] as num?)?.toInt() ?? 0,
        webspiderObsidianCoins: (data['webspider_obsidian_coins'] as num?)?.toInt() ?? 0,
        lastDailyClaimAt: data['last_daily_claim_at'] != null 
            ? DateTime.parse(data['last_daily_claim_at'].toString()) 
            : null,
        dailyStreakCount: (data['daily_streak_count'] as num?)?.toInt() ?? 0,
        totalDailyClaims: (data['total_daily_claims'] as num?)?.toInt() ?? 0,
        claimedMilestones: claimedMilestones,
      );
      state = AuthState(status: state.status, user: newUser);
    } catch (_) {}
  }

  Future<void> setGuest() async {
    state = AuthState.loading();
    try {
      final res = await _supabase.auth.signInAnonymously();
      if (res.user != null) {
        _fetchProfile(res.user!.id, null, null);
      }
    } catch (e) {
      state = AuthState.unauthenticated();
      rethrow;
    }
  }

  Future<void> signInAnonymously() async => setGuest();

  Future<void> login(String identifier, String password) async {
    state = AuthState.loading();
    try {
      String email = identifier;
      
      // Dual-ID Lookup: If user entered a phone number or username (no @), find linked email
      if (!identifier.contains('@')) {
        final res = await _supabase
            .from('profiles')
            .select('email_lookup')
            .or('phone.eq.$identifier,username.eq.${identifier.toLowerCase().trim()}')
            .maybeSingle();
        
        if (res == null) throw 'Username or Phone number not recognized.';
        email = res['email_lookup'] ?? '';
        if (email.isEmpty) throw 'Associated email not found.';
      }

      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      state = AuthState.unauthenticated();
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, {String? firstName, String? lastName, String? phone}) async {
    state = AuthState.loading();
    try {
      await _supabase.auth.signUp(
        email: email, 
        password: password,
        data: {'game': 'Aqua Sort'},
      );
      // Reset loading state if successful, allowing OTP screen to show buttons correctly
      state = AuthState.unauthenticated(); 
    } on AuthApiException catch (e) {
      state = AuthState.unauthenticated();
      if (e.code == 'over_email_send_rate_limit') {
        throw 'Too many requests. Please wait a few minutes before trying again.';
      }
      rethrow;
    } catch (e) {
      state = AuthState.unauthenticated();
      rethrow;
    }
  }

  Future<void> verifyOtp(String email, String token, {String? firstName, String? lastName, String? phone}) async {
    state = AuthState.loading();
    try {
      final res = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );

      if (res.user != null) {
        final randomNum = math.Random().nextInt(90000) + 10000;
        final randomName = 'SpiderPlayer_$randomNum';
        
        // Create initial profile with BOTH email (for lookup) and phone
        await _supabase.from('profiles').upsert({
          'id': res.user!.id,
          'first_name': '',
          'last_name': '',
          'display_name': randomName,
          'username': randomName.toLowerCase(),
          'email_lookup': email, // Save email here for phone-based lookup later
          'phone': phone,
          'coins': 0,
          'owned_skins': ['default'],
        });
        
        await _fetchProfile(res.user!.id, res.user!.email, res.user!.phone);
      } else {
        // If user is null, we are not authenticated
        state = AuthState.unauthenticated();
      }
    } on AuthApiException catch (e) {
      state = AuthState.unauthenticated();
      if (e.code == 'otp_expired') throw 'Code expired. Please resend.';
      if (e.code == 'invalid_otp') throw 'Invalid code. Please check and try again.';
      rethrow;
    } catch (e) {
      state = AuthState.unauthenticated();
      rethrow;
    }
  }

  // ── Track C: High-Security Purity Challenge & Reset ─────────────────────

  /// Initiates a custom "Purity Challenge" for sensitive account actions
  Future<void> initiatePurityChallenge() async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.email == null) throw 'Authentication required.';

    // 0. Cleanup: Delete any existing challenges for this user to ensure only the latest is valid
    await _supabase.from('purity_challenges').delete().eq('user_id', user.id);

    // 1. Generate a random 6-digit challenge code
    final String challengeCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();

    // 2. Store challenge code in purity_challenges table
    await _supabase.from('purity_challenges').upsert({
      'user_id': user.id,
      'code': challengeCode,
      'target_email': user.email,
      'challenge_type': 'PURITY_CHECK',
      'game': 'Aqua Sort',
      'expires_at': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
    });

    // Simulated Logs for Dev Console
    print('PURITY CHALLENGE CODE: $challengeCode');
  }

  /// Initiates a Dual-OTP Email Swap (Zero Casualization Protocol)
  Future<void> initiateEmailSwap(String newEmail) async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.email == null) throw 'Authentication required.';

    // Code A: Sent to Old Email
    final String codeA = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    // Code B: Sent to New Email
    final String codeB = (100000 + (DateTime.now().microsecondsSinceEpoch % 900000)).toString();

    // Store both challenges
    await _supabase.from('purity_challenges').upsert([
      {
        'user_id': user.id,
        'code': codeA,
        'challenge_type': 'OLD_EMAIL',
        'target_email': user.email,
        'game': 'Aqua Sort',
        'expires_at': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
      },
      {
        'user_id': user.id,
        'code': codeB,
        'challenge_type': 'NEW_EMAIL',
        'target_email': newEmail,
        'game': 'Aqua Sort',
        'expires_at': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
      }
    ]);

    // Simulated Logs (In production: send emails)
    print('ZERO CASUALIZATION - CODE A (OLD: ${user.email}): $codeA');
    print('ZERO CASUALIZATION - CODE B (NEW: $newEmail): $codeB');
  }

  /// Verifies Dual-OTP for Email Swap
  Future<bool> verifyEmailSwap(String newEmail, String oldCode, String newCode) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final challenges = await _supabase
        .from('purity_challenges')
        .select()
        .eq('user_id', user.id)
        .inFilter('code', [oldCode, newCode]);

    if (challenges.length < 2) return false;

    // Check expiry for both
    for (var challenge in challenges) {
      final expiresAt = DateTime.parse(challenge['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) return false;
    }

    // Process the update
    await _supabase.auth.updateUser(UserAttributes(email: newEmail));
    
    // Also update our lookup and profiles
    await _supabase.from('profiles').update({
      'email_lookup': newEmail,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);

    return true;
  }

  /// Verifies the custom Purity Challenge code
  Future<bool> verifyPurityChallenge(String code) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final res = await _supabase
        .from('purity_challenges')
        .select()
        .eq('user_id', user.id)
        .eq('code', code)
        .maybeSingle();

    if (res == null) return false;

    // Check expiry
    final expiresAt = DateTime.parse(res['expires_at']);
    if (DateTime.now().isAfter(expiresAt)) {
      throw 'Security challenge expired.';
    }

    // 3. One-time use: Delete the challenge after successful verification
    await _supabase
        .from('purity_challenges')
        .delete()
        .eq('user_id', user.id)
        .eq('code', code);

    return true;
  }

  Future<void> forgotPassword(String identifier) async {
    state = AuthState.loading();
    try {
      String email = identifier;

      // If phone or username provided (no @), find linked email
      if (!identifier.contains('@')) {
        final res = await _supabase
            .from('profiles')
            .select('email_lookup')
            .or('phone.eq.$identifier,username.eq.${identifier.toLowerCase().trim()}')
            .maybeSingle();
        
        if (res == null) throw 'Username or Phone number not linked to any account.';
        email = res['email_lookup'] ?? '';
        if (email.isEmpty) throw 'Associated email not found.';
      }

      String? redirectTo;
      if (kIsWeb) {
        redirectTo = '${Uri.base.origin}/?type=recovery';
      } else if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
        // For PC players, we use the custom protocol to redirect back to the app
        // Note: The scheme must be registered in Supabase Dashboard > Authentication > URL Configuration
        redirectTo = 'com.webspider.aquasort.mobile://login-callback/'; 
      } else {
        // For Mobile players, use the native deep link to open the app directly
        redirectTo = 'com.webspider.aquasort.mobile://login-callback/';
      }

      await _supabase.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
      debugPrint('AUTH_NOTIFIER: Reset link sent with redirectTo: $redirectTo');
      state = AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.unauthenticated();
      rethrow;
    }
  }

  Future<void> verifyRecoveryOtp(String identifier, String token) async {
    state = AuthState.loading();
    try {
      String email = identifier;

      // Dual-ID Lookup: If user entered a phone number or username (no @), find linked email
      if (!identifier.contains('@')) {
        final res = await _supabase
            .from('profiles')
            .select('email_lookup')
            .or('phone.eq.$identifier,username.eq.${identifier.toLowerCase().trim()}')
            .maybeSingle();
        
        if (res == null) throw 'Username or Phone number not recognized.';
        email = res['email_lookup'] ?? '';
        if (email.isEmpty) throw 'Associated email not found.';
      }

      await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );

      // Transition to recovering password state
      state = AuthState(
        status: AuthStatus.authenticated,
        user: state.user,
        isLoading: false,
        isRecoveringPassword: true,
      );
    } on AuthApiException catch (e) {
      state = AuthState.unauthenticated();
      if (e.code == 'otp_expired') throw 'Code expired. Please resend.';
      if (e.code == 'invalid_otp') throw 'Invalid code. Please check and try again.';
      rethrow;
    } catch (e) {
      state = AuthState.unauthenticated();
      rethrow;
    }
  }


  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? displayName,
    String? avatarUrl,
    String? username,
    String? phone,
    String? email,
    int? usernameChangesCount,
    DateTime? displayNameUpdatedAt,
  }) async {
    if (state.user == null || state.user!.id == 'guest') return;

    final updates = {
      'id': state.user!.id,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (username != null) 'username': username,
      if (phone != null) 'phone': phone,
      if (email != null) 'email_lookup': email,
      if (usernameChangesCount != null) 'username_changes_count': usernameChangesCount,
      if (displayNameUpdatedAt != null) 'display_name_updated_at': displayNameUpdatedAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await _supabase.from('profiles').upsert(updates);
      final newUser = state.user!.copyWith(
        firstName: firstName,
        lastName: lastName,
        displayName: displayName,
        avatarUrl: avatarUrl,
        username: username,
        phone: phone,
        email: email,
        usernameChangesCount: usernameChangesCount,
        displayNameUpdatedAt: displayNameUpdatedAt,
      );
      state = AuthState(status: state.status, user: newUser);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateEmail(String email) async {
    await _supabase.auth.updateUser(UserAttributes(email: email));
  }

  Future<bool> verifyOldPassword(String oldPassword) async {
    final email = state.user?.email;
    if (email == null) return false;
    try {
      // Attempt to sign in with current email and the provided "old" password to verify it
      await _supabase.auth.signInWithPassword(email: email, password: oldPassword);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updatePhone(String phone) async {
    await _supabase.auth.updateUser(UserAttributes(phone: phone));
  }

  Future<void> updatePassword(String newPassword) async {
    state = AuthState(
      status: state.status, 
      user: state.user, 
      isLoading: true, 
      isRecoveringPassword: state.isRecoveringPassword
    );
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      state = AuthState(
        status: state.status, 
        user: state.user, 
        isLoading: false, 
        isRecoveringPassword: false
      );
    } catch (e) {
      state = AuthState(
        status: state.status, 
        user: state.user, 
        isLoading: false, 
        isRecoveringPassword: state.isRecoveringPassword
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<void> deleteAccount() async {
    // Note: Deleting auth user usually requires admin privileges or specific edge function.
    // For now, we sign out and let RLS handle data isolation.
    await logout();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
