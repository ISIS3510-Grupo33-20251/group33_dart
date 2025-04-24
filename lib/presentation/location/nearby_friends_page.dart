import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/friends/friend.dart';
import '../widgets/friends/friend_list.dart';
import '../../globals.dart';
import 'package:group33_dart/data/sources/local/local_storage_service.dart';
import 'package:group33_dart/services/api_service_adapter.dart';
import 'add_friend_popup.dart';

final ApiServiceAdapter apiServiceAdapter =
    ApiServiceAdapter(backendUrl: backendUrl);
final LocalStorageService_localStorage = LocalStorageService();

class NearbyFriendsPage extends StatefulWidget {
  const NearbyFriendsPage({Key? key}) : super(key: key);

  @override
  State<NearbyFriendsPage> createState() => _NearbyFriendsPageState();
}

class _NearbyFriendsPageState extends State<NearbyFriendsPage> {
  List<Friend> friends = [];
  bool isLoading = true;
  String error = '';
  bool locationPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      Position? position;
      try {
        position = await _getLocation();
        if (position != null) {
          await _updateUserLocation(position);
        } else {
          setState(() {
            locationPermissionDenied = true;
          });
        }
      } catch (e) {
        setState(() {
          locationPermissionDenied = true;
        });
      }

      await _fetchFriends(position);
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<Position?> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _updateUserLocation(Position position) async {
    await apiServiceAdapter.updateUserLocationHttp(
      userId,
      position.latitude,
      position.longitude,
    );
  }

  Future<void> _fetchFriends(Position? userPosition) async {
    List<dynamic> data = await apiServiceAdapter.fetchNearbyFriendsHttp(userId);

    List<Friend> fetchedFriends =
        data.map((json) => Friend.fromJson(json)).toList();

    if (userPosition != null) {
      for (var friend in fetchedFriends) {
        friend.distance = Geolocator.distanceBetween(
              userPosition.latitude,
              userPosition.longitude,
              friend.latitude,
              friend.longitude,
            );
      }

      fetchedFriends.sort((a, b) => a.distance.compareTo(b.distance));
    }

    setState(() {
      friends = fetchedFriends;
      isLoading = false;
    });
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
          onPressed: () => Navigator.pop(context),
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
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: 'Refresh',
            onPressed: _initialize,
          ),
          AddFriendPopup(userId: userId),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : Column(
                  children: [
                    if (locationPermissionDenied)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          'Location permission denied. Showing friends without distance.',
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Expanded(child: FriendList(friends: friends)),
                  ],
                ),
    );
  }
}
