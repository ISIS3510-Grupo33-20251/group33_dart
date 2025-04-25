import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiServiceAdapter {
  final String backendUrl;

  ApiServiceAdapter({required this.backendUrl});

  String get authBaseUrl {
    // Si estamos en debug mode, usamos diferentes URLs dependiendo de la plataforma
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return '${backendUrl}/users/auth'; // Para emulador Android
      } else if (Platform.isIOS) {
        return '${backendUrl}/users/auth'; // Para simulador iOS
      }
    }
    // Para producción o casos no manejados, usa localhost
    return 'http://127.0.0.1:8000/users/auth';
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Attempting to login at: ${authBaseUrl}/login');
      final response = await http.post(
        Uri.parse('${authBaseUrl}/login'),
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

  Future<Map<String, dynamic>> register(String email, String password,
      {String? name}) async {
    try {
      // Si no se proporciona el nombre, extraerlo del email
      final userName = name ?? email.split('@')[0];

      print('Attempting to register at: ${authBaseUrl}/register');
      final response = await http.post(
        Uri.parse('${authBaseUrl}/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'name': userName,
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

  Future<List<Map<String, dynamic>>> fetchNotes(String endpoint) async {
    final response = await http.get(Uri.parse("$backendUrl/$endpoint"));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception("Error al obtener datos de $endpoint");
    }
  }

  Future<void> createNote(
    String title,
    String content,
    String subject,
    String userId,
  ) async {
    final response = await http.post(
      Uri.parse("$backendUrl/notes/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "title": title.trim(),
        "content": content,
        "subject": subject.trim(),
        "created_date": '2024-03-07T12:00:00Z',
        "last_modified": '2024-03-07T12:00:00Z',
        "owner_id": userId
      }),
    );

    if (response.statusCode == 200) {
      final noteId = json.decode(response.body)["_id"];
      final responseTags = await http.post(
        Uri.parse("$backendUrl/users/$userId/notes/$noteId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),
      );

      if (responseTags.statusCode != 200) {
        throw Exception("Error adding tags to the note");
      }
    } else {
      throw Exception("Error creating note");
    }
  }

  Future<void> updateNote(
    String noteId,
    String title,
    String content,
    String subject,
    String createdDate,
    String lastModified,
    String userId,
  ) async {
    final response = await http.put(
      Uri.parse("$backendUrl/notes/$noteId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "title": title.trim(),
        "content": content,
        "subject": subject.trim(),
        "created_date": createdDate,
        "last_modified": lastModified,
        "owner_id": userId
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Error updating note");
    }
  }

  Future<void> deleteNote(String noteId) async {
    final response = await http.delete(
      Uri.parse("$backendUrl/notes/$noteId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({}),
    );

    if (response.statusCode != 200) {
      throw Exception("Error deleting note");
    }
  }

  Future<List<Map<String, dynamic>>> fetchFlashcards(
      String userId, String subject) async {
    final response =
        await http.get(Uri.parse("$backendUrl/users/$userId/$subject/flash/"));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception("Error");
    }
  }

  Future<void> updateUserLocationHttp(
      String userId, double latitude, double longitude) async {
    final url = Uri.parse('$backendUrl/users/$userId/location');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update location');
    }
  }

  Future<List<dynamic>> fetchNearbyFriendsHttp(String userId) async {
    final url = Uri.parse('$backendUrl/users/$userId/friends/location');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch friends');
    }
  }

  Future<void> sendFriendRequest(String senderId, String receiverEmail) async {
    final response = await http.post(
      Uri.parse('$backendUrl/friend_requests/by_email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'senderId': senderId,
        'email': receiverEmail,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send friend request: ${response.body}');
    }
  }

  Future<List<dynamic>> getPendingRequests(String userId) async {
    final response = await http.get(
      Uri.parse('$backendUrl/friend_requests/pending/$userId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch pending requests: ${response.body}');
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final response = await http.post(
      Uri.parse('$backendUrl/friend_requests/$requestId/accept'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to accept request: ${response.body}');
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    final response = await http.post(
      Uri.parse('$backendUrl/friend_requests/$requestId/reject'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reject request: ${response.body}');
    }
  }

  Future<void> addFriend(String userId, String friendId) async {
    final response = await http.post(
      Uri.parse('$backendUrl/users/$userId/friends/$friendId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add friend: ${response.body}');
    }
  }

  Future<void> removeFriend(String userId, String friendId) async {
    final response = await http.delete(
      Uri.parse('$backendUrl/users/$userId/friends/$friendId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove friend: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchUserById(String userId) async {
    final response = await http.get(Uri.parse('$backendUrl/users/$userId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch user');
    }
  }

  // Schedule endpoints
  Future<List<Map<String, dynamic>>> getSchedules() async {
    final response = await http.get(
      Uri.parse('$backendUrl/schedules/'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch schedules');
    }
  }

  Future<Map<String, dynamic>> createSchedule(String userId) async {
    final response = await http.post(
      Uri.parse('$backendUrl/schedules/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create schedule');
    }
  }

  Future<Map<String, dynamic>> getSchedule(String scheduleId) async {
    final response = await http.get(
      Uri.parse('$backendUrl/schedules/$scheduleId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch schedule');
    }
  }

  Future<void> updateSchedule(
      String scheduleId, List<Map<String, dynamic>> meetings) async {
    final response = await http.put(
      Uri.parse('$backendUrl/schedules/$scheduleId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'meetings': meetings,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update schedule');
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    final response = await http.delete(
      Uri.parse('$backendUrl/schedules/$scheduleId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete schedule');
    }
  }

  Future<List<Map<String, dynamic>>> getScheduleMeetings(
      String scheduleId) async {
    final response = await http.get(
      Uri.parse('$backendUrl/schedules/$scheduleId/meetings'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch meetings');
    }
  }

  Future<void> addMeetingToSchedule(
      String scheduleId, Map<String, dynamic> meeting) async {
    final response = await http.post(
      Uri.parse('$backendUrl/schedules/$scheduleId/meetings'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(meeting),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add meeting');
    }
  }

  Future<void> removeMeetingFromSchedule(
      String scheduleId, String meetingId) async {
    final response = await http.delete(
      Uri.parse('$backendUrl/schedules/$scheduleId/meetings/$meetingId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to remove meeting');
    }
  }
}
