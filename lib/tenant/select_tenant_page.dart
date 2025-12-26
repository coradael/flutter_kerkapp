import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../core/widgets/loading_indicator.dart';
import 'tenant_service.dart';
import 'tenant_model.dart';
import 'tenant_provider.dart';

class SelectTenantPage extends StatefulWidget {
  final TenantProvider tenantProvider;

  const SelectTenantPage({
    super.key,
    required this.tenantProvider,
  });

  @override
  State<SelectTenantPage> createState() => _SelectTenantPageState();
}

class _SelectTenantPageState extends State<SelectTenantPage> {
  final _authService = AuthService();
  final _tenantService = TenantService();
  List<Tenant> _tenants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    final user = _authService.currentUser;
    if (user != null) {
      final tenants = await _tenantService.getUserTenants(user.id);
      setState(() {
        _tenants = tenants;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecteer Kerk')),
      body: _loading
          ? const LoadingIndicator()
          : ListView.builder(
              itemCount: _tenants.length,
              itemBuilder: (context, index) {
                final tenant = _tenants[index];
                return ListTile(
                  title: Text(tenant.name),
                  leading: const Icon(Icons.church),
                  onTap: () {
                    widget.tenantProvider.setTenant(tenant);
                    Navigator.pop(context);
                  },
                );
              },
            ),
    );
  }
}
