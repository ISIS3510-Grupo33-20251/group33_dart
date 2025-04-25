import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CacheService {
  final CacheManager _cache = DefaultCacheManager();

  Future<void> cacheFlashcard(
      String key, List<Map<String, dynamic>> data) async {
    final jsonString = jsonEncode(data);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    await _cache.putFile(
      key,
      bytes,
      fileExtension: 'json',
    );
  }

  Future<List<Map<String, dynamic>>> loadCachedFlashcard(String key) async {
    final fileInfo = await _cache.getFileFromCache(key);
    if (fileInfo == null) return [];

    try {
      final jsonString = await fileInfo.file.readAsString();
      final dynamic jsonData = jsonDecode(jsonString);
      return (jsonData as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      print('Error parsing cached data for key=$key: $e');
      return [];
    }
  }

  Future<void> removeCachedFlashcard(String key) async {
    await _cache.removeFile(key);
  }
  Future<void> cacheUserLocation(Map<String, double> location) async {
  final jsonString = jsonEncode(location);
  final bytes = Uint8List.fromList(utf8.encode(jsonString));
  await _cache.putFile(
    'last_user_location',
    bytes,
    fileExtension: 'json',
  );
}

Future<Map<String, double>?> loadCachedUserLocation() async {
  final fileInfo = await _cache.getFileFromCache('last_user_location');
  if (fileInfo == null) return null;

  try {
    final jsonString = await fileInfo.file.readAsString();
    final data = jsonDecode(jsonString);
    return {
      'latitude': (data['latitude'] ?? 0.0).toDouble(),
      'longitude': (data['longitude'] ?? 0.0).toDouble(),
    };
  } catch (e) {
    print('Error loading cached user location: $e');
    return null;
  }
}
}
