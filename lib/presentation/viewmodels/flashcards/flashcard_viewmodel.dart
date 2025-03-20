import 'package:flutter/foundation.dart';
import '../../../domain/models/flashcard.dart';
import '../../../domain/usecases/flashcards/get_flashcards_usecase.dart';

class FlashcardViewModel extends ChangeNotifier {
  final GetFlashcardsUseCase _getFlashcardsUseCase;
  List<Flashcard> _flashcards = [];
  bool _isLoading = false;
  String? _error;

  FlashcardViewModel(this._getFlashcardsUseCase);

  List<Flashcard> get flashcards => _flashcards;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> getFlashcards(String userId, String subject) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _flashcards = await _getFlashcardsUseCase.execute(userId, subject);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 