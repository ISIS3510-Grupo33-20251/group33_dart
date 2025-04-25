import 'package:flutter/material.dart';

class ClassModel {
  final String id;
  final String name;
  final String professor;
  final String room;
  final int dayOfWeek; // 0 = Monday, 4 = Friday
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Color color;

  ClassModel({
    required this.id,
    required this.name,
    required this.professor,
    required this.room,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'professor': professor,
      'room': room,
      'dayOfWeek': dayOfWeek,
      'startTime':
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'endTime':
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'color': color.value,
    };
  }

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      name: json['name'] as String,
      professor: json['professor'] as String? ?? '',
      room: json['room'] as String? ?? '',
      dayOfWeek: json['dayOfWeek'] as int,
      startTime: _parseTimeOfDay(json['startTime'] as String),
      endTime: _parseTimeOfDay(json['endTime'] as String),
      color: Color(json['color'] as int),
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
