import 'package:flutter/material.dart';

class PopupMenuWidget extends StatelessWidget {
  final Function(String) onSelected;

  const PopupMenuWidget({Key? key, required this.onSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person),
              SizedBox(width: 8),
              Text('Profile'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'friends',
          child: Row(
            children: [
              Icon(Icons.people),
              SizedBox(width: 8),
              Text('Friends'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'calculator',
          child: Row(
            children: [
              Icon(Icons.calculate),
              SizedBox(width: 8),
              Text('Calculator'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'kanban',
          child: Row(
            children: [
              Icon(Icons.view_kanban),
              SizedBox(width: 8),
              Text('Kanban Board'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout),
              SizedBox(width: 8),
              Text('Logout'),
            ],
          ),
        ),
      ],
    );
  }
}
