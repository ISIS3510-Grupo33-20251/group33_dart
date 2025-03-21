import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../globals.dart';

class AuthRepositoryImpl implements AuthRepository {
  final storage = const FlutterSecureStorage();
  final String baseUrl = '$backendUrl/users/auth';
  final SharedPreferences _prefs;
  static const String _tokenKey = 'auth_token';

  AuthRepositoryImpl(this._prefs);

  @override
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await storage.write(key: 'token', value: data['token']);
        await _prefs.setString(_tokenKey, data['token']);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> register(String email, String password) async {
    try {
      final name = email.split('@')[0];
      
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'name': name,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await storage.write(key: 'token', value: data['token']);
        await _prefs.setString(_tokenKey, data['token']);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> logout() async {
    await storage.delete(key: 'token');
    await _prefs.remove(_tokenKey);
  }

  @override
  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = _prefs.getString(_tokenKey);
    return token != null;
  }
} 