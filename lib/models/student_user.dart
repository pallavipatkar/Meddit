class StudentUser {
  final String id;
  final String name;
  final String username;
  final String email;
  final String branch;
  final String academicYear;
  final String enrollmentNumber;
  final String bio;
  final int karmaPoints;

  const StudentUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.branch,
    required this.academicYear,
    required this.enrollmentNumber,
    required this.bio,
    this.karmaPoints = 0,
  });

  String get formattedUsername =>
      username.startsWith('@') ? username : '@$username';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'M';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  StudentUser copyWith({
    String? name,
    String? username,
    String? email,
    String? branch,
    String? academicYear,
    String? enrollmentNumber,
    String? bio,
    int? karmaPoints,
  }) {
    return StudentUser(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      branch: branch ?? this.branch,
      academicYear: academicYear ?? this.academicYear,
      enrollmentNumber: enrollmentNumber ?? this.enrollmentNumber,
      bio: bio ?? this.bio,
      karmaPoints: karmaPoints ?? this.karmaPoints,
    );
  }
}
