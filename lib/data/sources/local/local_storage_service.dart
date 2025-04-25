import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:group33_dart/globals.dart';

class LocalStorageService {
  static const String _notesKey = 'cached_notes';
  static const String _actionQueueKey = 'cached_queue';
  static const String _friendsKey = 'cached_friends';

  Box get _box => Hive.box('storage');

  Future<void> ensureBoxIsOpen() async {
    if (!Hive.isBoxOpen('storage')) {
      await Hive.openBox('storage'); // Abre el box si no está abierto
    }
  }

  Future<void> saveActionQueue(List<Map<String, String>> actionQueue) async {
    final jsonQueue = jsonEncode(actionQueue);
    await _box.put(_actionQueueKey, jsonQueue);
    await _box.flush();
  }

  Future<List<Map<String, String>>> loadActionQueue() async {
    await ensureBoxIsOpen();
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
    await ensureBoxIsOpen();
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
  Future<void> saveFriends(List<Map<String, dynamic>> friends) async {
  final jsonFriends = jsonEncode(friends);
  await _box.put('cached_friends', jsonFriends);
  await _box.flush();
}

Future<List<Map<String, dynamic>>> loadFriends() async {
  await ensureBoxIsOpen();
  final raw = _box.get('cached_friends');
  if (raw == null) return [];
  final List<dynamic> decoded = jsonDecode(raw);
  return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
}

}
