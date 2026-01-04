import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'post_model.dart';

class PostService {
  final _supabase = Supabase.instance.client;

  // Get all posts for a tenant
  Future<List<Post>> getTenantPosts(String tenantId) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('*')
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false);

      final List<Post> posts = [];
      
      for (final json in response as List) {
        final userId = json['user_id'] as String;
        
        // Get profile info separately
        final profileResponse = await _supabase
            .from('profiles')
            .select('full_name, avatar_url, email')
            .eq('id', userId)
            .maybeSingle();
        
        // Use full_name if available, otherwise use email
        String? userName = profileResponse?['full_name'] as String?;
        if (userName == null || userName.isEmpty) {
          userName = profileResponse?['email'] as String?;
        }
        
        // Get like count
        final likesResponse = await _supabase
            .from('post_likes')
            .select()
            .eq('post_id', json['id']);
        final likeCount = (likesResponse as List).length;
        
        // Get comment count
        final commentsResponse = await _supabase
            .from('post_comments')
            .select()
            .eq('post_id', json['id']);
        final commentCount = (commentsResponse as List).length;
        
        posts.add(Post.fromJson({
          ...json,
          'user_name': userName,
          'user_avatar': profileResponse?['avatar_url'],
          'like_count': likeCount,
          'comment_count': commentCount,
        }));
      }
      
      return posts;
    } catch (e) {
      debugPrint('❌ Error getting posts: $e');
      return [];
    }
  }

  // Create a new post
  Future<bool> createPost({
    required String tenantId,
    required String userId,
    required String content,
    XFile? image,
  }) async {
    try {
      String? imageUrl;

      // Upload image if provided
      if (image != null) {
        final bytes = await image.readAsBytes();
        final fileExt = image.path.split('.').last;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath = '$tenantId/$userId/$timestamp.$fileExt';

        await _supabase.storage
            .from('posts')
            .uploadBinary(filePath, bytes);

        imageUrl = _supabase.storage.from('posts').getPublicUrl(filePath);
      }

      await _supabase.from('posts').insert({
        'tenant_id': tenantId,
        'user_id': userId,
        'content': content,
        'image_url': imageUrl,
      });

      return true;
    } catch (e) {
      debugPrint('❌ Error creating post: $e');
      return false;
    }
  }

  // Delete a post
  Future<bool> deletePost(String postId, String? imageUrl) async {
    try {
      // Delete image from storage if exists
      if (imageUrl != null) {
        final uri = Uri.parse(imageUrl);
        final path = uri.pathSegments.skip(4).join('/');
        await _supabase.storage.from('posts').remove([path]);
      }

      await _supabase.from('posts').delete().eq('id', postId);
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting post: $e');
      return false;
    }
  }

  // Like a post
  Future<bool> likePost(String postId, String userId) async {
    try {
      await _supabase.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
      return true;
    } catch (e) {
      debugPrint('❌ Error liking post: $e');
      return false;
    }
  }

  // Unlike a post
  Future<bool> unlikePost(String postId, String userId) async {
    try {
      await _supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('❌ Error unliking post: $e');
      return false;
    }
  }

  // Check if user has liked a post
  Future<bool> hasUserLiked(String postId, String userId) async {
    try {
      final response = await _supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('❌ Error checking like: $e');
      return false;
    }
  }

  // Get comments for a post
  Future<List<Map<String, dynamic>>> getPostComments(String postId) async {
    try {
      final response = await _supabase
          .from('post_comments')
          .select('*')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      final List<Map<String, dynamic>> comments = [];
      
      for (final json in response as List) {
        final userId = json['user_id'] as String;
        
        // Get user info from profiles
        final profileResponse = await _supabase
            .from('profiles')
            .select('full_name, avatar_url, email')
            .eq('id', userId)
            .maybeSingle();
        
        // Use full_name if available, otherwise use email
        String? userName = profileResponse?['full_name'];
        if (userName == null || userName.isEmpty) {
          userName = profileResponse?['email'];
        }
        
        comments.add({
          ...json,
          'user_name': userName ?? 'Onbekend',
          'user_avatar': profileResponse?['avatar_url'],
        });
      }
      
      return comments;
    } catch (e) {
      debugPrint('❌ Error getting comments: $e');
      return [];
    }
  }

  // Add a comment
  Future<bool> addComment(String postId, String userId, String commentText) async {
    try {
      await _supabase.from('post_comments').insert({
        'post_id': postId,
        'user_id': userId,
        'comment_text': commentText,
      });
      return true;
    } catch (e) {
      debugPrint('❌ Error adding comment: $e');
      return false;
    }
  }

  // Delete a comment
  Future<bool> deleteComment(String commentId) async {
    try {
      await _supabase.from('post_comments').delete().eq('id', commentId);
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting comment: $e');
      return false;
    }
  }
}
