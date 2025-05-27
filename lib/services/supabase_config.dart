import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://sgludiqvcolzgktealyh.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNnbHVkaXF2Y29semdrdGVhbHloIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxMzU2NjksImV4cCI6MjA2MzcxMTY2OX0.CBR-gHwI_53SyQh04bDfkyZaPvYXWRCfKPALSTVjULI';

  static late final SupabaseClient _client;

  static SupabaseClient get client => _client;

  static Future<void> initialize() async {
    try {
      print('\nInitializing Supabase...');
      
      // Initialize Supabase client
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        storageOptions: const StorageClientOptions(
          retryAttempts: 3,
        ),
        debug: true  // Enable debug mode for better error logging
      );
      
      _client = Supabase.instance.client;
      print('Supabase client initialized successfully');

      // Test storage access
      try {
        print('\nTesting storage access...');
        final buckets = await _client.storage.listBuckets();
        print('Available storage buckets: ${buckets.map((b) => b.name).toList()}');
        
        // Verify product_images bucket exists
        final productBucket = buckets.where((b) => b.name == 'product_images').firstOrNull;
        if (productBucket == null) {
          print('WARNING: product_images bucket not found!');
        } else {
          print('product_images bucket found and accessible');
        }
      } catch (storageError) {
        print('Error testing storage access:');
        print('- Error type: ${storageError.runtimeType}');
        print('- Error message: $storageError');
      }

      print('\nSupabase initialization completed');
    } catch (e) {
      print('Error initializing Supabase:');
      print('- Error type: ${e.runtimeType}');
      print('- Error message: $e');
      rethrow;
    }
  }

  static GoTrueClient get auth => Supabase.instance.client.auth;
}