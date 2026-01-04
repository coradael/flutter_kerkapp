import 'package:flutter/material.dart';
import '../profile/profile_page.dart';
import '../feed/feed_page.dart';
import '../community/community_page.dart';
import '../events/event_list_page.dart';
import '../tenant/members_page.dart';
import '../tenant/user_tenant_service.dart';
import '../auth/auth_service.dart';
import '../services/local_storage_service.dart';
import '../bible/bible_page.dart';
import '../settings/debug_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _userTenantService = UserTenantService();
  final _authService = AuthService();
  final _localStorage = LocalStorageService();
  bool _isAdmin = false;
  bool _checkingAdmin = true;
  String? _tenantId;
  int _selectedIndex = 0;

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

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'My Church';
      case 1:
        return 'Community';
      case 2:
        return 'Profiel';
      default:
        return 'My Church';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAdmin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> pages = [
      const FeedPage(),
      const CommunityPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
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
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
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
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profiel',
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
