class Friend {
  final String name;
  final double latitude;
  final double longitude;
  double distance;

  Friend({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.distance = 0.0,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    final location = json['location'] ?? {};
    return Friend(
      name: json['name'] ?? '',
      latitude: (location['latitude'] ?? 0.0).toDouble(),
      longitude: (location['longitude'] ?? 0.0).toDouble(),
    );
  }
}
