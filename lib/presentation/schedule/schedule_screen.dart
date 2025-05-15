import 'package:flutter/material.dart';
import '../../services/schedule_service.dart';
import '../../domain/models/class_model.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../globals.dart';
import 'dart:async';
import '../../domain/models/meeting_model.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _meetingLinkController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 8, minute: 0);
  int _selectedDay = 0;
  Color _selectedColor = ScheduleService.classColors[0];
  Timer? _timer;
  DateTime _now = DateTime.now();

  // NUEVO: Estado para la semana seleccionada
  late DateTime _selectedMonday;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Calcular el lunes de la semana actual
    _selectedMonday = _now.subtract(Duration(days: _now.weekday - 1));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer.periodic(const Duration(minutes: 1), (Timer t) {
        if (mounted) {
          setState(() {
            _now = DateTime.now();
          });
        }
      });
    });
    // Verifica si hay argumentos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null && args['openMeetingDialog'] == true) {
        _showMeetingDialog(); // Abre el diálogo de nueva meeting
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
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
    // Calcular el rango de la semana seleccionada
    final weekStart = _selectedMonday;
    final weekEnd = _selectedMonday.add(const Duration(days: 4));
    String weekRange =
        '${_formatDateShort(weekStart)} - ${_formatDateShort(weekEnd)}';
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<ScheduleService>(
        builder: (context, scheduleService, child) {
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                Column(
                  children: [
                    // --- NUEVO: Navegación de semanas compacta ---
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                _selectedMonday = _selectedMonday
                                    .subtract(const Duration(days: 7));
                              });
                            },
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () async {
                              // Selector de fecha para elegir la semana
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedMonday,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                // Calcular el lunes de la semana seleccionada
                                final monday = picked.subtract(
                                    Duration(days: picked.weekday - 1));
                                setState(() {
                                  _selectedMonday = monday;
                                });
                              }
                            },
                            child: Text(
                              weekRange,
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() {
                                _selectedMonday = _selectedMonday
                                    .add(const Duration(days: 7));
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    // --- FIN NUEVO ---
                    const SizedBox(height: 1),
                    _buildWeekDays(),
                    Expanded(
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Stack(
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
                    ),
                  ],
                ),
                // FAB para crear meetings
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    onPressed: () => _showAddDialog(),
                    child: const Icon(Icons.add),
                    backgroundColor: _selectedColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekDays() {
    List<String> dayAbbr = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
    // Calcular los días de la semana seleccionada
    List<String> dayNumbers = List.generate(5,
        (index) => (_selectedMonday.add(Duration(days: index))).day.toString());
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
            // Marcar el día actual solo si la semana seleccionada es la actual
            bool isCurrentDay = false;
            final today = DateTime.now();
            final thisDay = _selectedMonday.add(Duration(days: index));
            if (today.year == thisDay.year &&
                today.month == thisDay.month &&
                today.day == thisDay.day) {
              isCurrentDay = true;
            }
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
    if (currentDayIndex == -1) {
      return const SizedBox.shrink();
    }
    final now = _now;
    final currentHour = now.hour;
    final currentMinute = now.minute;
    if (currentHour < 7 || currentHour >= 20) {
      return const SizedBox.shrink();
    }
    final hourHeight = 60.0; // Height of each hour slot
    final minuteHeight = hourHeight / 60.0; // Height of each minute
    final timelinePosition =
        ((currentHour - 7) * hourHeight) + (currentMinute * minuteHeight);
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
    return SizedBox(
      height: 60.0 * 12, // 12 horas de 60px cada una
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 12, // 7:00 to 18:00
        itemBuilder: (context, index) {
          final hour = index + 7;
          return _buildTimeSlot(hour);
        },
      ),
    );
  }

  Widget _buildTimeSlot(int hour) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          // Time column
          Container(
            width: 56,
            padding: const EdgeInsets.only(left: 8),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 0.5),
              ),
            ),
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          // Day columns
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(5, (dayIndex) {
                return Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                                color: Colors.grey[300]!, width: 0.5),
                            top: BorderSide(
                                color: Colors.grey[300]!, width: 0.5),
                          ),
                        ),
                      ),
                      _buildClassBlock(hour, dayIndex),
                      _buildMeetingBlock(hour, dayIndex),
                    ],
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

    if (classes.isEmpty) {
      return const SizedBox.shrink();
    }

    final classModel = classes[0];
    final startHour = classModel.startTime.hour;
    final startMinute = classModel.startTime.minute;
    final endHour = classModel.endTime.hour;
    final endMinute = classModel.endTime.minute;

    // Solo mostrar el bloque si comienza en esta hora
    if (startHour != hour) {
      return const SizedBox.shrink();
    }

    // Calcular la posición y altura del bloque
    final startOffset = startMinute / 60.0 * 60; // Convertir a píxeles
    final duration =
        ((endHour - startHour) * 60 + (endMinute - startMinute)) / 60.0 * 60;

    return Positioned(
      top: startOffset,
      height: duration,
      left: 2,
      right: 2,
      child: GestureDetector(
        onTap: () => _showClassDialog(classModel),
        child: Container(
          decoration: BoxDecoration(
            color: classModel.color,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  classModel.name,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (duration > 40) ...[
                if (classModel.room.isNotEmpty && duration > 30)
                  Text(
                    classModel.room,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                if (duration > 25)
                  Text(
                    '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')} - ${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingBlock(int hour, int dayIndex) {
    final scheduleService = context.read<ScheduleService>();
    // Calcular la fecha real de la celda
    final cellDate = _selectedMonday.add(Duration(days: dayIndex));
    final meetings = scheduleService.getMeetingsForDateAndHour(cellDate, hour);

    if (meetings.isEmpty) {
      return const SizedBox.shrink();
    }

    final meetingModel = meetings[0];
    final startHour = meetingModel.startTime.hour;
    final startMinute = meetingModel.startTime.minute;
    final endHour = meetingModel.endTime.hour;
    final endMinute = meetingModel.endTime.minute;

    if (startHour != hour) {
      return const SizedBox.shrink();
    }

    final startOffset = startMinute / 60.0 * 60;
    final duration =
        ((endHour - startHour) * 60 + (endMinute - startMinute)) / 60.0 * 60;

    return Positioned(
      top: startOffset,
      height: duration,
      left: 2,
      right: 2,
      child: GestureDetector(
        onTap: () => _showMeetingDialog(meetingModel),
        child: Container(
          decoration: BoxDecoration(
            color: meetingModel.color,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  meetingModel.name,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (duration > 40) ...[
                if (meetingModel.room.isNotEmpty && duration > 30)
                  Text(
                    meetingModel.room,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                if (duration > 25)
                  Text(
                    '	${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')} - ${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Meeting'),
              subtitle: const Text('Create a new meeting'),
              onTap: () {
                Navigator.pop(context);
                _showMeetingDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.class_),
              title: const Text('Class'),
              subtitle: const Text('Coming soon...'),
              enabled: false,
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }

  void _showMeetingDialog([MeetingModel? meetingToEdit]) {
    // Variable para la fecha seleccionada
    DateTime selectedDate = _selectedMonday.add(Duration(days: _selectedDay));

    setState(() {
      if (meetingToEdit != null) {
        _titleController.text = meetingToEdit.name;
        _descriptionController.text = meetingToEdit.professor;
        _locationController.text = meetingToEdit.room;
        _meetingLinkController.clear(); // Ajusta si tienes link en el modelo
        _selectedColor = meetingToEdit.color;
        _startTime = meetingToEdit.startTime;
        _endTime = meetingToEdit.endTime;
        _selectedDay = meetingToEdit.dayOfWeek;
        // Si hay una fecha inicial en el meeting, usarla
        if (meetingToEdit.startDateTime != null) {
          selectedDate = meetingToEdit.startDateTime;
        }
      } else {
        _titleController.clear();
        _descriptionController.clear();
        _locationController.clear();
        _meetingLinkController.clear();
        _selectedColor = context.read<ScheduleService>().getRandomColor();
        _startTime = TimeOfDay(hour: _now.hour, minute: 0);
        _endTime = TimeOfDay(hour: _now.hour + 1, minute: 0);
        _selectedDay = _getCurrentDayIndex() != -1 ? _getCurrentDayIndex() : 0;
        // Usar la fecha de la semana seleccionada + día seleccionado
        selectedDate = _selectedMonday.add(Duration(days: _selectedDay));
      }
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(meetingToEdit == null ? 'New Meeting' : 'Edit Meeting'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _meetingLinkController,
                  decoration: const InputDecoration(
                    labelText: 'Meeting Link (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Reemplazamos el DropdownButtonFormField por un selector de fecha
                InkWell(
                  onTap: () async {
                    // Verificar la fecha seleccionada para asegurar que está dentro del rango válido
                    DateTime validInitialDate = selectedDate;
                    DateTime firstDate = DateTime(2020);
                    DateTime lastDate = DateTime(2030);

                    // Si la fecha seleccionada es posterior a la fecha límite, usar la fecha límite
                    if (validInitialDate.isAfter(lastDate)) {
                      validInitialDate = lastDate;
                    }
                    // Si la fecha seleccionada es anterior a la fecha inicial, usar la fecha inicial
                    if (validInitialDate.isBefore(firstDate)) {
                      validInitialDate = firstDate;
                    }

                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: validInitialDate,
                      firstDate: firstDate,
                      lastDate: lastDate,
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                        // Actualizar _selectedDay para mantener coherencia
                        _selectedDay =
                            (picked.weekday - 1) % 7; // 0 = Monday, 6 = Sunday
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
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
            if (meetingToEdit != null)
              TextButton(
                onPressed: () async {
                  try {
                    await context
                        .read<ScheduleService>()
                        .removeClass(meetingToEdit.id!);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Meeting deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    final msg = e.toString();
                    if (msg.contains('Meeting deleted locally')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Meeting deleted locally, will be updated when connected to internet'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting meeting: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final title = _titleController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title is required')),
                  );
                  return;
                }

                // Crear fechas de inicio y fin usando la fecha seleccionada
                final startDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  _startTime.hour,
                  _startTime.minute,
                );

                final endDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  _endTime.hour,
                  _endTime.minute,
                );

                context.read<ScheduleService>().selectedColor = _selectedColor;

                final meetingData = {
                  'title': title,
                  'description': _descriptionController.text.trim(),
                  'start_time': startDateTime.toIso8601String(),
                  'end_time': endDateTime.toIso8601String(),
                  'location': _locationController.text.trim(),
                  'meeting_link': _meetingLinkController.text.trim(),
                  'host_id': userId,
                  'participants': [],
                  'color':
                      '#${_selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
                  'day_of_week': _selectedDay,
                };

                try {
                  await context
                      .read<ScheduleService>()
                      .createMeeting(meetingData);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(meetingToEdit == null
                          ? 'Meeting created successfully'
                          : 'Meeting updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('Error creating/updating meeting: $e');
                  Navigator.pop(context);
                  final msg = e.toString();
                  if (msg.contains('Meeting created locally')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Meeting created locally, will be updated when connected to internet'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error creating/updating meeting: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(meetingToEdit == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClassDialog([ClassModel? classToEdit]) {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _meetingLinkController.clear();
      _selectedColor = context.read<ScheduleService>().getRandomColor();
      _startTime = TimeOfDay(hour: _now.hour, minute: 0);
      _endTime = TimeOfDay(hour: _now.hour + 1, minute: 0);
      _selectedDay = _getCurrentDayIndex() != -1 ? _getCurrentDayIndex() : 0;
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
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Class Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Professor',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _locationController,
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
            if (classToEdit != null)
              TextButton(
                onPressed: () {
                  context.read<ScheduleService>().removeClass(classToEdit.id);
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
                final name = _titleController.text.trim();
                if (name.isEmpty) return;

                print('Creating new class:');
                print('Name: $name');
                print('Day: $_selectedDay');
                print('Start time: ${_startTime.hour}:${_startTime.minute}');
                print('End time: ${_endTime.hour}:${_endTime.minute}');

                final newClass = ClassModel(
                  id: classToEdit?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  professor: _descriptionController.text.trim(),
                  room: _locationController.text.trim(),
                  dayOfWeek: _selectedDay,
                  startTime: _startTime,
                  endTime: _endTime,
                  color: _selectedColor,
                );

                final scheduleService = context.read<ScheduleService>();
                if (classToEdit != null) {
                  scheduleService.removeClass(classToEdit.id);
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
              child: Text(classToEdit == null ? 'Add' : 'Save'),
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

  // NUEVO: Formato corto de fecha para el header
  String _formatDateShort(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
