// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../services/supabase_config.dart';

class AuthService {
  static final _client = SupabaseConfig.client;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Use WEB client ID for Supabase compatibility
    clientId: '690711971091-b9g8ssq60v354ikhf7cd2tj3bbgbcme7.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
      'openid',
    ],
    // Force account selection every time
    forceCodeForRefreshToken: true,
  );

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

  // Google Sign In
  static Future<AuthResponse?> signInWithGoogle() async {
    try {
      print('🔍 Starting Google Sign In...');

      // Always sign out first to force account selection
      await _googleSignIn.signOut();

      // Start Google Sign In flow - this will show account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      print('📱 Google User: ${googleUser?.email}');

      if (googleUser == null) {
        // User cancelled the sign in
        print('❌ User cancelled Google Sign In');
        return null;
      }

      // Get Google authentication
      print('🔑 Getting Google authentication...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Get access token and id token
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      print('🎫 Access Token exists: ${accessToken != null}');
      print('🆔 ID Token exists: ${idToken != null}');

      if (accessToken == null || idToken == null) {
        print('❌ Missing tokens - Access: $accessToken, ID: $idToken');

        // Try to refresh tokens
        print('🔄 Attempting to refresh tokens...');
        await googleUser.clearAuthCache();
        final refreshedAuth = await googleUser.authentication;

        final newAccessToken = refreshedAuth.accessToken;
        final newIdToken = refreshedAuth.idToken;

        print('🔄 After refresh - Access Token exists: ${newAccessToken != null}');
        print('🔄 After refresh - ID Token exists: ${newIdToken != null}');

        if (newAccessToken == null || newIdToken == null) {
          throw Exception('Failed to get Google tokens after refresh - Access Token: ${newAccessToken != null}, ID Token: ${newIdToken != null}');
        }

        // Use refreshed tokens
        final accessTokenToUse = newAccessToken;
        final idTokenToUse = newIdToken;

        print('✅ Using refreshed tokens');

        // Sign in to Supabase with refreshed tokens
        final response = await _client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idTokenToUse!,
          accessToken: accessTokenToUse!,
        );

        return await _processGoogleSignInResponse(response, googleUser);
      }

      print('✅ Tokens received successfully');
      print('🔗 Signing in to Supabase...');

      // Sign in to Supabase with Google tokens
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken!,
        accessToken: accessToken!,
      );

      return await _processGoogleSignInResponse(response, googleUser);
    } catch (e) {
      print('💥 Detailed Google Sign In error: $e');
      print('📍 Error type: ${e.runtimeType}');
      if (e is Exception) {
        print('🔍 Exception details: ${e.toString()}');
      }
      throw Exception('Google Sign In failed: $e');
    }
  }

  // Google Sign In with Account Selection
  static Future<AuthResponse?> signInWithGoogleAccountPicker() async {
    try {
      print('🔍 Starting Google Sign In with Account Picker...');

      // Disconnect completely to force account selection
      await _googleSignIn.disconnect();

      // Start fresh Google Sign In flow - this will show account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      print('📱 Selected Google User: ${googleUser?.email}');

      if (googleUser == null) {
        print('❌ User cancelled Google Sign In');
        return null;
      }

      // Continue with normal flow
      return await _processGoogleAuthentication(googleUser);
    } catch (e) {
      print('💥 Google Account Picker error: $e');
      throw Exception('Google Account Selection failed: $e');
    }
  }

  // Helper method for Google authentication process
  static Future<AuthResponse> _processGoogleAuthentication(GoogleSignInAccount googleUser) async {
    // Get Google authentication
    print('🔑 Getting Google authentication...');
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Get access token and id token
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    print('🎫 Access Token exists: ${accessToken != null}');
    print('🆔 ID Token exists: ${idToken != null}');

    if (accessToken == null || idToken == null) {
      throw Exception('Failed to get Google tokens');
    }

    print('✅ Tokens received successfully');
    print('🔗 Signing in to Supabase...');

    // Sign in to Supabase with Google tokens
    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken!,
      accessToken: accessToken!,
    );

    return await _processGoogleSignInResponse(response, googleUser);
  }
  static Future<AuthResponse> _processGoogleSignInResponse(
      AuthResponse response,
      GoogleSignInAccount googleUser
      ) async {
    print('📊 Supabase response: ${response.user?.email}');

    if (response.user != null) {
      // Extract user information from Google
      final user = response.user!;
      final email = user.email ?? googleUser.email;
      final displayName = user.userMetadata?['full_name'] ??
          user.userMetadata?['name'] ??
          googleUser.displayName ??
          'User';

      print('👤 Creating user profile for: $email');

      // Generate username from email
      String username = email.split('@')[0];

      // Check if username already exists and make it unique if needed
      int counter = 1;
      String originalUsername = username;
      while (!(await isUsernameAvailable(username))) {
        username = '${originalUsername}_$counter';
        counter++;
      }

      print('📝 Username generated: $username');

      // Create or update user profile
      await createOrUpdateUser(
        userId: user.id,
        email: email,
        fullName: displayName,
        username: username,
        phone: '', // Google doesn't provide phone by default
      );

      print('✅ User profile created/updated successfully');
    }

    return response;
  }

  // Sign out from Google
  static Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error signing out from Google: $e');
    }
  }

  // Regular sign up
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
      // Sign out from Google first
      await signOutFromGoogle();
      // Then sign out from Supabase
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