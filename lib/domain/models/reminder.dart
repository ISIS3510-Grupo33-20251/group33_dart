class Reminder {
  final String id;
  final String userId;
  final String entityType;
  final String entityId;
  final DateTime remindAt;
  final String status;
  final String? notes; 

  Reminder({
    required this.id,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.remindAt,
    required this.status,
    this.notes,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
  print('🟡 Reminder.fromJson received: $json');

  if (!json.containsKey('entity_id')) {
    print('⚠️ Missing entity_id. Using "Untitled" as default.');
  }

  return Reminder(
    id: json['_id'],
    userId: json['user_id'],
    entityType: json['entity_type'],
    entityId: json['entity_id'] ?? 'Untitled',
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
      'entity_id': entityId,
      'remind_at': remindAt.toIso8601String(),
      'status': status,
      'notes': notes, 
    };
  }

  Reminder copyWith({
    String? id,
    String? userId,
    String? entityType,
    String? entityId,
    DateTime? remindAt,
    String? status,
    String? notes,
  }) {
    return Reminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      remindAt: remindAt ?? this.remindAt,
      status: status ?? this.status,
      notes: notes ?? this.notes, 
    );
  }
} 