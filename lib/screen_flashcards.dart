// Archivo: screen_flashcard.dart
import 'package:flutter/material.dart';
import './widgets/flashcards_screen.dart'; // Asegúrate de que la ruta sea la correcta

class ScreenFlashcard extends StatelessWidget {
  const ScreenFlashcard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se obtienen las notas pasadas como argumento en la ruta.
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final List<Map<String, dynamic>> notes = args['notes'];

    // Agrupamos las notas por subject, tomando la primera nota que encontremos para cada asignatura.
    final Map<String, Map<String, dynamic>> subjectNotes = {};
    for (var note in notes) {
      String subject = note['subject'] as String;
      if (!subjectNotes.containsKey(subject)) {
        subjectNotes[subject] = note;
      }
    }

    // Convertimos el mapa en una lista de flashcards.
    final List<Map<String, dynamic>> flashcards = subjectNotes.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Flashcards"),
      ),
      body: flashcards.isEmpty
          ? Center(child: Text("No hay flashcards disponibles"))
          : ListView.builder(
              itemCount: flashcards.length,
              itemBuilder: (context, index) {
                final flashcard = flashcards[index];
                return Card(
                  margin: EdgeInsets.all(10),
                  elevation: 3,
                  child: ListTile(
                    title: Text(flashcard['subject']),
                    subtitle: Text(flashcard['title'] ?? ''),
                    onTap: () {
                      // Al presionar la tarjeta se navega a FlashcardsScreen
                      // Se pasa el subject correspondiente (si está filtrado se puede usar ese, o el de la flashcard)
                      String subjectToPass = flashcard['subject'];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FlashcardsScreen(subject: subjectToPass),
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
