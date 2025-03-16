import 'package:flutter/material.dart';
import 'note.dart';

class ListNotes extends StatelessWidget {
  final List<Map<String, dynamic>> notes;
  final VoidCallback onNoteClosed; // Callback to trigger refresh

  const ListNotes({
    Key? key,
    required this.notes,
    required this.onNoteClosed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return Center(child: Text("No notes yet"));
    }

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
                    notes: notes,
                  ),
                ),
              ).then((_) {
                // When the Note screen is closed, trigger the refresh callback.
                onNoteClosed();
              });
            },
          ),
        );
      },
    );
  }
}
