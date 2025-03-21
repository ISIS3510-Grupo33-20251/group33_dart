import 'package:flutter/material.dart';
import 'friend.dart';

class FriendCard extends StatelessWidget {
  final Friend friend;

  const FriendCard({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade100,
          child: Text(
            friend.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.black),
          ),
        ),
        title: Text(
          friend.name,
          style: const TextStyle(fontSize: 16),
        ),
        subtitle: Text('${friend.distance.toStringAsFixed(2)} km away'),
        onTap: () {
          // this works for viewing a friends schedule
        },
      ),
    );
  }
}
