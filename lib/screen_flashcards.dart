import 'package:flutter/material.dart';
import './widgets/flashcards_screen.dart';

class ScreenFlashcard extends StatelessWidget {
  const ScreenFlashcard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final List<Map<String, dynamic>> notes = args['notes'];

    // Mapa para contar la cantidad de notas por asignatura
    final Map<String, int> subjectCount = {};
    final Map<String, Map<String, dynamic>> subjectNotes = {};

    for (var note in notes) {
      String subject = note['subject'] as String;
      subjectCount[subject] = (subjectCount[subject] ?? 0) + 1;
      if (!subjectNotes.containsKey(subject)) {
        subjectNotes[subject] = note;
      }
    }

    final List<Map<String, dynamic>> flashcards = subjectNotes.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Flashcards"),
      ),
      body: flashcards.isEmpty
          ? Center(child: Text("No flashcards available"))
          : ListView.builder(
              itemCount: flashcards.length,
              itemBuilder: (context, index) {
                final flashcard = flashcards[index];
                String subject = flashcard['subject'];
                int noteCount = subjectCount[subject] ?? 0;

                return Card(
                  margin: EdgeInsets.all(10),
                  elevation: 3,
                  child: ListTile(
                    title: Text(subject),
                    subtitle: Text("$noteCount notes"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FlashcardsScreen(subject: subject),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
