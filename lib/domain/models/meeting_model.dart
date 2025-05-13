import 'package:flutter/material.dart';
import 'package:group33_dart/globals.dart';

class MeetingModel {
  final String? id;
  final String name;
  final String professor;
  final String room;
  final int dayOfWeek;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Color color;
  final List<String> participants;

  MeetingModel({
    this.id,
    required this.name,
    required this.professor,
    required this.room,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.color,
    List<String>? participants,
  }) : participants = participants ?? [];

  Map<String, dynamic> toJson({DateTime? date, String? meetingLink}) {
    // Use provided date or today for ISO8601
    final now = date ?? DateTime.now();
    final startDateTime = DateTime(
        now.year, now.month, now.day, startTime.hour, startTime.minute);
    final endDateTime =
        DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);
    return {
      'title': name,
      'description': professor,
      'location': room,
      'day_of_week': dayOfWeek,
      'start_time': startDateTime.toIso8601String(),
      'end_time': endDateTime.toIso8601String(),
      'color': '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      'participants': participants,
      'host_id': userId,
      'meeting_link': meetingLink ?? '',
    };
  }

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['_id'],
      name: json['title'] ?? json['name'] ?? '',
      professor: json['description'] ?? json['professor'] ?? '',
      room: json['location'] ?? json['room'] ?? '',
      dayOfWeek: int.tryParse(json['day_of_week']?.toString() ?? '') ?? 0,
      startTime: _parseTimeOfDay(json['start_time']),
      endTime: _parseTimeOfDay(json['end_time']),
      color: _parseColor(json['color']),
      participants: List<String>.from(json['participants'] ?? []),
    );
  }

  static TimeOfDay _parseTimeOfDay(String time) {
    if (time.contains('T')) {
      final dateTime = DateTime.parse(time);
      return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    }
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static Color _parseColor(dynamic colorValue) {
    if (colorValue == null) return const Color(0xFFFF5252);
    if (colorValue is int) return Color(colorValue);
    if (colorValue is String) {
      if (colorValue.startsWith('#')) {
        return Color(int.parse(colorValue.replaceFirst('#', '0xff')));
      } else if (colorValue.startsWith('0x')) {
        return Color(int.parse(colorValue));
      }
    }
    return const Color(0xFFFF5252);
  }
}
