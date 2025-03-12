import 'package:flutter/material.dart';
import 'package:group33_dart/core/network/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    bool success = await _authService.login(email, password);

    _isLoading = false;
    notifyListeners();

    if (success) {
      print("🎉 AuthViewModel: Login successful!");
    } else {
      print("⚠️ AuthViewModel: Login failed.");
    }

    return success;
  }

  Future<void> logout() async {
    await _authService.logout();
    print("🚪 AuthViewModel: User logged out.");
  }
}

