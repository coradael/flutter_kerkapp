import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import 'event_comment_model.dart';

class EventCommentService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get comments for an event
  Future<List<EventComment>> getEventComments(String eventId) async {
    try {
      final response = await _supabase
          .from('event_comments')
          .select()
          .eq('event_id', eventId)
          .order('created_at', ascending: true);

      // Fetch user info for each comment
      final comments = <EventComment>[];
      for (final json in response as List) {
        final comment = EventComment.fromJson(json);
        
        // Get user profile
        try {
          final profile = await _supabase
              .from('profiles')
              .select('email, full_name')
              .eq('id', comment.userId)
              .maybeSingle();
          
          comments.add(EventComment(
            id: comment.id,
            eventId: comment.eventId,
            userId: comment.userId,
            commentText: comment.commentText,
            createdAt: comment.createdAt,
            updatedAt: comment.updatedAt,
            userEmail: profile?['email'],
            userName: profile?['full_name'] ?? profile?['email'] ?? 'Gebruiker',
          ));
        } catch (e) {
          // If profile fetch fails, add comment without user info
          comments.add(comment);
        }
      }
      
      return comments;
    } catch (e) {
      debugPrint('Error getting comments: $e');
      return [];
    }
  }

  // Add comment
  Future<bool> addComment(EventComment comment) async {
    try {
      await _supabase.from('event_comments').insert(comment.toJson());
      return true;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return false;
    }
  }

  // Update comment
  Future<bool> updateComment(String commentId, String newText) async {
    try {
      await _supabase
          .from('event_comments')
          .update({
            'comment_text': newText,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', commentId);
      return true;
    } catch (e) {
      debugPrint('Error updating comment: $e');
      return false;
    }
  }

  // Delete comment
  Future<bool> deleteComment(String commentId) async {
    try {
      await _supabase.from('event_comments').delete().eq('id', commentId);
      return true;
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      return false;
    }
  }

  // Get likes for an event
  Future<List<EventLike>> getEventLikes(String eventId) async {
    try {
      final response = await _supabase
          .from('event_likes')
          .select()
          .eq('event_id', eventId);

      return (response as List)
          .map((json) => EventLike.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting likes: $e');
      return [];
    }
  }

  // Check if user liked event
  Future<bool> hasUserLiked(String eventId, String userId) async {
    try {
      final response = await _supabase
          .from('event_likes')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking like status: $e');
      return false;
    }
  }

  // Like event
  Future<bool> likeEvent(String eventId, String userId) async {
    try {
      final like = EventLike(
        id: '',
        eventId: eventId,
        userId: userId,
        createdAt: DateTime.now(),
      );
      await _supabase.from('event_likes').insert(like.toJson());
      return true;
    } catch (e) {
      debugPrint('Error liking event: $e');
      return false;
    }
  }

  // Unlike event
  Future<bool> unlikeEvent(String eventId, String userId) async {
    try {
      await _supabase
          .from('event_likes')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('Error unliking event: $e');
      return false;
    }
  }
}
