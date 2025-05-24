import 'package:hive/hive.dart';
import '../../../models/kanban_task.dart';

class KanbanLocalService {
  static const String _tasksBox = 'kanban_tasks';
  static const String _queueBox = 'kanban_action_queue';
  static const String _kanbanIdBox = 'kanban_id';

  Future<void> ensureBoxesOpen() async {
    if (!Hive.isBoxOpen(_tasksBox)) {
      await Hive.openBox(_tasksBox);
    }
    if (!Hive.isBoxOpen(_queueBox)) {
      await Hive.openBox(_queueBox);
    }
  }

  // TASKS
  Future<void> saveTasks(List<KanbanTask> tasks) async {
    await ensureBoxesOpen();
    final box = Hive.box(_tasksBox);
    await box.clear();
    for (var task in tasks) {
      await box.put(task.id, task.toJson());
    }
  }

  Future<List<KanbanTask>> loadTasks() async {
    await ensureBoxesOpen();
    final box = Hive.box(_tasksBox);
    return box.values
        .map((json) => KanbanTask.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  // ACTION QUEUE
  Future<void> saveActionQueue(List<Map<String, dynamic>> queue) async {
    await ensureBoxesOpen();
    final box = Hive.box(_queueBox);
    await box.put('queue', queue);
  }

  Future<List<Map<String, dynamic>>> loadActionQueue() async {
    await ensureBoxesOpen();
    final box = Hive.box(_queueBox);
    final raw = box.get('queue');
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(raw);
  }

  Future<void> clearActionQueue() async {
    await ensureBoxesOpen();
    final box = Hive.box(_queueBox);
    await box.delete('queue');
  }

  Future<void> saveKanbanId(String kanbanId) async {
    await ensureBoxesOpen();
    final box = await Hive.openBox(_kanbanIdBox);
    await box.put('kanban_id', kanbanId);
  }

  Future<String?> loadKanbanId() async {
    await ensureBoxesOpen();
    final box = await Hive.openBox(_kanbanIdBox);
    return box.get('kanban_id');
  }
}
