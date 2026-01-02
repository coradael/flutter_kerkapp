class Event {
  final String id;
  final String tenantId;
  final String createdBy;
  final String title;
  final String? description;
  final DateTime? eventDate;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<EventFile>? files;

  Event({
    required this.id,
    required this.tenantId,
    required this.createdBy,
    required this.title,
    this.description,
    this.eventDate,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    this.files,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      createdBy: json['created_by'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventDate: json['event_date'] != null
          ? DateTime.parse(json['event_date'] as String)
          : null,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      files: json['event_files'] != null
          ? (json['event_files'] as List)
              .map((file) => EventFile.fromJson(file))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'tenant_id': tenantId,
      'created_by': createdBy,
      'title': title,
      'description': description,
      'event_date': eventDate?.toIso8601String(),
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    // Only include id if it's not empty (for updates)
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }
}

class EventFile {
  final String id;
  final String eventId;
  final String filePath;
  final String fileType;
  final String fileName;
  final int? fileSize;
  final DateTime createdAt;

  EventFile({
    required this.id,
    required this.eventId,
    required this.filePath,
    required this.fileType,
    required this.fileName,
    this.fileSize,
    required this.createdAt,
  });

  factory EventFile.fromJson(Map<String, dynamic> json) {
    return EventFile(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      filePath: json['file_path'] as String,
      fileType: json['file_type'] as String,
      fileName: json['file_name'] as String,
      fileSize: json['file_size'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'event_id': eventId,
      'file_path': filePath,
      'file_type': fileType,
      'file_name': fileName,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };
    
    // Only include id if it's not empty (for updates)
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }
}
