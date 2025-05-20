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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanban Board'),
      ),
      body: Row(
        children: [
          _buildColumn('To Do', 'todo'),
          _buildColumn('In Progress', 'in_progress'),
          _buildColumn('Done', 'done'),
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

    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: columnTasks.length,
                itemBuilder: (context, index) {
                  final task = columnTasks[index];
                  return Card(
                    margin: const EdgeInsets.all(4),
                    child: ListTile(
                      title: Text(task.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task.description.isNotEmpty)
                            Text(task.description),
                          if (task.subject != null)
                            Text('Subject: ${task.subject}'),
                          if (task.dueDate != null)
                            Text(
                                'Due: ${task.dueDate.toString().split(' ')[0]}'),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (newStatus) =>
                            _updateTaskStatus(task, newStatus),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'todo',
                            child: Text('Move to To Do'),
                          ),
                          const PopupMenuItem(
                            value: 'in_progress',
                            child: Text('Move to In Progress'),
                          ),
                          const PopupMenuItem(
                            value: 'done',
                            child: Text('Move to Done'),
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
      ),
    );
  }
}
