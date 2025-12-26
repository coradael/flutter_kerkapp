class Event {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final String tenantId;
  final DateTime? createdAt;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.location,
    required this.tenantId,
    this.createdAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      location: json['location'] as String?,
      tenantId: json['tenant_id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'location': location,
      'tenant_id': tenantId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
