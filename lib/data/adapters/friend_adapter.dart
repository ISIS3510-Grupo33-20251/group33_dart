import 'package:hive/hive.dart';
import '../../domain/models/friend.dart';

class FriendAdapter extends TypeAdapter<Friend> {
  @override
  final int typeId = 3; // Unique ID for this adapter

  @override
  Friend read(BinaryReader reader) {
    return Friend(
      id: reader.readString(),
      name: reader.readString(),
      email: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Friend obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.email);
  }
}
