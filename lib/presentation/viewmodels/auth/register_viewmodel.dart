import 'package:flutter/foundation.dart';
import '../../../domain/usecases/auth/register_usecase.dart';
import '../../../globals.dart';

class RegisterViewModel extends ChangeNotifier {
  final RegisterUseCase registerUseCase;
  bool isLoading = false;
  String? error;

  RegisterViewModel(this.registerUseCase);

  Future<bool> register(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final success = await registerUseCase.execute(email, password);
      // Set a default userId since we don't get it from the usecase anymore
      userId = email.split('@')[0]; // Use email username as user ID temporarily
      isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
} 