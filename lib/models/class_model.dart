class ClassModel {
  final String id;
  final String name;
  final String professor;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int color;
  final String location;

  ClassModel({
    required this.id,
    required this.name,
    required this.professor,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'professor': professor,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'color': color,
      'location': location,
    };
  }

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      name: json['name'] as String,
      professor: json['professor'] as String,
      dayOfWeek: json['dayOfWeek'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      color: json['color'] as int,
      location: json['location'] as String,
    );
  }
}
