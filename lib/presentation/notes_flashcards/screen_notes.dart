import 'package:flutter/material.dart';
import 'package:group33_dart/network/internet.dart';
import 'package:group33_dart/services/api_service_adapter.dart';
import 'package:group33_dart/services/local_storage_service.dart';
import 'package:group33_dart/widgets/list_notes.dart';
import '../../../globals.dart';
import '../../widgets/note.dart';

class ScreenNotes extends StatefulWidget {
  const ScreenNotes({super.key});

  @override
  _ScreenNotesState createState() => _ScreenNotesState();
}

class _ScreenNotesState extends State<ScreenNotes> {
  late Future<List<Map<String, dynamic>>> futureNotes;
  String? _selectedSubject; // null significa sin filtro (todas las notas)
  List<Map<String, dynamic>> _allNotes = [];
  final ApiServiceAdapter apiServiceAdapter =
      ApiServiceAdapter(backendUrl: backendUrl);
  final LocalStorageService _localStorage = LocalStorageService();

  @override
  void initState() {
    super.initState();
    futureNotes = fetchNotes();
  }

  Future<List<Map<String, dynamic>>> fetchNotes() async {
    final hasConnection = await checkInternetConnection();

    if (hasConnection) {
      try {
        final onlineNotes =
            await apiServiceAdapter.fetchNotes('users/$userId/notes/');
        await _localStorage.saveNotes(onlineNotes);
        return onlineNotes;
      } catch (e) {
        return _localStorage.loadNotes();
      }
    } else {
      return _localStorage.loadNotes();
    }
  }

  // Función auxiliar para calcular el número de notas filtradas.
  int _getFilteredCount(List<Map<String, dynamic>> notes) {
    if (_selectedSubject == null) return notes.length;
    return notes.where((note) => note['subject'] == _selectedSubject).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar customizado con título, cantidad de notas y menú debajo.
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(220), // Aumentamos la altura para acomodar el menú
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: futureNotes,
          builder: (context, snapshot) {
            // Construimos la lista de asignaturas una vez que tenemos los datos.
            List<String> subjects = [];
            if (snapshot.hasData) {
              subjects = snapshot.data!
                  .map((note) => note['subject'] as String)
                  .toSet()
                  .toList();
            }

            // Calculamos la cantidad de notas filtradas.
            int noteCount = 0;
            if (snapshot.hasData) {
              noteCount = _getFilteredCount(snapshot.data!);
              _allNotes = snapshot.data!;
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                // Logo en la parte superior central.
                Positioned(
                  top: 40,
                  child: Image.asset(
                    'assets/logo.png',
                    height: 60,
                    width: 60,
                  ),
                ),
                // Título de la página (cambia según la asignatura seleccionada).
                Positioned(
                  top: 100,
                  child: Text(
                    _selectedSubject ?? 'My notes',
                    style: TextStyle(
                      fontSize: 32,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                // Muestra la cantidad de notas filtradas.
                Positioned(
                  top: 150,
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w100,
                          ),
                        )
                      : Text(
                          '$noteCount notes',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w100,
                          ),
                        ),
                ),
                // Botón de menú colocado debajo del número de notas y alineado a la izquierda.
                Positioned(
                  top: 180, // ajusta este valor según sea necesario
                  left: 10, // lo posiciona a la izquierda
                  child: IconButton(
                    icon: Icon(Icons.menu),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return ListView(
                            children: [
                              ListTile(
                                title: Text('All Subjects'),
                                onTap: () {
                                  setState(() {
                                    _selectedSubject = null;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                              ...subjects.map((subject) => ListTile(
                                    title: Text(subject),
                                    onTap: () {
                                      setState(() {
                                        _selectedSubject = subject;
                                      });
                                      Navigator.pop(context);
                                    },
                                  )),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      // Usamos Stack en el body para colocar el nuevo botón adicional.
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: futureNotes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text("No notes available"));
          }
          // Aplicamos el filtrado si se ha seleccionado alguna asignatura.
          List<Map<String, dynamic>> notes = snapshot.data!;
          if (_selectedSubject != null) {
            notes = notes
                .where((note) => note['subject'] == _selectedSubject)
                .toList();
          }
          return Stack(
            children: [
              ListNotes(
                notes: notes,
                // Callback para refrescar la lista cuando se cierra la pantalla de una nota.
                onNoteClosed: () {
                  setState(() {
                    futureNotes = fetchNotes();
                  });
                },
              ),
              // Botón adicional en la esquina inferior izquierda.
              Positioned(
                bottom: 16, // margen inferior
                left: 16, // margen izquierdo
                child: FloatingActionButton(
                  onPressed: () {
                    // Navega a la ruta '/flashcards' pasando las notas filtradas.
                    Navigator.pushNamed(
                      context,
                      '/flashcards',
                      arguments: {
                        'notes': _allNotes,
                      },
                    );
                  },
                  child: Icon(Icons.web_stories_outlined),
                ),
              ),
            ],
          );
        },
      ),
      // Botón flotante existente en la esquina inferior derecha para agregar una nueva nota.
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final hasConnection = await checkInternetConnection();
          if (!hasConnection) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Not wifi connection, cannot create the note yet.'),
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Note(
                noteId: '',
                initialTitle: '',
                initialContent: '',
                initialSubject: '',
                created_date: '',
                last_modified: '',
                notes: _allNotes,
              ),
            ),
          ).then((_) {
            // Se refresca la lista al volver de la pantalla de la nota.
            setState(() {
              futureNotes = fetchNotes();
            });
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
