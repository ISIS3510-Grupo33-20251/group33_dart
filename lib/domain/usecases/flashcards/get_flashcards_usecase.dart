import '../../models/flashcard.dart';
import '../../repositories/flashcard_repository.dart';

class GetFlashcardsUseCase {
  final FlashcardRepository repository;

  GetFlashcardsUseCase(this.repository);

  Future<List<Flashcard>> execute(String userId, String subject) {
    return repository.getFlashcards(userId, subject);
  }
} 