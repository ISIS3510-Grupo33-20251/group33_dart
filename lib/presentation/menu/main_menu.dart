import 'package:flutter/material.dart';
import '../location/nearby_friends_page.dart';
import '../widgets/menu/popup_menu.dart';
import '../schedule/schedule_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../services/schedule_service.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/sources/local/cache_service.dart';
import '../../services/profile_service.dart';

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
            content: Text('Error logging out'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void handleMenuSelection(BuildContext context, String value) {
    if (value == 'profile') {
      Navigator.pushNamed(context, '/profile');
    } else if (value == 'friends') {
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

  Future<bool> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _handleSync(BuildContext context) async {
    final scheduleService = context.read<ScheduleService>();

    try {
      if (!await _checkConnectivity()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('There is no internet connection'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await scheduleService.syncNow();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule synced'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<DateTime?> _getLastSyncTime() async {
    final cacheService = CacheService();
    final cached = await cacheService.loadLastScheduleUpdate();
    if (cached != null && cached['lastSyncTime'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(cached['lastSyncTime']);
    }
    // fallback: try SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final lastSyncTimeStr = prefs.getString('lastSyncTime');
    if (lastSyncTimeStr != null) {
      final timestamp = int.tryParse(lastSyncTimeStr);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }
    return null;
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
            Consumer<ProfileService>(
              builder: (context, profileService, child) {
                return Container(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    'SEMESTER ${profileService.profile.semester}',
                    style: const TextStyle(
                        color: Color.fromARGB(255, 81, 80, 80),
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Schedule',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                Consumer<ScheduleService>(
                  builder: (context, scheduleService, child) {
                    return FutureBuilder<DateTime?>(
                      future: _getLastSyncTime(),
                      builder: (context, snapshot) {
                        final lastSyncTime = snapshot.data;
                        final syncStatus = _formatLastSyncTime(lastSyncTime);
                        return Text(
                          syncStatus,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 81, 80, 80),
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, size: 22),
            onPressed: () => _handleSync(context),
            tooltip: 'Sync now',
          ),
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
