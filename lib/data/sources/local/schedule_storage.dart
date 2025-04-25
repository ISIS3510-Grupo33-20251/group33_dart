import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../domain/models/class_model.dart';
import '../../adapters/time_of_day_adapter.dart';
import '../../adapters/color_adapter.dart';

class ScheduleStorage {
  static const String _scheduleBox = 'schedule_box';
  static const String _scheduleIdKey = 'schedule_id';
  static const String _classesKey = 'classes';
  Box? _box;

  Future<void> initialize() async {
    try {
      // Inicializar Hive si no está inicializado
      if (!Hive.isBoxOpen(_scheduleBox)) {
        await Hive.initFlutter();
      }

      // Registrar adaptadores
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ClassModelAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TimeOfDayAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(ColorAdapter());
      }

      // Abrir el box
      _box = await Hive.openBox(_scheduleBox);
      print('Hive box opened successfully');
    } catch (e) {
      print('Error initializing Hive: $e');
      rethrow;
    }
  }

  Future<void> saveScheduleId(String? scheduleId) async {
    try {
      if (_box == null) {
        await initialize();
      }
      await _box!.put(_scheduleIdKey, scheduleId);
      print('Schedule ID saved: $scheduleId');
    } catch (e) {
      print('Error saving schedule ID: $e');
      rethrow;
    }
  }

  Future<String?> getScheduleId() async {
    try {
      if (_box == null) {
        await initialize();
      }
      final id = _box!.get(_scheduleIdKey) as String?;
      print('Retrieved schedule ID: $id');
      return id;
    } catch (e) {
      print('Error getting schedule ID: $e');
      return null;
    }
  }

  Future<void> saveClasses(List<ClassModel> classes) async {
    try {
      if (_box == null) {
        await initialize();
      }
      await _box!.put(_classesKey, classes);
      print('Saved ${classes.length} classes to local storage');
    } catch (e) {
      print('Error saving classes: $e');
      rethrow;
    }
  }

  Future<List<ClassModel>> getClasses() async {
    try {
      if (_box == null) {
        await initialize();
      }
      final classes =
          _box!.get(_classesKey, defaultValue: <ClassModel>[]) as List;
      final result = List<ClassModel>.from(classes);
      print('Retrieved ${result.length} classes from local storage');
      return result;
    } catch (e) {
      print('Error getting classes: $e');
      return [];
    }
  }

  Future<void> addClass(ClassModel classModel) async {
    try {
      if (_box == null) {
        await initialize();
      }
      final classes = await getClasses();
      classes.add(classModel);
      await saveClasses(classes);
      print('Added class to local storage: ${classModel.name}');
    } catch (e) {
      print('Error adding class: $e');
      rethrow;
    }
  }

  Future<void> removeClass(String id) async {
    try {
      if (_box == null) {
        await initialize();
      }
      final classes = await getClasses();
      classes.removeWhere((c) => c.id == id);
      await saveClasses(classes);
      print('Removed class from local storage: $id');
    } catch (e) {
      print('Error removing class: $e');
      rethrow;
    }
  }

  Future<void> clear() async {
    try {
      if (_box == null) {
        await initialize();
      }
      await _box!.clear();
      print('Local storage cleared');
    } catch (e) {
      print('Error clearing storage: $e');
      rethrow;
    }
  }
}
