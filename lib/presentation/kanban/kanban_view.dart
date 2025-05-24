import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/kanban_task.dart';
import '../../services/api_service_adapter.dart';
import '../../globals.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/sources/local/kanban_local_service.dart';
import 'kanban_view_offline.dart';

class KanbanView extends StatefulWidget {
  const KanbanView({Key? key}) : super(key: key);

  @override
  State<KanbanView> createState() => _KanbanViewState();
}

class _KanbanViewState extends State<KanbanView> {
  List<KanbanTask> tasks = [];
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectController = TextEditingController();
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  int _selectedPriority = 2;
  int _currentColumnIndex = 0;
  bool _isHorizontalView = false;
  String? _kanbanId;
  bool? _isOffline;
  late final Connectivity _connectivity = Connectivity();
  late final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  bool _isLoading = false;

  final List<String> _columns = ['To Do', 'In Progress', 'Done'];
  final List<String> _statuses = ['todo', 'in_progress', 'done'];

  late final ApiServiceAdapter _apiService =
      ApiServiceAdapter(backendUrl: backendUrl);
  final KanbanLocalService _localService = KanbanLocalService();

  // Añadir mapa de caché para tareas por estado
  final Map<String, List<KanbanTask>> _tasksByStatus = {};

  // Añadir variables para métricas
  final Map<String, Stopwatch> _operationTimers = {};
  final Map<String, List<int>> _operationTimes = {};

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return const Color(0xFFC8E6C9); // pastel green
      case 2:
        return const Color(0xFFFFF9C4); // pastel yellow
      case 3:
        return const Color(0xFFFFCDD2); // pastel red/rose
      default:
        return Colors.grey.shade200; // Default grey
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchKanbanId();
    _checkConnectivity();
    _connectivity.onConnectivityChanged.listen((result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = result == ConnectivityResult.none;
    });
  }

  void _showOfflineBanner() {
    _scaffoldMessengerKey.currentState?.clearMaterialBanners();
    _scaffoldMessengerKey.currentState?.showMaterialBanner(
      MaterialBanner(
        content: const Text(
          'You are offline. Changes will sync when you are back online.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepOrange,
        actions: [
          TextButton(
            onPressed: () => _hideOfflineBanner(),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _hideOfflineBanner() {
    _scaffoldMessengerKey.currentState?.clearMaterialBanners();
  }

  Future<void> _fetchKanbanId() async {
    try {
      final id = await _apiService.getKanbanIdByUser(userId);
      setState(() {
        _kanbanId = id;
      });
      await _localService.saveKanbanId(id);
      await _fetchKanbanTasks(id);
    } catch (e) {
      final localId = await _localService.loadKanbanId();
      if (localId != null) {
        setState(() {
          _kanbanId = localId;
        });
        await _fetchKanbanTasks(localId);
      } else {
        final isOfflineNow =
            await Connectivity().checkConnectivity() == ConnectivityResult.none;
        if (!isOfflineNow) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('Error fetching Kanban ID: $e')),
          );
        }
      }
    }
  }

  Future<void> _fetchKanbanTasks(String kanbanId) async {
    try {
      if (_isOffline == true) {
        final localTasks = await _localService.loadTasks();
        setState(() {
          tasks = localTasks;
          _updateTasksCache();
        });
        return;
      }
      final backendTasks = await _apiService.getTasksForKanban(kanbanId);
      final mappedTasks = backendTasks.map((backendTask) {
        String localStatus = _toLocalStatus(backendTask['status']);
        int localPriority = backendTask['priority'] == 'high'
            ? 3
            : backendTask['priority'] == 'medium'
                ? 2
                : 1;
        return KanbanTask(
          id: backendTask['_id'],
          title: backendTask['title'],
          description: backendTask['description'] ?? '',
          status: localStatus,
          createdAt: DateTime.now(),
          dueDate: backendTask['due_date'] != null
              ? DateTime.parse(backendTask['due_date'])
              : null,
          subject: backendTask['subject'],
          priority: localPriority,
        );
      }).toList();

      // Guardar en almacenamiento local
      await _localService.saveTasks(mappedTasks);

      setState(() {
        tasks = mappedTasks;
        _updateTasksCache();
      });
    } catch (e) {
      final isOfflineNow =
          await Connectivity().checkConnectivity() == ConnectivityResult.none;
      if (!isOfflineNow) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Error fetching Kanban tasks: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _navigateColumn(int direction) {
    setState(() {
      _currentColumnIndex =
          (_currentColumnIndex + direction).clamp(0, _columns.length - 1);
    });
  }

  void _moveTask(KanbanTask task, int direction) {
    final currentIndex = _statuses.indexOf(task.status);
    final newIndex = (currentIndex + direction).clamp(0, _statuses.length - 1);
    _updateTaskStatus(task, _statuses[newIndex]);
  }

  Future<void> _showValidationError(String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validation Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _addTask() async {
    if (_kanbanId == null) {
      await _showValidationError('Kanban board not loaded.');
      return;
    }
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add New Task'),
          content: _isLoading
              ? const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()))
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: 'Title'),
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Please enter a title'
                              : null,
                        ),
                        TextFormField(
                          controller: _descriptionController,
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                          maxLines: 3,
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Please enter a description'
                              : null,
                        ),
                        TextFormField(
                          controller: _subjectController,
                          decoration:
                              const InputDecoration(labelText: 'Subject'),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _selectedPriority,
                          decoration:
                              const InputDecoration(labelText: 'Priority'),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Low')),
                            DropdownMenuItem(value: 2, child: Text('Medium')),
                            DropdownMenuItem(value: 3, child: Text('High')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedPriority = value ?? 2;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: Text(_selectedDueDate == null
                              ? 'Select Due Date & Time'
                              : 'Due: '
                                  '${_selectedDueDate!.toString().split(' ')[0]} '
                                  '${_selectedDueTime != null ? _selectedDueTime!.format(context) : ''}'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              setState(() {
                                _selectedDueDate = date;
                                _selectedDueTime = time;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      try {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          await _showValidationError(
                              'Please fill all required fields.');
                          return;
                        }
                        if (_selectedDueDate == null ||
                            _selectedDueTime == null) {
                          await _showValidationError(
                              'Please select a due date and time.');
                          return;
                        }
                        setStateDialog(() => _isLoading = true);
                        final dueDateTime = DateTime(
                          _selectedDueDate!.year,
                          _selectedDueDate!.month,
                          _selectedDueDate!.day,
                          _selectedDueTime!.hour,
                          _selectedDueTime!.minute,
                        );
                        String backendPriority = _selectedPriority == 3
                            ? 'high'
                            : _selectedPriority == 2
                                ? 'medium'
                                : 'low';
                        String backendStatus = 'pending';
                        if (_isOffline == true) {
                          // OFFLINE: Save locally and add to queue
                          final localId =
                              DateTime.now().millisecondsSinceEpoch.toString();
                          final localTask = KanbanTask(
                            id: localId,
                            title: _titleController.text,
                            description: _descriptionController.text,
                            status: 'todo',
                            createdAt: DateTime.now(),
                            dueDate: dueDateTime,
                            subject: _subjectController.text,
                            priority: _selectedPriority,
                          );
                          final tasksLocal = await _localService.loadTasks();
                          tasksLocal.add(localTask);
                          await _localService.saveTasks(tasksLocal);
                          // Add to action queue
                          final queue = await _localService.loadActionQueue();
                          queue.add({
                            'action': 'add',
                            'task': localTask.toJson(),
                          });
                          await _localService.saveActionQueue(queue);
                          setStateDialog(() => _isLoading = false);
                          Navigator.pop(context);
                          _scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Task saved locally. It will sync when you are back online.')),
                          );
                          _titleController.clear();
                          _descriptionController.clear();
                          _subjectController.clear();
                          _selectedDueDate = null;
                          _selectedDueTime = null;
                          _selectedPriority = 2;
                          setState(() {
                            tasks = tasksLocal;
                          });
                          return;
                        }
                        // ONLINE: Normal flow
                        final backendTask =
                            await _apiService.createKanbanTaskOnBackend(
                          title: _titleController.text,
                          description: _descriptionController.text,
                          dueDate: dueDateTime,
                          priority: backendPriority,
                          status: backendStatus,
                          userId: userId,
                        );
                        await _apiService.addTaskToKanban(
                            _kanbanId!, backendTask['_id']);
                        await _fetchKanbanTasks(_kanbanId!);
                        setStateDialog(() => _isLoading = false);
                        Navigator.pop(context);
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          const SnackBar(
                              content: Text('Task created successfully.')),
                        );
                        _titleController.clear();
                        _descriptionController.clear();
                        _subjectController.clear();
                        _selectedDueDate = null;
                        _selectedDueTime = null;
                        _selectedPriority = 2;
                      } catch (e) {
                        setStateDialog(() => _isLoading = false);
                        String errorMsg = 'Error creating task: ';
                        if (e.toString().contains('Failed host lookup')) {
                          errorMsg += 'No internet connection.';
                        } else {
                          errorMsg += e.toString();
                        }
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(content: Text(errorMsg)),
                        );
                      }
                    },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to map local status to backend status
  String _toBackendStatus(String localStatus) {
    switch (localStatus) {
      case 'todo':
        return 'pending';
      case 'in_progress':
        return 'in_progress';
      case 'done':
        return 'completed';
      default:
        return 'pending';
    }
  }

  // Helper to map backend status to local status
  String _toLocalStatus(String backendStatus) {
    switch (backendStatus) {
      case 'pending':
        return 'todo';
      case 'in_progress':
        return 'in_progress';
      case 'completed':
        return 'done';
      default:
        return 'todo';
    }
  }

  // Método para actualizar la caché
  void _updateTasksCache() {
    _tasksByStatus.clear();
    for (var task in tasks) {
      _tasksByStatus.putIfAbsent(task.status, () => []).add(task);
    }
  }

  void _startOperationTimer(String operation) {
    _operationTimers[operation] = Stopwatch()..start();
  }

  void _stopOperationTimer(String operation) {
    final timer = _operationTimers[operation];
    if (timer != null) {
      timer.stop();
      _operationTimes
          .putIfAbsent(operation, () => [])
          .add(timer.elapsedMilliseconds);
      print('$operation took ${timer.elapsedMilliseconds}ms');
      _operationTimers.remove(operation);
    }
  }

  Future<void> _updateTaskStatus(KanbanTask task, String newStatus) async {
    _startOperationTimer('move_task');
    String backendStatus = _toBackendStatus(newStatus);
    String backendPriority = task.priority == 3
        ? 'high'
        : task.priority == 2
            ? 'medium'
            : 'low';
    try {
      await _apiService.updateKanbanTaskOnBackend(
        id: task.id,
        title: task.title,
        description: task.description,
        dueDate: task.dueDate ?? DateTime.now(),
        priority: backendPriority,
        status: backendStatus,
        userId: userId,
      );

      setState(() {
        tasks.removeWhere((t) => t.id == task.id);
        final updatedTask = KanbanTask(
          id: task.id,
          title: task.title,
          description: task.description,
          status: newStatus,
          createdAt: task.createdAt,
          dueDate: task.dueDate,
          subject: task.subject,
          priority: task.priority,
        );
        tasks.add(updatedTask);
        _updateTasksCache();
      });
      _stopOperationTimer('move_task');
    } catch (e) {
      _stopOperationTimer('move_task');
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<void> _editTask(KanbanTask task) async {
    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _subjectController.text = task.subject ?? '';
    _selectedDueDate = task.dueDate;
    _selectedDueTime =
        TimeOfDay(hour: task.dueDate!.hour, minute: task.dueDate!.minute);
    _selectedPriority = task.priority;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Task'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a title' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Low')),
                    DropdownMenuItem(value: 2, child: Text('Medium')),
                    DropdownMenuItem(value: 3, child: Text('High')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value ?? 2;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(_selectedDueDate == null
                      ? 'Select Due Date & Time'
                      : 'Due: '
                          '${_selectedDueDate!.toString().split(' ')[0]} '
                          '${_selectedDueTime != null ? _selectedDueTime!.format(context) : ''}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedDueTime ?? TimeOfDay.now(),
                      );
                      setState(() {
                        _selectedDueDate = date;
                        _selectedDueTime = time;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _titleController.clear();
              _descriptionController.clear();
              _subjectController.clear();
              _selectedDueDate = null;
              _selectedDueTime = null;
              _selectedPriority = 2;
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final stopwatch = Stopwatch()..start();
                String backendPriority = _selectedPriority == 3
                    ? 'high'
                    : _selectedPriority == 2
                        ? 'medium'
                        : 'low';
                String backendStatus =
                    _toBackendStatus(task.status); // map local to backend
                try {
                  final dueDateTime = DateTime(
                    _selectedDueDate!.year,
                    _selectedDueDate!.month,
                    _selectedDueDate!.day,
                    _selectedDueTime!.hour,
                    _selectedDueTime!.minute,
                  );
                  await _apiService.updateKanbanTaskOnBackend(
                    id: task.id,
                    title: _titleController.text,
                    description: _descriptionController.text,
                    dueDate: dueDateTime,
                    priority: backendPriority,
                    status: backendStatus,
                    userId: userId,
                  );
                  // Optimización: Actualizar solo la tarea localmente
                  setState(() {
                    tasks.removeWhere((t) => t.id == task.id);
                    final updatedTask = KanbanTask(
                      id: task.id,
                      title: _titleController.text,
                      description: _descriptionController.text,
                      status: task.status,
                      createdAt: task.createdAt,
                      dueDate: dueDateTime,
                      subject: _subjectController.text,
                      priority: _selectedPriority,
                    );
                    tasks.add(updatedTask);
                    _updateTasksCache();
                  });
                } catch (e) {
                  _scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(content: Text('Error updating task: $e')),
                  );
                }
                stopwatch.stop();
                final elapsedMs = stopwatch.elapsedMilliseconds;
                _operationTimes
                    .putIfAbsent('edit_task', () => [])
                    .add(elapsedMs);
                print('Edit task took ${elapsedMs}ms');
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(content: Text('Editar tarea tomó ${elapsedMs}ms')),
                );
                _titleController.clear();
                _descriptionController.clear();
                _subjectController.clear();
                _selectedDueDate = null;
                _selectedDueTime = null;
                _selectedPriority = 2;
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(KanbanTask task) async {
    _startOperationTimer('delete_task');
    try {
      if (_kanbanId != null) {
        await _apiService.removeTaskFromKanban(_kanbanId!, task.id);
      }
      await _apiService.deleteKanbanTaskOnBackend(task.id);

      setState(() {
        tasks.removeWhere((t) => t.id == task.id);
        _updateTasksCache();
      });
      _stopOperationTimer('delete_task');
    } catch (e) {
      _stopOperationTimer('delete_task');
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error deleting task: $e')),
      );
    }
  }

  void _showTaskDetails(KanbanTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('Description: ${task.description}'),
                ),
              if (task.subject != null && task.subject!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('Subject: ${task.subject}'),
                ),
              if (task.dueDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                      'Due: ${task.dueDate!.toString().replaceFirst("T", " ").substring(0, 16)}'),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                    'Priority: ${task.priority == 3 ? 'High' : task.priority == 2 ? 'Medium' : 'Low'}'),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                    'Status: ${task.status == 'todo' ? 'To Do' : task.status == 'in_progress' ? 'In Progress' : 'Done'}'),
              ),
            ],
          ),
        ),
        actions: [
          if (_isHorizontalView) ...[
            TextButton(
              onPressed: () => _editTask(task),
              child: const Text('Editar'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteTask(task);
                Navigator.of(context).pop();
              },
              child: const Text('Borrar'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _processSyncQueue() async {
    final queue = await _localService.loadActionQueue();
    if (queue.isEmpty || _kanbanId == null) return;
    bool anySynced = false;
    for (final action in List<Map<String, dynamic>>.from(queue)) {
      try {
        if (action['action'] == 'add') {
          final taskJson = action['task'] as Map<String, dynamic>;
          final backendTask = await _apiService.createKanbanTaskOnBackend(
            title: taskJson['title'],
            description: taskJson['description'],
            dueDate: DateTime.parse(taskJson['dueDate']),
            priority: taskJson['priority'] == 3
                ? 'high'
                : taskJson['priority'] == 2
                    ? 'medium'
                    : 'low',
            status: 'pending',
            userId: userId,
          );
          await _apiService.addTaskToKanban(_kanbanId!, backendTask['_id']);
          anySynced = true;
        }
        if (action['action'] == 'delete') {
          final taskJson = action['task'] as Map<String, dynamic>;
          final taskId = taskJson['id'];
          await _apiService.removeTaskFromKanban(_kanbanId!, taskId);
          await _apiService.deleteKanbanTaskOnBackend(taskId);
          anySynced = true;
        }
        // Puedes agregar lógica para 'edit' si la implementas
        queue.remove(action);
        await _localService.saveActionQueue(queue);
      } catch (_) {
        continue;
      }
    }
    if (anySynced) {
      await _fetchKanbanTasks(_kanbanId!);
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Changes synced with the server.')),
      );
    }
    final tasksLocal = await _localService.loadTasks();
    if (tasksLocal.isNotEmpty) {
      await _localService.saveTasks([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    print('KanbanView build: _isOffline=$_isOffline, _kanbanId=$_kanbanId');
    if (_isOffline == null) {
      print('KanbanView: Loading state');
      return const Center(child: CircularProgressIndicator());
    }
    if (_isOffline!) {
      print('KanbanView: Offline, showing KanbanViewOffline');
      return const KanbanViewOffline();
    } else {
      print('KanbanView: Online, showing KanbanViewOnline');
      return KanbanViewOnline();
    }
  }
}

class KanbanViewOnline extends StatefulWidget {
  const KanbanViewOnline({Key? key}) : super(key: key);

  @override
  State<KanbanViewOnline> createState() => _KanbanViewOnlineState();
}

class _KanbanViewOnlineState extends State<KanbanViewOnline> {
  List<KanbanTask> tasks = [];
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectController = TextEditingController();
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  int _selectedPriority = 2;
  int _currentColumnIndex = 0;
  bool _isHorizontalView = false;
  String? _kanbanId;
  bool _isOffline = false;
  late final Connectivity _connectivity = Connectivity();
  late final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  bool _isLoading = false;

  final List<String> _columns = ['To Do', 'In Progress', 'Done'];
  final List<String> _statuses = ['todo', 'in_progress', 'done'];

  late final ApiServiceAdapter _apiService =
      ApiServiceAdapter(backendUrl: backendUrl);
  final KanbanLocalService _localService = KanbanLocalService();

  // Añadir mapa de caché para tareas por estado
  final Map<String, List<KanbanTask>> _tasksByStatus = {};

  // Añadir variables para métricas
  final Map<String, Stopwatch> _operationTimers = {};
  final Map<String, List<int>> _operationTimes = {};

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return const Color(0xFFC8E6C9); // pastel green
      case 2:
        return const Color(0xFFFFF9C4); // pastel yellow
      case 3:
        return const Color(0xFFFFCDD2); // pastel red/rose
      default:
        return Colors.grey.shade200; // Default grey
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchKanbanId();
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivity.onConnectivityChanged
        .listen((ConnectivityResult result) async {
      final offline = result == ConnectivityResult.none;
      if (offline != _isOffline) {
        setState(() {
          _isOffline = offline;
        });
        if (offline) {
          _showOfflineBanner();
        } else {
          _hideOfflineBanner();
          // On reconnect, try to sync the queue
          await _processSyncQueue();
        }
      }
    });
  }

  void _showOfflineBanner() {
    _scaffoldMessengerKey.currentState?.clearMaterialBanners();
    _scaffoldMessengerKey.currentState?.showMaterialBanner(
      MaterialBanner(
        content: const Text(
          'You are offline. Changes will sync when you are back online.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepOrange,
        actions: [
          TextButton(
            onPressed: () => _hideOfflineBanner(),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _hideOfflineBanner() {
    _scaffoldMessengerKey.currentState?.clearMaterialBanners();
  }

  Future<void> _fetchKanbanId() async {
    try {
      final id = await _apiService.getKanbanIdByUser(userId);
      setState(() {
        _kanbanId = id;
      });
      await _localService.saveKanbanId(id);
      await _fetchKanbanTasks(id);
    } catch (e) {
      final localId = await _localService.loadKanbanId();
      if (localId != null) {
        setState(() {
          _kanbanId = localId;
        });
        await _fetchKanbanTasks(localId);
      } else {
        final isOfflineNow =
            await Connectivity().checkConnectivity() == ConnectivityResult.none;
        if (!isOfflineNow) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('Error fetching Kanban ID: $e')),
          );
        }
      }
    }
  }

  Future<void> _fetchKanbanTasks(String kanbanId) async {
    try {
      if (_isOffline) {
        final localTasks = await _localService.loadTasks();
        setState(() {
          tasks = localTasks;
          _updateTasksCache();
        });
        return;
      }
      final backendTasks = await _apiService.getTasksForKanban(kanbanId);
      final mappedTasks = backendTasks.map((backendTask) {
        String localStatus = _toLocalStatus(backendTask['status']);
        int localPriority = backendTask['priority'] == 'high'
            ? 3
            : backendTask['priority'] == 'medium'
                ? 2
                : 1;
        return KanbanTask(
          id: backendTask['_id'],
          title: backendTask['title'],
          description: backendTask['description'] ?? '',
          status: localStatus,
          createdAt: DateTime.now(),
          dueDate: backendTask['due_date'] != null
              ? DateTime.parse(backendTask['due_date'])
              : null,
          subject: backendTask['subject'],
          priority: localPriority,
        );
      }).toList();

      // Guardar en almacenamiento local
      await _localService.saveTasks(mappedTasks);

      setState(() {
        tasks = mappedTasks;
        _updateTasksCache();
      });
    } catch (e) {
      final isOfflineNow =
          await Connectivity().checkConnectivity() == ConnectivityResult.none;
      if (!isOfflineNow) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Error fetching Kanban tasks: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _navigateColumn(int direction) {
    setState(() {
      _currentColumnIndex =
          (_currentColumnIndex + direction).clamp(0, _columns.length - 1);
    });
  }

  void _moveTask(KanbanTask task, int direction) {
    final currentIndex = _statuses.indexOf(task.status);
    final newIndex = (currentIndex + direction).clamp(0, _statuses.length - 1);
    _updateTaskStatus(task, _statuses[newIndex]);
  }

  Future<void> _showValidationError(String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validation Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _addTask() async {
    if (_kanbanId == null) {
      await _showValidationError('Kanban board not loaded.');
      return;
    }
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Add New Task'),
          content: _isLoading
              ? const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()))
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: 'Title'),
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Please enter a title'
                              : null,
                        ),
                        TextFormField(
                          controller: _descriptionController,
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                          maxLines: 3,
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Please enter a description'
                              : null,
                        ),
                        TextFormField(
                          controller: _subjectController,
                          decoration:
                              const InputDecoration(labelText: 'Subject'),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _selectedPriority,
                          decoration:
                              const InputDecoration(labelText: 'Priority'),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Low')),
                            DropdownMenuItem(value: 2, child: Text('Medium')),
                            DropdownMenuItem(value: 3, child: Text('High')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedPriority = value ?? 2;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: Text(_selectedDueDate == null
                              ? 'Select Due Date & Time'
                              : 'Due: '
                                  '${_selectedDueDate!.toString().split(' ')[0]} '
                                  '${_selectedDueTime != null ? _selectedDueTime!.format(context) : ''}'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              setState(() {
                                _selectedDueDate = date;
                                _selectedDueTime = time;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      try {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          await _showValidationError(
                              'Please fill all required fields.');
                          return;
                        }
                        if (_selectedDueDate == null ||
                            _selectedDueTime == null) {
                          await _showValidationError(
                              'Please select a due date and time.');
                          return;
                        }
                        setStateDialog(() => _isLoading = true);
                        final dueDateTime = DateTime(
                          _selectedDueDate!.year,
                          _selectedDueDate!.month,
                          _selectedDueDate!.day,
                          _selectedDueTime!.hour,
                          _selectedDueTime!.minute,
                        );
                        String backendPriority = _selectedPriority == 3
                            ? 'high'
                            : _selectedPriority == 2
                                ? 'medium'
                                : 'low';
                        String backendStatus = 'pending';
                        if (_isOffline) {
                          // OFFLINE: Save locally and add to queue
                          final localId =
                              DateTime.now().millisecondsSinceEpoch.toString();
                          final localTask = KanbanTask(
                            id: localId,
                            title: _titleController.text,
                            description: _descriptionController.text,
                            status: 'todo',
                            createdAt: DateTime.now(),
                            dueDate: dueDateTime,
                            subject: _subjectController.text,
                            priority: _selectedPriority,
                          );
                          final tasksLocal = await _localService.loadTasks();
                          tasksLocal.add(localTask);
                          await _localService.saveTasks(tasksLocal);
                          // Add to action queue
                          final queue = await _localService.loadActionQueue();
                          queue.add({
                            'action': 'add',
                            'task': localTask.toJson(),
                          });
                          await _localService.saveActionQueue(queue);
                          setStateDialog(() => _isLoading = false);
                          Navigator.pop(context);
                          _scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Task saved locally. It will sync when you are back online.')),
                          );
                          _titleController.clear();
                          _descriptionController.clear();
                          _subjectController.clear();
                          _selectedDueDate = null;
                          _selectedDueTime = null;
                          _selectedPriority = 2;
                          setState(() {
                            tasks = tasksLocal;
                          });
                          return;
                        }
                        // ONLINE: Normal flow
                        final backendTask =
                            await _apiService.createKanbanTaskOnBackend(
                          title: _titleController.text,
                          description: _descriptionController.text,
                          dueDate: dueDateTime,
                          priority: backendPriority,
                          status: backendStatus,
                          userId: userId,
                        );
                        await _apiService.addTaskToKanban(
                            _kanbanId!, backendTask['_id']);
                        await _fetchKanbanTasks(_kanbanId!);
                        setStateDialog(() => _isLoading = false);
                        Navigator.pop(context);
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          const SnackBar(
                              content: Text('Task created successfully.')),
                        );
                        _titleController.clear();
                        _descriptionController.clear();
                        _subjectController.clear();
                        _selectedDueDate = null;
                        _selectedDueTime = null;
                        _selectedPriority = 2;
                      } catch (e) {
                        setStateDialog(() => _isLoading = false);
                        String errorMsg = 'Error creating task: ';
                        if (e.toString().contains('Failed host lookup')) {
                          errorMsg += 'No internet connection.';
                        } else {
                          errorMsg += e.toString();
                        }
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(content: Text(errorMsg)),
                        );
                      }
                    },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to map local status to backend status
  String _toBackendStatus(String localStatus) {
    switch (localStatus) {
      case 'todo':
        return 'pending';
      case 'in_progress':
        return 'in_progress';
      case 'done':
        return 'completed';
      default:
        return 'pending';
    }
  }

  // Helper to map backend status to local status
  String _toLocalStatus(String backendStatus) {
    switch (backendStatus) {
      case 'pending':
        return 'todo';
      case 'in_progress':
        return 'in_progress';
      case 'completed':
        return 'done';
      default:
        return 'todo';
    }
  }

  // Método para actualizar la caché
  void _updateTasksCache() {
    _tasksByStatus.clear();
    for (var task in tasks) {
      _tasksByStatus.putIfAbsent(task.status, () => []).add(task);
    }
  }

  void _startOperationTimer(String operation) {
    _operationTimers[operation] = Stopwatch()..start();
  }

  void _stopOperationTimer(String operation) {
    final timer = _operationTimers[operation];
    if (timer != null) {
      timer.stop();
      _operationTimes
          .putIfAbsent(operation, () => [])
          .add(timer.elapsedMilliseconds);
      print('$operation took ${timer.elapsedMilliseconds}ms');
      _operationTimers.remove(operation);
    }
  }

  Future<void> _updateTaskStatus(KanbanTask task, String newStatus) async {
    _startOperationTimer('move_task');
    String backendStatus = _toBackendStatus(newStatus);
    String backendPriority = task.priority == 3
        ? 'high'
        : task.priority == 2
            ? 'medium'
            : 'low';
    try {
      await _apiService.updateKanbanTaskOnBackend(
        id: task.id,
        title: task.title,
        description: task.description,
        dueDate: task.dueDate ?? DateTime.now(),
        priority: backendPriority,
        status: backendStatus,
        userId: userId,
      );

      setState(() {
        tasks.removeWhere((t) => t.id == task.id);
        final updatedTask = KanbanTask(
          id: task.id,
          title: task.title,
          description: task.description,
          status: newStatus,
          createdAt: task.createdAt,
          dueDate: task.dueDate,
          subject: task.subject,
          priority: task.priority,
        );
        tasks.add(updatedTask);
        _updateTasksCache();
      });
      _stopOperationTimer('move_task');
    } catch (e) {
      _stopOperationTimer('move_task');
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<void> _editTask(KanbanTask task) async {
    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _subjectController.text = task.subject ?? '';
    _selectedDueDate = task.dueDate;
    _selectedDueTime =
        TimeOfDay(hour: task.dueDate!.hour, minute: task.dueDate!.minute);
    _selectedPriority = task.priority;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Task'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a title' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Low')),
                    DropdownMenuItem(value: 2, child: Text('Medium')),
                    DropdownMenuItem(value: 3, child: Text('High')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value ?? 2;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(_selectedDueDate == null
                      ? 'Select Due Date & Time'
                      : 'Due: '
                          '${_selectedDueDate!.toString().split(' ')[0]} '
                          '${_selectedDueTime != null ? _selectedDueTime!.format(context) : ''}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedDueTime ?? TimeOfDay.now(),
                      );
                      setState(() {
                        _selectedDueDate = date;
                        _selectedDueTime = time;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _titleController.clear();
              _descriptionController.clear();
              _subjectController.clear();
              _selectedDueDate = null;
              _selectedDueTime = null;
              _selectedPriority = 2;
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final stopwatch = Stopwatch()..start();
                String backendPriority = _selectedPriority == 3
                    ? 'high'
                    : _selectedPriority == 2
                        ? 'medium'
                        : 'low';
                String backendStatus =
                    _toBackendStatus(task.status); // map local to backend
                try {
                  final dueDateTime = DateTime(
                    _selectedDueDate!.year,
                    _selectedDueDate!.month,
                    _selectedDueDate!.day,
                    _selectedDueTime!.hour,
                    _selectedDueTime!.minute,
                  );
                  await _apiService.updateKanbanTaskOnBackend(
                    id: task.id,
                    title: _titleController.text,
                    description: _descriptionController.text,
                    dueDate: dueDateTime,
                    priority: backendPriority,
                    status: backendStatus,
                    userId: userId,
                  );
                  // Optimización: Actualizar solo la tarea localmente
                  setState(() {
                    tasks.removeWhere((t) => t.id == task.id);
                    final updatedTask = KanbanTask(
                      id: task.id,
                      title: _titleController.text,
                      description: _descriptionController.text,
                      status: task.status,
                      createdAt: task.createdAt,
                      dueDate: dueDateTime,
                      subject: _subjectController.text,
                      priority: _selectedPriority,
                    );
                    tasks.add(updatedTask);
                    _updateTasksCache();
                  });
                } catch (e) {
                  _scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(content: Text('Error updating task: $e')),
                  );
                }
                stopwatch.stop();
                final elapsedMs = stopwatch.elapsedMilliseconds;
                _operationTimes
                    .putIfAbsent('edit_task', () => [])
                    .add(elapsedMs);
                print('Edit task took ${elapsedMs}ms');
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(content: Text('Editar tarea tomó ${elapsedMs}ms')),
                );
                _titleController.clear();
                _descriptionController.clear();
                _subjectController.clear();
                _selectedDueDate = null;
                _selectedDueTime = null;
                _selectedPriority = 2;
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(KanbanTask task) async {
    _startOperationTimer('delete_task');
    try {
      if (_kanbanId != null) {
        await _apiService.removeTaskFromKanban(_kanbanId!, task.id);
      }
      await _apiService.deleteKanbanTaskOnBackend(task.id);

      setState(() {
        tasks.removeWhere((t) => t.id == task.id);
        _updateTasksCache();
      });
      _stopOperationTimer('delete_task');
    } catch (e) {
      _stopOperationTimer('delete_task');
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error deleting task: $e')),
      );
    }
  }

  void _showTaskDetails(KanbanTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('Description: ${task.description}'),
                ),
              if (task.subject != null && task.subject!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('Subject: ${task.subject}'),
                ),
              if (task.dueDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                      'Due: ${task.dueDate!.toString().replaceFirst("T", " ").substring(0, 16)}'),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                    'Priority: ${task.priority == 3 ? 'High' : task.priority == 2 ? 'Medium' : 'Low'}'),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                    'Status: ${task.status == 'todo' ? 'To Do' : task.status == 'in_progress' ? 'In Progress' : 'Done'}'),
              ),
            ],
          ),
        ),
        actions: [
          if (_isHorizontalView) ...[
            TextButton(
              onPressed: () => _editTask(task),
              child: const Text('Editar'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteTask(task);
                Navigator.of(context).pop();
              },
              child: const Text('Borrar'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _processSyncQueue() async {
    final queue = await _localService.loadActionQueue();
    if (queue.isEmpty || _kanbanId == null) return;
    bool anySynced = false;
    for (final action in List<Map<String, dynamic>>.from(queue)) {
      try {
        if (action['action'] == 'add') {
          final taskJson = action['task'] as Map<String, dynamic>;
          final backendTask = await _apiService.createKanbanTaskOnBackend(
            title: taskJson['title'],
            description: taskJson['description'],
            dueDate: DateTime.parse(taskJson['dueDate']),
            priority: taskJson['priority'] == 3
                ? 'high'
                : taskJson['priority'] == 2
                    ? 'medium'
                    : 'low',
            status: 'pending',
            userId: userId,
          );
          await _apiService.addTaskToKanban(_kanbanId!, backendTask['_id']);
          anySynced = true;
        }
        if (action['action'] == 'delete') {
          final taskJson = action['task'] as Map<String, dynamic>;
          final taskId = taskJson['id'];
          await _apiService.removeTaskFromKanban(_kanbanId!, taskId);
          await _apiService.deleteKanbanTaskOnBackend(taskId);
          anySynced = true;
        }
        // Puedes agregar lógica para 'edit' si la implementas
        queue.remove(action);
        await _localService.saveActionQueue(queue);
      } catch (_) {
        continue;
      }
    }
    if (anySynced) {
      await _fetchKanbanTasks(_kanbanId!);
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Changes synced with the server.')),
      );
    }
    final tasksLocal = await _localService.loadTasks();
    if (tasksLocal.isNotEmpty) {
      await _localService.saveTasks([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kanban Board'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(
                  _isHorizontalView ? Icons.view_agenda : Icons.view_column),
              onPressed: () {
                setState(() {
                  _isHorizontalView = !_isHorizontalView;
                });
              },
              tooltip: _isHorizontalView
                  ? 'Switch to Vertical View'
                  : 'Switch to Horizontal View',
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showTaskSummaryDialog,
              tooltip: 'Mostrar Resumen de Tareas',
            ),
            IconButton(
              icon: const Icon(Icons.speed),
              onPressed: _showPerformanceStats,
              tooltip: 'Mostrar Estadísticas de Rendimiento',
            ),
          ],
        ),
        body: (_kanbanId == null && !_isOffline)
            ? const Center(
                child: Text(
                  'Could not load Kanban board. Check your connection or try again later.',
                  style: TextStyle(fontSize: 18, color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              )
            : (_isHorizontalView
                ? Row(
                    children: [
                      for (int i = 0; i < _columns.length; i++)
                        Expanded(
                          child: _buildColumn(_columns[i], _statuses[i],
                              showHeader: true),
                        ),
                    ],
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios),
                              onPressed: _currentColumnIndex > 0
                                  ? () => _navigateColumn(-1)
                                  : null,
                            ),
                            Text(
                              _columns[_currentColumnIndex],
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios),
                              onPressed:
                                  _currentColumnIndex < _columns.length - 1
                                      ? () => _navigateColumn(1)
                                      : null,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildColumn(_columns[_currentColumnIndex],
                            _statuses[_currentColumnIndex]),
                      ),
                    ],
                  )),
        floatingActionButton: _kanbanId == null
            ? null
            : FloatingActionButton(
                onPressed: _kanbanId == null ? null : _addTask,
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  Widget _buildColumn(String title, String status, {bool showHeader = false}) {
    final columnTasks = _tasksByStatus[status] ?? [];
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          if (showHeader)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: columnTasks.isEmpty
                ? const Center(child: Text('No tasks'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: columnTasks.length,
                    itemBuilder: (context, index) {
                      final task = columnTasks[index];
                      return RepaintBoundary(
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          color: _getPriorityColor(task.priority),
                          child: ListTile(
                            title: Text(
                              task.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: _isHorizontalView ? 14 : 16,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                            onTap: () => _showTaskDetails(task),
                            trailing: !_isHorizontalView
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () => _editTask(task),
                                      ),
                                      IconButton(
                                        icon:
                                            const Icon(Icons.delete, size: 20),
                                        onPressed: () async =>
                                            await _deleteTask(task),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back,
                                            size: 20),
                                        onPressed: status != 'todo'
                                            ? () async =>
                                                await _updateTaskStatus(
                                                    task,
                                                    _statuses[_statuses
                                                            .indexOf(status) -
                                                        1])
                                            : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward,
                                            size: 20),
                                        onPressed: status != 'done'
                                            ? () async =>
                                                await _updateTaskStatus(
                                                    task,
                                                    _statuses[_statuses
                                                            .indexOf(status) +
                                                        1])
                                            : null,
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showTaskSummaryDialog() {
    final stopwatch = Stopwatch()..start();
    final int todoCount = tasks.where((t) => t.status == 'todo').length;
    final int inProgressCount =
        tasks.where((t) => t.status == 'in_progress').length;
    final int doneCount = tasks.where((t) => t.status == 'done').length;

    // Contadores por prioridad
    final int lowPriorityCount = tasks.where((t) => t.priority == 1).length;
    final int mediumPriorityCount = tasks.where((t) => t.priority == 2).length;
    final int highPriorityCount = tasks.where((t) => t.priority == 3).length;

    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds;
    print('Task summary calculation took ${elapsedMs}ms');
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('Resumen de tareas calculado en ${elapsedMs}ms')),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Task Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start, // Alinear el contenido a la izquierda
          children: [
            Text('By Status:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87)), // Color de texto oscuro
            const SizedBox(height: 4),
            _buildStatusSummary('To Do', todoCount, Colors.amber.shade700),
            const SizedBox(height: 4), // Espacio reducido
            _buildStatusSummary(
                'In Progress', inProgressCount, Colors.blue.shade400),
            const SizedBox(height: 4),
            _buildStatusSummary('Done', doneCount, Colors.green.shade400),
            const SizedBox(
                height: 16), // Espacio antes de la sección de prioridad
            Text('By Priority:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87)), // Color de texto oscuro
            const SizedBox(height: 4),
            _buildStatusSummary('Low', lowPriorityCount,
                const Color(0xFFC8E6C9)), // Verde pastel
            const SizedBox(height: 4),
            _buildStatusSummary('Medium', mediumPriorityCount,
                const Color(0xFFFFF9C4)), // Amarillo pastel
            const SizedBox(height: 4),
            _buildStatusSummary('High', highPriorityCount,
                const Color(0xFFFFCDD2)), // Rojo pastel/rosa
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummary(String label, int count, Color color) {
    // Usamos un color de texto oscuro para asegurar la legibilidad
    final Color textColor = Colors.black87;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(
                0.15), // Fondo claro con el color de estado/prioridad
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$label: ',
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    fontSize: 12), // Usar color de texto oscuro
              ),
              Text(
                '$count',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 14), // Usar color de texto oscuro
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Añadir método para mostrar estadísticas
  void _showPerformanceStats() {
    final stats = StringBuffer();
    stats.writeln('Performance Statistics:');
    stats.writeln('---------------------');

    _operationTimes.forEach((operation, times) {
      if (times.isNotEmpty) {
        final avg = times.reduce((a, b) => a + b) / times.length;
        final min = times.reduce((a, b) => a < b ? a : b);
        final max = times.reduce((a, b) => a > b ? a : b);
        stats.writeln('$operation:');
        stats.writeln('  Average: ${avg.toStringAsFixed(2)}ms');
        stats.writeln('  Min: ${min}ms');
        stats.writeln('  Max: ${max}ms');
        stats.writeln('  Samples: ${times.length}');
        stats.writeln('---------------------');
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Performance Statistics'),
        content: SingleChildScrollView(
          child: Text(stats.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
