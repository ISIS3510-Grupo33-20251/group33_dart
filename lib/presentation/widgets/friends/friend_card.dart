import 'package:flutter/material.dart';
import 'friend.dart';class FriendCard extends StatefulWidget {
  final Friend friend;

  const FriendCard({Key? key, required this.friend}) : super(key: key);

  @override
  State<FriendCard> createState() => _FriendCardState();
}

class _FriendCardState extends State<FriendCard> {
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
            widget.friend.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.black,fontWeight: FontWeight.bold ),
          ),
        ),
        title: Text(
          widget.friend.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(formatDistance(widget.friend.distance),style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
        onTap: () {
          // Future feature: open friend's schedule
        },
      ),
    );
  }
}
