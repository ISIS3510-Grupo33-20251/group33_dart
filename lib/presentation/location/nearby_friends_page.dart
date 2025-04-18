import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../widgets/friends/friend.dart';
import '../widgets/friends/friend_list.dart';
import '../../globals.dart';

class NearbyFriendsPage extends StatefulWidget {
  const NearbyFriendsPage({Key? key}) : super(key: key);

  @override
  State<NearbyFriendsPage> createState() => _NearbyFriendsPageState();
}

class _NearbyFriendsPageState extends State<NearbyFriendsPage> {
  List<Friend> friends = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      Position position = await _getLocation();
      await _updateUserLocation(position);
      await _fetchFriends(position);
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<Position> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _updateUserLocation(Position position) async {
    final url = Uri.parse('$backendUrl/users/$userId/location');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'latitude': position.latitude,
        'longitude': position.longitude,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update location');
    }
  }

  Future<void> _fetchFriends(Position userPosition) async {
    final url = Uri.parse('$backendUrl/users/$userId/friends/location');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      List<Friend> fetchedFriends =
          data.map((json) => Friend.fromJson(json)).toList();

      for (var friend in fetchedFriends) {
        friend.distance = Geolocator.distanceBetween(
              userPosition.latitude,
              userPosition.longitude,
              friend.latitude,
              friend.longitude,
            ) /
            1000; // to km
      }

      fetchedFriends.sort((a, b) => a.distance.compareTo(b.distance));

      setState(() {
        friends = fetchedFriends;
        isLoading = false;
      });
    } else {
      throw Exception('Failed to fetch friends');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Friends',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {
              // to program the add friends
            },
          ),
        ],
      ),
      body: FriendList(friends: friends),
    );
  }
}
