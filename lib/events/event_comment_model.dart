class EventComment {
  final String id;
  final String eventId;
  final String userId;
  final String commentText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userEmail;
  final String? userName;

  EventComment({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.commentText,
    required this.createdAt,
    required this.updatedAt,
    this.userEmail,
    this.userName,
  });

  factory EventComment.fromJson(Map<String, dynamic> json) {
    return EventComment(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      commentText: json['comment_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userEmail: json['user_email'] as String?,
      userName: json['user_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'event_id': eventId,
      'user_id': userId,
      'comment_text': commentText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }
}

class EventLike {
  final String id;
  final String eventId;
  final String userId;
  final DateTime createdAt;

  EventLike({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.createdAt,
  });

  factory EventLike.fromJson(Map<String, dynamic> json) {
    return EventLike(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'event_id': eventId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
    
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }
}
