import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import 'tenant_model.dart';

class TenantService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get all tenants for current user
  Future<List<Tenant>> getUserTenants(String userId) async {
    try {
      final response = await _supabase
          .from('user_tenants')
          .select('tenant_id, tenants(*)')
          .eq('user_id', userId);

      return (response as List)
          .map((item) => Tenant.fromJson(item['tenants'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get tenant by ID
  Future<Tenant?> getTenant(String tenantId) async {
    try {
      final response = await _supabase
          .from('tenants')
          .select()
          .eq('id', tenantId)
          .single();

      return Tenant.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
