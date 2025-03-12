import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String baseUrl = 'http://127.0.0.1:8000';
  final storage = const FlutterSecureStorage();

  Future<bool> login(String email, String password) async {
    try {
      print("📡 Sending Login Request...");

      final response = await http.post(
        Uri.parse('$baseUrl/users/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print("➡️ URL: $baseUrl/users/auth/login");
      print("➡️ Headers: {'Content-Type': 'application/json'}");
      print("➡️ Payload: ${jsonEncode({'email': email, 'password': password})}");

      // 🚀 Verificar si el servidor respondió
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'token', value: data['token']);
        print("✅ Login successful! Token saved: ${data['token']}");
        return true;
      } else {
        print("❌ Login failed with status ${response.statusCode}");
        print("🛑 Response body: ${response.body}");
        return false;
      }

    } catch (e) {
      print("🚨 Exception in login request: $e");
      return false;
    }
  }



  Future<void> logout() async {
    await storage.delete(key: 'token');
    print("🚪 Logged out. Token removed.");
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }
}
