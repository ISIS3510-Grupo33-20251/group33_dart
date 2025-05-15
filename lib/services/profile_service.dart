import 'package:flutter/material.dart';
import '../domain/models/student_profile.dart';

class ProfileService extends ChangeNotifier {
  StudentProfile _profile = StudentProfile.empty();

  StudentProfile get profile => _profile;

  void updateProfile({String? name, String? imageUrl, int? semester}) {
    _profile = StudentProfile(
      name: name ?? _profile.name,
      imageUrl: imageUrl ?? _profile.imageUrl,
      semester: semester ?? _profile.semester,
    );
    notifyListeners();
  }

  void updateSemester(int semester) {
    _profile = StudentProfile(
      name: _profile.name,
      imageUrl: _profile.imageUrl,
      semester: semester,
    );
    notifyListeners();
  }
}
