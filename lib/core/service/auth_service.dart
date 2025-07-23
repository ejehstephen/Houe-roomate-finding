import 'dart:developer';

import 'package:camp_nest/core/model/user_model.dart';
import 'package:camp_nest/core/utility/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Sign up with email and password
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required String school,
    required int age,
    required String gender,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'school': school, 'age': age, 'gender': gender},
      );

      if (response.user != null) {
        // Wait a moment for the trigger to create the profile
        await Future.delayed(const Duration(milliseconds: 500));

        // Try to get the user profile
        try {
          return await getUserProfile(response.user!.id);
        } catch (e) {
          // If profile doesn't exist yet, create it manually
          await _createUserProfile(
            userId: response.user!.id,
            name: name,
            email: email,
            school: school,
            age: age,
            gender: gender,
          );
          return await getUserProfile(response.user!.id);
        }
      }
      return null;
    } catch (e) {
      log(e.toString());
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Manual profile creation as fallback
  Future<void> _createUserProfile({
    required String userId,
    required String name,
    required String email,
    required String school,
    required int age,
    required String gender,
  }) async {
    await _client.from('user_profiles').insert({
      'id': userId,
      'name': name,
      'email': email,
      'school': school,
      'age': age,
      'gender': gender,
    });
  }

  // Sign in with email and password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return await getUserProfile(response.user!.id);
      }
      return null;
    } catch (e) {
      log(e.toString());
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response =
          await _client
              .from('user_profiles')
              .select()
              .eq('id', userId)
              .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
