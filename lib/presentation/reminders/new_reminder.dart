import 'package:flutter/material.dart';
import 'package:group33_dart/data/sources/local/local_storage_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import '../../domain/models/reminder.dart';
import '../../services/api_service_adapter.dart';
import '../../services/connectivity_service.dart';
import '../../core/network/actionQueueManager.dart';

class NewReminderForm extends StatefulWidget {
  final String userId;
  final ApiServiceAdapter api;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final Reminder? existingReminder;

  const NewReminderForm({
    super.key,
    required this.userId,
    required this.api,
    required this.onSave,
    this.existingReminder,
  });

  @override
  State<NewReminderForm> createState() => _NewReminderFormState();
}

class _NewReminderFormState extends State<NewReminderForm> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _selectedDate;
  final ConnectivityService connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    if (widget.existingReminder != null) {
      _titleCtrl.text = widget.existingReminder!.entityId;
      _notesCtrl.text = widget.existingReminder!.notes ?? '';
      _selectedDate = widget.existingReminder!.remindAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingReminder != null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "New Reminder",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: "Title",
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Set Date",
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                hintText: _selectedDate == null
                    ? "Choose date and time"
                    : DateFormat('yyyy-MM-dd hh:mm a').format(_selectedDate!),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now().add(const Duration(hours: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 12, minute: 0),
                  );
                  if (time != null) {
                    setState(() {
                      _selectedDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: "Notes",
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Clear", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () async {
  if (_selectedDate == null || _titleCtrl.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Title and date required")),
    );
    return;
  }

  final reminder = Reminder(
    id: widget.existingReminder?.id ?? const Uuid().v4(),
    userId: widget.userId,
    entityType: 'task',
    entityId: _titleCtrl.text.trim(),
    remindAt: _selectedDate!,
    status: widget.existingReminder?.status ?? 'pending',
    notes: _notesCtrl.text.trim(),
  );

  final reminderJson = reminder.toJson();
  final box = await Hive.openBox('reminders');
  List reminders = box.get('reminders') ?? [];

  reminders.removeWhere((r) => r['_id'] == reminder.id);
  final hasConnection = await connectivityService.checkConnectivity();
  if (!hasConnection) reminderJson['unsynced'] = true;

  reminders.add(reminderJson);
  await box.put('reminders', reminders);

  if (hasConnection) {
    try {
      if (isEditing) {
        await widget.api.updateReminder(reminder);
        await LocalStorageService().updateReminder(reminder.toJson()); 
      } else {
        await widget.api.createReminder(reminder);
      }
    } catch (e) {
      await ActionQueueManager().addAction(
        reminder.id,
        isEditing ? 'reminder update' : 'reminder create',
      );
    }
  } else {
    await ActionQueueManager().addAction(
      reminder.id,
      isEditing ? 'reminder update' : 'reminder create',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Reminder saved locally and will sync when online."),
      ),
    );
  }

  await widget.onSave(reminderJson);
  if (context.mounted) Navigator.pop(context);
},
                  child: Text(isEditing ? "Update" : "Save", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isEditing)
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Delete Reminder", style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Text("Are you sure you want to delete this reminder?", style: TextStyle(fontWeight: FontWeight.bold)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold))),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  );

                  if (confirm == true && widget.existingReminder != null) {
                    await widget.api.deleteReminder(widget.existingReminder!.id);
                    final reminderJson = widget.existingReminder!.toJson();
                    await widget.onSave(reminderJson);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
