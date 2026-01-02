import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import 'event_service.dart';
import 'event_model.dart';
import 'event_detail_page.dart';
import 'create_event_page.dart';
import 'event_storage_service.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final _eventService = EventService();
  final _localStorage = LocalStorageService();
  List<Event> _events = [];
  bool _loading = true;
  String? _tenantId;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    
    final tenantId = await _localStorage.getSelectedTenantId();
    
    if (kDebugMode) {
      print('📋 EventListPage - Loading events for tenant: $tenantId');
    }
    
    if (tenantId != null) {
      final events = await _eventService.getTenantEvents(tenantId);
      
      if (kDebugMode) {
        print('✅ EventListPage - Loaded ${events.length} events');
      }
      
      setState(() {
        _events = events;
        _tenantId = tenantId;
        _loading = false;
      });
    } else {
      if (kDebugMode) {
        print('⚠️ EventListPage - No tenant ID found');
      }
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evenementen'),
      ),
      floatingActionButton: _tenantId != null && _tenantId!.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateEventPage(tenantId: _tenantId!),
                  ),
                );
                if (result == true) {
                  _loadEvents();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Nieuw Event'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(
                  child: Text(
                    'Geen evenementen gevonden\nKlik op + om een event toe te voegen',
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadEvents,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      final firstImage = event.files?.firstWhere(
                        (file) => file.fileType == 'image',
                        orElse: () => EventFile(
                          id: '',
                          eventId: '',
                          filePath: '',
                          fileType: '',
                          fileName: '',
                          createdAt: DateTime.now(),
                        ),
                      );
                      final hasImage = firstImage?.filePath.isNotEmpty ?? false;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Toon foto als er een is
                            if (hasImage) ...[
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.network(
                                  EventStorageService().getFileUrl(firstImage!.filePath)!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Icon(Icons.broken_image, size: 50),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            ListTile(
                              leading: hasImage
                                  ? null
                                  : CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      child: Icon(
                                        event.files?.isNotEmpty == true
                                            ? Icons.attach_file
                                            : Icons.event,
                                        color: Colors.white,
                                      ),
                                    ),
                              title: Text(
                                event.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (event.description != null)
                                    Text(
                                      event.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (event.eventDate != null) ...[
                                        const Icon(Icons.calendar_today, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${event.eventDate!.day}/${event.eventDate!.month}/${event.eventDate!.year}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                      if (event.location != null) ...[
                                        const SizedBox(width: 12),
                                        const Icon(Icons.location_on, size: 14),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            event.location!,
                                            style: const TextStyle(fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EventDetailPage(event: event),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
