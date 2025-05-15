import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/profile_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service_adapter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _imageController;
  late TextEditingController _semesterController;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileService>().profile;
    _nameController = TextEditingController(text: profile.name);
    _imageController = TextEditingController(text: profile.imageUrl);
    _semesterController =
        TextEditingController(text: profile.semester.toString());
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
        _imageController.text = pickedFile.path;
      });
      // Guardar la imagen en el servicio y actualizar el perfil
      await context.read<ProfileService>().setProfileImage(_pickedImage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileService>().profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 24.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (profile.imageUrl.startsWith('http')
                                  ? NetworkImage(profile.imageUrl)
                                  : FileImage(File(profile.imageUrl)))
                              as ImageProvider,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.camera_alt,
                              size: 22, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                      context.read<ProfileService>().updateProfile(
                            name: _nameController.text,
                            imageUrl: _imageController.text,
                            semester:
                                int.tryParse(_semesterController.text) ?? 1,
                          );
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
