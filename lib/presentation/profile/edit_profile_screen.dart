import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _imageController;
  late TextEditingController _semesterController;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileService>().profile;
    _nameController = TextEditingController(text: profile.name);
    _imageController = TextEditingController(text: profile.imageUrl);
    _semesterController =
        TextEditingController(text: profile.semester.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _imageController,
              decoration: const InputDecoration(labelText: 'Image URL'),
            ),
            TextField(
              controller: _semesterController,
              decoration: const InputDecoration(labelText: 'Semester'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<ProfileService>().updateProfile(
                      name: _nameController.text,
                      imageUrl: _imageController.text,
                      semester: int.tryParse(_semesterController.text) ?? 1,
                    );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
