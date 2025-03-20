import 'package:flutter/material.dart';
import 'friend.dart';
import 'friend_card.dart';

class FriendList extends StatelessWidget {
  final List<Friend> friends;

  const FriendList({Key? key, required this.friends}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: friends.length,
      itemBuilder: (context, index) {
        return FriendCard(friend: friends[index]);
      },
    );
  }
}
