import 'package:flutter/material.dart';
import 'package:group33_dart/core/network/actionQueueManager.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../../domain/models/reminder.dart';
import '../../services/api_service_adapter.dart';
import 'new_reminder.dart';
import 'package:group33_dart/data/sources/local/local_storage_service.dart';
import 'package:group33_dart/services/connectivity_service.dart';

import '../../globals.dart';

final ApiServiceAdapter apiServiceAdapter = ApiServiceAdapter(backendUrl: backendUrl);
final LocalStorageService localStorage = LocalStorageService();
final ConnectivityService connectivityService = ConnectivityService();

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  List<Reminder> reminders = [];
  bool isLoading = true;
  String error = '';
  bool showCompleted = false;

  int get pendingCount => reminders.where((r) => r.status == 'pending').length;
  int get doneCount => reminders.where((r) => r.status == 'done').length;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final hasConnection = await connectivityService.checkConnectivity();

      if (!hasConnection) {
        error = 'No internet. Showing cached reminders.';
        await _loadRemindersFromCache();
        return;
      }

      await _fetchReminders();
    } catch (e) {
      setState(() {
        error = 'Error loading reminders: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadRemindersFromCache() async {
    final cached = await localStorage.loadReminders();
    setState(() {
      reminders = cached.map((json) {
        final Map<String, dynamic> m = json is Map<String, dynamic>
            ? json
            : Map<String, dynamic>.from(json);
        return Reminder.fromJson(m);
      }).toList();
      isLoading = false;
    });
  }

  Future<void> _fetchReminders() async {
    try {
      final fetched = await apiServiceAdapter.getRemindersForUser(userId);
      final local = await localStorage.loadReminders();

      final unsynced = local.where((r) => r['unsynced'] == true).toList();
      final synced = fetched.map((e) => e.toJson()).toList();
      final merged = [...synced, ...unsynced];

      await localStorage.saveReminders(merged);

      setState(() {
        reminders = merged.map((e) {
          final Map<String, dynamic> m = e is Map<String, dynamic>
              ? e
              : Map<String, dynamic>.from(e);
          return Reminder.fromJson(m);
        }).toList();
        isLoading = false;
        error = '';
      });
    } catch (e) {
      setState(() {
        error = 'Failed to fetch reminders from server: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _toggleReminderStatus(Reminder r) async {
    final updatedStatus = r.status == 'pending' ? 'done' : 'pending';
    final updatedReminder = r.copyWith(status: updatedStatus);
    final reminderJson = updatedReminder.toJson();

    final index = reminders.indexWhere((element) => element.id == r.id);
    if (index != -1) {
      setState(() => reminders[index] = updatedReminder);

      final hasConnection = await connectivityService.checkConnectivity();

      if (hasConnection) {
        try {
          await apiServiceAdapter.updateReminder(updatedReminder);
        } catch (_) {
          await ActionQueueManager().addAction(updatedReminder.id, 'reminder update');
        }
      } else {
        reminderJson['unsynced'] = true;
        await ActionQueueManager().addAction(updatedReminder.id, 'reminder update');
      }

      await localStorage.updateReminder(reminderJson);
    }
  }

  void _showNewReminderModal({Reminder? existingReminder}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: NewReminderForm(
          userId: userId,
          api: apiServiceAdapter,
          existingReminder: existingReminder,
          onSave: (Map<String, dynamic> newJson) async {
            final newReminder = Reminder.fromJson(newJson);
            final existingIndex = reminders.indexWhere((r) => r.id == newReminder.id);
            setState(() {
              if (existingIndex != -1) {
                reminders[existingIndex] = newReminder;
              } else {
                reminders.add(newReminder);
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredReminders = showCompleted
        ? reminders.where((r) => r.status == 'done').toList()
        : reminders.where((r) => r.status == 'pending').toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        title: const Text(
          'Reminders',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                showCompleted = !showCompleted;
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: showCompleted ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              showCompleted ? "Done" : "Pending",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _initialize,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Pending: $pendingCount • Done: $doneCount',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredReminders.length,
                    itemBuilder: (context, index) {
                      final r = filteredReminders[index];
                      final isUnsynced = r.toJson()['unsynced'] == true;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Checkbox(
                              value: r.status == 'done',
                              onChanged: (_) => _toggleReminderStatus(r),
                              checkColor: Colors.white,
                              activeColor: Colors.green,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    r.entityId,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isUnsynced)
                                  const Icon(Icons.sync_problem, color: Colors.orange, size: 18),
                              ],
                            ),
                            subtitle: Text(
                              DateFormat('EEE, MMM d • hh:mm a').format(r.remindAt),
                              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () => _showNewReminderModal(existingReminder: r),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => _showNewReminderModal(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
