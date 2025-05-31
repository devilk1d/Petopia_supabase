import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_config.dart';
import '../services/auth_service.dart';
import 'dart:convert';

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
                  images
                ),
                sellers: seller_id (
                  store_name,
                  store_image_url
                )
              ),
              payment_methods (
                name
              )
            ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Convert to JSON string first, then parse back to ensure proper typing
      final jsonString = jsonEncode(response);
      final List<dynamic> parsedData = jsonDecode(jsonString);

      return parsedData.map<Map<String, dynamic>>((item) {
        final Map<String, dynamic> order = Map<String, dynamic>.from(item);

        // Safely extract order items
        final List<dynamic> orderItemsRaw = order['order_items'] ?? [];
        final List<Map<String, dynamic>> orderItems = orderItemsRaw
            .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
            .toList();

        // Get first item safely
        Map<String, dynamic> firstItem = {};
        Map<String, dynamic> product = {};
        Map<String, dynamic> seller = {};

        if (orderItems.isNotEmpty) {
          firstItem = orderItems.first;
          product = Map<String, dynamic>.from(firstItem['products'] ?? {});
          seller = Map<String, dynamic>.from(firstItem['sellers'] ?? {});
        }

        final Map<String, dynamic> paymentMethod = Map<String, dynamic>.from(order['payment_methods'] ?? {});

        // Get product image
        String productImage = 'assets/images/placeholder.png';
        final images = product['images'];
        if (images is List && images.isNotEmpty) {
          productImage = images[0]?.toString() ?? productImage;
        }

        // Parse date safely
        DateTime orderDate = DateTime.now();
        try {
          if (order['created_at'] != null) {
            orderDate = DateTime.parse(order['created_at'].toString()).toLocal();
          }
        } catch (e) {
          print('Error parsing date: $e');
        }

        // Convert price safely
        double price = 0.0;
        try {
          final priceValue = firstItem['price'];
          if (priceValue != null) {
            price = double.parse(priceValue.toString());
          }
        } catch (e) {
          print('Error parsing price: $e');
        }

        // Convert total amount safely
        double totalAmount = 0.0;
        try {
          final totalValue = order['total_amount'];
          if (totalValue != null) {
            totalAmount = double.parse(totalValue.toString());
          }
        } catch (e) {
          print('Error parsing total amount: $e');
        }

        return <String, dynamic>{
          'id': order['id']?.toString() ?? '',
          'invoiceNumber': order['order_number']?.toString() ?? 'N/A',
          'storeName': seller['store_name']?.toString() ?? 'Petopia Store',
          'storeImage': seller['store_image_url']?.toString() ?? 'assets/images/icons/store.png',
          'productName': product['name']?.toString() ?? 'Multiple Products',
          'productImage': productImage,
          'quantity': '${orderItems.length} barang',
          'price': price,
          'date': orderDate,
          'status': _mapOrderStatus(order['status']?.toString(), order['payment_status']?.toString()),
          'totalAmount': totalAmount,
          'paymentMethod': paymentMethod['name']?.toString() ?? 'Unknown',
        };
      }).toList();
    } catch (e) {
      print('Error fetching transactions: $e');
      return <Map<String, dynamic>>[];
    }
  }

  // Get transactions filtered by status
  static Future<List<Map<String, dynamic>>> getTransactionsByStatus(String status) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) throw Exception('User not logged in');

      var query = _client
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
                images
              ),
              sellers: seller_id (
                store_name,
                store_image_url
              )
            ),
            payment_methods (
              name
            )
          ''')
          .eq('user_id', userId);

      // Add status filter
      switch (status.toUpperCase()) {
        case 'PENDING':
          query = query.eq('status', 'pending_payment');
          break;
        case 'ONGOING':
          query = query.neq('status', 'delivered').neq('status', 'pending_payment');
          break;
        case 'COMPLETED':
          query = query.eq('status', 'delivered');
          break;
        case 'FAILED':
          query = query.eq('payment_status', 'failed');
          break;
      }

      final response = await query.order('created_at', ascending: false);

      // Convert to JSON string first, then parse back
      final jsonString = jsonEncode(response);
      final List<dynamic> parsedData = jsonDecode(jsonString);

      List<Map<String, dynamic>> orders = parsedData
          .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
          .toList();

      // Additional filtering for ONGOING status
      if (status.toUpperCase() == 'ONGOING') {
        orders = orders.where((order) {
          final orderStatus = order['status']?.toString() ?? '';
          final paymentStatus = order['payment_status']?.toString() ?? '';
          return paymentStatus == 'paid' &&
              ['processing', 'waiting_shipment', 'shipped'].contains(orderStatus);
        }).toList();
      }

      return orders.map<Map<String, dynamic>>((order) {
        // Safely extract order items
        final List<dynamic> orderItemsRaw = order['order_items'] ?? [];
        final List<Map<String, dynamic>> orderItems = orderItemsRaw
            .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
            .toList();

        // Get first item safely
        Map<String, dynamic> firstItem = {};
        Map<String, dynamic> product = {};
        Map<String, dynamic> seller = {};

        if (orderItems.isNotEmpty) {
          firstItem = orderItems.first;
          product = Map<String, dynamic>.from(firstItem['products'] ?? {});
          seller = Map<String, dynamic>.from(firstItem['sellers'] ?? {});
        }

        final Map<String, dynamic> paymentMethod = Map<String, dynamic>.from(order['payment_methods'] ?? {});

        // Get product image
        String productImage = 'assets/images/placeholder.png';
        final images = product['images'];
        if (images is List && images.isNotEmpty) {
          productImage = images[0]?.toString() ?? productImage;
        }

        // Parse date safely
        DateTime orderDate = DateTime.now();
        try {
          if (order['created_at'] != null) {
            orderDate = DateTime.parse(order['created_at'].toString()).toLocal();
          }
        } catch (e) {
          print('Error parsing date: $e');
        }

        // Convert price safely
        double price = 0.0;
        try {
          final priceValue = firstItem['price'];
          if (priceValue != null) {
            price = double.parse(priceValue.toString());
          }
        } catch (e) {
          print('Error parsing price: $e');
        }

        // Convert total amount safely
        double totalAmount = 0.0;
        try {
          final totalValue = order['total_amount'];
          if (totalValue != null) {
            totalAmount = double.parse(totalValue.toString());
          }
        } catch (e) {
          print('Error parsing total amount: $e');
        }

        return <String, dynamic>{
          'id': order['id']?.toString() ?? '',
          'invoiceNumber': order['order_number']?.toString() ?? 'N/A',
          'storeName': seller['store_name']?.toString() ?? 'Petopia Store',
          'storeImage': seller['store_image_url']?.toString() ?? 'assets/images/icons/store.png',
          'productName': product['name']?.toString() ?? 'Multiple Products',
          'productImage': productImage,
          'quantity': '${orderItems.length} barang',
          'price': price,
          'date': orderDate,
          'status': _mapOrderStatus(order['status']?.toString(), order['payment_status']?.toString()),
          'totalAmount': totalAmount,
          'paymentMethod': paymentMethod['name']?.toString() ?? 'Unknown',
        };
      }).toList();
    } catch (e) {
      print('Error fetching transactions by status: $e');
      return <Map<String, dynamic>>[];
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
                images
              ),
              sellers: seller_id (
                store_name,
                store_image_url
              )
            ),
            payment_methods (
              name
            )
          ''')
          .eq('user_id', userId)
          .or('order_number.ilike.%${query}%')
          .order('created_at', ascending: false);

      // Convert to JSON string first, then parse back
      final jsonString = jsonEncode(response);
      final List<dynamic> parsedData = jsonDecode(jsonString);

      return parsedData.map<Map<String, dynamic>>((item) {
        final Map<String, dynamic> order = Map<String, dynamic>.from(item);

        // Safely extract order items
        final List<dynamic> orderItemsRaw = order['order_items'] ?? [];
        final List<Map<String, dynamic>> orderItems = orderItemsRaw
            .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
            .toList();

        // Get first item safely
        Map<String, dynamic> firstItem = {};
        Map<String, dynamic> product = {};
        Map<String, dynamic> seller = {};

        if (orderItems.isNotEmpty) {
          firstItem = orderItems.first;
          product = Map<String, dynamic>.from(firstItem['products'] ?? {});
          seller = Map<String, dynamic>.from(firstItem['sellers'] ?? {});
        }

        final Map<String, dynamic> paymentMethod = Map<String, dynamic>.from(order['payment_methods'] ?? {});

        // Get product image
        String productImage = 'assets/images/placeholder.png';
        final images = product['images'];
        if (images is List && images.isNotEmpty) {
          productImage = images[0]?.toString() ?? productImage;
        }

        // Parse date safely
        DateTime orderDate = DateTime.now();
        try {
          if (order['created_at'] != null) {
            orderDate = DateTime.parse(order['created_at'].toString()).toLocal();
          }
        } catch (e) {
          print('Error parsing date: $e');
        }

        // Convert price safely
        double price = 0.0;
        try {
          final priceValue = firstItem['price'];
          if (priceValue != null) {
            price = double.parse(priceValue.toString());
          }
        } catch (e) {
          print('Error parsing price: $e');
        }

        // Convert total amount safely
        double totalAmount = 0.0;
        try {
          final totalValue = order['total_amount'];
          if (totalValue != null) {
            totalAmount = double.parse(totalValue.toString());
          }
        } catch (e) {
          print('Error parsing total amount: $e');
        }

        return <String, dynamic>{
          'id': order['id']?.toString() ?? '',
          'invoiceNumber': order['order_number']?.toString() ?? 'N/A',
          'storeName': seller['store_name']?.toString() ?? 'Petopia Store',
          'storeImage': seller['store_image_url']?.toString() ?? 'assets/images/icons/store.png',
          'productName': product['name']?.toString() ?? 'Multiple Products',
          'productImage': productImage,
          'quantity': '${orderItems.length} barang',
          'price': price,
          'date': orderDate,
          'status': _mapOrderStatus(order['status']?.toString(), order['payment_status']?.toString()),
          'totalAmount': totalAmount,
          'paymentMethod': paymentMethod['name']?.toString() ?? 'Unknown',
        };
      }).toList();
    } catch (e) {
      print('Error searching transactions: $e');
      return <Map<String, dynamic>>[];
    }
  }

  // Map order status for display
  static String _mapOrderStatus(String? orderStatus, String? paymentStatus) {
    if (paymentStatus == 'pending') {
      return 'PENDING';
    } else if (paymentStatus == 'failed') {
      return 'FAILED';
    } else if (orderStatus == 'delivered') {
      return 'COMPLETED';
    } else if (orderStatus == 'pending_payment') {
      return 'PENDING';
    } else {
      return 'ONGOING';
    }
  }
}