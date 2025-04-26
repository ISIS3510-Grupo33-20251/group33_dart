import 'package:flutter/material.dart';
import '../location/nearby_friends_page.dart';
import '../widgets/menu/popup_menu.dart';
import '../schedule/schedule_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../services/schedule_service.dart';
import 'package:intl/intl.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Limpiar token y datos de usuario
      await prefs.remove('token');
      await prefs.remove('userId');

      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cerrar sesión'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void handleMenuSelection(BuildContext context, String value) {
    if (value == 'friends') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NearbyFriendsPage()),
      );
    } else if (value == 'logout') {
      _handleLogout(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected: $value')),
      );
    }
  }

  String _formatLastSyncTime(DateTime? lastSyncTime) {
    if (lastSyncTime == null) return 'Never synced';
    final now = DateTime.now();
    final difference = now.difference(lastSyncTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, y HH:mm').format(lastSyncTime);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SEMESTER 1',
                style: TextStyle(
                    color: Color.fromARGB(255, 81, 80, 80),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            Row(
              children: [
                const Text('Schedule',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                const SizedBox(width: 10),
                Consumer<ScheduleService>(
                  builder: (context, scheduleService, child) {
                    return Text(
                      _formatLastSyncTime(scheduleService.lastSyncTime),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  },
                ),
              ],
            ),
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
