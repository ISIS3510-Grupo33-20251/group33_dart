import 'package:flutter/foundation.dart';
import '../../../domain/usecases/auth/login_usecase.dart';
import '../../../globals.dart';

class LoginViewModel extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  bool isLoading = false;
  String? error;

  LoginViewModel(this.loginUseCase);

  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final user = await loginUseCase.execute(email, password);
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