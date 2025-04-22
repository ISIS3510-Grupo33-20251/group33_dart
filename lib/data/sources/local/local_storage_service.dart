import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:group33_dart/globals.dart';

class LocalStorageService {
  static const String _notesKey = 'cached_notes';
  static const String _flashcardsKey = 'cached_flashcards';
  static const String _actionQueueKey = 'cached_queue';

  Box get _box => Hive.box('storage');

  Future<void> saveActionQueue(List<Map<String, String>> actionQueue) async {
    final jsonQueue = jsonEncode(actionQueue);
    await _box.put(_actionQueueKey, jsonQueue);
    await _box.flush();
  }

  Future<List<Map<String, String>>> loadActionQueue() async {
    final raw = _box.get(_actionQueueKey);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => Map<String, String>.from(e)).toList();
  }

  Future<void> saveNotes(List<Map<String, dynamic>> notes) async {
    final jsonNotes = jsonEncode(notes);
    await _box.put(_notesKey, jsonNotes);
    await _box.flush();
  }

  Future<List<Map<String, dynamic>>> loadNotes() async {
    final raw = _box.get(_notesKey);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded
        .map((e) => Map<String, dynamic>.from(e))
        .where((note) => note['owner_id'] == userId && note['deleted'] != true)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getCreated() async {
    final notes = await loadNotes();
    return notes.where((note) => note['_id'].contains('test')).toList();
  }

  Future<void> updateNote(Map<String, dynamic> updatedNote) async {
    final notes = await loadNotes();
    final index = notes.indexWhere((note) => note['_id'] == updatedNote['_id']);

    if (index != -1) {
      notes[index]['title'] = updatedNote['title'];
      notes[index]['content'] = updatedNote['content'];
      notes[index]['subject'] = updatedNote['subject'];
      await saveNotes(notes);
    } else {
      throw Exception('Nota con noteId ${updatedNote['_id']} no encontrada');
    }
  }

  Future<void> createNote(Map<String, dynamic> newNote) async {
    final notes = await loadNotes();
    notes.add(newNote);
    await saveNotes(notes);
  }

  Future<void> deleteNoteById(String noteId) async {
    final notes = await loadNotes();
    final index = notes.indexWhere((note) => note['_id'] == noteId);
    if (index != -1) {
      notes[index]['deleted'] = true;
      await saveNotes(notes);
    }
  }

  Future<Map<String, dynamic>> getNote(String noteId) async {
    final notes = await loadNotes();
    return notes.firstWhere((note) => note['_id'] == noteId);
  }

  Future<void> saveFlashcards(
      String subject, List<Map<String, dynamic>> flashcards) async {
    final allFlashcards = await loadAllFlashcards();
    allFlashcards[subject] = flashcards;
    final jsonFlashcards = jsonEncode(allFlashcards);
    await _box.put(_flashcardsKey, jsonFlashcards);
    await _box.flush();
  }

  Future<List<Map<String, dynamic>>> loadFlashcards(String subject) async {
    final allFlashcards = await loadAllFlashcards();
    return allFlashcards[subject] ?? [];
  }

  Future<Map<String, List<Map<String, dynamic>>>> loadAllFlashcards() async {
    final raw = _box.get(_flashcardsKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final result = <String, List<Map<String, dynamic>>>{};

    decoded.forEach((key, value) {
      result[key] = List<Map<String, dynamic>>.from(value);
    });

    return result;
  }
}
