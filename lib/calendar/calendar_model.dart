class CalendarEvent {
  final String id;
  final String tenantId;
  final String userId;
  final String userName;
  final String title;
  final String? description;
  final DateTime eventDate;
  final DateTime startTime;
  final DateTime? endTime;
  final String? location;
  final String? color;
  final DateTime createdAt;

  CalendarEvent({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.userName,
    required this.title,
    this.description,
    required this.eventDate,
    required this.startTime,
    this.endTime,
    this.location,
    this.color,
    required this.createdAt,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? 'Onbekend',
      title: json['title'] ?? '',
      description: json['description'],
      eventDate: DateTime.parse(json['event_date']),
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      location: json['location'],
      color: json['color'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'user_id': userId,
      'user_name': userName,
      'title': title,
      'description': description,
      'event_date': eventDate.toIso8601String(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'location': location,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
