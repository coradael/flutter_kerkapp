import 'package:flutter/material.dart';
import '../events/event_list_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kerk App Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _DashboardCard(
              icon: Icons.event,
              title: 'Evenementen',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventListPage()),
                );
              },
            ),
            _DashboardCard(
              icon: Icons.book,
              title: 'Bijbel',
              onTap: () {
                // TODO: Navigate to Bible page
              },
            ),
            _DashboardCard(
              icon: Icons.people,
              title: 'Gemeenschap',
              onTap: () {
                // TODO: Navigate to Community page
                
              },
            ),
            _DashboardCard(
              icon: Icons.settings,
              title: 'Instellingen',
              onTap: () {
                // TODO: Navigate to Settings page
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
