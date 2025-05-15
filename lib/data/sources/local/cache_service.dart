import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:group33_dart/presentation/widgets/friends/friend.dart';


class CacheService {
  final CacheManager _cache = DefaultCacheManager();
  static const String _lastScheduleUpdateKey = 'last_schedule_update';
  static const String _profileImageKey = 'profile_image_path';

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

  Future<void> cacheLastScheduleUpdate(Map<String, dynamic> updateData) async {
    final jsonString = jsonEncode(updateData);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    await _cache.putFile(
      _lastScheduleUpdateKey,
      bytes,
      fileExtension: 'json',
    );
  }

  Future<Map<String, dynamic>?> loadLastScheduleUpdate() async {
    final fileInfo = await _cache.getFileFromCache(_lastScheduleUpdateKey);
    if (fileInfo == null) return null;

    try {
      final jsonString = await fileInfo.file.readAsString();
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error loading last schedule update: $e');
      return null;
    }
  }

  Future<void> removeLastScheduleUpdate() async {
    await _cache.removeFile(_lastScheduleUpdateKey);
  }tatic const String _friendLocationsKey = 'cached_friend_locations';

  Future<void> cacheFriendLocations(Map<String, Friend> friendMap) async {
    final dataList = friendMap.values.map((f) => f.toJson()).toList();
    final jsonString = jsonEncode(dataList);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    await _cache.putFile(
      _friendLocationsKey,
      bytes,
      fileExtension: 'json',
    );
  }

  Future<Map<String, Friend>> loadCachedFriendLocations() async {
    final fileInfo = await _cache.getFileFromCache(_friendLocationsKey);
    if (fileInfo == null) return {};

    try {
      final jsonString = await fileInfo.file.readAsString();
      final List<dynamic> list = jsonDecode(jsonString);
      final Map<String, Friend> result = {};
      for (var item in list) {
        final friend = Friend.fromJson(item);
        result[friend.email] = friend;
      }
      return result;
    } catch (e) {
      print('Error loading cached friend locations: $e');
      return {};
    }
  }

  Future<void> cacheProfileImage(String imagePath) async {
    await _cache.putFile(
      _profileImageKey,
      Uint8List.fromList(imagePath.codeUnits),
      fileExtension: 'txt',
    );
  }

  Future<String?> loadCachedProfileImage() async {
    final fileInfo = await _cache.getFileFromCache(_profileImageKey);
    if (fileInfo == null) return null;
    try {
      final path = await fileInfo.file.readAsString();
      return path;
    } catch (e) {
      print('Error loading cached profile image path: $e');
      return null;
    }
  }
