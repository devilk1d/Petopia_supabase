import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_config.dart';
import '../services/auth_service.dart';

class TransactionService {
  static final _client = SupabaseConfig.client;

  // Get all transactions for current user
  static Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await _client
          .from('orders')
          .select('''
            *,
            order_items (
              id,
              product_id,
              quantity,
              price,
              products (
                name,
                image_url
              )
            ),
            sellers (
              store_name,
              store_image
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((order) {
        final orderItems = order['order_items'] as List;
        final firstItem = orderItems.first;
        final product = firstItem['products'];
        final seller = order['sellers'];
        
        return {
          'id': order['id'],
          'invoiceNumber': order['invoice_number'],
          'storeName': seller['store_name'],
          'storeIcon': seller['store_image'],
          'productName': product['name'],
          'productImage': product['image_url'],
          'quantity': '${orderItems.length} barang',
          'price': firstItem['price'],
          'date': DateTime.parse(order['created_at']).toLocal(),
          'status': order['status'],
          'totalAmount': order['total_amount'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  // Get transactions filtered by status
  static Future<List<Map<String, dynamic>>> getTransactionsByStatus(String status) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await _client
          .from('orders')
          .select('''
            *,
            order_items (
              id,
              product_id,
              quantity,
              price,
              products (
                name,
                image_url
              )
            ),
            sellers (
              store_name,
              store_image
            )
          ''')
          .eq('user_id', userId)
          .eq('status', status)
          .order('created_at', ascending: false);

      return (response as List).map((order) {
        final orderItems = order['order_items'] as List;
        final firstItem = orderItems.first;
        final product = firstItem['products'];
        final seller = order['sellers'];
        
        return {
          'id': order['id'],
          'invoiceNumber': order['invoice_number'],
          'storeName': seller['store_name'],
          'storeIcon': seller['store_image'],
          'productName': product['name'],
          'productImage': product['image_url'],
          'quantity': '${orderItems.length} barang',
          'price': firstItem['price'],
          'date': DateTime.parse(order['created_at']).toLocal(),
          'status': order['status'],
          'totalAmount': order['total_amount'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching transactions by status: $e');
      return [];
    }
  }

  // Search transactions
  static Future<List<Map<String, dynamic>>> searchTransactions(String query) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await _client
          .from('orders')
          .select('''
            *,
            order_items (
              id,
              product_id,
              quantity,
              price,
              products (
                name,
                image_url
              )
            ),
            sellers (
              store_name,
              store_image
            )
          ''')
          .eq('user_id', userId)
          .or('invoice_number.ilike.%${query}%,sellers.store_name.ilike.%${query}%,order_items.products.name.ilike.%${query}%')
          .order('created_at', ascending: false);

      return (response as List).map((order) {
        final orderItems = order['order_items'] as List;
        final firstItem = orderItems.first;
        final product = firstItem['products'];
        final seller = order['sellers'];
        
        return {
          'id': order['id'],
          'invoiceNumber': order['invoice_number'],
          'storeName': seller['store_name'],
          'storeIcon': seller['store_image'],
          'productName': product['name'],
          'productImage': product['image_url'],
          'quantity': '${orderItems.length} barang',
          'price': firstItem['price'],
          'date': DateTime.parse(order['created_at']).toLocal(),
          'status': order['status'],
          'totalAmount': order['total_amount'],
        };
      }).toList();
    } catch (e) {
      print('Error searching transactions: $e');
      return [];
    }
  }
} 