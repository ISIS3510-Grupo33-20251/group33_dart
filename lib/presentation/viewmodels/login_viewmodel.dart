import 'package:flutter/foundation.dart';
import '../../domain/usecases/login_usecase.dart';

class LoginViewModel extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  String? error;
  bool isLoading = false;

  LoginViewModel(this._loginUseCase);

  Future<bool> login(String email, String password) async {
    error = null;
    isLoading = true;
    notifyListeners();

    try {
      final success = await _loginUseCase.execute(email, password);
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