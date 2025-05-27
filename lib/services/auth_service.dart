// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/supabase_config.dart';

class AuthService {
  static final _client = SupabaseConfig.client;

  // Get current user
  static User? get currentUser => _client.auth.currentUser;
  static String? get currentUserId => _client.auth.currentUser?.id;

  // Check if user is admin
  static Future<bool> isAdmin(String email) async {
    try {
      final response = await _client
          .from('admins')
          .select()
          .eq('email', email)
          .single();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Create or update user profile
  static Future<void> createOrUpdateUser({
    required String userId,
    required String email,
    required String fullName,
    required String username,
    required String phone,
  }) async {
    try {
      // Check if user exists
      final existingUser = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingUser == null) {
        // Create new user
        await _client.from('users').insert({
          'id': userId,
          'email': email,
          'username': username,
          'full_name': fullName,
          'phone': phone,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Update existing user
        await _client.from('users').update({
          'username': username,
          'full_name': fullName,
          'phone': phone,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      }
    } catch (e) {
      print('Error in createOrUpdateUser: $e');
      throw Exception('Failed to create/update user: $e');
    }
  }

  // Simple sign up without email verification
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String phone,
  }) async {
    try {
      // Create auth user
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Create user profile
        await createOrUpdateUser(
          userId: response.user!.id,
          email: email,
          fullName: fullName,
          username: username,
          phone: phone,
        );
      }

      return response;
    } catch (e) {
      print('Error in signUp: $e');
      throw Exception('Registration failed: $e');
    }
  }

  // Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Check if user has a profile, if not, create one
      if (response.user != null) {
        final userProfile = await _client
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();

        if (userProfile == null) {
          // Create default profile for manually created users
          await createOrUpdateUser(
            userId: response.user!.id,
            email: response.user!.email!,
            fullName: 'User',  // Default name
            username: response.user!.email!.split('@')[0],  // Use email prefix as username
            phone: '',  // Empty phone
          );
        }
      }

      return response;
    } catch (e) {
      print('Error in signIn: $e');
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      print('Error in signOut: $e');
      rethrow;
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUserId == null) return null;

      final response = await _client
          .from('users')
          .select()
          .eq('id', currentUserId!)
          .single();

      return response;
    } catch (e) {
      print('Error in getUserProfile: $e');
      return null;
    }
  }

  // Update user profile
  static Future<void> updateProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Not authenticated');

      await _client.from('profiles').update({
        'full_name': fullName,
        'phone_number': phoneNumber,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      print('Error in updateProfile: $e');
      rethrow;
    }
  }

  // Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  // Stream of auth state changes
  static Stream<AuthState> get authStateChanges {
    return _client.auth.onAuthStateChange;
  }

  static String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  static Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }

  static Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
    } catch (e) {
      print('Error updating password: $e');
      rethrow;
    }
  }

  // Check if username is available
  static Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('username', username)
          .single();
      return response == null;
    } catch (e) {
      return true;
    }
  }
}