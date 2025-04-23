import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class NotesAnalysis extends StatelessWidget {
  final List<Map<String, dynamic>> notes;

  const NotesAnalysis({Key? key, required this.notes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (var note in notes) {
      final subject = note['subject'] as String? ?? 'Unknown';
      counts[subject] = (counts[subject] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return Center(child: Text('No notes'));
    }

    final total = counts.values.reduce((a, b) => a + b);
    final entries = counts.entries.toList();

    return Column(
      children: [
        // Chart with flexible space
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                sections: entries.map((e) {
                  final percentage = (e.value / total) * 100;
                  final color = Colors
                      .primaries[entries.indexOf(e) % Colors.primaries.length];
                  return PieChartSectionData(
                    color: color,
                    value: percentage,
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: 60,
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ),
        // Constrained legend with horizontal scroll
        SizedBox(
          height: 40, // Fixed height for legend
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: entries.map((e) {
                  final color = Colors
                      .primaries[entries.indexOf(e) % Colors.primaries.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${e.key} (${e.value})',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
