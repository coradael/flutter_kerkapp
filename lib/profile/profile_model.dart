class Profile {
  final String id;
  final String? email;
  final String? tenantId;
  final String? fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    this.email,
    this.tenantId,
    this.fullName,
    this.phoneNumber,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String?,
      tenantId: json['tenant_id'] as String?,
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'tenant_id': tenantId,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
