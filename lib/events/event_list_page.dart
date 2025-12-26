import 'package:flutter/material.dart';
import '../core/widgets/loading_indicator.dart';
import 'event_service.dart';
import 'event_model.dart';
import 'event_detail_page.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final _eventService = EventService();
  List<Event> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    // TODO: Get tenant ID from TenantProvider
    final events = await _eventService.getEvents('tenant-id-placeholder');
    setState(() {
      _events = events;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evenementen')),
      body: _loading
          ? const LoadingIndicator()
          : _events.isEmpty
              ? const Center(child: Text('Geen evenementen gevonden'))
              : ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return ListTile(
                      title: Text(event.title),
                      subtitle: Text(event.description ?? ''),
                      trailing: Text(
                        '${event.startTime.day}/${event.startTime.month}',
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailPage(event: event),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
