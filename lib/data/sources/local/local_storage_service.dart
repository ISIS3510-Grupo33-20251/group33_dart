import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:group33_dart/globals.dart';
import '../../../domain/models/class_model.dart';

class LocalStorageService {
  static const String _notesKey = 'cached_notes';
  static const String _actionQueueKey = 'cached_queue';
  static const String _friendsKey = 'cached_friends';
  static const String _classesKey = 'cached_classes';
  static const String _scheduleIdKey = 'schedule_id';

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

  // Schedule methods
  Future<void> saveScheduleId(String id) async {
    await _box.put(_scheduleIdKey, id);
    await _box.flush();
  }

  String? getScheduleId() {
    return _box.get(_scheduleIdKey);
  }

  Future<void> saveClasses(List<ClassModel> classes) async {
    final jsonClasses = jsonEncode(classes.map((c) => c.toJson()).toList());
    await _box.put(_classesKey, jsonClasses);
    await _box.flush();
  }

  Future<List<ClassModel>> loadClasses() async {
    await ensureBoxIsOpen();
    final raw = _box.get(_classesKey);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => ClassModel.fromJson(e)).toList();
  }

  Future<void> addClass(ClassModel classModel) async {
    final classes = await loadClasses();
    classes.add(classModel);
    await saveClasses(classes);
  }

  Future<void> removeClass(String classId) async {
    final classes = await loadClasses();
    classes.removeWhere((c) => c.id == classId);
    await saveClasses(classes);
  }
  Future<void> saveReminders(List<Map<String, dynamic>> reminders) async {
  final box = await Hive.openBox('reminders');
  await box.put('reminders', reminders);
}
Future<List<Map<String, dynamic>>> loadReminders() async {
  final box = await Hive.openBox('reminders');
  final data = box.get('reminders');
  if (data == null || data is! List) return [];
  return data.cast<Map<String, dynamic>>();
}
Future<Map<String, dynamic>> getReminder(String id) async {
  final box = await Hive.openBox('reminders');
  final List<dynamic> reminders = box.get('reminders') ?? [];
  final reminder = reminders
    .cast<Map<String, dynamic>>()
    .firstWhere((e) => e['_id'] == id, orElse: () => throw Exception('Reminder with ID $id not found'));
return reminder;
}
Future<void> updateReminder(Map<String, dynamic> updatedReminder) async {
  final box = await Hive.openBox('reminders');
  final List<dynamic> reminders = box.get('reminders') ?? [];

  final index = reminders.indexWhere((r) => r['_id'] == updatedReminder['_id']);

  if (index != -1) {
    reminders[index] = updatedReminder;
  } else {
    reminders.add(updatedReminder); // fallback
  }

  await box.put('reminders', reminders);
}



}
