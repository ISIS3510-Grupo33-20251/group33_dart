import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/profile_service.dart';
import 'dart:io';
import '../../services/api_service_adapter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileService>().profile;
    ImageProvider? imageProvider;
    if (profile.imageUrl.isNotEmpty) {
      if (profile.imageUrl.startsWith('http')) {
        imageProvider = NetworkImage(profile.imageUrl);
      } else if (File(profile.imageUrl).existsSync()) {
        imageProvider = FileImage(File(profile.imageUrl));
      }
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text('Profile',
              style: TextStyle(fontWeight: FontWeight.bold))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.person, size: 80)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              profile.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Semester: ${profile.semester}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final hasConnection = await hasInternetConnection();
                if (!hasConnection) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('There is no internet connection.'),
                    ),
                  );
                  return;
                }
                Navigator.pushNamed(context, '/edit_profile');
              },
              child: const Text('Edit Profile',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
