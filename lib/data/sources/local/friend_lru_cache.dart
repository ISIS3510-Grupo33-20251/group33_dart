import 'dart:collection';
import 'package:group33_dart/presentation/widgets/friends/friend.dart';

class FriendLRUCache {
  final int capacity;
  final LinkedHashMap<String, Friend> _cache = LinkedHashMap();

  FriendLRUCache({this.capacity = 10});

  void put(String email, Friend friend) {
    if (_cache.containsKey(email)) {
      _cache.remove(email);
    } else if (_cache.length >= capacity) {
      _cache.remove(_cache.keys.first);
    }
    _cache[email] = friend;
  }

  Friend? get(String email) {
    if (!_cache.containsKey(email)) return null;
    final friend = _cache.remove(email)!;
    _cache[email] = friend;
    return friend;
  }

  List<Friend> getAll() => _cache.values.toList();

  Map<String, Friend> get cacheMap => _cache;
}
