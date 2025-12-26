import 'package:flutter/material.dart';
import 'event_model.dart';

class EventDetailPage extends StatelessWidget {
  final Event event;

  const EventDetailPage({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            if (event.description != null) ...[
              Text(
                'Beschrijving:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(event.description!),
              const SizedBox(height: 16),
            ],
            Text(
              'Starttijd:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(event.startTime.toString()),
            const SizedBox(height: 8),
            if (event.endTime != null) ...[
              Text(
                'Eindtijd:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(event.endTime.toString()),
              const SizedBox(height: 8),
            ],
            if (event.location != null) ...[
              Text(
                'Locatie:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(event.location!),
            ],
          ],
        ),
      ),
    );
  }
}
