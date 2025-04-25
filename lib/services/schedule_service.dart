import 'package:flutter/material.dart';
import '../domain/models/class_model.dart';
import '../data/sources/local/cache_service.dart';
import 'api_service_adapter.dart';
import '../globals.dart';

class ScheduleService extends ChangeNotifier {
  static const String _cacheKey = 'schedule_cache';
  static const String _scheduleIdKey = 'schedule_id_cache';
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
      // Try to load schedule ID from cache first
      final cachedScheduleId =
          await _cacheService.loadCachedFlashcard(_scheduleIdKey);
      if (cachedScheduleId.isNotEmpty && cachedScheduleId[0] is Map) {
        _scheduleId = (cachedScheduleId[0] as Map)['id']?.toString();
        print('Loaded schedule ID from cache: $_scheduleId');
      }

      // Try to load classes from cache
      final cachedData = await _cacheService.loadCachedFlashcard(_cacheKey);
      if (cachedData.isNotEmpty) {
        _classes = cachedData.map((json) => ClassModel.fromJson(json)).toList();
        notifyListeners();
        print('Loaded ${_classes.length} classes from cache');
      }

      // Try to sync with backend
      await _syncWithBackend();
    } catch (e) {
      print('Error initializing schedule: $e');
    }
  }

  Future<void> _syncWithBackend() async {
    if (userId == null) {
      print('No userId available, working in offline mode');
      return;
    }

    try {
      if (_scheduleId == null) {
        print('Attempting to get or create schedule for user $userId');

        try {
          final schedules = await _apiService.getSchedules();
          print('Found ${schedules.length} schedules');

          var userSchedule = schedules.firstWhere(
            (schedule) => schedule['user_id'] == userId,
            orElse: () => {},
          );

          if (userSchedule.isNotEmpty) {
            _scheduleId = userSchedule['_id'];
            print('Found existing schedule with ID: $_scheduleId');
          } else {
            print('No existing schedule found, creating new one...');
            try {
              final newSchedule = await _apiService.createSchedule(userId!);
              _scheduleId = newSchedule['_id'];
              print('Created new schedule with ID: $_scheduleId');
            } catch (e) {
              print('Failed to create schedule, working in offline mode: $e');
              return;
            }
          }

          if (_scheduleId != null) {
            await _cacheService.cacheFlashcard(_scheduleIdKey, [
              {'id': _scheduleId}
            ]);
            print('Cached schedule ID: $_scheduleId');
          }
        } catch (e) {
          print('Error accessing backend, working in offline mode: $e');
          return;
        }
      }

      if (_scheduleId != null) {
        await _loadMeetings();
      }
    } catch (e) {
      print('Error during backend sync, continuing in offline mode: $e');
    }
  }

  Future<void> _loadMeetings() async {
    if (_scheduleId == null) {
      print('No schedule ID available');
      return;
    }

    try {
      print('Loading meetings for schedule $_scheduleId');
      final meetings = await _apiService.getScheduleMeetings(_scheduleId!);
      print('Received ${meetings.length} meetings from backend');

      _classes = meetings.map((meeting) {
        print(
            'Processing meeting: ${meeting['name']} on day ${meeting['day_of_week']}');
        return ClassModel(
          id: meeting['_id'],
          name: meeting['name'],
          professor: meeting['professor'] ?? '',
          room: meeting['room'] ?? '',
          dayOfWeek: int.parse(meeting['day_of_week'].toString()),
          startTime: _parseTimeOfDay(meeting['start_time']),
          endTime: _parseTimeOfDay(meeting['end_time']),
          color: Color(int.parse(meeting['color'] ?? '0xFFFF5252')),
        );
      }).toList();

      await _updateCache();
      notifyListeners();
      print('Successfully loaded and cached ${_classes.length} meetings');
    } catch (e) {
      print('Error loading meetings: $e');
      throw Exception('Failed to load meetings: $e');
    }
  }

  Future<void> addClass(ClassModel classModel) async {
    try {
      print('Adding new class: ${classModel.name}');

      // Primero guardamos localmente
      _classes.add(classModel);
      notifyListeners();
      await _updateCache();
      print('Class added locally');

      // Luego intentamos sincronizar con el backend
      try {
        if (_scheduleId == null) {
          print('No schedule ID available, attempting to sync with backend...');
          await _syncWithBackend();
        }

        if (_scheduleId != null) {
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

          print(
              'Adding meeting to schedule $_scheduleId with data: $meetingData');
          await _apiService.addMeetingToSchedule(_scheduleId!, meetingData);
          print('Successfully synced with backend');

          // Recargar las clases desde el backend
          await _loadMeetings();
        } else {
          print('Working in offline mode - changes will sync later');
        }
      } catch (e) {
        print('Backend sync failed: $e');
        print('Continuing in offline mode - changes are saved locally');
      }

      print(
          'Class added successfully (${_scheduleId == null ? 'offline' : 'online'} mode)');
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
    final classes = _classes.where((c) {
      final isCorrectDay = c.dayOfWeek == dayIndex;
      final startsThisHour = c.startTime.hour == hour;

      print(
          'Checking class ${c.name}: day=${c.dayOfWeek}, hour=${c.startTime.hour}');
      print('Comparing with: dayIndex=$dayIndex, hour=$hour');
      print('isCorrectDay=$isCorrectDay, startsThisHour=$startsThisHour');

      return isCorrectDay && startsThisHour;
    }).toList();

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
