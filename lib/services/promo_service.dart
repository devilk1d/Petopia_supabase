// lib/services/promo_service.dart
import '../models/promo_model.dart';
import 'supabase_config.dart';
import 'auth_service.dart';

class PromoService {
  static final _client = SupabaseConfig.client;

  static final List<PromoModel> _defaultPromos = [
    PromoModel(
      id: '1',
      code: 'WELCOME',
      title: 'Welcome Discount',
      description: 'Get 20% off on your first purchase',
      discountType: 'percentage',
      discountValue: 20,
      minPurchase: 50000,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      isActive: true,
      createdAt: DateTime.now(),
    ),
    PromoModel(
      id: '2',
      code: 'PETFOOD',
      title: 'Pet Food Sale',
      description: 'Save big on premium pet food',
      discountType: 'percentage',
      discountValue: 15,
      minPurchase: 100000,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 14)),
      isActive: true,
      createdAt: DateTime.now(),
    ),
  ];

  // Get all active promos
  static Future<List<PromoModel>> getActivePromos() async {
    try {
      final response = await _client
          .from('promos')
          .select()
          .eq('is_active', true)
          .gte('end_date', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      if (response == null || (response as List).isEmpty) {
        print('Using default promos');
        return _defaultPromos;
      }

      return (response as List)
          .map((json) => PromoModel.fromJson(json))
          .toList();
    } catch (e) {
      print('PromoService error: $e');
      print('Using default promos due to error');
      return _defaultPromos;
    }
  }

  // Validate promo code
  static Future<PromoModel?> validatePromoCode(String code, double totalAmount) async {
    try {
      final response = await _client
          .from('promos')
          .select()
          .eq('code', code.toUpperCase())
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      final promo = PromoModel.fromJson(response);

      // Check if promo is valid
      if (!promo.isActive) return null;
      if (totalAmount < promo.minPurchase) return null;
      if (promo.endDate != null && DateTime.now().isAfter(promo.endDate!)) return null;
      if (promo.usageLimit != null && promo.usedCount >= promo.usageLimit!) return null;

      return promo;
    } catch (e) {
      return null;
    }
  }

  // Apply promo code and get discount amount
  static Future<double> applyPromoCode(String code, double totalAmount) async {
    final promo = await validatePromoCode(code, totalAmount);
    if (promo == null) return 0;

    return promo.calculateDiscount(totalAmount);
  }

  // Use promo code (increment used count)
  static Future<void> usePromoCode(String promoId) async {
    try {
      await _client
          .rpc('increment_promo_usage', params: {'promo_id': promoId});
    } catch (e) {
      throw Exception('Failed to use promo code: $e');
    }
  }

  // Create promo (for sellers and admins)
  static Future<PromoModel> createPromo({
    required String code,
    required String title,
    String? description,
    required String discountType,
    required double discountValue,
    double minPurchase = 0,
    double? maxDiscount,
    int? usageLimit,
    DateTime? endDate,
    String? sellerId, // null for admin promos
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final promoData = {
        'code': code.toUpperCase(),
        'title': title,
        'description': description,
        'discount_type': discountType,
        'discount_value': discountValue,
        'min_purchase': minPurchase,
        'max_discount': maxDiscount,
        'usage_limit': usageLimit,
        'end_date': endDate?.toIso8601String(),
        if (sellerId != null) 'seller_id': sellerId,
        if (sellerId == null) 'admin_id': userId, // Assume admin if no seller_id
      };

      final response = await _client
          .from('promos')
          .insert(promoData)
          .select()
          .single();

      return PromoModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create promo: $e');
    }
  }

  // Get promos by seller
  static Future<List<PromoModel>> getPromosBySeller(String sellerId) async {
    try {
      final response = await _client
          .from('promos')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PromoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch seller promos: $e');
    }
  }

  // Update promo
  static Future<PromoModel> updatePromo(PromoModel promo) async {
    try {
      final response = await _client
          .from('promos')
          .update({
        'title': promo.title,
        'description': promo.description,
        'discount_type': promo.discountType,
        'discount_value': promo.discountValue,
        'min_purchase': promo.minPurchase,
        'max_discount': promo.maxDiscount,
        'usage_limit': promo.usageLimit,
        'end_date': promo.endDate?.toIso8601String(),
        'is_active': promo.isActive,
      })
          .eq('id', promo.id)
          .select()
          .single();

      return PromoModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update promo: $e');
    }
  }

  // Delete promo (set inactive)
  static Future<void> deletePromo(String promoId) async {
    try {
      await _client
          .from('promos')
          .update({'is_active': false})
          .eq('id', promoId);
    } catch (e) {
      throw Exception('Failed to delete promo: $e');
    }
  }
}