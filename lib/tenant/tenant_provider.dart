import 'package:flutter/foundation.dart';
import 'tenant_model.dart';

class TenantProvider extends ChangeNotifier {
  Tenant? _currentTenant;

  Tenant? get currentTenant => _currentTenant;

  void setTenant(Tenant tenant) {
    _currentTenant = tenant;
    notifyListeners();
  }

  void clearTenant() {
    _currentTenant = null;
    notifyListeners();
  }

  bool get hasTenant => _currentTenant != null;
}
