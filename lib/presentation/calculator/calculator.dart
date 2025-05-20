import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalculatorWidget extends StatefulWidget {
  const CalculatorWidget({super.key});
  @override
  _CalculatorWidgetState createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends State<CalculatorWidget> {
  final List<TextEditingController> _gradeControllers = [];
  final List<TextEditingController> _percentControllers = [];
  final TextEditingController _targetGradeController = TextEditingController();

  bool _isFindMode = false;
  String _resultText = '';

  @override
  void initState() {
    super.initState();
    _addEntry();
  }

  void _addEntry() {
    setState(() {
      _gradeControllers.add(TextEditingController());
      _percentControllers.add(TextEditingController());
    });
  }

  void _removeEntry(int index) {
    setState(() {
      _gradeControllers[index].dispose();
      _percentControllers[index].dispose();
      _gradeControllers.removeAt(index);
      _percentControllers.removeAt(index);
    });
  }

  void _calculate() {
    final entries = <Map<String, double>>[];
    for (int i = 0; i < _gradeControllers.length; i++) {
      final grade =
          double.tryParse(_gradeControllers[i].text.replaceAll(",", "."));
      final percent =
          double.tryParse(_percentControllers[i].text.replaceAll(",", "."));
      if (grade == null || percent == null) {
        setState(() {
          _resultText = 'Please put valid numbers';
        });
        return;
      }
      entries.add({'grade': grade, 'percent': percent});
    }

    if (!_isFindMode) {
      // Sumar contribuciones
      double total = 0;
      double pcTotal = 0;
      for (var e in entries) {
        total += (e['grade']! / 5.0) * e['percent']!;
        pcTotal += e['percent']!;
      }
      setState(() {
        if (pcTotal != 100) {
          _resultText = 'Percentages should add exactly 100';
        } else {
          _resultText =
              'Estimated final grade: ${(total * 5 / 100).toStringAsFixed(2)}/5.0\n${(total * 5 / 100) < 3.0 ? 'Better luck next semester!' : 'Congratulations!'}';
        }
      });
    } else {
      final target =
          double.tryParse(_targetGradeController.text.replaceAll(",", "."));
      if (target == null) {
        setState(() {
          _resultText = 'Please put valid numbers';
        });
        return;
      }
      double current = 0;
      double usedPercent = 0;
      for (var e in entries) {
        current += (e['grade']! / 5.0) * e['percent']!;
        usedPercent += e['percent']!;
      }
      final double remainPercent = 100.0 - usedPercent;
      if (remainPercent <= 0) {
        setState(() {
          _resultText = 'The percentage is 100% or more already';
        });
        return;
      }
      final targetContrib = (target / 5.0) * 100.0;
      final neededContrib = targetContrib - current;
      final neededGrade = (neededContrib / remainPercent) * 5.0;
      setState(() {
        if (neededGrade > 5.0) {
          _resultText =
              'Not possible! you need ${neededGrade.toStringAsFixed(2)}/5.0 in the remaining ${remainPercent.toStringAsFixed(2)}%';
        } else if (neededGrade < 0) {
          _resultText =
              'You have already reached the target grade. Congratulations!';
        } else {
          _resultText =
              'You need ${neededGrade.toStringAsFixed(2)}/5.0 in the remaining ${remainPercent.toStringAsFixed(0)}%';
        }
      });
    }
  }

  @override
  void dispose() {
    for (var c in _gradeControllers) {
      c.dispose();
    }
    for (var c in _percentControllers) {
      c.dispose();
    }
    _targetGradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Color de fondo de la página
      appBar: AppBar(
        title: const Text('Calculator'),
        backgroundColor: Colors.purple, // Ajusta según tu tema
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // Para que no se corte en pantallas pequeñas
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
                    ToggleButtons(
                      borderRadius: BorderRadius.circular(8),
                      isSelected: [_isFindMode == false, _isFindMode == true],
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
                    const Text('All grades should be over 5.0'),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _gradeControllers.length,
                      itemBuilder: (_, idx) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _gradeControllers[idx],
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9\.,]')),
                                ],
                                keyboardType: TextInputType.numberWithOptions(
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
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addEntry,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
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
