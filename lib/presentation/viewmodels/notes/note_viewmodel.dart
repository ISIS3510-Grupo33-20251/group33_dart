import 'package:flutter/foundation.dart';
import '../../../domain/models/note.dart';
import '../../../domain/usecases/notes/get_notes_usecase.dart';

class NoteViewModel extends ChangeNotifier {
  final GetNotesUseCase _getNotesUseCase;
  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;

  NoteViewModel(this._getNotesUseCase);

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> getNotes(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notes = await _getNotesUseCase.execute(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 