import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_service.dart';
import '../domain/user_profile.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService();
  ref.onDispose(service.dispose);
  return service;
});

final currentUserProvider = StreamProvider<UserProfile?>((ref) {
  final service = ref.watch(authServiceProvider);
  return _currentUserStream(service);
});

/// Emits the already-known profile first, then follows auth changes. Without
/// this, the initial mock/local profile (emitted synchronously in the service
/// constructor, before any listener attaches) would be lost.
Stream<UserProfile?> _currentUserStream(AuthService service) async* {
  final current = service.currentUser;
  if (current != null) yield current;
  yield* service.userStream;
}

class AuthState {
  final bool isLoading;
  final String? errorMessage;

  const AuthState({this.isLoading = false, this.errorMessage});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  Future<bool> signInWithEmail(String email, String password) async {
    state = const AuthState(isLoading: true);
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      state = const AuthState();
      return true;
    } catch (e) {
      state = AuthState(errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, String displayName) async {
    state = const AuthState(isLoading: true);
    try {
      await _authService.createUserWithEmailAndPassword(email, password, displayName);
      state = const AuthState();
      return true;
    } catch (e) {
      state = AuthState(errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AuthState(isLoading: true);
    try {
      await _authService.signInWithGoogle();
      state = const AuthState();
      return true;
    } catch (e) {
      state = AuthState(errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}

final authControllerProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthNotifier(service);
});

