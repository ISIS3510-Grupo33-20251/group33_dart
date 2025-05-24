import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:group33_dart/core/network/actionQueueManager.dart';
import 'package:group33_dart/data/sources/local/local_storage_service.dart';
import 'package:group33_dart/globals.dart';
import 'package:group33_dart/services/api_service_adapter.dart';

class CalculatorWidget extends StatefulWidget {
  const CalculatorWidget({super.key});
  @override
  _CalculatorWidgetState createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends State<CalculatorWidget> {
  final LocalStorageService _localStorage = LocalStorageService();
  final ApiServiceAdapter apiServiceAdapter =
      ApiServiceAdapter(backendUrl: backendUrl);

  // --- per‐entry controllers
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _gradeControllers = [];
  final List<TextEditingController> _percentControllers = [];
  final TextEditingController _targetGradeController = TextEditingController();

  // --- subject management
  List<String> _subjects = [];
  String? _selectedSubject;
  bool _loadingSubjects = true;

  // --- find vs calculate
  bool _isFindMode = false;
  String _resultText = '';

  /// Guardado de datos por subject
  Map<String, List<Map<String, String>>> _savedData = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (ActionQueueManager().getIsConnected()) {
      _savedData = await apiServiceAdapter.getCalcInfo(userId);
      _localStorage.addCalcData(_savedData);
    } else {
      _savedData = await _localStorage.loadCalcData();
    }
    await _loadSubjects();
  }

  /// Carga de lista de subjects desde los datos guardados
  Future<void> _loadSubjects() async {
    if (ActionQueueManager().getIsConnected()) {
      await ActionQueueManager().waitForEmptyQueue();
    }

    setState(() {
      _subjects = _savedData.keys.toList();
      if (_subjects.isEmpty) {
        const defaultSubj = 'Default Subject';
        _subjects = [defaultSubj];
        _savedData[defaultSubj] = [];
      }
      _selectedSubject = _subjects.first;
      _loadSubjectData();
      _loadingSubjects = false;
    });
  }

  /// Refresca las filas en base al subject actual
  void _loadSubjectData() {
    // limpiar controladores previos
    for (var c in _nameControllers) c.dispose();
    for (var c in _gradeControllers) c.dispose();
    for (var c in _percentControllers) c.dispose();
    _nameControllers.clear();
    _gradeControllers.clear();
    _percentControllers.clear();

    final list = _savedData[_selectedSubject] ?? [];
    if (list.isEmpty) {
      _addEntry();
    } else {
      for (var e in list) {
        _addEntry(
          name: e['name']!,
          grade: e['grade']!,
          percent: e['percent']!,
        );
      }
    }
  }

  /// Añade una nueva fila
  void _addEntry({String name = '', String grade = '', String percent = ''}) {
    final nc = TextEditingController(text: name);
    final gc = TextEditingController(text: grade);
    final pc = TextEditingController(text: percent);
    nc.addListener(_onAnyFieldChanged);
    gc.addListener(_onAnyFieldChanged);
    pc.addListener(_onAnyFieldChanged);

    setState(() {
      _nameControllers.add(nc);
      _gradeControllers.add(gc);
      _percentControllers.add(pc);
    });
  }

  /// Elimina una fila por índice
  void _removeEntry(int i) {
    setState(() {
      _nameControllers[i].dispose();
      _gradeControllers[i].dispose();
      _percentControllers[i].dispose();
      _nameControllers.removeAt(i);
      _gradeControllers.removeAt(i);
      _percentControllers.removeAt(i);
      _onAnyFieldChanged();
    });
  }

  /// Guarda los cambios de las filas en _savedData y almacenamiento local
  Future<void> _onAnyFieldChanged() async {
    if (_selectedSubject == null) return;
    final list = <Map<String, String>>[];
    for (var i = 0; i < _nameControllers.length; i++) {
      list.add({
        'name': _nameControllers[i].text,
        'grade': _gradeControllers[i].text,
        'percent': _percentControllers[i].text,
      });
    }
    _savedData[_selectedSubject!] = list;
    _localStorage.addCalcData(_savedData);
    if (!(await ActionQueueManager().updateAction('calc', 'update calc'))) {
      ActionQueueManager().addAction('calc', 'update calc');
    }
  }

  /// Lógica de cálculo y búsqueda
  void _calculate() {
    final entries = <Map<String, double>>[];
    for (var i = 0; i < _gradeControllers.length; i++) {
      final g = double.tryParse(_gradeControllers[i].text.replaceAll(',', '.'));
      final p =
          double.tryParse(_percentControllers[i].text.replaceAll(',', '.'));
      if (g == null || p == null) {
        setState(() => _resultText = 'Please put valid numbers');
        return;
      }
      entries.add({'grade': g, 'percent': p});
    }

    if (!_isFindMode) {
      double total = 0, pcTotal = 0;
      for (var e in entries) {
        total += (e['grade']! / 5.0) * e['percent']!;
        pcTotal += e['percent']!;
      }
      setState(() {
        if (pcTotal != 100) {
          _resultText = 'Percentages should add exactly 100';
        } else {
          final est = (total * 5 / 100);
          _resultText = 'Estimated final grade: ${est.toStringAsFixed(2)}/5.0\n'
              '${est < 3.0 ? 'Better luck next semester!' : 'Congratulations!'}';
        }
      });
    } else {
      final target =
          double.tryParse(_targetGradeController.text.replaceAll(',', '.'));
      if (target == null) {
        setState(() => _resultText = 'Please put valid numbers');
        return;
      }
      double current = 0, used = 0;
      for (var e in entries) {
        current += (e['grade']! / 5.0) * e['percent']!;
        used += e['percent']!;
      }
      final remain = 100 - used;
      if (remain <= 0) {
        setState(() => _resultText = 'The percentage is 100% or more already');
        return;
      }
      final targetContrib = (target / 5.0) * 100;
      final neededContrib = targetContrib - current;
      final neededGrade = (neededContrib / remain) * 5.0;

      setState(() {
        if (neededGrade > 5.0) {
          _resultText =
              'Not possible! You need ${neededGrade.toStringAsFixed(2)}/5.0 '
              'in the remaining ${remain.toStringAsFixed(2)}%';
        } else if (neededGrade < 0) {
          _resultText =
              'You have already reached the target grade. Congratulations!';
        } else {
          _resultText = 'You need ${neededGrade.toStringAsFixed(2)}/5.0 '
              'in the remaining ${remain.toStringAsFixed(0)}%';
        }
      });
    }
  }

  /// Muestra diálogo para agregar nueva subject
  Future<void> _showAddSubjectDialog() async {
    String newSubject = '';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Subject'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Subject Name'),
          onChanged: (val) => newSubject = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newSubject.trim().isNotEmpty) {
                setState(() {
                  final subj = newSubject.trim();
                  _subjects.add(subj);
                  _localStorage.addCalcSubjects(_subjects);
                  _selectedSubject = subj;
                  _savedData[subj] = [];
                  _loadSubjectData();
                  _resultText = '';
                });
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Muestra diálogo para confirmar y eliminar la subject actual
  Future<void> _deleteSubject() async {
    final subject = _selectedSubject;
    if (subject == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar "$subject"?'),
        content: const Text(
            '¿Estás seguro de que quieres eliminar esta asignatura y todos sus datos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _subjects.remove(subject);
      _savedData.remove(subject);
      _localStorage.addCalcSubjects(_subjects);
      _localStorage.addCalcData(_savedData);

      if (_subjects.isNotEmpty) {
        _selectedSubject = _subjects.first;
        _loadSubjectData();
      } else {
        const defaultSubj = 'Default Subject';
        _subjects = [defaultSubj];
        _savedData[defaultSubj] = [];
        _localStorage.addCalcSubjects(_subjects);
        _localStorage.addCalcData(_savedData);
        _selectedSubject = defaultSubj;
        _loadSubjectData();
      }
      _resultText = '';
    });
  }

  @override
  void dispose() {
    for (var c in _nameControllers) c.dispose();
    for (var c in _gradeControllers) c.dispose();
    for (var c in _percentControllers) c.dispose();
    _targetGradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSubjects) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Calculator'),
        backgroundColor: Colors.purple,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- SUBJECT DROPDOWN WITH ADD & DELETE
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSubject,
                            decoration: InputDecoration(
                              labelText: 'Subject',
                              border: OutlineInputBorder(),
                            ),
                            items: _subjects
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (subj) => setState(() {
                              _selectedSubject = subj;
                              _loadSubjectData();
                              _resultText = '';
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          tooltip: 'Add Subject',
                          onPressed: _showAddSubjectDialog,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever),
                          tooltip: 'Delete Subject',
                          onPressed: _deleteSubject,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- CALC vs FIND toggle
                    ToggleButtons(
                      borderRadius: BorderRadius.circular(8),
                      isSelected: [_isFindMode == false, _isFindMode],
                      onPressed: (i) => setState(() {
                        _isFindMode = i == 1;
                        _resultText = '';
                      }),
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Final Grade'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Target Grade'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('All grades should be over 5.0'),
                    const SizedBox(height: 16),

                    // --- DYNAMIC ROWS
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _gradeControllers.length,
                      itemBuilder: (_, idx) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameControllers[idx],
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _gradeControllers[idx],
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9\.,]')),
                                  ],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Grade ${idx + 1}',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _percentControllers[idx],
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9\.,]')),
                                  ],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: '%',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeEntry(idx),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    TextButton.icon(
                      onPressed: _addEntry,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Row'),
                    ),

                    if (_isFindMode) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _targetGradeController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9\.,]')),
                        ],
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Final target score (out of 5.0)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _calculate,
                      child: const Text('Calculate'),
                    ),
                    const SizedBox(height: 16),
                    Text(_resultText, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
