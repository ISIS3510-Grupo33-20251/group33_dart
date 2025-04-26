import 'package:flutter/material.dart';
import '../domain/models/class_model.dart';
import '../domain/models/meeting_model.dart';
import '../data/sources/local/schedule_storage.dart';
import 'api_service_adapter.dart';
import '../globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleService extends ChangeNotifier {
  final ScheduleStorage _storage = ScheduleStorage();
  final ApiServiceAdapter _apiService;
  List<ClassModel> _classes = [];
  String? _scheduleId;
  bool _isInitialized = false;
  static const String _scheduleIdKey = 'schedule_id';

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

      // Intentar obtener el scheduleId de SharedPreferences primero
      final prefs = await SharedPreferences.getInstance();
      _scheduleId = prefs.getString(_scheduleIdKey);
      print('Retrieved scheduleId from SharedPreferences: $_scheduleId');

      // Si no hay scheduleId en SharedPreferences, intentar obtenerlo del storage local
      if (_scheduleId == null) {
        _scheduleId = await _storage.getScheduleId();
        if (_scheduleId != null) {
          await prefs.setString(_scheduleIdKey, _scheduleId!);
          print('Saved scheduleId to SharedPreferences: $_scheduleId');
        }
      }

      // Cargar clases del almacenamiento local primero
      print('Loading local classes...');
      _classes = await _storage.getClasses();
      if (_classes.isNotEmpty) {
        print('Loaded ${_classes.length} classes from local storage');
        notifyListeners();
      }

      // Si tenemos userId, intentar sincronizar con el backend
      if (userId.isNotEmpty) {
        print('UserId available, syncing with backend...');
        await _syncWithBackend();
      } else {
        print('No userId available, working in offline mode');
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing schedule: $e');
      _isInitialized = true;
    }
  }

  Future<void> _syncWithBackend() async {
    try {
      if (_scheduleId == null) {
        print('No scheduleId found, checking backend...');
        final schedules = await _apiService.getSchedules();
        print('Found ${schedules.length} schedules in backend');

        var userSchedule = schedules.firstWhere(
          (schedule) => schedule['user_id'] == userId,
          orElse: () => {},
        );

        if (userSchedule.isNotEmpty) {
          _scheduleId = userSchedule['_id'];
          print('Found existing schedule in backend with ID: $_scheduleId');
        } else {
          print('No schedule found in backend, creating new one...');
          final newSchedule = await _apiService.createSchedule({
            'user_id': userId,
            'meetings': [],
          });
          _scheduleId = newSchedule['_id'];
          print('Created new schedule with ID: $_scheduleId');
        }

        // Guardar el scheduleId en SharedPreferences y storage local
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_scheduleIdKey, _scheduleId!);
        await _storage.saveScheduleId(_scheduleId);
      }

      // Verificar si necesitamos sincronizar las clases
      if (_classes.isEmpty) {
        print('No local classes found, loading from backend...');
        await _loadMeetings();
      } else {
        print('Local classes found, checking for updates...');
        final backendClasses =
            await _apiService.getScheduleMeetings(_scheduleId!);
        if (backendClasses.length != _classes.length) {
          print('Class count mismatch, updating from backend...');
          await _loadMeetings();
        }
      }
    } catch (e) {
      print('Error during backend sync: $e');
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

      await _storage.saveClasses(_classes);
      notifyListeners();
      print('Successfully synced and saved ${_classes.length} classes');
    } catch (e) {
      print('Error loading meetings from backend: $e');
      if (_classes.isEmpty) {
        _classes = await _storage.getClasses();
        if (_classes.isNotEmpty) {
          print('Fallback to local storage: loaded ${_classes.length} classes');
          notifyListeners();
        }
      }
    }
  }

  Future<void> addClass(ClassModel classModel) async {
    try {
      print('Adding new class: ${classModel.name}');

      // Convertir ClassModel a MeetingModel
      final meetingModel = MeetingModel(
        name: classModel.name,
        professor: classModel.professor,
        room: classModel.room,
        dayOfWeek: classModel.dayOfWeek,
        startTime: classModel.startTime,
        endTime: classModel.endTime,
        color: classModel.color,
      );

      // Crear el meeting en el backend
      final createdMeeting =
          await _apiService.createMeeting(meetingModel.toJson());
      print('Meeting created with response: $createdMeeting');

      // Actualizar el modelo con el ID del backend
      final updatedClass = ClassModel(
        id: createdMeeting['_id'],
        name: classModel.name,
        professor: classModel.professor,
        room: classModel.room,
        dayOfWeek: classModel.dayOfWeek,
        startTime: classModel.startTime,
        endTime: classModel.endTime,
        color: classModel.color,
      );

      // Agregar el meeting al schedule
      if (_scheduleId != null) {
        await _apiService.addMeetingToSchedule(
            _scheduleId!, createdMeeting['_id']);
        print('Meeting added to schedule successfully');
      }

      // Guardar localmente
      await _storage.addClass(updatedClass);
      _classes.add(updatedClass);
      notifyListeners();
      print('Class added successfully with ID: ${createdMeeting['_id']}');
    } catch (e) {
      print('Error adding class: $e');
      throw Exception('Failed to add class: $e');
    }
  }

  Future<void> removeClass(String id) async {
    try {
      // Eliminar del backend primero
      await _apiService.deleteMeeting(id);
      print('Meeting deleted from backend');

      // Si el schedule existe, remover la referencia del meeting
      if (_scheduleId != null) {
        await _apiService.removeMeetingFromSchedule(_scheduleId!, id);
        print('Meeting reference removed from schedule');
      }

      // Eliminar localmente
      await _storage.removeClass(id);
      _classes.removeWhere((c) => c.id == id);
      notifyListeners();
      print('Class removed successfully');
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

  Future<void> createMeeting(Map<String, dynamic> meetingData) async {
    try {
      print('Creating meeting with data: $meetingData');

      // Asegurarse de que tenemos un scheduleId
      if (_scheduleId == null) {
        await _syncWithBackend();
        if (_scheduleId == null) {
          throw Exception('No schedule ID available');
        }
      }

      // Crear el meeting en el backend
      final createdMeeting = await _apiService.createMeeting(meetingData);
      print('Meeting created with ID: ${createdMeeting['_id']}');

      // Agregar el meeting al schedule
      await _apiService.addMeetingToSchedule(
          _scheduleId!, createdMeeting['_id']);
      print('Meeting added to schedule $_scheduleId');

      // Convertir el meeting a ClassModel para mostrar en el calendario
      final classModel = ClassModel(
        id: createdMeeting['_id'],
        name: meetingData['title'],
        professor: meetingData['description'] ?? '',
        room: meetingData['location'] ?? '',
        dayOfWeek: int.parse(meetingData['day_of_week']),
        startTime: _parseTimeFromDateTime(meetingData['start_time']),
        endTime: _parseTimeFromDateTime(meetingData['end_time']),
        color: Color(int.parse(meetingData['color'])),
      );

      // Guardar localmente
      await _storage.addClass(classModel);
      _classes.add(classModel);
      notifyListeners();
      print('Meeting added successfully and converted to class for display');
    } catch (e) {
      print('Error creating meeting: $e');
      throw Exception('Failed to create meeting: $e');
    }
  }

  TimeOfDay _parseTimeFromDateTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }
}
