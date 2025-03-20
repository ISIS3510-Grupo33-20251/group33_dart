import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../globals.dart';

class AuthRepositoryImpl implements AuthRepository {
  final storage = const FlutterSecureStorage();
  final String baseUrl = '$backendUrl/users/auth';

  @override
  Future<User> login(String email, String password) async {
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
        return User(
          id: data['userId'],
          email: email,
          name: email.split('@')[0], // Usando el email como nombre por defecto
        );
      } else if (response.statusCode == 422) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail']?[0]?['msg'] ?? 'Validation error');
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  @override
  Future<User> register(String email, String password) async {
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
        return User(
          id: data['userId'],
          email: email,
          name: name,
        );
      } else if (response.statusCode == 422) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail']?[0]?['msg'] ?? 'Validation error');
      } else {
        throw Exception('Failed to register: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  @override
  Future<void> logout() async {
    await storage.delete(key: 'token');
  }

  @override
  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }
} 