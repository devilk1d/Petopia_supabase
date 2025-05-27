import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_config.dart';
import '../services/auth_service.dart';

class UserService {
  static final _client = SupabaseConfig.client;

  // Get current user profile
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Subscribe to user profile changes
  static Stream<Map<String, dynamic>> subscribeToUserProfile() {
    final userId = AuthService.getCurrentUserId();
    if (userId == null) throw Exception('User not logged in');

    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((event) => event.first);
  }

  // Get all profiles in the household
  static Future<List<Map<String, dynamic>>> getHouseholdProfiles() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      // Get the household ID of the current user
      final userProfile = await _client
          .from('profiles')
          .select('household_id')
          .eq('id', userId)
          .single();

      if (userProfile == null || userProfile['household_id'] == null) {
        return [];
      }

      // Get all profiles in the same household
      final response = await _client
          .from('profiles')
          .select()
          .eq('household_id', userProfile['household_id'])
          .order('created_at');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching household profiles: $e');
      return [];
    }
  }

  // Get user's store profiles
  static Future<List<Map<String, dynamic>>> getUserStores() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await _client
          .from('sellers')
          .select()
          .eq('user_id', userId)
          .order('created_at');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching user stores: $e');
      return [];
    }
  }

  // Update user profile
  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      // Add updated_at timestamp
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('users')
          .update(data)
          .eq('id', userId)
          .select()
          .single();

      return response != null;
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
} 