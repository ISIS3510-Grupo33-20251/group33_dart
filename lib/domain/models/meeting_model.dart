import 'package:flutter/material.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'professor': professor,
      'room': room,
      'day_of_week': dayOfWeek,
      'start_time':
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'end_time':
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'color': color.value.toString(),
      'participants': participants,
    };
  }

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['_id'],
      name: json['name'],
      professor: json['professor'] ?? '',
      room: json['room'] ?? '',
      dayOfWeek: int.parse(json['day_of_week'].toString()),
      startTime: _parseTimeOfDay(json['start_time']),
      endTime: _parseTimeOfDay(json['end_time']),
      color: Color(int.parse(json['color'] ?? '0xFFFF5252')),
      participants: List<String>.from(json['participants'] ?? []),
    );
  }

  static TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}
