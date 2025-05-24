import 'package:flutter/material.dart';
import 'package:group33_dart/core/network/actionQueueManager.dart';
import 'package:intl/intl.dart';
import '../../domain/models/reminder.dart';
import '../../services/api_service_adapter.dart';
import 'new_reminder.dart';
import 'package:group33_dart/data/sources/local/local_storage_service.dart';
import 'package:group33_dart/services/connectivity_service.dart';
import 'package:group33_dart/data/sources/local/cache_service.dart';
import '../../globals.dart';

final apiServiceAdapter   = ApiServiceAdapter(backendUrl: backendUrl);
final localStorageService = LocalStorageService();
final connectivityService = ConnectivityService();
final cacheService        = CacheService();

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
  int get doneCount    => reminders.where((r) => r.status    == 'done'   ).length;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => isLoading = true);
    final hasConnection = await connectivityService.checkConnectivity();

    if (!hasConnection) {
      error = 'No internet. Showing cached reminders.';
      await _loadRemindersFromCache();
    } else {
      await _fetchReminders();
    }
  }

  Future<void> _loadRemindersFromCache() async {
    final cached = await localStorageService.loadReminders();
    setState(() {
      reminders = cached.map((json) => Reminder.fromJson(json)).toList();
      isLoading = false;
    });
  }

  Future<void> _fetchReminders() async {
    try {
      final cachedJson = await cacheService.loadCachedFlashcard('reminders');
      if (cachedJson.isNotEmpty) {
        reminders = cachedJson.map((j) => Reminder.fromJson(j)).toList();
        setState(() => isLoading = false);
      }

      final fetched  = await apiServiceAdapter.getRemindersForUser(userId);
      final local    = await localStorageService.loadReminders();
      final unsynced = local.where((r) => r['unsynced'] == true).toList();
      final synced   = fetched.map((e) => e.toJson()).toList();
      final merged   = [...synced, ...unsynced];

      await cacheService.cacheFlashcard('reminders', merged);
      await localStorageService.saveReminders(merged);

      setState(() {
        reminders = merged.map((e) => Reminder.fromJson(e)).toList();
        isLoading = false;
        error = '';
      });
    } catch (e) {
      setState(() {
        error = 'Failed to fetch reminders: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _toggleReminderStatus(Reminder r) async {
    final updatedStatus   = r.status == 'pending' ? 'done' : 'pending';
    final updatedReminder = r.copyWith(status: updatedStatus);
    final reminderJson    = updatedReminder.toJson();

    final idx = reminders.indexWhere((x) => x.id == r.id);
    if (idx == -1) return;
    setState(() => reminders[idx] = updatedReminder);

    final hasConnection = await connectivityService.checkConnectivity();
    if (hasConnection) {
      try {
        await apiServiceAdapter.updateReminder(updatedReminder);
      } catch (_) {
        await ActionQueueManager().addAction(r.id, 'reminder update');
      }
    } else {
      reminderJson['unsynced'] = true;
      await ActionQueueManager().addAction(r.id, 'reminder update');
    }
    await localStorageService.updateReminder(reminderJson);
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
  setState(() {
    // Buscamos si ya existía
    final idx = reminders.indexWhere((r) => r.id == newReminder.id);
    if (idx == -1) {
      // No existía: lo añadimos (nuevo)
      reminders.add(newReminder);
    } else {
      // Existía: lo reemplazamos (update)
      reminders[idx] = newReminder;
    }
  });
},


        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = showCompleted
      ? reminders.where((r) => r.status=='done'   ).toList()
      : reminders.where((r) => r.status=='pending').toList();

    return DefaultTextStyle(
      style: const TextStyle(fontWeight: FontWeight.bold),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Reminders',
            style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
  onPressed: () => setState(() => showCompleted = !showCompleted),
  style: TextButton.styleFrom(
    backgroundColor: showCompleted ? Colors.green : Colors.red,
    foregroundColor: Colors.white,
    textStyle: const TextStyle(fontWeight: FontWeight.bold),
  ),
  child: Text(showCompleted ? 'Done' : 'Pending'),
),
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
                    padding: const EdgeInsets.all(12),
                    child: Text(error, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Pending: $pendingCount • Done: $doneCount',style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final r       = list[i];
                      final unsynced = r.toJson()['unsynced'] == true;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
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
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                if (unsynced)
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
      ),
    );
  }
}
