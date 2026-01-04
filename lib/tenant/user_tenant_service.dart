import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserTenantService {
  final _supabase = Supabase.instance.client;

  // Get all members of a tenant with their profile info
  Future<List<Map<String, dynamic>>> getTenantMembers(String tenantId) async {
    try {
      // First get all user_tenants for this tenant
      final userTenantsResponse = await _supabase
          .from('user_tenants')
          .select('*')
          .eq('tenant_id', tenantId);
      
      // Then get profiles for each user
      final List<Map<String, dynamic>> membersWithProfiles = [];
      
      for (final userTenant in userTenantsResponse) {
        final userId = userTenant['user_id'];
        final email = userTenant['email'];
        
        debugPrint('🔍 Querying profile for user: $userId');
        
        final profileResponse = await _supabase
            .from('profiles')
            .select('id, email, full_name, phone_number, avatar_url, role')
            .eq('id', userId)
            .maybeSingle();
        
        debugPrint('📦 Profile response: $profileResponse');
        
        if (profileResponse != null) {
          membersWithProfiles.add({
            ...userTenant,
            'profiles': profileResponse,
          });
        } else {
          // User has no profile yet, show with email from user_tenants
          membersWithProfiles.add({
            ...userTenant,
            'profiles': {
              'id': userId,
              'email': email,
              'full_name': null, // Will show email instead
              'phone_number': null,
              'avatar_url': null,
              'role': null,
            },
          });
        }
      }
      
      return membersWithProfiles;
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

  // Get all tenants for a user
  Future<List<Map<String, dynamic>>> getUserTenants(String userId) async {
    try {
      final response = await _supabase
          .from('user_tenants')
          .select('''
            *,
            tenants:tenant_id (
              id,
              name
            )
          ''')
          .eq('user_id', userId);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('❌ Error getting user tenants: $e');
      return [];
    }
  }
}
