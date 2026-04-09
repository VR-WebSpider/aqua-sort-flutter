import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { authenticated, guest, unauthenticated }

class AuthUser {
  final String firstName;
  final String lastName;
  final String displayName;
  final String? email;
  final String? avatarUrl;

  const AuthUser({
    required this.firstName,
    required this.lastName,
    required this.displayName,
    this.email,
    this.avatarUrl,
  });

  // Legacy compatibility
  String get username => displayName;

  factory AuthUser.guest() => const AuthUser(
    firstName: 'Guest',
    lastName: 'Sorter',
    displayName: 'Guest Sorter',
  );
}

class AuthState {
  final AuthStatus status;
  final AuthUser? user;

  const AuthState({
    required this.status,
    this.user,
  });

  factory AuthState.unauthenticated() => const AuthState(status: AuthStatus.unauthenticated);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.unauthenticated());

  void setGuest() {
    state = AuthState(
      status: AuthStatus.guest,
      user: AuthUser.guest(),
    );
  }

  void login(String firstName, {String lastName = 'Sorter', String? displayName, String? email}) {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: AuthUser(firstName: firstName, lastName: lastName, displayName: displayName ?? firstName, email: email),
    );
  }

  void logout() {
    state = AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
