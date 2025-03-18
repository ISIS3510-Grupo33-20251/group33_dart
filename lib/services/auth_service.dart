import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static String get baseUrl {
    // Si estamos en debug mode, usamos diferentes URLs dependiendo de la plataforma
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/users/auth'; // Para emulador Android
      } else if (Platform.isIOS) {
        return 'http://127.0.0.1:8000/users/auth'; // Para simulador iOS
      }
    }
    // Para producción o casos no manejados, usa localhost
    return 'http://127.0.0.1:8000/users/auth';
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Attempting to login at: ${baseUrl}/login');
      final response = await http.post(
        Uri.parse('${baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 422) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail']?[0]?['msg'] ?? 'Validation error');
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      print('Error during login: $e');
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      // Extraer el nombre del email (todo antes del @)
      final name = email.split('@')[0];
      
      print('Attempting to register at: ${baseUrl}/register');
      final response = await http.post(
        Uri.parse('${baseUrl}/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'name': name,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 422) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail']?[0]?['msg'] ?? 'Validation error');
      } else {
        throw Exception('Failed to register: ${response.body}');
      }
    } catch (e) {
      print('Error during registration: $e');
      throw Exception('Failed to connect to server: $e');
    }
  }
} 