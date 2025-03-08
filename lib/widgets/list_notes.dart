import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../globals.dart';
import 'note.dart';

class ListNotes extends StatefulWidget {
  const ListNotes({super.key});

  @override
  _ListNotesState createState() => _ListNotesState();
}

class _ListNotesState extends State<ListNotes> {
  Future<List<Map<String, dynamic>>> fetchNotes() async {
    final response = await http.get(Uri.parse("$backendUrl/users/$userId/notes/"));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception("Error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchNotes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No notes yet"));
        }

        final notes = snapshot.data!;
        return ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];

            String contentPreview = (note.containsKey('content') && note['content'] is String)
                ? (note['content'] as String).length > 20
                    ? (note['content'] as String).substring(0, 20) + "..."
                    : note['content'] as String
                : "No content";

            return Card(
              margin: EdgeInsets.all(10),
              elevation: 3,
              child: ListTile(
                title: Text(note['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note['subject']),
                    SizedBox(height: 5),
                    Text(
                      contentPreview, 
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                trailing: Text(
                  note['created_date'].toString().split("T")[0], 
                  style: TextStyle(color: Colors.grey[700]),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Note(
                        noteId: note['_id'], 
                        initialTitle: note['title'], 
                        initialContent: note['content'],
                        initialSubject: note['subject'],
                        created_date: note['created_date'],
                        last_modified: note['last_modified'],
                      ),
                    ),
                  ).then((_) {setState(() {}); });
                },
              ),
            );
          },
        );
      },
    );
  }
}
