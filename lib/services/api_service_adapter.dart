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
    if (kDebugMode) {
      if (Platform.isAndroid || Platform.isIOS) {
        return '$backendUrl/users/auth';
      }
    }
    return '$backendUrl/users/auth';
  }

  // ... (omitted unchanged code for brevity)

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

  // ... (omitted unchanged code for brevity)
}

Future<bool> hasInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('example.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
