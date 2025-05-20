import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/kanban_task.dart';

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
  int _selectedPriority = 2;
  int _currentColumnIndex = 0;
  bool _isHorizontalView = false;

  final List<String> _columns = ['To Do', 'In Progress', 'Done'];
  final List<String> _statuses = ['todo', 'in_progress', 'done'];

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

  void _addTask() {
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
                      ? 'Select Due Date'
                      : 'Due: ${_selectedDueDate!.toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDueDate = date;
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
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                final task = KanbanTask(
                  id: const Uuid().v4(),
                  title: _titleController.text,
                  description: _descriptionController.text,
                  status: 'todo',
                  createdAt: DateTime.now(),
                  dueDate: _selectedDueDate,
                  subject: _subjectController.text,
                  priority: _selectedPriority,
                );
                setState(() {
                  tasks.add(task);
                });
                _titleController.clear();
                _descriptionController.clear();
                _subjectController.clear();
                _selectedDueDate = null;
                _selectedPriority = 2;
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _updateTaskStatus(KanbanTask task, String newStatus) {
    setState(() {
      final index = tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        tasks[index] = task.copyWith(status: newStatus);
      }
    });
  }

  void _editTask(KanbanTask task) {
    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _subjectController.text = task.subject ?? '';
    _selectedDueDate = task.dueDate;
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
                      ? 'Select Due Date'
                      : 'Due: ${_selectedDueDate!.toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDueDate = date;
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
              _selectedPriority = 2;
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                setState(() {
                  final index = tasks.indexWhere((t) => t.id == task.id);
                  if (index != -1) {
                    tasks[index] = task.copyWith(
                      title: _titleController.text,
                      description: _descriptionController.text,
                      subject: _subjectController.text,
                      dueDate: _selectedDueDate,
                      priority: _selectedPriority,
                    );
                  }
                });
                _titleController.clear();
                _descriptionController.clear();
                _subjectController.clear();
                _selectedDueDate = null;
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

  void _deleteTask(KanbanTask task) {
    setState(() {
      tasks.removeWhere((t) => t.id == task.id);
    });
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
                    child: _buildColumn(_columns[i], _statuses[i]),
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

  Widget _buildColumn(String title, String status) {
    final columnTasks = tasks.where((task) => task.status == status).toList();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.description.isNotEmpty) Text(task.description),
                        if (task.subject != null)
                          Text('Subject: ${task.subject}'),
                        if (task.dueDate != null)
                          Text('Due: ${task.dueDate.toString().split(' ')[0]}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editTask(task),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteTask(task),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: status != 'todo'
                              ? () => _moveTask(task, -1)
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: status != 'done'
                              ? () => _moveTask(task, 1)
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
