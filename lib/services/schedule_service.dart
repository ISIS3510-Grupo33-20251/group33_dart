import 'package:flutter/material.dart';
import '../domain/models/class_model.dart';
import '../data/sources/local/cache_service.dart';
import 'api_service_adapter.dart';
import '../globals.dart';

class ScheduleService extends ChangeNotifier {
  static const String _cacheKey = 'schedule_cache';
  final CacheService _cacheService = CacheService();
  final ApiServiceAdapter _apiService;
  List<ClassModel> _classes = [];
  String? _scheduleId;

  static const List<Color> classColors = [
    Color(0xFFFF5252), // Red
    Color(0xFFFF7043), // Deep Orange
    Color(0xFFFFCA28), // Amber
    Color(0xFF66BB6A), // Green
    Color(0xFF26C6DA), // Cyan
    Color(0xFF42A5F5), // Blue
    Color(0xFF7E57C2), // Deep Purple
    Color(0xFFEC407A), // Pink
  ];

  List<ClassModel> get classes => _classes;

  ScheduleService() : _apiService = ApiServiceAdapter(backendUrl: backendUrl) {
    _initializeSchedule();
  }

  Future<void> _initializeSchedule() async {
    try {
      // Try to load from cache first
      final cachedData = await _cacheService.loadCachedFlashcard(_cacheKey);
      if (cachedData.isNotEmpty) {
        _classes = cachedData.map((json) => ClassModel.fromJson(json)).toList();
        notifyListeners();
        print('Loaded ${_classes.length} classes from cache');
      }

      if (userId == null) {
        print('No userId available, skipping backend sync');
        return;
      }

      // Get or create schedule for the user
      final schedules = await _apiService.getSchedules();
      final userSchedule = schedules.firstWhere(
        (schedule) => schedule['user_id'] == userId,
        orElse: () => {},
      );

      if (userSchedule.isNotEmpty) {
        _scheduleId = userSchedule['_id'];
      } else {
        final newSchedule = await _apiService.createSchedule(userId!);
        _scheduleId = newSchedule['_id'];
      }

      print('Using schedule ID: $_scheduleId');
      await _loadMeetings();
    } catch (e) {
      print('Error initializing schedule: $e');
    }
  }

  Future<void> _loadMeetings() async {
    if (_scheduleId == null) {
      print('No schedule ID available');
      return;
    }

    try {
      final meetings = await _apiService.getScheduleMeetings(_scheduleId!);
      _classes = meetings
          .map((meeting) => ClassModel(
                id: meeting['_id'],
                name: meeting['name'],
                professor: meeting['professor'] ?? '',
                room: meeting['room'] ?? '',
                dayOfWeek: int.parse(meeting['day_of_week'].toString()),
                startTime: _parseTimeOfDay(meeting['start_time']),
                endTime: _parseTimeOfDay(meeting['end_time']),
                color: Color(int.parse(meeting['color'] ?? '0xFFFF5252')),
              ))
          .toList();

      await _updateCache();
      notifyListeners();
      print('Loaded ${_classes.length} meetings from backend');
    } catch (e) {
      print('Error loading meetings: $e');
    }
  }

  Future<void> addClass(ClassModel classModel) async {
    if (_scheduleId == null) {
      print('No schedule ID available, initializing...');
      await _initializeSchedule();
    }
    if (_scheduleId == null) {
      throw Exception('Failed to initialize schedule');
    }

    try {
      // Preparar los datos para el backend
      final meetingData = {
        'name': classModel.name,
        'professor': classModel.professor,
        'room': classModel.room,
        'day_of_week': classModel.dayOfWeek.toString(),
        'start_time':
            '${classModel.startTime.hour.toString().padLeft(2, '0')}:${classModel.startTime.minute.toString().padLeft(2, '0')}',
        'end_time':
            '${classModel.endTime.hour.toString().padLeft(2, '0')}:${classModel.endTime.minute.toString().padLeft(2, '0')}',
        'color': classModel.color.value.toString(),
      };

      // Agregar al backend
      await _apiService.addMeetingToSchedule(_scheduleId!, meetingData);

      // Recargar las clases desde el backend para obtener el ID correcto
      await _loadMeetings();

      print('Added class successfully: ${classModel.name}');
    } catch (e) {
      print('Error adding class: $e');
      throw Exception('Failed to add class: $e');
    }
  }

  Future<void> removeClass(String id) async {
    if (_scheduleId == null) return;

    try {
      await _apiService.removeMeetingFromSchedule(_scheduleId!, id);
      _classes.removeWhere((c) => c.id == id);
      await _updateCache();
      notifyListeners();
      print('Removed class with id: $id');
    } catch (e) {
      print('Error removing class: $e');
      throw Exception('Failed to remove class');
    }
  }

  Future<void> _updateCache() async {
    try {
      await _cacheService.cacheFlashcard(
        _cacheKey,
        _classes.map((c) => c.toJson()).toList(),
      );
      print('Updated cache with ${_classes.length} classes');
    } catch (e) {
      print('Error updating cache: $e');
    }
  }

  List<ClassModel> getClassesForDayAndHour(int dayIndex, int hour) {
    final classes = _classes
        .where((c) => c.dayOfWeek == dayIndex && c.startTime.hour == hour)
        .toList();
    print('Found ${classes.length} classes for day $dayIndex at hour $hour');
    return classes;
  }

  Color getRandomColor() {
    return classColors[_classes.length % classColors.length];
  }

  static TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  Future<void> initializeSchedule() async {
    await _initializeSchedule();
  }

  void debugPrintClasses() {
    print('Current classes in memory:');
    for (var c in _classes) {
      print(
          'Class: ${c.name} - Day: ${c.dayOfWeek} - Time: ${c.startTime.hour}:${c.startTime.minute}');
    }
  }
}
