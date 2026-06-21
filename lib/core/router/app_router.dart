import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aqua_sort/core/services/audio_service.dart';
import 'package:aqua_sort/features/auth/providers/auth_provider.dart';
import 'package:aqua_sort/features/auth/screens/splash_screen.dart';
import 'package:aqua_sort/features/auth/screens/login_screen.dart';
import 'package:aqua_sort/features/auth/screens/register_screen.dart';
import 'package:aqua_sort/features/auth/screens/otp_screen.dart';
import 'package:aqua_sort/features/auth/screens/verification_screen.dart';
import 'package:aqua_sort/features/auth/screens/success_screen.dart';
import 'package:aqua_sort/features/auth/screens/forgot_password_screen.dart';
import 'package:aqua_sort/features/auth/screens/reset_password_screen.dart';
import 'package:aqua_sort/features/lobby/screens/lobby_screen.dart';
import 'package:aqua_sort/features/profile/screens/profile_screen.dart';
import 'package:aqua_sort/features/game/screens/game_screen.dart';
import 'package:aqua_sort/features/leaderboard/screens/leaderboard_screen.dart';
import 'package:aqua_sort/features/lobby/screens/campaign_screen.dart';
import 'package:aqua_sort/features/lobby/screens/multiplayer_lobby_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(ref.watch(authProvider.notifier).stream),
    observers: [
      NavigationAudioObserver(),
    ],
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isLoggedIn = auth.status != AuthStatus.unauthenticated;
      
      final isAuthPath = state.uri.path == '/login' || 
                        state.uri.path == '/register' || 
                        state.uri.path == '/' ||
                        state.uri.path == '/otp' ||
                        state.uri.path == '/verification' || 
                        state.uri.path == '/forgot-password' ||
                        state.uri.path == '/success';

      // 1. Password Recovery takes priority
      if (auth.isRecoveringPassword && state.uri.path != '/reset-password') {
        debugPrint('ROUTER: Redirecting to /reset-password');
        return '/reset-password';
      }

      // 2. Unauthenticated users must be on an auth path
      if (!isLoggedIn) {
        return isAuthPath ? null : '/';
      }

      // 2. Logged in users (Authenticated or Guest) should not be on auth paths
      // EXCEPT if a guest manually tries to go to login/register to upgrade
      if (isLoggedIn && isAuthPath) {
        // If it's a guest on login/register, allow it
        if (auth.status == AuthStatus.guest && (state.uri.path == '/login' || state.uri.path == '/register')) {
           return null;
        }
        
        // If we are on success or verification, allow the animation to play
        if (state.uri.path == '/success' || state.uri.path == '/verification') {
          return null;
        }

        // Otherwise (authenticated on splash, or guest on splash), go to lobby
        return '/lobby';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (c, s) => const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (c, s) => _fadeTransition(s, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (c, s) => _fadeTransition(s, const RegisterScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (c, s) => _fadeTransition(s, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (c, s) => _fadeTransition(s, const ResetPasswordScreen()),
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (c, s) => _fadeTransition(s, OtpScreen(userData: s.extra as Map<String, dynamic>)),
      ),
      GoRoute(
        path: '/verification',
        pageBuilder: (c, s) => _fadeTransition(s, VerificationScreen(userData: s.extra as Map<String, dynamic>)),
      ),
      GoRoute(
        path: '/success',
        pageBuilder: (c, s) {
          final data = s.extra as Map<String, dynamic>?;
          return _fadeTransition(s, SuccessScreen(
            title: data?['title'],
            message: data?['message'],
          ));
        },
      ),
      GoRoute(
        path: '/lobby',
        pageBuilder: (c, s) => _zoomTransition(s, const CampaignScreen()),
      ),
      GoRoute(
        path: '/lobby-v1',
        pageBuilder: (c, s) => _fadeTransition(s, const LobbyScreen()),
      ),
      GoRoute(
        path: '/multiplayer',
        pageBuilder: (c, s) => _zoomTransition(s, const MultiplayerLobbyScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (c, s) => _slideTransition(s, const ProfileScreen(), begin: const Offset(1, 0)),
      ),
      GoRoute(
        path: '/customization',
        pageBuilder: (c, s) => _zoomTransition(s, const CustomizationScreen()),
      ),
      GoRoute(
        path: '/game',
        pageBuilder: (c, s) => _slideTransition(s, const GameScreen(), begin: const Offset(0, 1)),
      ),
      GoRoute(
        path: '/leaderboard',
        pageBuilder: (c, s) => _slideTransition(s, const LeaderboardScreen(), begin: const Offset(0, 1)),
      ),
    ],
  );
});

CustomTransitionPage _fadeTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

CustomTransitionPage _slideTransition(GoRouterState state, Widget child, {required Offset begin}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      );
    },
  );
}

CustomTransitionPage _zoomTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

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

class NavigationAudioObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute != null) {
      AudioService.instance.playClick();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      AudioService.instance.playClick();
    }
  }
}
