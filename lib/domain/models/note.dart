class Note {
  final String id;
  final String title;
  final String content;
  final String subject;
  final String userId;
  final DateTime createdDate;
  final DateTime lastModified;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.subject,
    required this.userId,
    required this.createdDate,
    required this.lastModified,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      subject: json['subject'] ?? '',
      userId: json['owner_id'] ?? '',
      createdDate: DateTime.parse(json['created_date'] ?? DateTime.now().toIso8601String()),
      lastModified: DateTime.parse(json['last_modified'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'content': content,
      'subject': subject,
      'owner_id': userId,
      'created_date': createdDate.toIso8601String(),
      'last_modified': lastModified.toIso8601String(),
    };
  }
} 