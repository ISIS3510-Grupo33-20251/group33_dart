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
      final user = await registerUseCase.execute(email, password);
      userId = user.id;  // Actualizando la variable global
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
} 