import '../models/flashcard.dart';

abstract class FlashcardRepository {
  Future<List<Flashcard>> getFlashcards(String userId, String subject);
  Future<Flashcard> createFlashcard(Flashcard flashcard);
  Future<Flashcard> updateFlashcard(Flashcard flashcard);
  Future<void> deleteFlashcard(String flashcardId);
  Future<List<String>> getSubjects(String userId);
} 