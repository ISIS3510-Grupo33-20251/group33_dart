import 'package:flutter/material.dart';
import 'package:group33_dart/services/api_service_adapter.dart';

import '../globals.dart';

bool contieneEmojis(String texto) {
  final regexEmoji = RegExp(r'^[\p{L}\p{N}\p{P}\p{Zs}\n\r]+$', unicode: true);

  return !regexEmoji.hasMatch(texto);
}

String normalizarSaltos(String texto) {
  return texto.replaceAll(RegExp(r'\n+'), '\n');
}

final ApiServiceAdapter apiServiceAdapter =
    ApiServiceAdapter(backendUrl: backendUrl);

class Note extends StatefulWidget {
  final String noteId;
  final String initialTitle;
  final String initialContent;
  final String initialSubject;
  final String created_date;
  final String last_modified;
  final List<Map<String, dynamic>> notes;

  const Note({
    super.key,
    required this.noteId,
    required this.initialTitle,
    required this.initialContent,
    required this.initialSubject,
    required this.created_date,
    required this.last_modified,
    required this.notes,
  });

  @override
  _NoteState createState() => _NoteState();
}

class _NoteState extends State<Note> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _subjectController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    _subjectController = TextEditingController(text: widget.initialSubject);
  }

  Future<void> updateNote() async {
    try {
      await apiServiceAdapter.updateNote(
        widget.noteId,
        _titleController.text,
        normalizarSaltos(_contentController.text),
        _subjectController.text,
        widget.created_date,
        widget.last_modified,
        userId,
      );
      Navigator.pop(context); // Cierra la pantalla después de actualizar
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al actualizar la nota")),
      );
    }
  }

  Future<void> createNote() async {
    try {
      await apiServiceAdapter.createNote(
        _titleController.text,
        normalizarSaltos(_contentController.text),
        _subjectController.text,
        userId,
      );
      Navigator.pop(context); // Cierra la pantalla después de crear
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al crear la nota")),
      );
    }
  }

  Future<void> deleteNote() async {
    try {
      await apiServiceAdapter.deleteNote(widget.noteId);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al eliminar la nota")),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se obtiene la lista de subjects únicos a partir de widget.notes
    final List<String> subjectOptions =
        widget.notes.map((note) => note['subject'] as String).toSet().toList();

    // Si el subject actual no está en la lista y no es vacío, se agrega
    if (_subjectController.text.isNotEmpty &&
        !subjectOptions.contains(_subjectController.text)) {
      subjectOptions.add(_subjectController.text);
    }

    // Opción especial para agregar un nuevo subject
    const String addNewOption = "Add new subject";
    if (!subjectOptions.contains(addNewOption)) {
      subjectOptions.add(addNewOption);
    }

    return Scaffold(
      appBar: AppBar(title: Text("Edit Note")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo de título
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Title"),
            ),
            SizedBox(height: 10),
            // Campo de contenido
            TextField(
              controller: _contentController,
              decoration: InputDecoration(labelText: "Content"),
              maxLines: 5,
            ),
            SizedBox(height: 10),
            // Dropdown para seleccionar o agregar un subject
            DropdownButtonFormField<String>(
              value: _subjectController.text.isNotEmpty
                  ? _subjectController.text
                  : null,
              decoration: InputDecoration(labelText: "Subject"),
              items: subjectOptions.map((subject) {
                return DropdownMenuItem<String>(
                  value: subject,
                  child: Text(subject),
                );
              }).toList(),
              onChanged: (value) async {
                if (value == addNewOption) {
                  // Mostrar diálogo para ingresar un nuevo subject
                  final newSubject = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      final TextEditingController newSubjectController =
                          TextEditingController();
                      return AlertDialog(
                        title: Text("New Subject"),
                        content: TextField(
                          controller: newSubjectController,
                          decoration: InputDecoration(
                            labelText: "Type new subject",
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, newSubjectController.text);
                            },
                            child: Text("Add"),
                          ),
                        ],
                      );
                    },
                  );
                  if (newSubject != null && newSubject.trim().isNotEmpty) {
                    setState(() {
                      _subjectController.text = newSubject.trim();
                    });
                  } else {
                    _subjectController.text = "";
                  }
                } else {
                  setState(() {
                    _subjectController.text = value ?? "";
                  });
                }
              },
            ),
            SizedBox(height: 20),
            // Botón para guardar (crear o actualizar)
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.trim().isEmpty ||
                    _contentController.text.trim().isEmpty ||
                    _subjectController.text.trim().isEmpty ||
                    contieneEmojis(_titleController.text.trim()) ||
                    contieneEmojis(_contentController.text.trim()) ||
                    contieneEmojis(_subjectController.text.trim())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No se permiten emojis ni campos vacíos!'),
                    ),
                  );
                } else {
                  if (widget.noteId.isEmpty) {
                    createNote();
                  } else {
                    updateNote();
                  }
                }
              },
              child: Text("Save"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (widget.noteId.isNotEmpty) {
            deleteNote();
          } else {
            Navigator.pop(context);
          }
        },
        child: Icon(Icons.delete),
      ),
    );
  }
}
