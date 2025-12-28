class UserTenant {
  final String id;
  final String userId;
  final String tenantId;
  final String? role;
  final String? email;
  final bool isActive;
  final DateTime? createdAt;

  UserTenant({
    required this.id,
    required this.userId,
    required this.tenantId,
    this.role,
    this.email,
    this.isActive = true,
    this.createdAt,
  });

  factory UserTenant.fromJson(Map<String, dynamic> json) {
    return UserTenant(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      tenantId: json['tenant_id'] as String,
      role: json['role'] as String?,
      email: json['email'] as String?,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'tenant_id': tenantId,
      'role': role,
      'email': email,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
