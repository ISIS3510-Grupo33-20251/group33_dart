import '../models/note.dart';

abstract class NoteRepository {
  Future<List<Note>> getNotes(String userId);
  Future<Note> createNote(Note note);
  Future<Note> updateNote(Note note);
  Future<void> deleteNote(String noteId);
  Future<List<String>> getSubjects(String userId);
} 