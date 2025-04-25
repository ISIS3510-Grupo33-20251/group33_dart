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
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'color': color.value,
      'dayOfWeek': dayOfWeek,
    };
  }

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'],
      name: json['name'],
      professor: json['professor'],
      room: json['room'],
      dayOfWeek: json['dayOfWeek'],
      startTime: TimeOfDay(
        hour: int.parse(json['startTime'].split(':')[0]),
        minute: int.parse(json['startTime'].split(':')[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(json['endTime'].split(':')[0]),
        minute: int.parse(json['endTime'].split(':')[1]),
      ),
      color: Color(json['color']),
    );
  }
}
