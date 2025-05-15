import 'package:flutter/material.dart';

class PopupMenuWidget extends StatelessWidget {
  final void Function(String value) onSelected;

  const PopupMenuWidget({Key? key, required this.onSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu, color: Colors.black),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 8,
      onSelected: onSelected,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildStyledItem('Profile'),
        _buildStyledItem('Friends'),
        _buildStyledItem('Share'),
        _buildStyledItem('Settings'),
        _buildStyledItem('Guide'),
        _buildStyledItem('Logout'),
      ],
    );
  }

  PopupMenuItem<String> _buildStyledItem(String label) {
    return PopupMenuItem<String>(
      value: label.toLowerCase(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        width: 150,
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
