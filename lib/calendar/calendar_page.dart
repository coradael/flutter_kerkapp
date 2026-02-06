import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../auth/auth_service.dart';
import '../services/local_storage_service.dart';
import 'calendar_service.dart';
import 'calendar_model.dart';
import 'create_calendar_event_page.dart';
import '../events/event_service.dart';
import '../events/event_model.dart';
import '../events/event_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _authService = AuthService();
  final _localStorage = LocalStorageService();
  final _calendarService = CalendarService();
  final _eventService = EventService();
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {}; // Changed to dynamic to hold both types
  bool _loading = true;
  String? _tenantId;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    
    _tenantId = await _localStorage.getSelectedTenantId();
    if (_tenantId == null) {
      setState(() => _loading = false);
      return;
    }

    // Load both calendar events and feed events
    final calendarEvents = await _calendarService.getTenantEvents(_tenantId!);
    final feedEvents = await _eventService.getTenantEvents(_tenantId!);
    
    // Group events by date
    final Map<DateTime, List<dynamic>> eventMap = {};
    
    // Add calendar events
    for (final event in calendarEvents) {
      final date = DateTime(
        event.eventDate.year,
        event.eventDate.month,
        event.eventDate.day,
      );
      if (eventMap[date] == null) {
        eventMap[date] = [];
      }
      eventMap[date]!.add(event);
    }
    
    // Add feed events
    for (final event in feedEvents) {
      if (event.eventDate != null) {
        final date = DateTime(
          event.eventDate!.year,
          event.eventDate!.month,
          event.eventDate!.day,
        );
        if (eventMap[date] == null) {
          eventMap[date] = [];
        }
        eventMap[date]!.add(event);
      }
    }
    
    setState(() {
      _events = eventMap;
      _loading = false;
    });
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _events[date] ?? [];
  }

  Future<void> _createEvent() async {
    if (_tenantId == null) return;

    final user = _authService.currentUser;
    if (user == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCalendarEventPage(
          tenantId: _tenantId!,
          userId: user.id,
          selectedDate: _selectedDay ?? _focusedDay,
        ),
      ),
    );

    if (result == true) {
      _loadEvents();
    }
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Evenement verwijderen?'),
        content: const Text('Weet je zeker dat je dit evenement wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _calendarService.deleteEvent(event.id);
      _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar<dynamic>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  eventLoader: _getEventsForDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: const CalendarStyle(
                    outsideDaysVisible: false,
                    markersMaxCount: 3,
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    }
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildEventList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createEvent,
        icon: const Icon(Icons.add),
        label: const Text('Nieuw Evenement'),
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay ?? _focusedDay);
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Geen evenementen op deze dag',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        
        // Check if it's a CalendarEvent or Event (from feed)
        if (event is CalendarEvent) {
          return _buildCalendarEventCard(event);
        } else if (event is Event) {
          return _buildFeedEventCard(event);
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCalendarEventCard(CalendarEvent event) {
    final isOwnEvent = event.userId == _authService.currentUser?.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getEventColor(event.color),
          child: const Icon(Icons.event, color: Colors.white),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description != null) ...[
              const SizedBox(height: 4),
              Text(
                event.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (event.endTime != null) ...[
                  Text(' - ', style: TextStyle(color: Colors.grey.shade600)),
                  Text(
                    '${event.endTime!.hour}:${event.endTime!.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Door: ${event.userName}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: isOwnEvent
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteEvent(event),
              )
            : null,
      ),
    );
  }

  Widget _buildFeedEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailPage(event: event),
            ),
          );
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.deepPurple.shade300,
            child: const Icon(Icons.campaign, color: Colors.white),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Feed Event',
                  style: TextStyle(
                    color: Colors.deepPurple.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  event.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              if (event.location != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'Door: ${event.creatorName ?? "Onbekend"}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEventColor(String? colorStr) {
    switch (colorStr) {
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}
