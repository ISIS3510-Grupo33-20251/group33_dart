import 'package:flutter/material.dart';
import 'package:group33_dart/screen_flashcards.dart';
import 'screen_notes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Navegación',
      initialRoute: '/',  // Ruta inicial
      routes: {
        '/': (context) => ScreenNotes(),
        // '/notes': (context) => ScreenNotes(),
        '/flashcards': (context) => ScreenFlashcard(),
      },
    );
  }
}

