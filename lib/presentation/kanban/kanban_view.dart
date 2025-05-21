import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/kanban_task.dart';
import '../../services/api_service_adapter.dart';
import '../../globals.dart';

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

  final List<String> _columns = ['To Do', 'In Progress', 'Done'];
  final List<String> _statuses = ['todo', 'in_progress', 'done'];

  late final ApiServiceAdapter _apiService =
      ApiServiceAdapter(backendUrl: backendUrl);

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return const Color(0xFFC8E6C9); // pastel green
      case 2:
        return const Color(0xFFFFF9C4); // pastel yellow
      case 3:
        return const Color(0xFFFFCDD2); // pastel red/rose
      default:
        return Colors.grey.shade200;
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Task'),
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
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter a description'
                      : null,
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
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
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
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (!(_formKey.currentState?.validate() ?? false)) {
                  await _showValidationError(
                      'Please fill all required fields.');
                  return;
                }
                if (_selectedDueDate == null || _selectedDueTime == null) {
                  await _showValidationError(
                      'Please select a due date and time.');
                  return;
                }
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
                final backendTask = await _apiService.createKanbanTaskOnBackend(
                  title: _titleController.text,
                  description: _descriptionController.text,
                  dueDate: dueDateTime,
                  priority: backendPriority,
                  status: backendStatus,
                  userId: userId,
                );
                // Map backend status to local status
                String localStatus = backendTask['status'] == 'pending'
                    ? 'todo'
                    : backendTask['status'] == 'in_progress'
                        ? 'in_progress'
                        : 'done';
                setState(() {
                  tasks.add(KanbanTask(
                    id: backendTask['_id'],
                    title: backendTask['title'],
                    description: backendTask['description'],
                    status: localStatus,
                    createdAt: DateTime.now(),
                    dueDate: DateTime.parse(backendTask['due_date']),
                    subject: _subjectController.text,
                    priority: _selectedPriority,
                  ));
                });
                _titleController.clear();
                _descriptionController.clear();
                _subjectController.clear();
                _selectedDueDate = null;
                _selectedDueTime = null;
                _selectedPriority = 2;
                Navigator.pop(context);
              } catch (e) {
                String errorMsg = 'Error creating task: ';
                if (e.toString().contains('Failed host lookup')) {
                  errorMsg += 'No internet connection.';
                } else {
                  errorMsg += e.toString();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorMsg)),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTaskStatus(KanbanTask task, String newStatus) async {
    // Map local status to backend status
    String backendStatus = newStatus == 'todo'
        ? 'pending'
        : newStatus == 'in_progress'
            ? 'in_progress'
            : 'done';
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
      // Refresh from backend
      final backendTask = await _apiService.getKanbanTaskById(task.id);
      setState(() {
        final index = tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          tasks[index] = task.copyWith(
            status: newStatus,
            title: backendTask['title'],
            description: backendTask['description'],
            dueDate: DateTime.parse(backendTask['due_date']),
            priority: backendTask['priority'] == 'high'
                ? 3
                : backendTask['priority'] == 'medium'
                    ? 2
                    : 1,
            // subject remains local
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
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
                String backendPriority = _selectedPriority == 3
                    ? 'high'
                    : _selectedPriority == 2
                        ? 'medium'
                        : 'low';
                String backendStatus = task.status; // keep current status
                try {
                  await _apiService.updateKanbanTaskOnBackend(
                    id: task.id,
                    title: _titleController.text,
                    description: _descriptionController.text,
                    dueDate: _selectedDueDate ?? DateTime.now(),
                    priority: backendPriority,
                    status: backendStatus,
                    userId: userId,
                  );
                  // Refresh from backend
                  final backendTask =
                      await _apiService.getKanbanTaskById(task.id);
                  setState(() {
                    final index = tasks.indexWhere((t) => t.id == task.id);
                    if (index != -1) {
                      tasks[index] = task.copyWith(
                        title: backendTask['title'],
                        description: backendTask['description'],
                        dueDate: DateTime.parse(backendTask['due_date']),
                        priority: backendTask['priority'] == 'high'
                            ? 3
                            : backendTask['priority'] == 'medium'
                                ? 2
                                : 1,
                        status: backendTask['status'],
                        // subject remains local
                      );
                    }
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating task: $e')),
                  );
                }
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
    try {
      await _apiService.deleteKanbanTaskOnBackend(task.id);
      setState(() {
        tasks.removeWhere((t) => t.id == task.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting task: $e')),
      );
    }
  }

  void _showTaskDetails(KanbanTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Column(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanban Board'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon:
                Icon(_isHorizontalView ? Icons.view_agenda : Icons.view_column),
            onPressed: () {
              setState(() {
                _isHorizontalView = !_isHorizontalView;
              });
            },
            tooltip: _isHorizontalView
                ? 'Switch to Vertical View'
                : 'Switch to Horizontal View',
          ),
        ],
      ),
      body: _isHorizontalView
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
                        onPressed: _currentColumnIndex < _columns.length - 1
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
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildColumn(String title, String status, {bool showHeader = false}) {
    final columnTasks = tasks.where((task) => task.status == status).toList();

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
            child: ListView.builder(
              itemCount: columnTasks.length,
              itemBuilder: (context, index) {
                final task = columnTasks[index];
                return Card(
                  margin: const EdgeInsets.all(4),
                  color: _getPriorityColor(task.priority),
                  child: ListTile(
                    title: Text(task.title),
                    onTap: () => _showTaskDetails(task),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editTask(task),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async => await _deleteTask(task),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: status != 'todo'
                              ? () async => await _updateTaskStatus(task,
                                  _statuses[_statuses.indexOf(status) - 1])
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: status != 'done'
                              ? () async => await _updateTaskStatus(task,
                                  _statuses[_statuses.indexOf(status) + 1])
                              : null,
                        ),
                      ],
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
}
