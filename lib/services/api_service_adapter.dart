import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../domain/models/friend.dart';
import '../domain/models/reminder.dart';

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
    return '$backendUrl/users/auth';
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
      print('Failed to fetch friends');
      print(userId);
      print(response.statusCode);
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
      // Validación básica
      if (meetingData['title'] == null || meetingData['title'].trim().isEmpty) {
        throw Exception('Title is required');
      }
      if (meetingData['start_time'] == null ||
          meetingData['end_time'] == null) {
        throw Exception('Start and end time are required');
      }

      // Asegúrate de que las fechas sean ISO 8601
      final startTime = meetingData['start_time'] is DateTime
          ? meetingData['start_time']
          : DateTime.parse(meetingData['start_time']);
      final endTime = meetingData['end_time'] is DateTime
          ? meetingData['end_time']
          : DateTime.parse(meetingData['end_time']);

      String jsonString = json.encode({
        'title': meetingData['title'],
        'description': meetingData['description'],
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'location': meetingData['location'],
        'meeting_link': meetingData['meeting_link'],
        'host_id': meetingData['host_id'],
        'participants': meetingData['participants'] ?? [],
        'color': meetingData['color'],
        'day_of_week': meetingData['day_of_week'],
      });

      final url = Uri.parse('$backendUrl/meetings/');
      print('Sending request to: $url');
      print('Request body: $jsonString');

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
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/schedules/$scheduleId/meetings'),
      );

      print('Schedule meetings response status: ${response.statusCode}');
      print('Schedule meetings response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedResponse = json.decode(response.body);
        List<Map<String, dynamic>> meetings = [];

        // Verificar si la respuesta es una lista
        if (decodedResponse is List) {
          // Para cada ID de reunión, obtener sus detalles
          for (var item in decodedResponse) {
            String meetingId;
            if (item is Map && item.containsKey('_id')) {
              meetingId = item['_id'];
            } else if (item is String) {
              meetingId = item;
            } else {
              print('Unexpected item format: $item');
              continue;
            }

            try {
              // Obtener los detalles de la reunión
              final meetingResponse = await http.get(
                Uri.parse('$backendUrl/meetings/$meetingId'),
              );

              if (meetingResponse.statusCode == 200) {
                final meetingData = json.decode(meetingResponse.body);
                if (meetingData is Map) {
                  meetings.add(Map<String, dynamic>.from(meetingData));
                }
              } else {
                print('Failed to get meeting details for ID: $meetingId');
              }
            } catch (e) {
              print('Error getting meeting details for ID: $meetingId - $e');
            }
          }
        } else if (decodedResponse is Map) {
          // Si la respuesta es un solo objeto
          meetings.add(Map<String, dynamic>.from(decodedResponse));
        }

        print('Processed ${meetings.length} meetings with full details');
        return meetings;
      }
      throw Exception('Failed to get schedule meetings: ${response.body}');
    } catch (e) {
      print('Error in getScheduleMeetings: $e');
      throw Exception('Failed to get schedule meetings: $e');
    }
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

  // Actualizar el nombre del usuario en el backend
  Future<void> updateUserName(String userId, String newName) async {
    // Obtener datos actuales del usuario
    final user = await fetchUserById(userId);
    final url = Uri.parse('$backendUrl/users/$userId');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': newName,
        'email': user['email'],
        'password': user['password'],
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update user name: \\${response.body}');
    }
  }

  Future<Map<String, dynamic>> createKanbanTaskOnBackend({
    required String title,
    required String description,
    required DateTime dueDate,
    required String priority,
    required String status,
    required String userId,
    String? assigneeId,
  }) async {
    final url = Uri.parse('$backendUrl/tasks/');
    final response = await http.post(
      url,
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'due_date': dueDate.toIso8601String(),
        'priority': priority,
        'status': status,
        'user_id': userId,
        'assignee_id': assigneeId ?? userId,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create task: ${response.body}');
    }
  }

  Future<void> deleteKanbanTaskOnBackend(String taskId) async {
    final url = Uri.parse('$backendUrl/tasks/$taskId');
    final response = await http.delete(
      url,
      headers: {'accept': 'application/json'},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to delete task: ${response.body}');
    }
  }

  Future<void> updateKanbanTaskOnBackend({
    required String id,
    required String title,
    required String description,
    required DateTime dueDate,
    required String priority,
    required String status,
    required String userId,
    String? assigneeId,
  }) async {
    final url = Uri.parse('$backendUrl/tasks/$id');
    final response = await http.put(
      url,
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'due_date': dueDate.toIso8601String(),
        'priority': priority,
        'status': status,
        'user_id': userId,
        'assignee_id': assigneeId ?? userId,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to update task: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getKanbanTaskById(String id) async {
    final url = Uri.parse('$backendUrl/tasks/$id');
    final response = await http.get(
      url,
      headers: {'accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get task: ${response.body}');
    }
  }

  Future<String> getKanbanIdByUser(String userId) async {
    final url = Uri.parse('$backendUrl/users/$userId/kanban');
    final response = await http.get(
      url,
      headers: {'accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['kanban_id'];
    } else {
      throw Exception('Failed to get kanban id: ${response.body}');
    }
  }

  Future<void> addTaskToKanban(String kanbanId, String taskId) async {
    final url = Uri.parse('$backendUrl/kanban/$kanbanId/tasks/$taskId');
    final response = await http.post(
      url,
      headers: {'accept': 'application/json'},
      body: '',
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add task to kanban: ${response.body}');
    }
  }

  Future<void> removeTaskFromKanban(String kanbanId, String taskId) async {
    final url = Uri.parse('$backendUrl/kanban/$kanbanId/tasks/$taskId');
    final response = await http.delete(
      url,
      headers: {'accept': 'application/json'},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to remove task from kanban: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getTasksForKanban(String kanbanId) async {
    final url = Uri.parse('$backendUrl/kanban/$kanbanId');
    final response = await http.get(
      url,
      headers: {'accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> allTaskIds = data['all_tasks'] ?? [];
      List<Map<String, dynamic>> tasks = [];
      for (var taskId in allTaskIds) {
        try {
          final task = await getKanbanTaskById(taskId);
          tasks.add(task);
        } catch (e) {
          // If a task is not found, skip it
          continue;
        }
      }
      return tasks;
    } else {
      throw Exception('Failed to get kanban tasks: ${response.body}');
    }
  }
  // Crear recordatorio
Future<void> createReminder(Reminder reminder) async {
  final url = Uri.parse('$backendUrl/reminders/');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(reminder.toJson()),
  );
  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception('Failed to create reminder: ${response.body}');
  }
}

Future<List<Reminder>> getRemindersForUser(String userId) async {
  final url = Uri.parse('$backendUrl/reminders/user/$userId');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List decoded = jsonDecode(response.body);
    return decoded.map((e) => Reminder.fromJson(e)).toList();
  }

  throw Exception('Failed to fetch reminders: ${response.body}');
}




Future<List<Reminder>> getRemindersForTask(String taskId) async {
  final url = Uri.parse('$backendUrl/reminders/task/$taskId');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final List decoded = jsonDecode(response.body);
    return decoded.map((e) => Reminder.fromJson(e)).toList();
  }
  throw Exception('Failed to fetch task reminders: ${response.body}');
}

Future<List<Reminder>> getRemindersForMeeting(String meetingId) async {
  final url = Uri.parse('$backendUrl/reminders/meeting/$meetingId');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final List decoded = jsonDecode(response.body);
    return decoded.map((e) => Reminder.fromJson(e)).toList();
  }
  throw Exception('Failed to fetch meeting reminders: ${response.body}');
}


Future<void> updateReminder(Reminder reminder) async {
  final url = Uri.parse('$backendUrl/reminders/${reminder.id}');
  final response = await http.put(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(reminder.toJson()),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to update reminder: ${response.body}');
  }
}


Future<void> deleteReminder(String reminderId) async {
  final url = Uri.parse('$backendUrl/reminders/$reminderId');
  final response = await http.delete(url);
  if (response.statusCode != 200) {
    throw Exception('Failed to delete reminder: ${response.body}');
  }
}
Future<void> updateReminderStatus(String reminderId, String newStatus) async {
  final response = await http.put(
    Uri.parse('$backendUrl/reminders/$reminderId/status'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'status': newStatus}),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to update reminder status');
  }
}
Future<void> createReminderFromJson(Map<String, dynamic> json) async {
  final url = Uri.parse('$backendUrl/reminders/');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(json),
  );
  if (response.statusCode != 201 && response.statusCode != 200) {
    throw Exception('Failed to create reminder from JSON');
  }
}

Future<void> updateReminderFromJson(String id, Map<String, dynamic> json) async {
  final Map<String, dynamic> sanitizedJson = Map.of(json)..remove('_id');
  final url = Uri.parse('$backendUrl/reminders/$id');
  final response = await http.put(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(sanitizedJson),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to update reminder from JSON');
  }
}



  Future<Map<String, List<Map<String, String>>>> getCalcInfo(
      String userId) async {
    final response = await http.get(
      Uri.parse('$backendUrl/calculator/user/$userId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> datos = jsonDecode(response.body);
      final Map<String, List<Map<String, String>>> datosConvertidos = {};

      for (var item in datos) {
        final String nombreMateria = item['subject_name'];
        final List<Map<String, String>> entradas = [];

        for (var entrada in item['entries']) {
          entradas.add({
            'name': entrada['name'].toString(),
            'grade': entrada['grade'].toString(),
            'percent': entrada['percentage'].toString(),
          });
        }

        datosConvertidos[nombreMateria] = entradas;
      }

      return datosConvertidos;
    } else {
      throw Exception('Failed to fetch calculator info: ${response.body}');
    }
  }

  Future<void> deleteAllCalcInfo(String userId) async {
    final url = Uri.parse('$backendUrl/calculator/user/$userId');

    await http.delete(url);
  }

  Future<void> updateAllCalcInfo(String userId) async {
    final url = Uri.parse('$backendUrl/calculator/user/$userId');

    await http.delete(url);
  }

  Future<void> uploadSavedData(
    Map<String, List<Map<String, String>>> savedData,
    String ownerId,
  ) async {
    final url = Uri.parse('$backendUrl/calculator/');

    for (final entry in savedData.entries) {
      final subjectName = entry.key;
      final rawEntries = entry.value;

      final formattedEntries = rawEntries.map((e) {
        return {
          'name': e['name'],
          'percentage': double.tryParse(e['percent'] ?? '0') ?? 0.0,
          'grade': double.tryParse(e['grade'] ?? '0') ?? 0.0,
        };
      }).toList();

      final subjectData = {
        'subject_name': subjectName,
        'owner_id': ownerId,
        'entries': formattedEntries,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(subjectData),
      );
    }
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