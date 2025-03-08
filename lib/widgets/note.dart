import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../globals.dart';

class Note extends StatefulWidget {
  final String noteId;
  final String initialTitle;
  final String initialContent;
  final String initialSubject;
  final String created_date;
  final String last_modified;

  const Note({
    super.key,
    required this.noteId,
    required this.initialTitle,
    required this.initialContent,
    required this.initialSubject,
    required this.created_date,
    required this.last_modified,
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

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "TItle"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(labelText: "Content"),
              maxLines: 5,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(labelText: "Subject"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (widget.noteId.isEmpty) {
                  createNote();
                } else {
                  updateNote();
                }
              },
              child: Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
