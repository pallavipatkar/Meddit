import 'package:flutter/foundation.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  String? _preselectedCommunityId;

  int get currentIndex => _currentIndex;
  String? get preselectedCommunityId => _preselectedCommunityId;

  void setIndex(int index) {
    if (index < 0 || index > 4) return;
    _currentIndex = index;
    notifyListeners();
  }

  void openCreatePost({String? communityId}) {
    _preselectedCommunityId = communityId;
    _currentIndex = 2;
    notifyListeners();
  }

  void clearPreselectedCommunity() {
    _preselectedCommunityId = null;
  }
}
