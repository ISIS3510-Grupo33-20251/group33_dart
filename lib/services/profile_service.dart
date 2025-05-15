import 'package:flutter/material.dart';
import '../domain/models/student_profile.dart';
import 'dart:io';
import '../data/sources/local/cache_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../globals.dart';
import 'api_service_adapter.dart';

class ProfileService extends ChangeNotifier {
  StudentProfile _profile = StudentProfile.empty();
  final CacheService _cacheService = CacheService();

  StudentProfile get profile => _profile;

  ProfileService() {
    _initProfileFromBackend();
  }

  Future<void> _initProfileFromBackend() async {
    if (_profile.name == 'Your Name' && userId.isNotEmpty) {
      try {
        final url = Uri.parse('$backendUrl/users/$userId');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['name'] != null && data['name'].toString().isNotEmpty) {
            _profile = StudentProfile(
              name: data['name'],
              imageUrl: _profile.imageUrl,
              semester: _profile.semester,
            );
            notifyListeners();
          }
        }
      } catch (e) {
        // ignore error, fallback to default
      }
    }
  }

  void updateProfile({String? name, String? imageUrl, int? semester}) async {
    final oldName = _profile.name;
    print('[ProfileService] updateProfile called. Old name: '
        '[33m$oldName[0m, New name: [32m$name[0m');
    _profile = StudentProfile(
      name: name ?? _profile.name,
      imageUrl: imageUrl ?? _profile.imageUrl,
      semester: semester ?? _profile.semester,
    );
    notifyListeners();
    // Si el nombre cambió y hay userId, actualizar en el backend
    if (name != null && name != oldName && userId.isNotEmpty) {
      print(
          '[ProfileService] Attempting to update name in backend for userId: $userId');
      try {
        final api = ApiServiceAdapter(backendUrl: backendUrl);
        await api.updateUserName(userId, name);
        print('[ProfileService] Name updated successfully in backend.');
      } catch (e) {
        print('[ProfileService] Error updating name in backend: $e');
      }
    } else {
      print(
          '[ProfileService] Name not changed or userId missing, skipping backend update.');
    }
  }

  void updateSemester(int semester) {
    _profile = StudentProfile(
      name: _profile.name,
      imageUrl: _profile.imageUrl,
      semester: semester,
    );
    notifyListeners();
  }

  // NUEVO: Guardar imagen localmente y actualizar el perfil
  Future<void> setProfileImage(File imageFile) async {
    // Guardar la imagen en caché usando CacheService
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'profile_image.jpg';
    final savedImage = await imageFile.copy('${appDir.path}/$fileName');
    // Opcional: podrías usar _cacheService para guardar la ruta
    await _cacheService.cacheProfileImage(savedImage.path);
    _profile = StudentProfile(
      name: _profile.name,
      imageUrl: savedImage.path,
      semester: _profile.semester,
    );
    notifyListeners();
  }

  // NUEVO: Obtener la imagen cacheada
  Future<String?> getCachedProfileImage() async {
    return await _cacheService.loadCachedProfileImage();
  }
}
