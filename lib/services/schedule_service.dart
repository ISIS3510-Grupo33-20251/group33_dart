import 'package:flutter/material.dart';
import '../domain/models/class_model.dart';
import '../domain/models/meeting_model.dart';
import '../data/sources/local/local_storage_service.dart';
import '../data/sources/local/cache_service.dart';
import 'api_service_adapter.dart';
import '../globals.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/cache/lru_cache.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ScheduleService extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  final CacheService _cache = CacheService();
  final ApiServiceAdapter _apiService;
  final LRUCache<String, DateTime> _syncTimeCache =
      LRUCache<String, DateTime>(1);
  static const String _lastSyncKey = 'lastSync';
  Timer? _syncTimer;
  bool _isOnline = true;

  List<ClassModel> _classes = [];
  String? _scheduleId;
  bool _isInitialized = false;
  static const String _scheduleIdKey = 'schedule_id';
  Box<dynamic>? _box;
  Color? selectedColor;

  // Lista de meetings
  List<MeetingModel> _meetings = [
    // Ejemplo de meeting de prueba
    MeetingModel(
      id: 'm1',
      name: 'Team Sync',
      professor: 'John Doe',
      room: 'Zoom',
      dayOfWeek: 0, // Lunes
      startTime: TimeOfDay(hour: 14, minute: 0),
      endTime: TimeOfDay(hour: 15, minute: 0),
      color: Colors.blue,
    ),
  ];

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
  DateTime? get lastSyncTime => _syncTimeCache.get(_lastSyncKey);
  String? get scheduleId => _scheduleId;

  ScheduleService() : _apiService = ApiServiceAdapter(backendUrl: backendUrl) {
    _initializeSchedule();
    _startConnectivityListener();
    _startSyncTimer();
  }

  void _startConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _isOnline = result != ConnectivityResult.none;
      if (_isOnline && userId.isNotEmpty) {
        _syncWithBackend();
      }
    });
  }

  void _startSyncTimer() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isOnline && userId.isNotEmpty) {
        _syncWithBackend();
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
    super.dispose();
  }

  Future<void> _initializeSchedule() async {
    if (_isInitialized) return;

    try {
      print('Initializing schedule storage...');
      await _storage.ensureBoxIsOpen();

      // Intentar obtener el scheduleId de SharedPreferences primero
      final prefs = await SharedPreferences.getInstance();
      _scheduleId = prefs.getString(_scheduleIdKey);

      // Recuperar la última hora de sincronización
      final lastSyncTimeStr = prefs.getString('lastSyncTime');
      if (lastSyncTimeStr != null) {
        final timestamp = int.tryParse(lastSyncTimeStr);
        if (timestamp != null) {
          _syncTimeCache.put(
              _lastSyncKey, DateTime.fromMillisecondsSinceEpoch(timestamp));
        }
      }

      print('Retrieved scheduleId from SharedPreferences: $_scheduleId');

      // Si no hay scheduleId en SharedPreferences, intentar obtenerlo del storage local
      if (_scheduleId == null) {
        _scheduleId = await _storage.getScheduleId();
        if (_scheduleId != null) {
          await prefs.setString(_scheduleIdKey, _scheduleId!);
          await _storage.saveScheduleId(_scheduleId!);
          print('Saved scheduleId to SharedPreferences: $_scheduleId');
        }
      }

      // Cargar clases del almacenamiento local primero
      print('Loading local classes...');
      _classes = await _storage.loadClasses();
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
    if (!_isOnline) {
      print('No internet connection available, skipping sync');
      return;
    }

    try {
      // Verificar si hay una actualización pendiente en caché
      final lastUpdate = await _cache.loadLastScheduleUpdate();
      if (lastUpdate != null) {
        print('Found pending schedule update in cache');
        // Intentar aplicar la actualización pendiente
        try {
          if (lastUpdate['type'] == 'add') {
            await addClass(ClassModel.fromJson(lastUpdate['class']));
          } else if (lastUpdate['type'] == 'remove') {
            await removeClass(lastUpdate['classId']);
          }
          // Eliminar la actualización de la caché después de aplicarla
          await _cache.removeLastScheduleUpdate();
        } catch (e) {
          print('Error applying cached update: $e');
        }
      }

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

          // Cargar las clases del horario existente
          final backendClasses =
              await _apiService.getScheduleMeetings(_scheduleId!);
          print('Found ${backendClasses.length} classes in backend');

          // Si hay clases locales, verificar si hay conflictos
          if (_classes.isNotEmpty) {
            print('Merging local and backend classes...');
            // Crear un mapa de clases locales por ID
            final localClassesMap =
                Map.fromEntries(_classes.map((c) => MapEntry(c.id, c)));

            // Actualizar o agregar clases del backend
            for (var meeting in backendClasses) {
              final classId = meeting['_id'];
              if (localClassesMap.containsKey(classId)) {
                // Actualizar clase existente
                localClassesMap[classId] = ClassModel(
                  id: classId,
                  name: meeting['title'] ?? meeting['name'] ?? 'Untitled',
                  professor:
                      meeting['description'] ?? meeting['professor'] ?? '',
                  room: meeting['location'] ?? meeting['room'] ?? '',
                  startTime: _parseTimeOfDay(meeting['start_time']),
                  endTime: _parseTimeOfDay(meeting['end_time']),
                  color: Color(int.parse(meeting['color'] ?? '0xFFFF5252')),
                );
              } else {
                // Agregar nueva clase
                _classes.add(ClassModel(
                  id: classId,
                  name: meeting['title'] ?? meeting['name'] ?? 'Untitled',
                  professor:
                      meeting['description'] ?? meeting['professor'] ?? '',
                  room: meeting['location'] ?? meeting['room'] ?? '',
                  startTime: _parseTimeOfDay(meeting['start_time']),
                  endTime: _parseTimeOfDay(meeting['end_time']),
                  color: Color(int.parse(meeting['color'] ?? '0xFFFF5252')),
                ));
              }
            }
          } else {
            // Si no hay clases locales, cargar todas del backend
            await _loadMeetings();
          }
        } else {
          print('No schedule found in backend, creating new one...');
          final newSchedule = await _apiService.createSchedule({
            'user_id': userId,
            'meetings': [],
          });
          _scheduleId = newSchedule['_id'];
          print('Created new schedule with ID: $_scheduleId');

          // Si hay clases locales, subirlas al backend
          if (_classes.isNotEmpty) {
            print('Uploading local classes to new schedule...');
            for (var classModel in _classes) {
              final meetingModel = MeetingModel(
                name: classModel.name,
                professor: classModel.professor,
                room: classModel.room,
                dayOfWeek: classModel.dayOfWeek,
                startTime: classModel.startTime,
                endTime: classModel.endTime,
                color: classModel.color,
              );

              final createdMeeting =
                  await _apiService.createMeeting(meetingModel.toJson());
              await _apiService.addMeetingToSchedule(
                  _scheduleId!, createdMeeting['_id']);
            }
          }
        }

        // Guardar el scheduleId en SharedPreferences y storage local
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_scheduleIdKey, _scheduleId!);
        await _storage.saveScheduleId(_scheduleId!);
      } else {
        // Si ya tenemos un scheduleId, verificar si hay actualizaciones
        print('Checking for schedule updates...');
        final backendClasses =
            await _apiService.getScheduleMeetings(_scheduleId!);

        // Verificar si hay diferencias en las clases
        if (backendClasses.length != _classes.length) {
          print('Class count mismatch, updating from backend...');
          await _loadMeetings();
        } else {
          // Verificar si hay cambios en las clases existentes
          final localClassesMap =
              Map.fromEntries(_classes.map((c) => MapEntry(c.id, c)));

          bool hasChanges = false;
          for (var meeting in backendClasses) {
            final classId = meeting['_id'];
            if (localClassesMap.containsKey(classId)) {
              final localClass = localClassesMap[classId]!;
              if (localClass.name != (meeting['title'] ?? meeting['name']) ||
                  localClass.professor !=
                      (meeting['description'] ?? meeting['professor']) ||
                  localClass.room != (meeting['location'] ?? meeting['room'])) {
                hasChanges = true;
                break;
              }
            }
          }

          if (hasChanges) {
            print('Class content mismatch, updating from backend...');
            await _loadMeetings();
          }
        }
      }

      // Actualizar el tiempo de última sincronización
      final now = DateTime.now();
      _syncTimeCache.put(_lastSyncKey, now);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'lastSyncTime', now.millisecondsSinceEpoch.toString());

      // Guardar las clases actualizadas en el almacenamiento local
      await _storage.saveClasses(_classes);

      notifyListeners();
      print('Sync completed successfully at ${now.toIso8601String()}');
    } catch (e) {
      print('Error during backend sync: $e');
    }
  }

  Future<void> _loadMeetings() async {
    if (_scheduleId == null) return;

    try {
      print('Loading meetings from backend...');
      final meetings = await _apiService.getScheduleMeetings(_scheduleId!);
      print('Found ${meetings.length} meetings in backend');

      _classes = meetings.map((meeting) {
        print('Processing meeting: $meeting');

        // Extraer y validar los datos necesarios
        final String id = meeting['_id']?.toString() ?? '';
        final String name = meeting['title']?.toString() ??
            meeting['name']?.toString() ??
            'Untitled';
        final String professor = meeting['description']?.toString() ??
            meeting['professor']?.toString() ??
            '';
        final String room = meeting['location']?.toString() ??
            meeting['room']?.toString() ??
            '';
        final String startTime = meeting['start_time']?.toString() ?? '00:00';
        final String endTime = meeting['end_time']?.toString() ?? '00:00';
        final String colorStr = meeting['color']?.toString() ?? '0xFFFF5252';

        print('Parsed meeting data:');
        print('  ID: $id');
        print('  Name: $name');
        print('  Professor: $professor');
        print('  Room: $room');
        print('  Start Time: $startTime');
        print('  End Time: $endTime');
        print('  Color: $colorStr');

        return ClassModel(
          id: id,
          name: name,
          professor: professor,
          room: room,
          startTime: _parseTimeOfDay(startTime),
          endTime: _parseTimeOfDay(endTime),
          color: Color(int.parse(colorStr)),
        );
      }).toList();

      await _storage.saveClasses(_classes);
      notifyListeners();
      print('Successfully synced and saved ${_classes.length} classes');
    } catch (e) {
      print('Error loading meetings from backend: $e');
      if (_classes.isEmpty) {
        _classes = await _storage.loadClasses();
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

      if (!_isOnline) {
        // Si no hay conexión, guardar la actualización en caché
        await _cache.cacheLastScheduleUpdate({
          'type': 'add',
          'class': classModel.toJson(),
        });
        // Guardar localmente
        await _storage.saveClasses([..._classes, classModel]);
        _classes.add(classModel);
        notifyListeners();
        return;
      }

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
      await _storage.saveClasses([..._classes, updatedClass]);
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
      if (!_isOnline) {
        // Si no hay conexión, guardar la actualización en caché
        await _cache.cacheLastScheduleUpdate({
          'type': 'remove',
          'classId': id,
        });
        // Eliminar localmente
        _classes.removeWhere((c) => c.id == id);
        await _storage.saveClasses(_classes);
        notifyListeners();
        return;
      }

      // Eliminar del backend primero
      await _apiService.deleteMeeting(id);
      print('Meeting deleted from backend');

      // Si el schedule existe, remover la referencia del meeting
      if (_scheduleId != null) {
        await _apiService.removeMeetingFromSchedule(_scheduleId!, id);
        print('Meeting reference removed from schedule');
      }

      // Eliminar localmente
      _classes.removeWhere((c) => c.id == id);
      removeMeeting(id); // También remueve de meetings
      await _storage.saveClasses(_classes);
      notifyListeners();
      print('Class removed successfully');
    } catch (e) {
      print('Error removing class: $e');
      throw Exception('Failed to remove class: $e');
    }
  }

  Future<void> clearLocalData() async {
    try {
      _classes = [];
      _scheduleId = null;
      _isInitialized = false;
      await _storage.saveClasses([]);
      notifyListeners();
      print('Local data cleared');
    } catch (e) {
      print('Error clearing local data: $e');
    }
  }

  List<ClassModel> getClassesForDayAndHour(int dayIndex, int hour) {
    final classes = _classes.where((c) {
      final isCorrectDay = c.dayOfWeek == dayIndex;
      final startsInThisHour = c.startTime.hour == hour;
      return isCorrectDay && startsInThisHour;
    }).toList();

    return classes;
  }

  Color getRandomColor() {
    return classColors[_classes.length % classColors.length];
  }

  static TimeOfDay _parseTimeOfDay(String time) {
    try {
      // Intentar diferentes formatos de tiempo
      if (time.contains('T')) {
        // Formato ISO 8601 (YYYY-MM-DDTHH:mm:ss)
        final dateTime = DateTime.parse(time);
        return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
      }

      // Formato HH:mm
      final parts = time.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }

      // Si no se puede parsear, retornar tiempo por defecto
      print('Warning: Could not parse time format: $time');
      return const TimeOfDay(hour: 0, minute: 0);
    } catch (e) {
      print('Error parsing time: $time - $e');
      return const TimeOfDay(hour: 0, minute: 0);
    }
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
      if (_scheduleId == null) {
        await _syncWithBackend();
        if (_scheduleId == null) {
          throw Exception('No schedule ID available');
        }
      }
      final createdMeeting = await _apiService.createMeeting(meetingData);
      print('Meeting created with ID: ${createdMeeting['_id']}');
      await _apiService.addMeetingToSchedule(
          _scheduleId!, createdMeeting['_id']);
      print('Meeting added to schedule $_scheduleId');
      final startDateTime = DateTime.parse(meetingData['start_time']);
      final endDateTime = DateTime.parse(meetingData['end_time']);
      final meetingModel = MeetingModel(
        id: createdMeeting['_id'],
        name: meetingData['title'],
        professor: meetingData['description'] ?? '',
        room: meetingData['location'] ?? '',
        dayOfWeek: _getDayOfWeekFromDateTime(startDateTime),
        startTime:
            TimeOfDay(hour: startDateTime.hour, minute: startDateTime.minute),
        endTime: TimeOfDay(hour: endDateTime.hour, minute: endDateTime.minute),
        color: selectedColor ?? Colors.blue,
      );
      addMeeting(meetingModel);
      print('Meeting added successfully and converted to meeting for display');
    } catch (e) {
      print('Error creating meeting: $e');
      throw Exception('Failed to create meeting: $e');
    }
  }

  int _getDayOfWeekFromDateTime(DateTime dateTime) {
    // Convertir de DateTime (1-7, Lun-Dom) a nuestro formato (0-4, Lun-Vie)
    int day = dateTime.weekday - 1;
    return day >= 5 ? 0 : day; // Si es fin de semana, asignar al lunes
  }

  TimeOfDay _parseTimeFromDateTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  Future<void> syncNow() async {
    if (!_isOnline) {
      throw Exception('No hay conexión a internet');
    }

    if (userId.isEmpty) {
      throw Exception('Usuario no autenticado');
    }

    await _syncWithBackend();
  }

  // Método para obtener meetings por día y hora
  List<MeetingModel> getMeetingsForDayAndHour(int dayIndex, int hour) {
    return _meetings
        .where((m) => m.dayOfWeek == dayIndex && m.startTime.hour == hour)
        .toList();
  }

  void addMeeting(MeetingModel meeting) {
    _meetings.add(meeting);
    notifyListeners();
  }

  void removeMeeting(String id) {
    _meetings.removeWhere((m) => m.id == id);
    notifyListeners();
  }
}
