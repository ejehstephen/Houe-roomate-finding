import 'package:camp_nest/core/model/user_model.dart';
import 'package:camp_nest/core/service/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ------------------------------
/// 🔹 AUTH STATE
/// ------------------------------
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

/// ------------------------------
/// 🔹 AUTH NOTIFIER
/// ------------------------------
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState()) {
    _loadCurrentUser();
  }

  /// ✅ Load user from storage if token/session exists
  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      state = state.copyWith(user: user);
    }
  }

  /// ✅ REGISTER user — backend sends OTP
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
    required String school,
    required int age,
    required String gender,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.signUp(
        name: name,
        email: email,
        password: password,
        school: school,
        age: age,
        gender: gender,
      );

      if (result['success'] == true) {
        state = state.copyWith(user: result['user'], isLoading: false);
      } else {
        state = state.copyWith(error: result['error'], isLoading: false);
      }
      return result;
    } catch (e) {
      final errorMap = {'success': false, 'error': e.toString()};
      state = state.copyWith(error: e.toString(), isLoading: false);
      return errorMap;
    }
  }

  /// ✅ LOGIN — only works after verification
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    print('🔥 DEBUG AuthProvider: Starting signIn for $email');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.signIn(
        email: email,
        password: password,
      );

      print('🔥 DEBUG AuthProvider: Auth service result: ${result['success']}');
      if (result['user'] != null) {
        print('🔥 DEBUG AuthProvider: User received: ${result['user'].name}');
      }

      if (result['success'] == true) {
        state = state.copyWith(user: result['user'], isLoading: false);

        // Force refresh to get the most up-to-date profile image and data
        await refreshUser();
      } else {
        state = state.copyWith(error: result['error'], isLoading: false);
      }
      return result;
    } catch (e) {
      print('❌ DEBUG AuthProvider: Exception during signIn: $e');
      final errorMap = {'success': false, 'error': e.toString()};
      state = state.copyWith(error: e.toString(), isLoading: false);
      return errorMap;
    }
  }

  /// ✅ VERIFY OTP
  Future<bool> verifyOtp(String userId, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _authService.verifyOtp(userId, code);
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// 🔁 RESEND OTP
  Future<bool> resendOtp(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _authService.resendOtp(userId);
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// ✅ UPDATE USER PROFILE
  Future<void> updateUserProfile(UserModel user) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.updateUserProfile(user);
      if (result['success'] == true) {
        state = state.copyWith(user: result['user'], isLoading: false);
      } else {
        state = state.copyWith(error: result['error'], isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// ✅ LOGOUT
  Future<void> signOut() async {
    await _authService.signOut();
    state = AuthState();
  }

  /// 🧩 Setters for local changes
  void setUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  Future<void> setProfileImage(String imageUrl) async {
    final updated = await _authService.setProfileImage(imageUrl);
    if (updated != null) {
      state = state.copyWith(user: updated);
    }
  }

  /// Force refresh the current user state with fresh profile image
  Future<void> refreshUser() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.refreshCurrentUser();
      if (user != null) {
        state = state.copyWith(user: user, isLoading: false);
      } else {
        state = state.copyWith(user: null, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

/// ------------------------------
/// 🔹 PROVIDERS
/// ------------------------------
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
