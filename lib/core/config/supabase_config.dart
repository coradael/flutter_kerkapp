import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://jmuvtokmpzjotipsujqr.supabase.co';
  static const String supabaseAnonKey = 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImptdXZ0b2ttcHpqb3RpcHN1anFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1Nzg3MzEsImV4cCI6MjA3NDE1NDczMX0.uXX-WFGZxnw9faHJjILuorpjfySsjI-b-PAFqcGby1Q';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
