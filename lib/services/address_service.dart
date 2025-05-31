// lib/services/address_service.dart
import 'supabase_config.dart';
import 'auth_service.dart';
import '../models/address_model.dart';

class AddressService {
  static final _client = SupabaseConfig.client;

  // Get all user addresses
  static Future<List<AddressModel>> getUserAddresses() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await _client
          .from('user_addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AddressModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch addresses: $e');
    }
  }

  // Add new address
  static Future<AddressModel> addAddress(AddressModel address) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      // If this is set as default, update other addresses
      if (address.isDefault) {
        await _client
            .from('user_addresses')
            .update({'is_default': false})
            .eq('user_id', userId);
      }

      final response = await _client
          .from('user_addresses')
          .insert({
        'user_id': userId,
        'label': address.label,
        'recipient_name': address.recipientName,
        'phone': address.phone,
        'address': address.address,
        'city': address.city,
        'postal_code': address.postalCode,
        'latitude': address.latitude,
        'longitude': address.longitude,
        'is_default': address.isDefault,
      })
          .select()
          .single();

      return AddressModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add address: $e');
    }
  }

  // Update address
  static Future<AddressModel> updateAddress(AddressModel address) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      // If this is set as default, update other addresses
      if (address.isDefault) {
        await _client
            .from('user_addresses')
            .update({'is_default': false})
            .eq('user_id', userId)
            .neq('id', address.id);
      }

      final response = await _client
          .from('user_addresses')
          .update({
        'label': address.label,
        'recipient_name': address.recipientName,
        'phone': address.phone,
        'address': address.address,
        'city': address.city,
        'postal_code': address.postalCode,
        'latitude': address.latitude,
        'longitude': address.longitude,
        'is_default': address.isDefault,
      })
          .eq('id', address.id)
          .eq('user_id', userId)
          .select()
          .single();

      return AddressModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  // Delete address
  static Future<void> deleteAddress(String addressId) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      await _client
          .from('user_addresses')
          .delete()
          .eq('id', addressId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  // Set default address
  static Future<void> setDefaultAddress(String addressId) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      // Remove default from all addresses
      await _client
          .from('user_addresses')
          .update({'is_default': false})
          .eq('user_id', userId);

      // Set new default
      await _client
          .from('user_addresses')
          .update({'is_default': true})
          .eq('id', addressId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to set default address: $e');
    }
  }

  // Get default address
  static Future<AddressModel?> getDefaultAddress() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) return null;

      final response = await _client
          .from('user_addresses')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      if (response == null) return null;
      return AddressModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}