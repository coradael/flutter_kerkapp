import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserTenantService {
  final _supabase = Supabase.instance.client;

  // Get all members of a tenant with their profile info
  Future<List<Map<String, dynamic>>> getTenantMembers(String tenantId) async {
    try {
      final response = await _supabase
          .from('user_tenants')
          .select('''
            *,
            profiles:user_id (
              id,
              email,
              full_name,
              phone_number,
              avatar_url,
              role
            )
          ''')
          .eq('tenant_id', tenantId);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('❌ Error getting tenant members: $e');
      return [];
    }
  }

  // Get user's role in a tenant
  Future<String?> getUserRoleInTenant(String userId, String tenantId) async {
    try {
      final response = await _supabase
          .from('user_tenants')
          .select('role')
          .eq('user_id', userId)
          .eq('tenant_id', tenantId)
          .maybeSingle();

      return response?['role'] as String?;
    } catch (e) {
      debugPrint('❌ Error getting user role: $e');
      return null;
    }
  }

  // Check if user is admin in tenant
  Future<bool> isUserAdmin(String userId, String tenantId) async {
    final role = await getUserRoleInTenant(userId, tenantId);
    return role?.toLowerCase() == 'admin';
  }

  // Update user role (admin only)
  Future<bool> updateUserRole(String userId, String tenantId, String newRole) async {
    try {
      await _supabase
          .from('user_tenants')
          .update({'role': newRole})
          .eq('user_id', userId)
          .eq('tenant_id', tenantId);
      return true;
    } catch (e) {
      debugPrint('❌ Error updating user role: $e');
      return false;
    }
  }

  // Remove user from tenant (admin only)
  Future<bool> removeUserFromTenant(String userId, String tenantId) async {
    try {
      await _supabase
          .from('user_tenants')
          .delete()
          .eq('user_id', userId)
          .eq('tenant_id', tenantId);
      return true;
    } catch (e) {
      debugPrint('❌ Error removing user from tenant: $e');
      return false;
    }
  }

  // Toggle user active status (admin only)
  Future<bool> toggleUserActiveStatus(String userId, String tenantId, bool isActive) async {
    try {
      await _supabase
          .from('user_tenants')
          .update({'is_active': isActive})
          .eq('user_id', userId)
          .eq('tenant_id', tenantId);
      return true;
    } catch (e) {
      debugPrint('❌ Error toggling user active status: $e');
      return false;
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      debugPrint('❌ Error sending password reset email: $e');
      return false;
    }
  }
}
