class _Node<K, V> {
  K key;
  V value;
  _Node<K, V>? prev;
  _Node<K, V>? next;

  _Node(this.key, this.value);
}

class LRUCache<K, V> {
  final int capacity;
  final Map<K, _Node<K, V>> _cache = {};
  _Node<K, V>? _head;
  _Node<K, V>? _tail;

  LRUCache(this.capacity) {
    if (capacity <= 0) {
      throw ArgumentError('Capacity must be positive');
    }
  }

  V? get(K key) {
    final node = _cache[key];
    if (node == null) return null;

    _moveToFront(node);
    return node.value;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      final node = _cache[key]!;
      node.value = value;
      _moveToFront(node);
      return;
    }

    final newNode = _Node(key, value);
    _cache[key] = newNode;
    _addToFront(newNode);

    if (_cache.length > capacity) {
      _removeLRU();
    }
  }

  void _moveToFront(_Node<K, V> node) {
    if (node == _head) return;

    if (node.prev != null) {
      node.prev!.next = node.next;
    }
    if (node.next != null) {
      node.next!.prev = node.prev;
    }
    if (node == _tail) {
      _tail = node.prev;
    }

    node.prev = null;
    node.next = _head;
    if (_head != null) {
      _head!.prev = node;
    }
    _head = node;
    if (_tail == null) {
      _tail = node;
    }
  }

  void _addToFront(_Node<K, V> node) {
    node.next = _head;
    node.prev = null;
    if (_head != null) {
      _head!.prev = node;
    }
    _head = node;
    if (_tail == null) {
      _tail = node;
    }
  }

  void _removeLRU() {
    if (_tail == null) return;

    _cache.remove(_tail!.key);
    if (_tail!.prev != null) {
      _tail!.prev!.next = null;
      _tail = _tail!.prev;
    } else {
      _head = null;
      _tail = null;
    }
  }

  void clear() {
    _cache.clear();
    _head = null;
    _tail = null;
  }

  bool containsKey(K key) => _cache.containsKey(key);
}
