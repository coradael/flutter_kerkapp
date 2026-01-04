import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../tenant/user_tenant_service.dart';
import '../services/storage_service.dart';
import '../profile/view_profile_page.dart';
import '../auth/auth_service.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final _userTenantService = UserTenantService();
  final _localStorage = LocalStorageService();
  final _storageService = StorageService();
  final _authService = AuthService();

  List<Map<String, dynamic>> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _loading = true);

    final tenantId = await _localStorage.getSelectedTenantId();
    if (tenantId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final members = await _userTenantService.getTenantMembers(tenantId);
      debugPrint('📊 CommunityPage - Loaded ${members.length} members');
      
      // Debug: print member data
      for (final member in members) {
        debugPrint('👤 Member: ${member['email']}');
        debugPrint('   Profiles data: ${member['profiles']}');
      }
      
      setState(() {
        _members = members;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ CommunityPage - Error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _members.isEmpty
            ? const Center(
                child: Text('Geen leden gevonden'),
              )
            : RefreshIndicator(
                onRefresh: _loadMembers,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final profile = member['profiles'] as Map<String, dynamic>?;
                      final role = member['role'] as String? ?? 'member';
                      final isActive = member['is_active'] as bool? ?? false;

                      final fullName = profile?['full_name'] as String?;
                      final email = profile?['email'] as String?;
                      final phoneNumber = profile?['phone_number'] as String?;
                      final avatarUrl = profile?['avatar_url'] as String?;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ViewProfilePage(
                                  member: member,
                                  isCurrentUser: _authService.currentUser?.id == profile?['id'],
                                ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: role == 'admin' ? Colors.orange : Colors.blue,
                            backgroundImage: avatarUrl != null && _storageService.getAvatarUrl(avatarUrl) != null
                                ? NetworkImage(_storageService.getAvatarUrl(avatarUrl)!)
                                : null,
                            child: avatarUrl == null
                                ? Text(
                                    (fullName ?? email ?? 'U')
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  )
                                : null,
                          ),
                          title: Text(
                            fullName ?? email ?? 'Geen naam',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (email != null) Text(email),
                              if (phoneNumber != null) Text('📱 $phoneNumber'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: role == 'admin'
                                          ? Colors.orange.shade100
                                          : Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      role == 'admin' ? '👑 Admin' : '👤 Lid',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: role == 'admin'
                                            ? Colors.orange.shade900
                                            : Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.green.shade100
                                          : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isActive ? '✅ Actief' : '⏸️ Inactief',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isActive
                                            ? Colors.green.shade900
                                            : Colors.red.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: phoneNumber != null
                              ? IconButton(
                                  icon: const Icon(Icons.phone, color: Colors.blue),
                                  onPressed: () {
                                    // Open phone dialer
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Bel: $phoneNumber')),
                                    );
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                );
  }
}
