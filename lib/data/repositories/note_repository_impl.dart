import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../globals.dart';

class NoteRepositoryImpl implements NoteRepository {
  @override
  Future<List<Note>> getNotes(String userId) async {
    final response = await http.get(
      Uri.parse("$backendUrl/users/$userId/notes/"),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Note.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notes');
    }
  }

  @override
  Future<Note> createNote(Note note) async {
    final response = await http.post(
      Uri.parse("$backendUrl/notes/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(note.toJson()),
    );

    if (response.statusCode == 200) {
      final noteId = json.decode(response.body)["_id"];
      
      final responseTags = await http.post(
        Uri.parse("$backendUrl/users/${note.userId}/notes/$noteId"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({}),
      );

      if (responseTags.statusCode == 200) {
        return Note.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to associate note with user');
      }
    } else {
      throw Exception('Failed to create note');
    }
  }

  @override
  Future<Note> updateNote(Note note) async {
    final response = await http.put(
      Uri.parse("$backendUrl/notes/${note.id}"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(note.toJson()),
    );

    if (response.statusCode == 200) {
      return Note.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update note');
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    final response = await http.delete(
      Uri.parse("$backendUrl/notes/$noteId"),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete note');
    }
  }

  @override
  Future<List<String>> getSubjects(String userId) async {
    final response = await http.get(
      Uri.parse("$backendUrl/users/$userId/subjects"),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => json['subject'] as String).toList();
    } else {
      throw Exception('Failed to load subjects');
    }
  }
} 