import 'package:flutter/material.dart';
import '../events/event_list_page.dart';
import '../tenant/members_page.dart';
import '../tenant/user_tenant_service.dart';
import '../auth/auth_service.dart';
import '../services/local_storage_service.dart';
import '../bible/bible_page.dart';
import '../settings/debug_page.dart';
import '../community/community_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _userTenantService = UserTenantService();
  final _authService = AuthService();
  final _localStorage = LocalStorageService();
  bool _isAdmin = false;
  bool _checkingAdmin = true;
  String? _tenantId;

  @override
  void initState() {
    super.initState();
    _checkIfAdmin();
  }

  Future<void> _checkIfAdmin() async {
    final user = _authService.currentUser;
    final tenantId = await _localStorage.getSelectedTenantId();
    
    if (user != null && tenantId != null) {
      final isAdmin = await _userTenantService.isUserAdmin(user.id, tenantId);
      setState(() {
        _isAdmin = isAdmin;
        _tenantId = tenantId;
        _checkingAdmin = false;
      });
    } else {
      setState(() => _checkingAdmin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAdmin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kerk App Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Herlaad Admin Status',
            onPressed: () {
              _checkIfAdmin();
            },
          ),
        ],
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
            if (_isAdmin && _tenantId != null)
              _DashboardCard(
                icon: Icons.people,
                title: 'Leden',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MembersPage(tenantId: _tenantId!),
                    ),
                  );
                },
              ),
            _DashboardCard(
              icon: Icons.book,
              title: 'Bijbel',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BiblePage()),
                );
              },
            ),
            _DashboardCard(
              icon: Icons.people_outline,
              title: 'Gemeenschap',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CommunityPage()),
                );
              },
            ),
            _DashboardCard(
              icon: Icons.settings,
              title: 'Instellingen',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DebugPage()),
                );
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
  final Color? color;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: color?.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
