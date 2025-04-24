import 'package:flutter/material.dart';
import 'friend.dart';

class FriendCard extends StatelessWidget {
  final Friend friend;

  const FriendCard({super.key, required this.friend});

  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m away';
    } else {
      double distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)} km away';
    }
  }

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
        subtitle: Text(formatDistance(friend.distance)),
        onTap: () {
          // this works for viewing a friend's schedule
        },
      ),
    );
  }
}
