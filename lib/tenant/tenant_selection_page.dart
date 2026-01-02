import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../services/local_storage_service.dart';
import 'user_tenant_service.dart';
import '../home/home_page.dart';

class TenantSelectionPage extends StatefulWidget {
  const TenantSelectionPage({super.key});

  @override
  State<TenantSelectionPage> createState() => _TenantSelectionPageState();
}

class _TenantSelectionPageState extends State<TenantSelectionPage> {
  final _userTenantService = UserTenantService();
  final _authService = AuthService();
  final _localStorage = LocalStorageService();
  
  List<Map<String, dynamic>> _userTenants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserTenants();
  }

  Future<void> _loadUserTenants() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final response = await _userTenantService.getUserTenants(user.id);
      
      if (kDebugMode) {
        print('📊 TenantSelection - User tenants count: ${response.length}');
        for (var tenant in response) {
          print('  - Tenant ID: ${tenant['tenant_id']}, Name: ${tenant['tenant_name']}');
        }
      }
      
      setState(() {
        _userTenants = response;
        _loading = false;
      });

      // If user has only one tenant, auto-select it
      if (_userTenants.length == 1) {
        final tenantId = _userTenants[0]['tenant_id'] as String?;
        if (tenantId != null && tenantId.isNotEmpty) {
          if (kDebugMode) {
            print('🎯 TenantSelection - Auto-selecting single tenant: $tenantId');
          }
          await _selectTenant(tenantId);
        } else {
          if (kDebugMode) {
            print('⚠️ TenantSelection - Tenant ID is null or empty!');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ TenantSelection - Error loading tenants: $e');
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _selectTenant(String tenantId) async {
    if (tenantId.isEmpty) {
      if (kDebugMode) {
        print('❌ TenantSelection - Cannot save empty tenant ID!');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Ongeldige kerk ID')),
        );
      }
      return;
    }
    
    if (kDebugMode) {
      print('✅ TenantSelection - Saving tenant: $tenantId');
    }
    
    try {
      await _localStorage.saveSelectedTenantId(tenantId);
      
      // Verify it was saved
      final saved = await _localStorage.getSelectedTenantId();
      if (kDebugMode) {
        print('🔍 TenantSelection - Verified saved tenant: $saved');
      }
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ TenantSelection - Error saving tenant: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fout bij opslaan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userTenants.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Geen Kerk')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Je bent nog niet toegevoegd aan een kerk.\nNeem contact op met je kerk administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecteer Kerk'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _userTenants.length,
        itemBuilder: (context, index) {
          final userTenant = _userTenants[index];
          final tenant = userTenant['tenants'];
          final tenantName = tenant?['name'] ?? 'Onbekende Kerk';
          final role = userTenant['role'] ?? 'member';
          final tenantId = userTenant['tenant_id'];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: role == 'admin' ? Colors.orange : Colors.blue,
                child: Icon(
                  role == 'admin' ? Icons.shield : Icons.church,
                  color: Colors.white,
                ),
              ),
              title: Text(
                tenantName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                role == 'admin' ? '👑 Admin' : '👤 Member',
                style: TextStyle(
                  color: role == 'admin' ? Colors.orange : Colors.blue,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectTenant(tenantId),
            ),
          );
        },
      ),
    );
  }
}
