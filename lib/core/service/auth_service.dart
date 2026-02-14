import 'dart:convert';
import 'dart:io';
import 'package:camp_nest/core/model/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:camp_nest/core/extension/config.dart';

// ... imports remain ...

// ========================= COMPATIBILITY METHODS =========================

// Legacy getter: return AppConfig.apiBaseUrl (old logic) or empty string
// depending on if components still need to contact old backend.
// If images are now absolute Supabase URLs, consumers should handle that.

class AuthService {
  static const String _userKey = 'user_data';
  final SupabaseClient _client = Supabase.instance.client;

  // Legacy getter: return AppConfig.apiBaseUrl (old logic) or empty string
  String get baseUrl => AppConfig.apiBaseUrl;

  // ========================= COMPATIBILITY METHODS =========================
  Future<bool> isAuthenticated() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return false;
      if (JwtDecoder.isExpired(session.accessToken)) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ========================= AUTH OPERATIONS =========================

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    required String school,
    required int age,
    required String gender,
  }) async {
    try {
      // 1. Sign up with Supabase Auth
      // 1. Sign up with Supabase Auth
      final AuthResponse res = await _client.auth.signUp(
        email: email,
        password: password,
        // DEV: Commented out for development testing
        // emailRedirectTo: 'io.campnest://confirm-email',
        data: {
          'name': name,
          'school': school,
          'age': age,
          'gender': gender,
          'profile_image': '',
        },
      );

      final User? user = res.user;
      final Session? session = res.session;

      print('🔥 DEBUG: SignUp - User: ${user?.id}');
      print(
        '🔥 DEBUG: SignUp - Session: ${session != null ? "EXISTS" : "NULL"}',
      );

      if (user == null) {
        return {'success': false, 'error': 'Sign up failed. No user created.'};
      }

      // If session is null, it means email confirmation is required
      if (session == null) {
        // We do NOT store user locally yet because they aren't fully logged in
        return {
          'success': true,
          'message': 'Please check your email to verify your account.',
          'emailConfirmationRequired': true,
          'user': null,
        };
      }

      // 2. Insert extra fields into public.users
      // NOTE: We now rely on a POSTGRES TRIGGER to do this insertion to avoid RLS issues.
      // See triggers.sql

      final userModel = UserModel(
        id: user.id,
        name: name,
        email: email,
        school: school,
        age: age,
        gender: gender,
        preferences: [],
        profileImage: '',
        phoneNumber: null,
      );

      // The manual insert is removed because the trigger 'on_auth_user_created' handles it.

      // 3. Store locally
      await _storeUser(userModel);

      return {
        'success': true,
        'message': 'Registration successful!',
        'user': userModel,
      };
    } catch (e) {
      if (e is AuthException) {
        return {'success': false, 'error': e.message};
      }
      return {'success': false, 'error': 'An unexpected error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final User? user = res.user;
      if (user == null) {
        return {'success': false, 'error': 'Sign in failed.'};
      }

      // Fetch user profile from public.users
      final userProfile = await getUserProfile(user.id);

      if (userProfile != null) {
        // Check if user is banned
        if (userProfile.isBanned) {
          await signOut(); // Force logout
          return {
            'success': false,
            'error':
                'Your account has been suspended for violating community guidelines. Please contact support if you believe this is an error.',
          };
        }

        await _storeUser(userProfile);
        return {'success': true, 'user': userProfile};
      }

      return {
        'success': true,
        'user': null,
      }; // Auth worked but profile missing?
    } catch (e) {
      if (e is AuthException) {
        return {'success': false, 'error': e.message};
      }
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ========================= OTP-BASED AUTHENTICATION =========================

  /// Send OTP to email for email verification (sign-up confirmation)
  Future<Map<String, dynamic>> sendEmailVerificationOTP(String email) async {
    try {
      await _client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null, // OTP only, no redirect
      );
      return {
        'success': true,
        'message': 'Verification code sent to your email!',
      };
    } catch (e) {
      if (e is AuthException) {
        return {'success': false, 'error': e.message};
      }
      return {'success': false, 'error': 'Error sending OTP: $e'};
    }
  }

  /// Verify email OTP code
  Future<Map<String, dynamic>> verifyEmailOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (response.session != null && response.user != null) {
        // Fetch full user profile
        final userModel = await getUserProfile(response.user!.id);
        if (userModel != null) {
          await _storeUser(userModel);
        }

        return {
          'success': true,
          'message': 'Email verified successfully!',
          'user': userModel,
        };
      }

      return {'success': false, 'error': 'Verification failed'};
    } catch (e) {
      if (e is AuthException) {
        return {'success': false, 'error': e.message};
      }
      return {'success': false, 'error': 'Error verifying OTP: $e'};
    }
  }

  /// Send OTP for password reset
  Future<Map<String, dynamic>> sendPasswordResetOTP(String email) async {
    try {
      await _client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false, // Don't create new user if email doesn't exist
        emailRedirectTo: null,
      );
      return {
        'success': true,
        'message': 'Password reset code sent to your email!',
      };
    } catch (e) {
      if (e is AuthException) {
        return {'success': false, 'error': e.message};
      }
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  /// Verify OTP and reset password
  Future<Map<String, dynamic>> verifyOTPAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      // First verify the OTP
      final verifyResponse = await _client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (verifyResponse.session == null) {
        return {'success': false, 'error': 'Invalid or expired OTP'};
      }

      // Update password
      await _client.auth.updateUser(UserAttributes(password: newPassword));

      // Sign out after password reset (user will need to log in with new password)
      await signOut();

      return {
        'success': true,
        'message':
            'Password reset successfully! Please log in with your new password.',
      };
    } catch (e) {
      if (e is AuthException) {
        return {'success': false, 'error': e.message};
      }
      return {'success': false, 'error': 'Error resetting password: $e'};
    }
  }

  // ========================= LEGACY DEEPLINK-BASED (DEPRECATED) =========================

  @Deprecated('Use sendPasswordResetOTP instead')
  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.campnest://reset-password',
      );
      return {
        'success': true,
        'message':
            'Password reset email sent! Check your inbox (and spam folder).',
      };
    } catch (e) {
      if (e is AuthException) {
        return {'success': false, 'error': e.message};
      }
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    await _clearStoredData();
  }

  Future<void> deleteAccount() async {
    try {
      await _client.rpc('delete_user');
      await _clearStoredData();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // ========================= USER DATA =========================

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final data =
          await _client.from('users').select().eq('id', userId).maybeSingle();

      if (data == null) return null;
      return UserModel.fromJson(data);
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(UserModel user) async {
    try {
      // UserModel toJson uses snake_case which matches schema
      await _client.from('users').update(user.toJson()).eq('id', user.id);

      await _storeUser(user);
      return {'success': true, 'user': user};
    } catch (e) {
      return {'success': false, 'error': 'Update failed: $e'};
    }
  }

  Future<String> uploadProfileImage(File imageFile) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final fileExt = imageFile.path.split('.').last;
      final fileName =
          '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _client.storage
          .from('avatars') // Assuming 'avatars' bucket, or 'listing-images'
          .upload(fileName, imageFile);

      final imageUrl = _client.storage.from('avatars').getPublicUrl(fileName);

      // Update user profile
      await _client
          .from('users')
          .update({'profile_image': imageUrl})
          .eq('id', userId);

      // Update local storage
      final currentUser = await getStoredUser();
      if (currentUser != null) {
        await _storeUser(currentUser.copyWith(profileImage: imageUrl));
      }

      return imageUrl;
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  // ========================= LOCAL STORAGE =========================

  Future<void> _storeUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_userKey);
    if (jsonStr != null) {
      return UserModel.fromJson(jsonDecode(jsonStr));
    }
    return null;
  }

  Future<void> _clearStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<UserModel?> getCurrentUser() async {
    // Return Supabase user if logged in, combined with DB profile
    final session = _client.auth.currentSession;
    if (session == null) return null;

    // Attempt fast return from local storage
    var localUser = await getStoredUser();
    if (localUser != null) return localUser;

    // Fallback fetch
    final profile = await getUserProfile(session.user.id);
    if (profile != null) await _storeUser(profile);
    return profile;
  }

  // Method needed for backward compatibility or direct token usage
  Future<String?> getToken() async {
    return _client.auth.currentSession?.accessToken;
  }

  Future<bool> verifyOtp(String userId, String code) async {
    // Supabase handles OTP differently.
    // If migrating, you might use verifyOTP() from client.auth
    // For now returning true to bypass or false if strictly needed
    try {
      final res = await _client.auth.verifyOTP(
        token: code,
        type: OtpType.signup,
        email: (await getUserProfile(userId))?.email,
      );
      return res.session != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resendOtp(String userId) async {
    // Stub or implement with client.auth.resend();
    return true;
  }

  Future<UserModel?> setProfileImage(String imageUrl) async {
    final user = await getCurrentUser();
    if (user != null) {
      final updated = user.copyWith(profileImage: imageUrl);
      await updateUserProfile(updated);
      return updated;
    }
    return null;
  }

  Future<UserModel?> refreshCurrentUser() async {
    // Force fetch from DB (bypass local cache)
    final session = _client.auth.currentSession;
    if (session == null) return null;

    final profile = await getUserProfile(session.user.id);
    if (profile != null) {
      // If user was banned, force logout
      if (profile.isBanned) {
        await signOut();
        return null;
      }
      await _storeUser(profile); // Update local cache with fresh data
    }
    return profile;
  }
}
