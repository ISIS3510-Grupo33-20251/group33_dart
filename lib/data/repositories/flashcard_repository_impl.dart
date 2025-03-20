import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/flashcard.dart';
import '../../domain/repositories/flashcard_repository.dart';
import '../../globals.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  @override
  Future<List<Flashcard>> getFlashcards(String userId, String subject) async {
    final response = await http.get(
      Uri.parse("$backendUrl/users/$userId/$subject/flash/"),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Flashcard.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load flashcards');
    }
  }

  @override
  Future<Flashcard> createFlashcard(Flashcard flashcard) async {
    final response = await http.post(
      Uri.parse("$backendUrl/flash/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(flashcard.toJson()),
    );

    if (response.statusCode == 200) {
      return Flashcard.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create flashcard');
    }
  }

  @override
  Future<Flashcard> updateFlashcard(Flashcard flashcard) async {
    final response = await http.put(
      Uri.parse("$backendUrl/flash/${flashcard.id}"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(flashcard.toJson()),
    );

    if (response.statusCode == 200) {
      return Flashcard.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update flashcard');
    }
  }

  @override
  Future<void> deleteFlashcard(String flashcardId) async {
    final response = await http.delete(
      Uri.parse("$backendUrl/flash/$flashcardId"),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete flashcard');
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