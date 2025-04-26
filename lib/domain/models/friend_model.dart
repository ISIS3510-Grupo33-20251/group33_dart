import 'package:hive/hive.dart';

part 'friend_model.g.dart';

@HiveType(typeId: 3)
class FriendModel {
  @HiveField(0)
  final String email;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? scheduleId;

  FriendModel({
    required this.email,
    required this.name,
    this.scheduleId,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'scheduleId': scheduleId,
    };
  }

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      email: json['email'] as String,
      name: json['name'] as String,
      scheduleId: json['scheduleId'] as String?,
    );
  }
}
