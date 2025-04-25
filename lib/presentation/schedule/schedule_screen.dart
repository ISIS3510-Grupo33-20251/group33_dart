import 'package:flutter/material.dart';
import '../../services/schedule_service.dart';
import '../../domain/models/class_model.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../globals.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _professorController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 8, minute: 0);
  int _selectedDay = 0;
  Color _selectedColor = ScheduleService.classColors[0];
  ClassModel? _editingClass;

  @override
  void dispose() {
    _nameController.dispose();
    _professorController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleService>(
      builder: (context, scheduleService, child) {
        return Stack(
          children: [
            Column(
              children: [
                _buildWeekDays(),
                Expanded(
                  child: _buildTimeSlots(),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () => _showClassDialog(),
                child: const Icon(Icons.add),
                backgroundColor: _selectedColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeekDays() {
    final List<String> days = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
    final List<String> dates = ['25', '26', '27', '28', '29'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = index;
              });
            },
            child: Column(
              children: [
                Text(
                  days[index],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: index == _selectedDay
                        ? Colors.grey[200]
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dates[index],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: index == _selectedDay ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimeSlots() {
    return ListView.builder(
      itemCount: 12, // 7:00 to 18:00
      itemBuilder: (context, index) {
        final hour = index + 7;
        return _buildTimeSlot(hour);
      },
    );
  }

  Widget _buildTimeSlot(int hour) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$hour:00',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: List.generate(5, (index) {
                return Expanded(
                  child: _buildClassBlock(hour, index),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassBlock(int hour, int dayIndex) {
    final scheduleService = context.read<ScheduleService>();
    final classes = scheduleService.getClassesForDayAndHour(dayIndex, hour);

    if (classes.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(2),
      );
    }

    return GestureDetector(
      onTap: () => _showClassDialog(classes[0]),
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: classes[0].color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              classes[0].name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (classes[0].professor.isNotEmpty)
              Text(
                classes[0].professor,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            if (classes[0].room.isNotEmpty)
              Text(
                classes[0].room,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  void _showClassDialog([ClassModel? classToEdit]) {
    _editingClass = classToEdit;
    if (classToEdit != null) {
      _nameController.text = classToEdit.name;
      _professorController.text = classToEdit.professor;
      _roomController.text = classToEdit.room;
      _selectedColor = classToEdit.color;
      _startTime = classToEdit.startTime;
      _endTime = classToEdit.endTime;
      _selectedDay = classToEdit.dayOfWeek;
    } else {
      _nameController.clear();
      _professorController.clear();
      _roomController.clear();
      _selectedColor = context.read<ScheduleService>().getRandomColor();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(classToEdit == null ? 'Add Class' : 'Edit Class'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Class Name'),
                ),
                TextField(
                  controller: _professorController,
                  decoration: const InputDecoration(labelText: 'Professor'),
                ),
                TextField(
                  controller: _roomController,
                  decoration: const InputDecoration(labelText: 'Room'),
                ),
                const SizedBox(height: 16),
                // Day selector
                DropdownButtonFormField<int>(
                  value: _selectedDay,
                  decoration: const InputDecoration(labelText: 'Day'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Monday')),
                    DropdownMenuItem(value: 1, child: Text('Tuesday')),
                    DropdownMenuItem(value: 2, child: Text('Wednesday')),
                    DropdownMenuItem(value: 3, child: Text('Thursday')),
                    DropdownMenuItem(value: 4, child: Text('Friday')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedDay = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Time selectors
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text('Start: ${_startTime.format(context)}'),
                        onPressed: () async {
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: _startTime,
                          );
                          if (time != null) {
                            setState(() => _startTime = time);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text('End: ${_endTime.format(context)}'),
                        onPressed: () async {
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: _endTime,
                          );
                          if (time != null) {
                            setState(() => _endTime = time);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Color', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                _buildColorPicker(setState),
              ],
            ),
          ),
          actions: [
            if (_editingClass != null)
              TextButton(
                onPressed: () {
                  context
                      .read<ScheduleService>()
                      .removeClass(_editingClass!.id);
                  Navigator.pop(context);
                  setState(() {});
                },
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = _nameController.text.trim();
                final professor = _professorController.text.trim();
                final room = _roomController.text.trim();

                if (name.isEmpty) return;

                final scheduleService = context.read<ScheduleService>();

                if (_editingClass != null) {
                  scheduleService.removeClass(_editingClass!.id);
                }

                final newClass = ClassModel(
                  id: _editingClass?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  professor: professor,
                  room: room,
                  dayOfWeek: _selectedDay,
                  startTime: _startTime,
                  endTime: _endTime,
                  color: _selectedColor,
                );

                scheduleService.addClass(newClass);
                Navigator.pop(context);
                setState(() {});
              },
              child: Text(_editingClass == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(StateSetter setState) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ScheduleService.classColors.map((color) {
        return GestureDetector(
          onTap: () {
            setState(() => _selectedColor = color);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    _selectedColor == color ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
