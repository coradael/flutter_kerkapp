import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../auth/auth_service.dart';
import '../tenant/tenant_selection_page.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final _localStorage = LocalStorageService();
  final _authService = AuthService();
  String? _currentTenantId;

  @override
  void initState() {
    super.initState();
    _loadTenantId();
  }

  Future<void> _loadTenantId() async {
    final tenantId = await _localStorage.getSelectedTenantId();
    setState(() => _currentTenantId = tenantId);
  }

  Future<void> _clearTenant() async {
    await _localStorage.clearSelectedTenantId();
    await _loadTenantId();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Tenant ID gewist')),
      );
    }
  }

  Future<void> _clearAllData() async {
    await _localStorage.clearAll();
    await _loadTenantId();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Alle data gewist')),
      );
    }
  }

  Future<void> _reselect() async {
    await _localStorage.clearSelectedTenantId();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TenantSelectionPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Info'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Info',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Email: ${user?.email ?? "Not logged in"}'),
                  Text('User ID: ${user?.id ?? "N/A"}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tenant Info',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Current Tenant ID: ${_currentTenantId ?? "Niet geselecteerd"}'),
                  Text('Is Empty: ${_currentTenantId?.isEmpty ?? true}'),
                  Text('Length: ${_currentTenantId?.length ?? 0}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _clearTenant,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Wis Tenant ID'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _reselect,
            icon: const Icon(Icons.refresh),
            label: const Text('Selecteer Kerk Opnieuw'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _clearAllData,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Wis ALLE Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
