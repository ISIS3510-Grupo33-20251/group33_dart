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
  bool isAnimating = false; // Nueva variable para controlar la animación

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
      throw Exception("Error");
    }
  }

  void nextCard(List<Map<String, dynamic>> flashcards) {
    setState(() {
      currentCardIndex = (currentCardIndex + 1) % flashcards.length;
      isFlipped = false;
    });
  }

  void prevCard(List<Map<String, dynamic>> flashcards) {
    setState(() {
      currentCardIndex = (currentCardIndex - 1) % flashcards.length;
      isFlipped = false;
    });
  }

  void flipCard() {
    // Inicia la animación: se muestra texto vacío mientras gira.
    
    // A la mitad de la animación (150ms de 300ms) se invierte la cara.
    Future.delayed(Duration(milliseconds: 150), () {
      setState(() {
      isAnimating = true;
    });
      setState(() {
        isFlipped = !isFlipped;
      });
    });
    // Al finalizar la animación se desactiva el flag.
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        isAnimating = false;
      });
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
              return Center(child: Text("Error"));
            }

            final flashcards = snapshot.data!;

            // Modo Preview: muestra todas las flashcards en una lista y un botón para practicar.
            if (!isPracticeMode) {
              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.70,
                        child: ListView.builder(
                          itemCount: flashcards.length,
                          itemBuilder: (context, index) {
                            final card = flashcards[index];
                            return Card(
                              margin: EdgeInsets.all(8.0),
                              elevation: 2,
                              child: ListTile(
                                title: Text(card['question']),
                              ),
                            );
                          },
                        ),
                      ),
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
                    Text(isFlipped ? 'Answer' : 'Question'),
                    GestureDetector(
                      onTap: flipCard,
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          final rotate = Tween(begin: 0.0, end: 3.14).animate(animation);
                          return AnimatedBuilder(
                            animation: rotate,
                            builder: (context, child) {
                              final isUnder = (rotate.value > 1.57);
                              return Transform(
                                transform: Matrix4.rotationY(rotate.value),
                                alignment: Alignment.center,
                                child: isUnder
                                    ? Transform(
                                        transform: Matrix4.rotationY(3.14),
                                        alignment: Alignment.center,
                                        child: child,
                                      )
                                    : child,
                              );
                            },
                            child: child,
                          );
                        },
                        child: Container(
                          key: ValueKey<bool>(isFlipped), // Clave única para animación
                          width: MediaQuery.of(context).size.width * 0.50,
                          height: MediaQuery.of(context).size.height * 0.5,
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                          ),
                          // Aquí se muestra el texto vacío si se está animando.
                          child: Text(
                            isAnimating ? '' : (isFlipped ? currentCard['answer'] : currentCard['question']),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      ElevatedButton(
                      onPressed: () => prevCard(flashcards),
                      child: Text("Prev"),
                    ),
                    ElevatedButton(
                      onPressed: () => nextCard(flashcards),
                      child: Text("Next"),
                    ),
                    ],),
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
