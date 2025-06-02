// lib/services/checkout_service.dart
import 'supabase_config.dart';
import 'auth_service.dart';
import '../models/address_model.dart';
import '../services/promo_service.dart';

class CheckoutService {
  static final _client = SupabaseConfig.client;

  // Get payment methods - NO AUTH REQUIRED
  static Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      print('Fetching payment methods...');

      final response = await _client
          .from('payment_methods')
          .select()
          .eq('is_active', true)
          .order('name');

      print('Payment methods response: ${response?.length ?? 0} items');

      if (response == null || (response as List).isEmpty) {
        print('No payment methods found, returning defaults');
        return _getDefaultPaymentMethods();
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching payment methods: $e');
      return _getDefaultPaymentMethods();
    }
  }

  // Default payment methods as fallback
  static List<Map<String, dynamic>> _getDefaultPaymentMethods() {
    return [
      {
        'id': '1',
        'name': 'BCA Virtual Account',
        'type': 'bank',
        'logo_url': 'assets/images/icons/bca.png',
        'is_active': true,
      },
      {
        'id': '2',
        'name': 'Mandiri Virtual Account',
        'type': 'bank',
        'logo_url': 'assets/images/icons/mandiri.png',
        'is_active': true,
      },
      {
        'id': '3',
        'name': 'BRI Virtual Account',
        'type': 'bank',
        'logo_url': 'assets/images/icons/bri.png',
        'is_active': true,
      },
      {
        'id': '4',
        'name': 'Alfamart / Alfamidi',
        'type': 'retail',
        'logo_url': 'assets/images/icons/alfa.png',
        'is_active': true,
      },
    ];
  }

  // Get default shipping address - AUTH REQUIRED
  static Future<Map<String, dynamic>?> getDefaultShippingAddress(String userId) async {
    try {
      print('Getting default shipping address for user: $userId');

      final response = await _client
          .rpc('get_default_shipping_address', params: {'p_user_id': userId});

      if (response != null) {
        print('Default shipping address found');
        return response as Map<String, dynamic>;
      } else {
        print('No default shipping address found');
        return null;
      }
    } catch (e) {
      print('Error getting default shipping address: $e');
      return null;
    }
  }

  // Get shipping methods - NO AUTH REQUIRED
  static Future<List<Map<String, dynamic>>> getShippingMethods() async {
    try {
      print('Fetching shipping methods...');

      final response = await _client
          .from('shipping_methods')
          .select()
          .eq('is_active', true)
          .order('name');

      print('Shipping methods response: ${response?.length ?? 0} items');

      if (response == null || (response as List).isEmpty) {
        print('No shipping methods found, returning defaults');
        return _getDefaultShippingMethods();
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching shipping methods: $e');
      return _getDefaultShippingMethods();
    }
  }

  // Default shipping methods as fallback
  static List<Map<String, dynamic>> _getDefaultShippingMethods() {
    return [
      {
        'id': '1',
        'name': 'JNE Regular',
        'type': 'standard',
        'logo_url': 'assets/images/kurir/jne.png',
        'base_cost': 11000,
        'is_active': true,
      },
      {
        'id': '2',
        'name': 'JNE YES',
        'type': 'express',
        'logo_url': 'assets/images/kurir/jne.png',
        'base_cost': 18000,
        'is_active': true,
      },
      {
        'id': '3',
        'name': 'SiCepat Regular',
        'type': 'standard',
        'logo_url': 'assets/images/kurir/sicepat.png',
        'base_cost': 10000,
        'is_active': true,
      },
      {
        'id': '4',
        'name': 'SiCepat BEST',
        'type': 'express',
        'logo_url': 'assets/images/kurir/sicepat.png',
        'base_cost': 17000,
        'is_active': true,
      },
      {
        'id': '5',
        'name': 'J&T Ekonomi',
        'type': 'economy',
        'logo_url': 'assets/images/kurir/jnt.png',
        'base_cost': 9000,
        'is_active': true,
      },
      {
        'id': '6',
        'name': 'J&T Express',
        'type': 'express',
        'logo_url': 'assets/images/kurir/jnt.png',
        'base_cost': 15000,
        'is_active': true,
      },
      {
        'id': '7',
        'name': 'AnterAja Regular',
        'type': 'standard',
        'logo_url': 'assets/images/kurir/anteraja.jpg',
        'base_cost': 10500,
        'is_active': true,
      },
      {
        'id': '8',
        'name': 'AnterAja Next Day',
        'type': 'express',
        'logo_url': 'assets/images/kurir/anteraja.jpg',
        'base_cost': 16500,
        'is_active': true,
      },
    ];
  }

  // Calculate shipping cost based on distance, weight, etc. - NO AUTH REQUIRED
  static Future<double> calculateShippingCost({
    required String shippingMethodId,
    required Map<String, dynamic> shippingAddress,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    try {
      print('Calculating shipping cost for method: $shippingMethodId');

      // Try to get base cost from shipping method
      double baseCost = 15000.0; // Default cost

      try {
        final response = await _client
            .from('shipping_methods')
            .select('base_cost')
            .eq('id', shippingMethodId)
            .maybeSingle();

        if (response != null) {
          baseCost = (response['base_cost'] as num).toDouble();
        } else {
          // Check default shipping methods
          final defaultMethods = _getDefaultShippingMethods();
          final method = defaultMethods.firstWhere(
                (m) => m['id'] == shippingMethodId,
            orElse: () => {'base_cost': 15000},
          );
          baseCost = (method['base_cost'] as num).toDouble();
        }
      } catch (e) {
        print('Error getting shipping method cost: $e');
      }

      // Calculate total weight and apply weight-based pricing
      double totalWeight = 0;
      for (var item in cartItems) {
        // Assume each item has a weight field or default weight
        double itemWeight = (item['weight'] as num?)?.toDouble() ?? 0.5; // Default 0.5kg
        int quantity = item['quantity'] as int? ?? 1;
        totalWeight += itemWeight * quantity;
      }

      // Additional cost per kg after first kg
      if (totalWeight > 1.0) {
        baseCost += (totalWeight - 1.0) * 2000; // Rp 2000 per additional kg
      }

      print('Calculated shipping cost: $baseCost');
      return baseCost;
    } catch (e) {
      print('Error calculating shipping cost: $e');
      // Return default shipping cost if calculation fails
      return 15000.0;
    }
  }

  // Apply promo code - NO AUTH REQUIRED (for validation)
  static Future<Map<String, dynamic>?> applyPromoCode(
      String promoCode,
      double subtotal,
      ) async {
    try {
      print('Applying promo code: $promoCode for subtotal: $subtotal');

      // Use PromoService to validate the promo code
      final promo = await PromoService.validatePromoCode(promoCode, subtotal);
      if (promo == null) {
        print('Promo code validation failed');
        return null;
      }

      // Calculate discount
      double discountAmount = promo.calculateDiscount(subtotal);

      print('Promo applied successfully, discount: $discountAmount');

      return {
        'promo_id': promo.id,
        'discount_amount': discountAmount,
        'promo_title': promo.title,
      };
    } catch (e) {
      print('Error applying promo code: $e');
      return null;
    }
  }

  // Get cities for dropdown (can be extended to use external API) - NO AUTH REQUIRED
  static Future<List<String>> getCities() async {
    // This can be replaced with a call to an external API for Indonesian cities
    return [
      'Jakarta Pusat', 'Jakarta Utara', 'Jakarta Selatan', 'Jakarta Timur', 'Jakarta Barat',
      'Bandung', 'Surabaya', 'Medan', 'Makassar', 'Semarang', 'Yogyakarta', 'Palembang',
      'Tangerang', 'Depok', 'Bekasi', 'Bogor', 'Malang', 'Solo', 'Balikpapan', 'Banjarmasin'
    ];
  }

  // Validate postal code format - NO AUTH REQUIRED
  static bool isValidPostalCode(String postalCode) {
    return RegExp(r'^\d{5}$').hasMatch(postalCode);
  }

  // Validate phone number format - NO AUTH REQUIRED
  static bool isValidPhoneNumber(String phone) {
    return RegExp(r'^08[0-9]{8,11}$').hasMatch(phone);
  }
}