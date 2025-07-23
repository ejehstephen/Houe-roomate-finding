import 'package:camp_nest/core/model/user_model.dart';
import 'package:camp_nest/core/service/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState()) {
    _initializeAuth();
  }

  void _initializeAuth() {
    // Check if user is already signed in
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      _loadUserProfile(currentUser.id);
    }

    // Listen to auth state changes
    _authService.authStateChanges.listen((authState) {
      if (authState.event == AuthChangeEvent.signedIn &&
          authState.session?.user != null) {
        _loadUserProfile(authState.session!.user.id);
      } else if (authState.event == AuthChangeEvent.signedOut) {
        state = AuthState();
      }
    });
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      final user = await _authService.getUserProfile(userId);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.signIn(email: email, password: password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String school,
    required int age,
    required String gender,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        school: school,
        age: age,
        gender: gender,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = AuthState();
  }
}

// Providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
