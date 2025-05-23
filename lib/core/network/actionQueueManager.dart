import 'dart:async';
import 'dart:isolate';
import 'package:group33_dart/core/network/internet.dart';
import 'package:group33_dart/data/sources/local/local_storage_service.dart';
import 'package:group33_dart/services/api_service_adapter.dart';
import 'package:group33_dart/globals.dart';

class ActionQueueManager {
  /// Singleton pattern
  static final ActionQueueManager _instance = ActionQueueManager._internal();
  factory ActionQueueManager() => _instance;
  ActionQueueManager._internal();

  final LocalStorageService _localStorage = LocalStorageService();
  final ApiServiceAdapter apiServiceAdapter =
      ApiServiceAdapter(backendUrl: backendUrl);

  bool _isProcessing = false;
  bool _isConnected = false;
  Timer? _timer;

  /// Number of pending actions in the queue
  Future<int> get queueLength async =>
      (await _localStorage.loadActionQueue()).length;

  /// Initialize the queue manager: perform an immediate check and start monitoring
  Future<void> init() async {
    dispose();
    await _checkConnection(); // Usar la verificación de conexión con Isolate
    print('Manager inicializado');
    await _startMonitoring();
  }

  /// Method to set the connection status
  void setConnectionStatus(bool isConnected) {
    _isConnected = isConnected;
    if (_isConnected && userId != '1') {
      _processQueue();
    }
  }

  /// Start periodic monitoring of the connection
  Future<void> _startMonitoring() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _timer =
        Timer.periodic(const Duration(seconds: 5), (_) => _checkConnection());
  }

  /// Check the internet connection using an isolate
  Future<void> _checkConnection() async {
    try {
      final receivePort =
          ReceivePort(); // Puerto para recibir mensajes del Isolate

      // Llama al Isolate para realizar la verificación de conexión
      await Isolate.spawn(checkConnectionInIsolate, receivePort.sendPort);

      // Espera el resultado del Isolate
      final result = await receivePort.first;

      setConnectionStatus(
          result); // Establece el estado de la conexión basado en el resultado
    } catch (e) {
      print('Error verifying connection in isolate: $e');
      setConnectionStatus(
          false); // En caso de error, establece la conexión como falsa
    }
  }

  /// Function to be executed in the isolate to check the internet connection
  static Future<void> checkConnectionInIsolate(SendPort sendPort) async {
    try {
      final result =
          await checkInternetConnection(); // Verificación de conexión
      sendPort.send(result); // Enviar el resultado al puerto de envío
    } catch (e) {
      print('Error in isolate: $e');
      sendPort.send(false); // Enviar 'false' si ocurre un error
    }
  }

  /// Add a new action to the queue
  Future<void> addAction(String id, String action) async {
    final queue = await _localStorage.loadActionQueue();
    queue.add({'key': id, 'value': action, 'attempts': '0'});
    await _localStorage.saveActionQueue(queue);
    if (_isConnected && userId != '1') {
      await _processQueue();
    }
  }

  /// Update an existing action in the queue
  Future<bool> updateAction(String id, String newAction) async {
    final queue = await _localStorage.loadActionQueue();
    final index = queue.indexWhere((entry) => entry['key'] == id);
    if (index != -1) {
      queue[index] = {'key': id, 'value': newAction, 'attempts': '0'};
      await _localStorage.saveActionQueue(queue);
      return true;
    }
    return false;
  }

  /// Process the queue: send each action to the server
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      var queue = await _localStorage.loadActionQueue();

      while (queue.isNotEmpty && _isConnected) {
        final entry = queue.removeAt(0);
        await _localStorage.saveActionQueue(queue);
        try {
          await actionCatalog(entry['key'] ?? '', entry['value'] ?? '');
        } catch (e) {
          print('Error while executing action: $e');
          String attempts = entry['attempts'] ?? '0';
          if (attempts == '0') {
            entry['attempts'] = '1';
            queue.add(entry);
            await _localStorage.saveActionQueue(queue);
          } else {
            print('Descartando acción después de 2 intentos: ${entry['key']}');
          }
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Block until queue is empty (useful for testing/sync)
  Future<void> waitForEmptyQueue({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final endTime = DateTime.now().add(timeout);
    while (
        (await _localStorage.loadActionQueue()).isNotEmpty || _isProcessing) {
      if (DateTime.now().isAfter(endTime)) {
        throw Exception('Timeout waiting for empty queue');
      }
      if (!(await checkInternetConnection())) {
        throw Exception('No connection');
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Map action keys to API calls
  Future<void> actionCatalog(String id, String action) async {
    if (action == 'note create') {
      final note = await _localStorage.getNote(id);
      await apiServiceAdapter.createNote(
        note['title'],
        note['content'],
        note['subject'],
        userId,
      );
    } else if (action == 'note update') {
      final note = await _localStorage.getNote(id);
      await apiServiceAdapter.updateNote(
        id,
        note['title'],
        note['content'],
        note['subject'],
        DateTime.now().toIso8601String(),
        DateTime.now().toIso8601String(),
        userId,
      );
    } else if (action == 'note delete') {
      await apiServiceAdapter.deleteNote(id);
    }
    else if (action == 'reminder create') {
  final reminderJson = await _localStorage.getReminder(id);
  await apiServiceAdapter.createReminderFromJson(reminderJson);
} else if (action == 'reminder update') {
  final reminderJson = await _localStorage.getReminder(id);
  await apiServiceAdapter.updateReminderFromJson(id, reminderJson);
}

  }

  /// Clean up timer
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  bool getIsConnected() {
    return _isConnected;
  }
}
