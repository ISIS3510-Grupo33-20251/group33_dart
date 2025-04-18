import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiServiceAdapter {
  final String backendUrl;

  ApiServiceAdapter({required this.backendUrl});

  Future<List<Map<String, dynamic>>> fetchNotes(String endpoint) async {
    final response = await http.get(Uri.parse("$backendUrl/$endpoint"));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception("Error al obtener datos de $endpoint");
    }
  }

  Future<void> createNote(
    String title,
    String content,
    String subject,
    String userId,
  ) async {
    final response = await http.post(
      Uri.parse("$backendUrl/notes/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "title": title.trim(),
        "content": content,
        "subject": subject.trim(),
        "created_date": '2024-03-07T12:00:00Z',
        "last_modified": '2024-03-07T12:00:00Z',
        "owner_id": userId
      }),
    );

    if (response.statusCode == 200) {
      final noteId = json.decode(response.body)["_id"];
      final responseTags = await http.post(
        Uri.parse("$backendUrl/users/$userId/notes/$noteId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),
      );

      if (responseTags.statusCode != 200) {
        throw Exception("Error adding tags to the note");
      }
    } else {
      throw Exception("Error creating note");
    }
  }

  Future<void> updateNote(
    String noteId,
    String title,
    String content,
    String subject,
    String createdDate,
    String lastModified,
    String userId,
  ) async {
    final response = await http.put(
      Uri.parse("$backendUrl/notes/$noteId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "title": title.trim(),
        "content": content,
        "subject": subject.trim(),
        "created_date": createdDate,
        "last_modified": lastModified,
        "owner_id": userId
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Error updating note");
    }
  }

  Future<void> deleteNote(String noteId) async {
    final response = await http.delete(
      Uri.parse("$backendUrl/notes/$noteId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({}),
    );

    if (response.statusCode != 200) {
      throw Exception("Error deleting note");
    }
  }

  Future<List<Map<String, dynamic>>> fetchFlashcards(
      String userId, String subject) async {
    final response =
        await http.get(Uri.parse("$backendUrl/users/$userId/$subject/flash/"));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception("Error");
    }
  }
}
