import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../core/config/supabase_config.dart';

class StorageService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  static const String avatarsBucket = 'avatars';

  // Upload avatar - works on both web and mobile (following React Native pattern)
  Future<String?> uploadAvatar(String userId, XFile file) async {
    try {
      print('📁 Starting file upload for user: $userId');
      print('📁 File path: ${file.path}');
      print('📁 Platform: ${kIsWeb ? "Web" : "Mobile"}');
      
      // Get file extension
      final fileExt = file.path.split('.').last.split('?').first.toLowerCase();
      print('📁 File extension: $fileExt');
      
      // Create unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$userId/$timestamp.$fileExt';

      print('📁 Target path: $filePath');
      print('📁 Uploading to bucket: $avatarsBucket');

      // Read bytes from file (works on both web and mobile)
      final bytes = await file.readAsBytes();
      print('📁 File size: ${bytes.length} bytes');

      // Upload to Supabase Storage
      final uploadResponse = await _supabase.storage
          .from(avatarsBucket)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _getContentType(fileExt),
            ),
          );

      print('✅ File uploaded successfully');
      
      // Get public URL
      final publicUrl = _supabase.storage
          .from(avatarsBucket)
          .getPublicUrl(filePath);
      
      print('🔗 Public URL: $publicUrl');
      
      return publicUrl;
    } catch (e, stackTrace) {
      print('❌ Storage upload error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Get correct content type for image
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  // Delete avatar
  Future<bool> deleteAvatar(String userId) async {
    try {
      // List all files for this user
      final files = await _supabase.storage
          .from(avatarsBucket)
          .list(path: userId);
      
      // Delete all files
      if (files.isNotEmpty) {
        final filePaths = files.map((file) => '$userId/${file.name}').toList();
        await _supabase.storage
            .from(avatarsBucket)
            .remove(filePaths);
      }
      
      return true;
    } catch (e) {
      print('❌ Delete error: $e');
      return false;
    }
  }

  // Get avatar URL
  String? getAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    return avatarUrl;
  }
}
