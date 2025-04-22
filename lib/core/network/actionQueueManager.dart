import 'dart:async';
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
    while (userId == '1') {
      await Future.delayed(Duration(
          seconds: 1)); // Espera 1 segundo antes de comprobar nuevamente
    }
    dispose();
    await _checkConnection();
    print('Manager inicializado');
    await _startMonitoring();
  }

  Future<void> _startMonitoring() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _timer =
        Timer.periodic(const Duration(seconds: 5), (_) => _checkConnection());
  }

  Future<void> _checkConnection() async {
    print(await _localStorage.loadActionQueue());
    print(await _localStorage.loadNotes());
    try {
      final result = await checkInternetConnection();
      if (result) {
        if (!_isConnected) {
          _isConnected = true;
          await _processQueue();
        }
      } else {
        _isConnected = false;
      }
    } catch (e) {
      print('Error verifying connection: $e');
      _isConnected = false;
    }
  }

  /// Add a new action to the queue
  Future<void> addAction(String id, String action) async {
    final queue = await _localStorage.loadActionQueue();
    queue.add({'key': id, 'value': action});
    await _localStorage.saveActionQueue(queue);
    if (_isConnected) {
      await _processQueue();
    }
  }

  /// Update an existing action in the queue
  Future<bool> updateAction(String id, String newAction) async {
    final queue = await _localStorage.loadActionQueue();
    final index = queue.indexWhere((entry) => entry['key'] == id);
    if (index != -1) {
      queue[index] = {'key': id, 'value': newAction};
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
    print(await _localStorage.loadActionQueue());
    print(await _localStorage.loadNotes());

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
  }

  /// Clean up timer
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
