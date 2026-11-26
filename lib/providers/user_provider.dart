import 'package:flutter/foundation.dart';
import '../models/student_user.dart';
import '../services/mock_campus_service.dart';

class UserProvider extends ChangeNotifier {
  final MockCampusService _service;
  late StudentUser _currentUser;

  UserProvider({MockCampusService? service})
      : _service = service ?? MockCampusService() {
    _currentUser = _service.getCurrentStudent();
  }

  StudentUser get currentUser => _currentUser;

  bool updateProfile({
    required String name,
    required String username,
    required String branch,
    required String academicYear,
    required String bio,
  }) {
    final cleanName = name.trim();
    final cleanUsername = username.trim().replaceFirst(RegExp(r'^@+'), '');
    if (cleanName.isEmpty || cleanUsername.isEmpty) return false;

    _currentUser = _currentUser.copyWith(
      name: cleanName,
      username: cleanUsername,
      branch: branch,
      academicYear: academicYear,
      bio: bio.trim(),
    );
    notifyListeners();
    return true;
  }

  void incrementKarma(int delta) {
    _currentUser = _currentUser.copyWith(
      karmaPoints: _currentUser.karmaPoints + delta,
    );
    notifyListeners();
  }
}
