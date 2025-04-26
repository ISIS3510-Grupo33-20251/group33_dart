import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../domain/models/friend.dart';

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

  // Meetings endpoints
  Future<Map<String, dynamic>> createMeeting(
      Map<String, dynamic> meetingData) async {
    try {
      // Imprimir el JSON que se va a enviar
      String jsonString = json.encode({
        '_id': meetingData['_id'],
        'title': meetingData['title'],
        'description': meetingData['description'],
        'start_time': meetingData['start_time'],
        'end_time': meetingData['end_time'],
        'location': meetingData['location'],
        'meeting_link': meetingData['meeting_link'],
        'host_id': meetingData['host_id'],
        'participants': meetingData['participants'] ?? [],
      });

      // Crear la URL
      final url = Uri.parse('$backendUrl/meetings/');
      print('Sending request to: $url'); // Imprimir la URL

      // Imprimir el comando curl
      print(
          'curl -X POST $url -H "Content-Type: application/json" -d \'$jsonString\'');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonString,
      );

      print('Create meeting response status: ${response.statusCode}');
      print('Create meeting response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw Exception('Failed to create meeting: ${response.body}');
    } catch (e) {
      print('Error creating meeting: $e');
      throw Exception('Failed to create meeting: $e');
    }
  }

  Future<void> deleteMeeting(String meetingId) async {
    final response = await http.delete(
      Uri.parse('$backendUrl/meetings/$meetingId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete meeting: ${response.body}');
    }
  }

  // Schedule endpoints
  Future<List<Map<String, dynamic>>> getSchedules() async {
    final response = await http.get(Uri.parse('$backendUrl/schedules/'));

    if (response.statusCode == 200) {
      List<dynamic> schedules = json.decode(response.body);
      return schedules.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to get schedules: ${response.body}');
  }

  Future<Map<String, dynamic>> createSchedule(
      Map<String, dynamic> scheduleData) async {
    final response = await http.post(
      Uri.parse('$backendUrl/schedules/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(scheduleData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create schedule: ${response.body}');
  }

  Future<List<Map<String, dynamic>>> getScheduleMeetings(
      String scheduleId) async {
    final response = await http.get(
      Uri.parse('$backendUrl/schedules/$scheduleId/meetings'),
    );

    if (response.statusCode == 200) {
      List<dynamic> meetings = json.decode(response.body);
      return meetings.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to get schedule meetings: ${response.body}');
  }

  Future<void> addMeetingToSchedule(String scheduleId, String meetingId) async {
    final response = await http.post(
      Uri.parse('$backendUrl/schedules/$scheduleId/meetings/$meetingId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add meeting to schedule: ${response.body}');
    }
  }

  Future<void> removeMeetingFromSchedule(
      String scheduleId, String meetingId) async {
    final response = await http.delete(
      Uri.parse('$backendUrl/schedules/$scheduleId/meetings/$meetingId'),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to remove meeting from schedule: ${response.body}');
    }
  }

  // Nuevo método para obtener la lista de amigos
  Future<List<Friend>> getFriendsList(String userId) async {
    final response = await http.get(
      Uri.parse('$backendUrl/users/$userId/friends'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      List<dynamic> friendsJson = json.decode(response.body);
      return friendsJson.map((json) => Friend.fromJson(json)).toList();
    }
    throw Exception('Failed to get friends list: ${response.body}');
  }

  // Nuevo método para añadir participantes a una reunión
  Future<void> addParticipantsToMeeting(
      String meetingId, List<String> participantIds) async {
    final response = await http.post(
      Uri.parse('$backendUrl/meetings/$meetingId/participants'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'participant_ids': participantIds,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to add participants to meeting: ${response.body}');
    }
  }

  // Nuevo método para remover participantes de una reunión
  Future<void> removeParticipantFromMeeting(
      String meetingId, String participantId) async {
    final response = await http.delete(
      Uri.parse('$backendUrl/meetings/$meetingId/participants/$participantId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to remove participant from meeting: ${response.body}');
    }
  }

  // Nuevo método para obtener los participantes de una reunión
  Future<List<Friend>> getMeetingParticipants(String meetingId) async {
    final response = await http.get(
      Uri.parse('$backendUrl/meetings/$meetingId/participants'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      List<dynamic> participantsJson = json.decode(response.body);
      return participantsJson.map((json) => Friend.fromJson(json)).toList();
    }
    throw Exception('Failed to get meeting participants: ${response.body}');
  }
}

Future<bool> hasInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('example.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
