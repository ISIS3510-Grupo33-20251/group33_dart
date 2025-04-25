import 'package:flutter/material.dart';
import '../domain/models/class_model.dart';
import '../data/sources/local/schedule_storage.dart';
import 'api_service_adapter.dart';
import '../globals.dart';

class ScheduleService extends ChangeNotifier {
  final ScheduleStorage _storage = ScheduleStorage();
  final ApiServiceAdapter _apiService;
  List<ClassModel> _classes = [];
  String? _scheduleId;
  bool _isInitialized = false;

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
    if (_isInitialized) return;

    try {
      print('Initializing schedule storage...');
      await _storage.initialize();

      // Cargar datos locales primero
      print('Loading local data...');
      _scheduleId = await _storage.getScheduleId();
      _classes = await _storage.getClasses();

      if (_classes.isNotEmpty) {
        print('Loaded ${_classes.length} classes from local storage');
        notifyListeners();
      }

      // Intentar sincronizar con el backend solo si tenemos userId
      if (userId != null) {
        print('Attempting to sync with backend...');
        await _syncWithBackend();
      } else {
        print('No userId available, working in offline mode');
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing schedule: $e');
      _isInitialized = true; // Marcar como inicializado para evitar bucles
    }
  }

  Future<void> _syncWithBackend() async {
    try {
      if (_scheduleId == null) {
        print('No local schedule ID, checking backend...');
        final schedules = await _apiService.getSchedules();
        print('Found ${schedules.length} schedules');

        var userSchedule = schedules.firstWhere(
          (schedule) => schedule['user_id'] == userId,
          orElse: () => {},
        );

        if (userSchedule.isNotEmpty) {
          _scheduleId = userSchedule['_id'];
          print('Found existing schedule with ID: $_scheduleId');
          await _storage.saveScheduleId(_scheduleId);
        } else {
          print('Creating new schedule...');
          final newSchedule = await _apiService.createSchedule(userId!);
          _scheduleId = newSchedule['_id'];
          print('Created new schedule with ID: $_scheduleId');
          await _storage.saveScheduleId(_scheduleId);
        }
      }

      // Cargar clases del backend
      if (_scheduleId != null) {
        await _loadMeetings();
      }
    } catch (e) {
      print('Error syncing with backend: $e');
    }
  }

  Future<void> _loadMeetings() async {
    if (_scheduleId == null) return;

    try {
      print('Loading meetings from backend...');
      final meetings = await _apiService.getScheduleMeetings(_scheduleId!);

      _classes = meetings.map((meeting) {
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

      // Guardar las clases localmente
      await _storage.saveClasses(_classes);
      notifyListeners();
      print('Synced and saved ${_classes.length} classes locally');
    } catch (e) {
      print('Error loading meetings from backend: $e');
    }
  }

  Future<void> addClass(ClassModel classModel) async {
    try {
      print('Adding new class: ${classModel.name}');

      // Generar un ID temporal si no existe
      if (classModel.id.isEmpty) {
        classModel = ClassModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: classModel.name,
          professor: classModel.professor,
          room: classModel.room,
          dayOfWeek: classModel.dayOfWeek,
          startTime: classModel.startTime,
          endTime: classModel.endTime,
          color: classModel.color,
        );
      }

      // Guardar localmente primero
      await _storage.addClass(classModel);
      _classes.add(classModel);
      notifyListeners();
      print('Class added to local storage');

      // Intentar sincronizar con el backend
      if (_scheduleId != null) {
        try {
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

          await _apiService.addMeetingToSchedule(_scheduleId!, meetingData);
          print('Class synced with backend');

          // Recargar desde el backend para obtener el ID correcto
          await _loadMeetings();
        } catch (e) {
          print('Failed to sync with backend: $e');
        }
      }
    } catch (e) {
      print('Error adding class: $e');
      throw Exception('Failed to add class: $e');
    }
  }

  Future<void> removeClass(String id) async {
    try {
      // Eliminar localmente primero
      await _storage.removeClass(id);
      _classes.removeWhere((c) => c.id == id);
      notifyListeners();
      print('Class removed from local storage');

      // Intentar eliminar del backend
      if (_scheduleId != null) {
        try {
          await _apiService.removeMeetingFromSchedule(_scheduleId!, id);
          print('Class removed from backend');
        } catch (e) {
          print('Failed to remove class from backend: $e');
        }
      }
    } catch (e) {
      print('Error removing class: $e');
      throw Exception('Failed to remove class: $e');
    }
  }

  Future<void> clearLocalData() async {
    try {
      await _storage.clear();
      _classes = [];
      _scheduleId = null;
      _isInitialized = false;
      notifyListeners();
      print('Local data cleared');
    } catch (e) {
      print('Error clearing local data: $e');
    }
  }

  List<ClassModel> getClassesForDayAndHour(int dayIndex, int hour) {
    final classes = _classes.where((c) {
      final isCorrectDay = c.dayOfWeek == dayIndex;
      final startsThisHour = c.startTime.hour == hour;
      return isCorrectDay && startsThisHour;
    }).toList();

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

  void debugPrintClasses() {
    print('Current classes in memory:');
    for (var c in _classes) {
      print(
          'Class: ${c.name} - Day: ${c.dayOfWeek} - Time: ${c.startTime.hour}:${c.startTime.minute}');
    }
  }
}
