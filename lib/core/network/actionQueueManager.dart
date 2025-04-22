import 'dart:async';
import 'package:group33_dart/core/network/internet.dart';

typedef ActionCallback = Future<void> Function();

class ActionQueueManager {
  int get queueLength => _actionQueue.length;
  bool _isProcessing = false;
  static final ActionQueueManager _instance = ActionQueueManager._internal();
  factory ActionQueueManager() => _instance;

  ActionQueueManager._internal() {
    _startMonitoring();
  }

  final List<MapEntry<String, ActionCallback>> _actionQueue = [];
  bool _isConnected = false;

  Timer? _timer;

  void _startMonitoring() {
    _timer = Timer.periodic(Duration(seconds: 5), (_) => _checkConnection());
  }

  Future<void> _checkConnection() async {
    try {
      final result = await checkInternetConnection();
      if (result && !_isConnected) {
        _isConnected = true;
        _processQueue();
      } else if (!result) {
        _isConnected = false;
      }
    } catch (e) {
      print('Error verifying connection: $e');
      _isConnected = false;
    }
  }

  Future<void> addAction(String id, ActionCallback action) async {
    _actionQueue.add(MapEntry(id, action));
    if (_isConnected) {
      _processQueue();
    }
  }

  bool updateAction(String id, ActionCallback newAction) {
    final index = _actionQueue.indexWhere((entry) => entry.key == id);
    if (index != -1) {
      _actionQueue[index] = MapEntry(id, newAction);
      return true;
    }
    return false;
  }

  void _processQueue() async {
    _isProcessing = true;
    while (_actionQueue.isNotEmpty && _isConnected) {
      final entry = _actionQueue.removeAt(0);
      try {
        await entry.value();
      } catch (e) {
        print('Error while action: $e');
      }
    }
    _isProcessing = false;
  }

  Future<void> waitForEmptyQueue({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (_actionQueue.isNotEmpty || _isProcessing) {
      if (DateTime.now().isAfter(endTime)) {
        throw Exception('Timeout');
      }

      if (!(await checkInternetConnection())) {
        throw Exception('No wifi');
      }

      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
