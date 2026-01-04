import 'package:flutter/material.dart';
import '../events/event_list_page.dart';
import '../tenant/members_page.dart';
import '../tenant/user_tenant_service.dart';
import '../auth/auth_service.dart';
import '../services/local_storage_service.dart';
import '../bible/bible_page.dart';
import '../settings/debug_page.dart';
import '../community/community_page.dart';
import '../feed/feed_page.dart';

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
  int _currentIndex = 0;

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

    final pages = [
      const FeedPage(),
      const CommunityPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'My Church' : 'Gemeenschap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'Menu',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => _MenuPage(
                  isAdmin: _isAdmin,
                  tenantId: _tenantId,
                )),
              );
            },
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Community',
          ),
        ],
      ),
    );
  }
}

class _MenuPage extends StatelessWidget {
  final bool isAdmin;
  final String? tenantId;

  const _MenuPage({
    required this.isAdmin,
    required this.tenantId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Evenementen'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventListPage()),
              );
            },
          ),
          if (isAdmin && tenantId != null)
            ListTile(
              leading: const Icon(Icons.people, color: Colors.orange),
              title: const Text('Leden Beheren'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MembersPage(tenantId: tenantId!),
                  ),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Gemeenschap'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CommunityPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Bijbel'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BiblePage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Instellingen'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DebugPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
