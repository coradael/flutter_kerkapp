import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class EventStorageService {
  final _supabase = Supabase.instance.client;
  final String bucketName = 'event-files';

  // Upload image
  Future<String?> uploadImage(XFile file, String userId) async {
    try {
      final bytes = await file.readAsBytes();
      final fileExt = file.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      await _supabase.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: false,
            ),
          );

      return filePath;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      return null;
    }
  }

  // Upload document
  Future<String?> uploadDocument(PlatformFile file, String userId) async {
    try {
      final bytes = file.bytes;
      if (bytes == null) return null;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final filePath = '$userId/$fileName';

      await _supabase.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(file.extension ?? ''),
              upsert: false,
            ),
          );

      return filePath;
    } catch (e) {
      debugPrint('❌ Error uploading document: $e');
      return null;
    }
  }

  // Get public URL for file
  String? getFileUrl(String filePath) {
    try {
      return _supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);
    } catch (e) {
      debugPrint('❌ Error getting file URL: $e');
      return null;
    }
  }

  // Delete file
  Future<bool> deleteFile(String filePath) async {
    try {
      await _supabase.storage
          .from(bucketName)
          .remove([filePath]);

      return true;
    } catch (e) {
      debugPrint('❌ Error deleting file: $e');
      return false;
    }
  }

  // Determine file type based on extension
  String getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return 'image';
    } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
      return 'video';
    } else {
      return 'document';
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
