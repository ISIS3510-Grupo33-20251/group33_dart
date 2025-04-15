import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../globals.dart';


bool contieneEmojis(String texto) {
  final regexEmoji = RegExp(r'^[\p{L}\p{N}\p{P}\p{Zs}]+$', unicode: true);

  return !regexEmoji.hasMatch(texto);
}

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
    final response = await http.put(
      Uri.parse("$backendUrl/notes/${widget.noteId}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "title": _titleController.text,
        "content": _contentController.text,
        "subject": _subjectController.text,
        "created_date": widget.created_date,
        "last_modified": widget.last_modified,
        "owner_id": userId
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context); // Cierra la pantalla después de guardar
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al actualizar la nota")),
      );
    }
  }

  Future<void> createNote() async {
    final response = await http.post(
      Uri.parse("$backendUrl/notes/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "title": _titleController.text,
        "content": _contentController.text,
        "subject": _subjectController.text,
        "created_date": '2024-03-07T12:00:00Z',
        "last_modified": '2024-03-07T12:00:00Z',
        "owner_id": userId
      }),
    );

    if (response.statusCode == 200) {
      final noteId = json.decode(response.body)["_id"];

      final responseTags = await http.post(
        Uri.parse("$backendUrl/users/$userId/notes/$noteId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),
      );

      if (responseTags.statusCode == 200) {
        Navigator.pop(context); // Cierra la pantalla después de ambas peticiones exitosas
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error")),
      );
    }
  }

  Future<void> deleteNote() async {
    final response = await http.delete(
      Uri.parse("$backendUrl/notes/${widget.noteId}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error")),
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
    final List<String> subjectOptions = widget.notes
        .map((note) => note['subject'] as String)
        .toSet()
        .toList();

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
              if (newSubject != null && newSubject.isNotEmpty) {
                setState(() {
                  _subjectController.text = newSubject;
                });
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
            if(_titleController.text.isEmpty ||
               _contentController.text.isEmpty ||
               _subjectController.text.isEmpty ||
               contieneEmojis(_titleController.text) ||
               contieneEmojis(_contentController.text) ||
               contieneEmojis(_subjectController.text)
            ){
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Emojis nor blank inputs are permited!'),
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
