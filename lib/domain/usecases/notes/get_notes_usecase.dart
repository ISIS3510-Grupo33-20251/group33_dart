import '../../models/note.dart';
import '../../repositories/note_repository.dart';

class GetNotesUseCase {
  final NoteRepository repository;

  GetNotesUseCase(this.repository);

  Future<List<Note>> execute(String userId) {
    return repository.getNotes(userId);
  }
} 