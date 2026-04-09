import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/features/auth/screens/splash_screen.dart';
import 'package:aqua_sort/features/auth/screens/login_screen.dart';
import 'package:aqua_sort/features/auth/screens/register_screen.dart';
import 'package:aqua_sort/features/auth/screens/otp_screen.dart';
import 'package:aqua_sort/features/auth/screens/verification_screen.dart';
import 'package:aqua_sort/features/auth/screens/success_screen.dart';
import 'package:aqua_sort/features/lobby/screens/lobby_screen.dart';
import 'package:aqua_sort/features/profile/screens/profile_screen.dart';
import 'package:aqua_sort/features/game/screens/game_screen.dart';
import 'package:aqua_sort/features/leaderboard/screens/leaderboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(ref.watch(authProvider.notifier).stream),
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isLoggedIn = auth.status != AuthStatus.unauthenticated;
      
      final isAuthPath = state.uri.path == '/login' || 
                        state.uri.path == '/register' || 
                        state.uri.path == '/' ||
                        state.uri.path == '/otp' ||
                        state.uri.path == '/verification';

      // 1. Unauthenticated users must be on an auth path
      if (!isLoggedIn) {
        return isAuthPath ? null : '/login';
      }

      // 2. Logged in users (Authenticated or Guest) should not be on auth paths
      // EXCEPT if a guest manually tries to go to login/register to upgrade
      if (isLoggedIn && isAuthPath) {
        // If it's a guest on login/register, allow it
        if (auth.status == AuthStatus.guest && (state.uri.path == '/login' || state.uri.path == '/register')) {
           return null;
        }
        // Otherwise (authenticated on splash, or guest on splash), go to lobby
        return '/lobby';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/',            builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/login',       builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register',    builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/otp',         builder: (c, s) => OtpScreen(userData: s.extra as Map<String, dynamic>)),
      GoRoute(path: '/verification',builder: (c, s) => VerificationScreen(userData: s.extra as Map<String, dynamic>)),
      GoRoute(path: '/success',     builder: (c, s) => const SuccessScreen()),
      GoRoute(path: '/lobby',       builder: (c, s) => const CampaignScreen()),
      GoRoute(path: '/lobby-v1',    builder: (c, s) => const LobbyScreen()),
      GoRoute(path: '/profile',     builder: (c, s) => const ProfileScreen()),
      GoRoute(path: '/game',        builder: (c, s) => const GameScreen()),
      GoRoute(path: '/leaderboard', builder: (c, s) => const LeaderboardScreen()),
    ],
  );
});

// Helper for GoRouter to listen to Stream
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) {
      Future.microtask(() => notifyListeners());
    });
  }
  @override void dispose() { _subscription.cancel(); super.dispose(); }
}
