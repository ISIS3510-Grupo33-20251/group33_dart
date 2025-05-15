import 'package:flutter/material.dart';
import 'package:group33_dart/presentation/location/add_friend.dart';
import 'package:group33_dart/presentation/location/pending_requests.dart';
import '../../globals.dart';

class AddFriendPopup extends StatelessWidget {
  final String userId;

  const AddFriendPopup({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.add, color: Colors.black),
      color: Colors.white, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8, 
      onSelected: (value) {
        if (value == 'add') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddFriend(userId: userId)),
          );
        } else if (value == 'requests') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PendingRequests()),
          );
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'add',
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Add Friend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'requests',
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Friend Requests',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
