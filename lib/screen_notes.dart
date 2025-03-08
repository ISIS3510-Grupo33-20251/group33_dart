import 'package:flutter/material.dart';
import 'package:group33_dart/widgets/list_notes.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../globals.dart';

List<PopupMenuEntry<String>> buildMenuItems() {
    return [
      PopupMenuItem(value: "opcion1", child: Text("Opción 1")),
      PopupMenuItem(value: "opcion2", child: Text("Opción 2")),
      PopupMenuItem(value: "opcion3", child: Text("Opción 3")),
    ];
  }

class ScreenNotes extends StatelessWidget {
  const ScreenNotes({super.key});

  Future<int> fetchNotes() async {
    final response = await http.get(Uri.parse("$backendUrl/users/$userId/notes/"));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body)).length;
    } else {
      throw Exception("Error al cargar notas");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(preferredSize: Size.fromHeight(180), 
      child: Stack(
        alignment: Alignment.center,
        children: [  
          Positioned(top: 40, child: Image.asset('assets/logo.png', height: 60, width: 60,)),
          Positioned(top: 100, child: Text('My notes', style:  TextStyle(fontSize: 32, fontFamily: 'Inter', fontWeight: FontWeight.w400),)),
          Positioned(top: 150, child: FutureBuilder<int>(
              future: fetchNotes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text('Cargando...',style:  TextStyle(fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w100));
                } else if (snapshot.hasError) {
                  return Text('0 Notas', style:  TextStyle(fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w100));
                } else {
                  return Text('${snapshot.data} notas', style:  TextStyle(fontSize: 16, fontFamily: 'Inter', fontWeight: FontWeight.w100));
                }
              },
            )),
          Positioned(top: 170, child: SizedBox(width: MediaQuery.of(context).size.width * 0.9,child:  Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            PopupMenuButton(itemBuilder: (context) => buildMenuItems(), icon: Icon(Icons.more_vert)),
            Spacer(),
            IconButton(onPressed: () {}, icon: Icon(Icons.search)),

          ],),))

        ],
      )),
      body:  ListNotes(),
    );
  }
  
}

