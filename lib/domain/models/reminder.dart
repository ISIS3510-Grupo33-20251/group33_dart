class Reminder {
  final String id;
  final String userId;
  final String entityType;
  final DateTime remindAt;
  final String status;
  final String? notes;

  Reminder({
    required this.id,
    required this.userId,
    required this.entityType,
    required this.remindAt,
    required this.status,
    this.notes,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['_id'],
      userId: json['user_id'],
      entityType: json['entity_type'],
      remindAt: DateTime.parse(json['remind_at']),
      status: json['status'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user_id': userId,
      'entity_type': entityType,
      'remind_at': remindAt.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  Reminder copyWith({
    String? id,
    String? userId,
    String? entityType,
    DateTime? remindAt,
    String? status,
    String? notes,
  }) {
    return Reminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entityType: entityType ?? this.entityType,
      remindAt: remindAt ?? this.remindAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
