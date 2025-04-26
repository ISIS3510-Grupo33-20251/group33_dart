import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import '../../../domain/models/class_model.dart';
import '../../../domain/models/friend.dart';
import '../../adapters/time_of_day_adapter.dart';
import '../../adapters/color_adapter.dart';
import '../../adapters/friend_adapter.dart' as friend_adapter;

class ScheduleStorage {
  static const String _boxName = 'schedule_box';
  static const String _scheduleIdKey = 'schedule_id';
  static const String _classesKey = 'classes';
  static const String _friendsKey = 'friends';
  static const String _pendingFriendsKey = 'pending_friends';

  late Box _box;

  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TimeOfDayAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ColorAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(friend_adapter.FriendAdapter());
    }

    _box = await Hive.openBox(_boxName);
  }

  // Schedule methods
  Future<void> saveScheduleId(String id) async {
    await _box.put(_scheduleIdKey, id);
  }

  String? getScheduleId() {
    return _box.get(_scheduleIdKey);
  }

  Future<void> saveClasses(List<ClassModel> classes) async {
    await _box.put(_classesKey, classes);
  }

  List<ClassModel> getClasses() {
    return (_box.get(_classesKey) as List?)?.cast<ClassModel>() ?? [];
  }

  Future<void> addClass(ClassModel classModel) async {
    final classes = getClasses();
    classes.add(classModel);
    await saveClasses(classes);
  }

  Future<void> removeClass(String classId) async {
    final classes = getClasses();
    classes.removeWhere((c) => c.id == classId);
    await saveClasses(classes);
  }

  // Friend methods
  Future<void> saveFriends(List<Friend> friends) async {
    await _box.put(_friendsKey, friends);
  }

  List<Friend> getFriends() {
    return (_box.get(_friendsKey) as List?)?.cast<Friend>() ?? [];
  }

  Future<void> addFriend(Friend friend) async {
    final friends = getFriends();
    if (!friends.any((f) => f.email == friend.email)) {
      friends.add(friend);
      await saveFriends(friends);
    }
  }

  Future<void> removeFriend(String email) async {
    final friends = getFriends();
    friends.removeWhere((f) => f.email == email);
    await saveFriends(friends);
  }

  // Pending friend requests
  Future<void> savePendingFriends(List<Friend> pendingFriends) async {
    await _box.put(_pendingFriendsKey, pendingFriends);
  }

  List<Friend> getPendingFriends() {
    return (_box.get(_pendingFriendsKey) as List?)?.cast<Friend>() ?? [];
  }

  Future<void> addPendingFriend(Friend friend) async {
    final pendingFriends = getPendingFriends();
    if (!pendingFriends.any((f) => f.email == friend.email)) {
      pendingFriends.add(friend);
      await savePendingFriends(pendingFriends);
    }
  }

  Future<void> removePendingFriend(String email) async {
    final pendingFriends = getPendingFriends();
    pendingFriends.removeWhere((f) => f.email == email);
    await savePendingFriends(pendingFriends);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
