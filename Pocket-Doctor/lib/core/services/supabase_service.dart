import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static const String _defaultUrl = 'https://woimsjvxbocisrdxgzls.supabase.co';
  static const String _defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndvaW1zanZ4Ym9jaXNyZHhnemxzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYwMDQyNDgsImV4cCI6MjEwMTU4MDI0OH0.hatKhslHoIQjOheAo5_kV2s8A1EK5qY-HGp6NpjKplI';

  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'] ?? _defaultUrl;
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? _defaultAnonKey;

    try {
      await Supabase.initialize(
        url: url.isNotEmpty ? url : _defaultUrl,
        anonKey: anonKey.isNotEmpty ? anonKey : _defaultAnonKey,
        debug: kDebugMode,
      );
      debugPrint('Supabase initialized successfully for Pocket Doctor: $url');
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
    }
  }
}
