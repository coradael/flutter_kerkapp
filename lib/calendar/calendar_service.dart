import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'calendar_model.dart';

class CalendarService {
  final _supabase = Supabase.instance.client;

  Future<List<CalendarEvent>> getTenantEvents(String tenantId) async {
    try {
      final response = await _supabase
          .from('calendar_events')
          .select('*, profiles!calendar_events_user_id_fkey(full_name)')
          .eq('tenant_id', tenantId)
          .order('event_date', ascending: true)
          .order('start_time', ascending: true);

      return (response as List)
          .map((json) {
            json['user_name'] = json['profiles']?['full_name'] ?? 'Onbekend';
            return CalendarEvent.fromJson(json);
          })
          .toList();
    } catch (e) {
      debugPrint('Error loading calendar events: $e');
      return [];
    }
  }

  Future<bool> createEvent({
    required String tenantId,
    required String userId,
    required String title,
    String? description,
    required DateTime eventDate,
    required DateTime startTime,
    DateTime? endTime,
    String? location,
    String? color,
  }) async {
    try {
      await _supabase.from('calendar_events').insert({
        'tenant_id': tenantId,
        'user_id': userId,
        'title': title,
        'description': description,
        'event_date': eventDate.toIso8601String().split('T')[0],
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'location': location,
        'color': color ?? 'blue',
      });
      return true;
    } catch (e) {
      debugPrint('Error creating calendar event: $e');
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      await _supabase
          .from('calendar_events')
          .delete()
          .eq('id', eventId);
      return true;
    } catch (e) {
      debugPrint('Error deleting calendar event: $e');
      return false;
    }
  }
}
