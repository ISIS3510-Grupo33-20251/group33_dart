import 'package:flutter/material.dart';
import '../../services/schedule_service.dart';
import '../../domain/models/class_model.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../globals.dart';
import 'dart:async';

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
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer.periodic(const Duration(minutes: 1), (Timer t) {
        if (mounted) {
          setState(() {
            _now = DateTime.now();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _nameController.dispose();
    _professorController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  // Función para obtener el índice del día actual (0-4 para Lun-Vie)
  int _getCurrentDayIndex() {
    final now = DateTime.now();
    // Convert from DateTime's 1-7 (Mon-Sun) to our 0-4 (Mon-Fri)
    final weekday = now.weekday - 1;
    // Return -1 if it's weekend, otherwise return 0-4
    return weekday >= 5 ? -1 : weekday;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleService>(
      builder: (context, scheduleService, child) {
        return SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 1), // Add small padding at top
                  _buildWeekDays(),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildTimeSlots(),
                        if (_getCurrentDayIndex() != -1 &&
                            _now.hour >= 7 &&
                            _now.hour < 20)
                          _buildCurrentTimeLine(),
                      ],
                    ),
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
          ),
        );
      },
    );
  }

  Widget _buildWeekDays() {
    List<String> dayAbbr = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
    // Calculate the dates for this week
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    List<String> dayNumbers = List.generate(
        5, (index) => (monday.add(Duration(days: index))).day.toString());
    int currentDayIndex = _getCurrentDayIndex();

    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            alignment: Alignment.center,
            child: Text(
              'Time',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          ...List.generate(5, (index) {
            bool isCurrentDay = index == currentDayIndex;
            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isCurrentDay ? Colors.blue.withOpacity(0.1) : null,
                  border: Border(
                    left: BorderSide(
                      color: Colors.grey[300]!,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayNumbers[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isCurrentDay ? FontWeight.bold : FontWeight.normal,
                        color: isCurrentDay ? Colors.blue : Colors.grey[600],
                      ),
                    ),
                    Text(
                      dayAbbr[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isCurrentDay ? FontWeight.bold : FontWeight.normal,
                        color: isCurrentDay ? Colors.blue : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCurrentTimeLine() {
    final currentDayIndex = _getCurrentDayIndex();
    print('Current day index: $currentDayIndex');

    if (currentDayIndex == -1) {
      print('Not showing timeline: weekend');
      return const SizedBox.shrink();
    }

    final now = _now;
    final currentHour = now.hour;
    final currentMinute = now.minute;

    print('Current time: $currentHour:$currentMinute');

    // Only show timeline during school hours (7-20)
    if (currentHour < 7 || currentHour >= 20) {
      print('Not showing timeline: outside school hours');
      return const SizedBox.shrink();
    }

    // Calculate position
    final hourHeight = 60.0; // Height of each hour slot
    final minuteHeight = hourHeight / 60.0; // Height of each minute
    final timelinePosition =
        ((currentHour - 7) * hourHeight) + (currentMinute * minuteHeight);

    print('Timeline position: $timelinePosition');

    return Positioned(
      left: 56,
      right: 0,
      top: timelinePosition,
      child: Container(
        height: 2,
        color: Colors.red.withOpacity(0.8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: -4,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          Container(
            width: 56,
            padding: const EdgeInsets.only(left: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(5, (index) {
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Colors.grey[300]!,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: _buildClassBlock(hour, index),
                  ),
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

    print(
        'Building class block for day $dayIndex, hour $hour. Found ${classes.length} classes');

    if (classes.isEmpty) {
      return const SizedBox(
        width: double.infinity,
        height: double.infinity,
      );
    }

    final classModel = classes[0];
    print(
        'Class found: ${classModel.name} at ${classModel.startTime.hour}:${classModel.startTime.minute}');
    return GestureDetector(
      onTap: () => _showClassDialog(classModel),
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: classModel.color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              classModel.name,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (classModel.room.isNotEmpty)
              Text(
                classModel.room,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  void _showClassDialog([ClassModel? classToEdit]) {
    setState(() {
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
        _startTime = TimeOfDay(hour: _now.hour, minute: 0);
        _endTime = TimeOfDay(hour: _now.hour + 1, minute: 0);
        _selectedDay = _getCurrentDayIndex() != -1 ? _getCurrentDayIndex() : 0;
      }
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(classToEdit == null ? 'New Class' : 'Edit Class'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Class Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _professorController,
                  decoration: const InputDecoration(
                    labelText: 'Professor',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _roomController,
                  decoration: const InputDecoration(
                    labelText: 'Room',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedDay,
                  decoration: const InputDecoration(
                    labelText: 'Day',
                    border: OutlineInputBorder(),
                  ),
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
                if (name.isEmpty) return;

                print('Creating new class:');
                print('Name: $name');
                print('Day: $_selectedDay');
                print('Start time: ${_startTime.hour}:${_startTime.minute}');
                print('End time: ${_endTime.hour}:${_endTime.minute}');

                final newClass = ClassModel(
                  id: _editingClass?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  professor: _professorController.text.trim(),
                  room: _roomController.text.trim(),
                  dayOfWeek: _selectedDay,
                  startTime: _startTime,
                  endTime: _endTime,
                  color: _selectedColor,
                );

                final scheduleService = context.read<ScheduleService>();
                if (_editingClass != null) {
                  scheduleService.removeClass(_editingClass!.id);
                }
                try {
                  scheduleService.addClass(newClass);
                  scheduleService.debugPrintClasses();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Class added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('Error in dialog when adding class: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding class: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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

  Widget _buildClassCard(ClassModel classModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: classModel.color,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            classModel.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            classModel.room,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
