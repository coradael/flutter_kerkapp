import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../services/storage_service.dart';
import 'user_tenant_service.dart';

class MembersPage extends StatefulWidget {
  final String tenantId;
  
  const MembersPage({super.key, required this.tenantId});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final _userTenantService = UserTenantService();
  final _authService = AuthService();
  final _storageService = StorageService();
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoadMembers();
  }

  Future<void> _checkAdminAndLoadMembers() async {
    final user = _authService.currentUser;
    if (user != null) {
      final isAdmin = await _userTenantService.isUserAdmin(user.id, widget.tenantId);
      setState(() => _isAdmin = isAdmin);
      
      if (isAdmin) {
        await _loadMembers();
      } else {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMembers() async {
    setState(() => _loading = true);
    
    final members = await _userTenantService.getTenantMembers(widget.tenantId);
    
    setState(() {
      _members = members;
      _loading = false;
    });
  }

  Future<void> _updateRole(String userId, String currentRole) async {
    final newRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wijzig Rol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Admin'),
              leading: const Icon(Icons.shield),
              selected: currentRole == 'admin',
              onTap: () => Navigator.pop(context, 'admin'),
            ),
            ListTile(
              title: const Text('Member'),
              leading: const Icon(Icons.person),
              selected: currentRole == 'member',
              onTap: () => Navigator.pop(context, 'member'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
        ],
      ),
    );

    if (newRole != null && newRole != currentRole) {
      final success = await _userTenantService.updateUserRole(
        userId,
        widget.tenantId,
        newRole,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '✅ Rol bijgewerkt' : '❌ Fout bij bijwerken'),
          ),
        );
        
        if (success) {
          _loadMembers();
        }
      }
    }
  }

  Future<void> _removeMember(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lid Verwijderen'),
        content: Text('Weet je zeker dat je $userName wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _userTenantService.removeUserFromTenant(
        userId,
        widget.tenantId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '✅ Lid verwijderd' : '❌ Fout bij verwijderen'),
          ),
        );
        
        if (success) {
          _loadMembers();
        }
      }
    }
  }

  Future<void> _toggleActiveStatus(String userId, String userName, bool currentStatus) async {
    final newStatus = !currentStatus;
    final action = newStatus ? 'activeren' : 'deactiveren';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lid $action'),
        content: Text('Weet je zeker dat je $userName wilt $action?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(newStatus ? 'Activeren' : 'Deactiveren'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _userTenantService.toggleUserActiveStatus(
        userId,
        widget.tenantId,
        newStatus,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? '✅ Status bijgewerkt naar ${newStatus ? "actief" : "inactief"}' 
              : '❌ Fout bij bijwerken status'),
          ),
        );
        
        if (success) {
          _loadMembers();
        }
      }
    }
  }

  Future<void> _sendPasswordReset(String email, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wachtwoord Resetten'),
        content: Text(
          'Er wordt een wachtwoord reset link gestuurd naar:\n\n$email\n\nDoorgaan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Versturen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _userTenantService.sendPasswordResetEmail(email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? '✅ Reset email verstuurd naar $email' 
              : '❌ Fout bij versturen email'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leden'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadMembers,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_isAdmin
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Je hebt geen toegang tot deze pagina.\nAlleen admins kunnen leden beheren.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              : _members.isEmpty
                  ? const Center(
                      child: Text('Geen leden gevonden'),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMembers,
                      child: ListView.builder(
                        itemCount: _members.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          final profile = member['profiles'];
                          final role = member['role'] ?? 'member';
                          final isActive = member['is_active'] ?? true;
                          
                          final fullName = profile?['full_name'] ?? 'Onbekend';
                          final email = profile?['email'] ?? '';
                          final avatarUrl = profile?['avatar_url'];
                          final userId = profile?['id'];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Opacity(
                              opacity: isActive ? 1.0 : 0.5,
                              child: ListTile(
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: avatarUrl != null
                                          ? NetworkImage(
                                              _storageService.getAvatarUrl(avatarUrl)!,
                                            )
                                          : null,
                                      child: avatarUrl == null
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    if (!isActive)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.block,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(
                                  fullName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    decoration: isActive ? null : TextDecoration.lineThrough,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(email),
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
                                                ? Colors.orange.withValues(alpha: 0.2)
                                                : Colors.blue.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            role == 'admin' ? '👑 Admin' : '👤 Member',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: role == 'admin'
                                                  ? Colors.orange[800]
                                                  : Colors.blue[800],
                                              fontWeight: FontWeight.w500,
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
                                                ? Colors.green.withValues(alpha: 0.2)
                                                : Colors.red.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            isActive ? '✓ Actief' : '✗ Inactief',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isActive
                                                  ? Colors.green[800]
                                                  : Colors.red[800],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: _authService.currentUser?.id != userId
                                    ? PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'change_role') {
                                            _updateRole(userId, role);
                                          } else if (value == 'toggle_active') {
                                            _toggleActiveStatus(userId, fullName, isActive);
                                          } else if (value == 'reset_password') {
                                            _sendPasswordReset(email, fullName);
                                          } else if (value == 'remove') {
                                            _removeMember(userId, fullName);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'change_role',
                                            child: Row(
                                              children: [
                                                Icon(Icons.swap_horiz, size: 20),
                                                SizedBox(width: 8),
                                                Text('Wijzig Rol'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'toggle_active',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isActive ? Icons.block : Icons.check_circle,
                                                  size: 20,
                                                  color: isActive ? Colors.orange : Colors.green,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  isActive ? 'Deactiveren' : 'Activeren',
                                                  style: TextStyle(
                                                    color: isActive ? Colors.orange : Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'reset_password',
                                            child: Row(
                                              children: [
                                                Icon(Icons.lock_reset, size: 20, color: Colors.blue),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Reset Wachtwoord',
                                                  style: TextStyle(color: Colors.blue),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'remove',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, size: 20, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Verwijderen',
                                                  style: TextStyle(color: Colors.red),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : Chip(
                                        label: const Text(
                                          'Jij',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: Colors.green.withValues(alpha: 0.2),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
