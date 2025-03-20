class Flashcard {
  final String id;
  final String question;
  final String answer;
  final String subject;
  final String userId;
  final DateTime createdDate;
  final DateTime lastModified;

  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    required this.subject,
    required this.userId,
    required this.createdDate,
    required this.lastModified,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['_id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      subject: json['subject'] ?? '',
      userId: json['owner_id'] ?? '',
      createdDate: DateTime.parse(json['created_date'] ?? DateTime.now().toIso8601String()),
      lastModified: DateTime.parse(json['last_modified'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'question': question,
      'answer': answer,
      'subject': subject,
      'owner_id': userId,
      'created_date': createdDate.toIso8601String(),
      'last_modified': lastModified.toIso8601String(),
    };
  }
} 