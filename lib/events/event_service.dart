import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import 'event_model.dart';

class EventService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get all events for a tenant
  Future<List<Event>> getEvents(String tenantId) async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('tenant_id', tenantId)
          .order('start_time', ascending: true);

      return (response as List)
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get event by ID
  Future<Event?> getEvent(String eventId) async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('id', eventId)
          .single();

      return Event.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Create event
  Future<bool> createEvent(Event event) async {
    try {
      await _supabase.from('events').insert(event.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update event
  Future<bool> updateEvent(Event event) async {
    try {
      await _supabase
          .from('events')
          .update(event.toJson())
          .eq('id', event.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete event
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _supabase.from('events').delete().eq('id', eventId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
