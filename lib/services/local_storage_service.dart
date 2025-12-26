import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keySelectedTenantId = 'selected_tenant_id';

  // Save selected tenant ID
  Future<void> saveSelectedTenantId(String tenantId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedTenantId, tenantId);
  }

  // Get selected tenant ID
  Future<String?> getSelectedTenantId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedTenantId);
  }

  // Clear selected tenant ID
  Future<void> clearSelectedTenantId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySelectedTenantId);
  }

  // Clear all data
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
