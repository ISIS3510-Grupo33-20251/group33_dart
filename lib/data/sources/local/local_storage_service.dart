import 'package:hive/hive.dart';

class LocalStorageService {
  static const String _notesKey = 'cached_notes';
  static const String _flashcardsKey = 'cached_flashcards';

  final Box _box = Hive.box('storage');

  Future<void> saveNotes(List<Map<String, dynamic>> notes) async {
    await _box.put(_notesKey, notes);
  }

  Future<List<Map<String, dynamic>>> loadNotes() async {
    final notes = _box.get(_notesKey, defaultValue: []);

    final notes_ = List<Map<String, dynamic>>.from(notes);
    return notes_;
  }

  Future<List<Map<String, dynamic>>> getCreated() async {
    final notes = await loadNotes();

    final filteredNotes =
        notes.where((note) => note['_id'].contains('test')).toList();
    return filteredNotes;
  }

  Future<void> closeTest(String noteId) async {
    final notes = await loadNotes();
    final index = notes.indexWhere((note) => note['_id'] == noteId);

    if (index != -1) {
      notes[index]['_id'] = notes[index]['_id'].replaceAll('test', 'loaded');

      await saveNotes(notes);
    } else {
      throw Exception('Nota con noteId $noteId no encontrada');
    }
  }

  Future<void> updateNote(Map<String, dynamic> updatedNote) async {
    final notes = await loadNotes();
    final noteId = updatedNote['_id'];
    final index = notes.indexWhere((note) => note['_id'] == noteId);

    if (index != -1) {
      notes[index]['title'] = updatedNote['title'];
      notes[index]['content'] = updatedNote['content'];
      notes[index]['subject'] = updatedNote['subject'];

      await saveNotes(notes);
    } else {
      throw Exception('Nota con noteId $noteId no encontrada');
    }
  }

  Future<void> createNote(Map<String, dynamic> newNote) async {
    print('New Note: $newNote');
    final notes = await loadNotes();
    notes.add(newNote);
    await saveNotes(notes);
  }

  Future<void> deleteNoteById(String noteId) async {
    final notes = await loadNotes();
    final filteredNotes = notes.where((note) => note['_id'] != noteId).toList();
    await saveNotes(filteredNotes);
  }

  Future<void> saveFlashcards(
      String subject, List<Map<String, dynamic>> flashcards) async {
    final allFlashcards = await loadAllFlashcards();
    allFlashcards[subject] = flashcards;
    await _box.put(_flashcardsKey, allFlashcards);
  }

  Future<List<Map<String, dynamic>>> loadFlashcards(String subject) async {
    final allFlashcards = await loadAllFlashcards();
    return allFlashcards[subject] ?? [];
  }

  Future<Map<String, List<Map<String, dynamic>>>> loadAllFlashcards() async {
    final stored = _box.get(_flashcardsKey, defaultValue: {});
    final result = <String, List<Map<String, dynamic>>>{};
    stored.forEach((key, value) {
      result[key] = List<Map<String, dynamic>>.from(value);
    });
    return result;
  }
}
