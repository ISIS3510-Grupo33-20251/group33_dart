// Crea un nuevo archivo local_storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorageService {
  static const String _notesKey = 'cached_notes';
  static const String _flashcardsKey = 'cached_flashcards';

  Future<void> saveNotes(List<Map<String, dynamic>> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = notes.map((note) => jsonEncode(note)).toList();
    await prefs.setStringList(_notesKey, notesJson);
  }

  Future<List<Map<String, dynamic>>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList(_notesKey) ?? [];
    return notesJson
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
  }

  Future<void> saveFlashcards(
      String subject, List<Map<String, dynamic>> flashcards) async {
    final prefs = await SharedPreferences.getInstance();
    final allFlashcards = await loadAllFlashcards();
    allFlashcards[subject] = flashcards;
    await prefs.setString(_flashcardsKey, jsonEncode(allFlashcards));
  }

  Future<List<Map<String, dynamic>>> loadFlashcards(String subject) async {
    final allFlashcards = await loadAllFlashcards();
    return allFlashcards[subject] ?? [];
  }

  Future<Map<String, List<Map<String, dynamic>>>> loadAllFlashcards() async {
    final prefs = await SharedPreferences.getInstance();
    final flashcardsJson = prefs.getString(_flashcardsKey);
    if (flashcardsJson == null) return {};
    final decoded = jsonDecode(flashcardsJson) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(
        key, (value as List).map((e) => e as Map<String, dynamic>).toList()));
  }
}
