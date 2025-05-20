class KanbanTask {
  final String id;
  final String title;
  final String description;
  final String status; // 'todo', 'in_progress', 'done'
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? subject;
  final int priority; // 1-3 (low, medium, high)

  KanbanTask({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.dueDate,
    this.subject,
    this.priority = 2,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'subject': subject,
      'priority': priority,
    };
  }

  factory KanbanTask.fromJson(Map<String, dynamic> json) {
    return KanbanTask(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      subject: json['subject'],
      priority: json['priority'] ?? 2,
    );
  }

  KanbanTask copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? dueDate,
    String? subject,
    int? priority,
  }) {
    return KanbanTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      subject: subject ?? this.subject,
      priority: priority ?? this.priority,
    );
  }
}
