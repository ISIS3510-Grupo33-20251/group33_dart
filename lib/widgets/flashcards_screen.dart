// Archivo: flashcards_screen.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../globals.dart'; 

class FlashcardsScreen extends StatefulWidget {
  final String subject;
  const FlashcardsScreen({Key? key, required this.subject}) : super(key: key);

  @override
  _FlashcardsScreenState createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  late Future<List<Map<String, dynamic>>> futureFlashcards;
  bool isPracticeMode = false;
  int currentCardIndex = 0;
  bool isFlipped = false;

  @override
  void initState() {
    super.initState();
    futureFlashcards = fetchFlashcards();
  }

  Future<List<Map<String, dynamic>>> fetchFlashcards() async {
    final response = await http.get(Uri.parse("$backendUrl/users/$userId/${widget.subject}/flash/"));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception("Error al obtener flashcards");
    }
  }

  void nextCard(List<Map<String, dynamic>> flashcards) {
    setState(() {
      currentCardIndex = (currentCardIndex + 1) % flashcards.length;
      isFlipped = false;
    });
  }

  void flipCard() {
    setState(() {
      isFlipped = !isFlipped;
    });
  }

  Future<bool> _onWillPop() async {
    if (isPracticeMode) {
      // Si estamos en modo practice, volvemos al modo preview en lugar de salir de la pantalla.
      setState(() {
        isPracticeMode = false;
      });
      return false; // No permitir pop (retroceso) del Navigator.
    }
    return true; // Permitir pop si ya estamos en modo preview.
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Flashcards"),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: futureFlashcards,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Center(child: Text("Error al cargar flashcards"));
            }

            final flashcards = snapshot.data!;

            // Modo Preview: muestra todas las flashcards en una lista y un botón para practicar.
            if (!isPracticeMode) {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: flashcards.length,
                      itemBuilder: (context, index) {
                        final card = flashcards[index];
                        return Card(
                          margin: EdgeInsets.all(8.0),
                          elevation: 2,
                          child: ListTile(
                            title: Text(card['question']),
                            subtitle: Text(card['answer']),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      child: Text("Practice"),
                      onPressed: () {
                        setState(() {
                          isPracticeMode = true;
                          currentCardIndex = 0;
                          isFlipped = false;
                        });
                      },
                    ),
                  ),
                ],
              );
            } else {
              // Modo Practice: muestra una flashcard a la vez, con la posibilidad de girarla para ver la respuesta.
              final currentCard = flashcards[currentCardIndex];
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: flipCard,
                      child: Card(
                        elevation: 4.0,
                        margin: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            isFlipped ? currentCard['answer'] : currentCard['question'],
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => nextCard(flashcards),
                      child: Text("Next"),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // Vuelve al modo Preview sin salir de la pantalla
                        setState(() {
                          isPracticeMode = false;
                        });
                      },
                      child: Text("Back to Preview"),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
