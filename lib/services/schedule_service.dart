import 'package:flutter/material.dart';
import '../domain/models/class_model.dart';

class ScheduleService extends ChangeNotifier {
  final List<ClassModel> _classes = [];

  static const List<Color> classColors = [
    Color(0xFF7D91FA), // Azul principal
    Color(0xFFFF6B6B), // Rojo
    Color(0xFF4ECDC4), // Turquesa
    Color(0xFFFFBE0B), // Amarillo
    Color(0xFF95E1D3), // Verde menta
    Color(0xFFA78BFA), // Púrpura
    Color(0xFFFF9F1C), // Naranja
    Color(0xFF4CAF50), // Verde
  ];

  List<ClassModel> get classes => List.unmodifiable(_classes);

  void addClass(ClassModel classModel) {
    _classes.add(classModel);
    notifyListeners();
  }

  void removeClass(String id) {
    _classes.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  List<ClassModel> getClassesForDayAndHour(int day, int hour) {
    return _classes
        .where((c) =>
            c.dayOfWeek == day &&
            c.startTime.hour <= hour &&
            c.endTime.hour > hour)
        .toList();
  }

  Color getRandomColor() {
    return classColors[_classes.length % classColors.length];
  }
}
