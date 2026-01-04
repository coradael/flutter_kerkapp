import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import 'event_model.dart';

class EventService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get all events for a tenant
  Future<List<Event>> getTenantEvents(String tenantId) async {
    try {
      final response = await _supabase
          .from('events')
          .select('*, event_files(*)')
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false);

      final List<Event> events = [];
      
      for (final json in response as List) {
        final createdBy = json['created_by'] as String;
        
        // Get creator profile info
        final profileResponse = await _supabase
            .from('profiles')
            .select('full_name, avatar_url, email')
            .eq('id', createdBy)
            .maybeSingle();
        
        // Use full_name if available, otherwise use email
        String? creatorName = profileResponse?['full_name'] as String?;
        if (creatorName == null || creatorName.isEmpty) {
          creatorName = profileResponse?['email'] as String?;
        }
        
        events.add(Event.fromJson({
          ...json,
          'creator_name': creatorName,
          'creator_avatar': profileResponse?['avatar_url'],
        }));
      }
      
      return events;
    } catch (e) {
      debugPrint('Error getting tenant events: $e');
      return [];
    }
  }

  // Get event by ID
  Future<Event?> getEvent(String eventId) async {
    try {
      final response = await _supabase
          .from('events')
          .select('*, event_files(*)')
          .eq('id', eventId)
          .single();

      return Event.fromJson(response);
    } catch (e) {
      debugPrint('Error getting event: $e');
      return null;
    }
  }

  // Create event
  Future<String?> createEvent(Event event) async {
    try {
      final response = await _supabase
          .from('events')
          .insert(event.toJson())
          .select('id')
          .single();
      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating event: $e');
      return null;
    }
  }

  // Update event
  Future<bool> updateEvent(String eventId, Event event) async {
    try {
      await _supabase
          .from('events')
          .update({
            'title': event.title,
            'description': event.description,
            'event_date': event.eventDate?.toIso8601String(),
            'location': event.location,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', eventId);
      return true;
    } catch (e) {
      debugPrint('Error updating event: $e');
      return false;
    }
  }

  // Delete event
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _supabase.from('events').delete().eq('id', eventId);
      return true;
    } catch (e) {
      debugPrint('Error deleting event: $e');
      return false;
    }
  }

  // Add event file
  Future<bool> addEventFile(EventFile eventFile) async {
    try {
      await _supabase.from('event_files').insert(eventFile.toJson());
      return true;
    } catch (e) {
      debugPrint('Error adding event file: $e');
      return false;
    }
  }

  // Delete event file
  Future<bool> deleteEventFile(String fileId) async {
    try {
      await _supabase.from('event_files').delete().eq('id', fileId);
      return true;
    } catch (e) {
      debugPrint('Error deleting event file: $e');
      return false;
    }
  }
}
