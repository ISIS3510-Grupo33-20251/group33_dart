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
  bool isAnimating = false; // Variable para controlar la animación

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
      return false; // No permitir pop.
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

            // Si la longitud de flashcards es 0, muestra un aviso y cierra la vista.
            if (flashcards.isEmpty) {
              // Utilizamos addPostFrameCallback para evitar problemas con el ciclo de vida del widget.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("There is not enough information to create flashcards for this subject :("))
                );
                Navigator.pop(context);
              });
              // Retornamos un Container vacío mientras se cierra la vista.
              return Container();
            }

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
                          key: ValueKey<bool>(isFlipped),
                          width: MediaQuery.of(context).size.width * 0.50,
                          height: MediaQuery.of(context).size.height * 0.5,
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                          ),
                          child: Text(
                            isAnimating ? '' : (isFlipped ? currentCard['answer'] : currentCard['question']),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => prevCard(flashcards),
                          child: Text("Prev"),
                        ),
                        ElevatedButton(
                          onPressed: () => nextCard(flashcards),
                          child: Text("Next"),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
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
