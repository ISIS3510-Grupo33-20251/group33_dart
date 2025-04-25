import 'package:flutter/material.dart';
import '../location/nearby_friends_page.dart';
import '../widgets/menu/popup_menu.dart';
import '../schedule/schedule_screen.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  void handleMenuSelection(BuildContext context, String value) {
    if (value == 'friends') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NearbyFriendsPage()),
      );
    } else if (value == 'logout') {
      // Limpiar las credenciales del usuario y redirigir a la pantalla de bienvenida
      Navigator.of(context).pushReplacementNamed('/welcome');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected: $value')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SEMESTER 1',
                style: TextStyle(
                    color: Color.fromARGB(255, 81, 80, 80),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            Text('Schedule',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: PopupMenuWidget(
              onSelected: (value) => handleMenuSelection(context, value),
            ),
          ),
        ],
      ),
      body: const ScheduleScreen(),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          if (index == 2) {
            Navigator.pushNamed(context, '/notes');
          }
        },
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[400],
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Reminders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'Notes'),
        ],
      ),
    );
  }
}
