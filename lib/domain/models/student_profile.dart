class StudentProfile {
  String name;
  String imageUrl;
  int semester;

  StudentProfile({
    required this.name,
    required this.imageUrl,
    required this.semester,
  });

  factory StudentProfile.empty() => StudentProfile(
        name: 'Your Name',
        imageUrl: 'https://i.pravatar.cc/300',
        semester: 1,
      );
}
