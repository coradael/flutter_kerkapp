import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import 'profile_model.dart';

class ProfileService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get profile by user ID
  Future<Profile?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return Profile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Update profile
  Future<bool> updateProfile(Profile profile) async {
    try {
      await _supabase
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Create profile
  Future<bool> createProfile(Profile profile) async {
    try {
      await _supabase.from('profiles').insert(profile.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }
}
