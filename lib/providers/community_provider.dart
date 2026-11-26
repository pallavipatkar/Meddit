import 'package:flutter/foundation.dart';
import '../models/community.dart';
import '../services/mock_campus_service.dart';

enum CommunityFilter { all, joined, branches, clubs, campus }

class CommunityProvider extends ChangeNotifier {
  final MockCampusService _service;
  late List<Community> _communities;
  CommunityFilter _activeFilter = CommunityFilter.all;
  String _browseQuery = '';
  String _userBranch = '';

  CommunityProvider({MockCampusService? service})
      : _service = service ?? MockCampusService() {
    _communities = _service.fetchCommunities();
  }

  List<Community> get allCommunities => List.unmodifiable(_communities);

  List<Community> get joinedCommunities =>
      _communities.where((c) => c.isJoined).toList();

  CommunityFilter get activeFilter => _activeFilter;
  String get browseQuery => _browseQuery;
  String get userBranch => _userBranch;

  /// Resolves the community corresponding to a student's branch (e.g. CSE -> m/cse).
  Community? communityForBranch(String branch) {
    final normalized = _normalizeBranch(branch);
    if (normalized.isEmpty) return null;

    for (final community in _communities) {
      if (community.category != CommunityCategory.branch) continue;
      final key = _normalizeBranch(community.branchKey ?? '');
      if (key == normalized ||
          _normalizeBranch(community.name).contains(normalized)) {
        return community;
      }
    }
    return null;
  }

  Community? get userBranchCommunity => communityForBranch(_userBranch);

  bool isUserBranchCommunity(Community community) {
    final branchComm = userBranchCommunity;
    return branchComm != null && branchComm.id == community.id;
  }

  /// Syncs the current mock student's branch and automatically ensures
  /// their branch community is joined when the branch changes.
  void syncUserBranch(
    String branch, {
    bool autoJoinBranch = true,
    bool notify = true,
  }) {
    final normalized = _normalizeBranch(branch);
    if (_normalizeBranch(_userBranch) == normalized) return;

    _userBranch = branch;
    if (autoJoinBranch) {
      final branchComm = communityForBranch(branch);
      if (branchComm != null && !branchComm.isJoined) {
        final idx = _communities.indexWhere((c) => c.id == branchComm.id);
        if (idx != -1) {
          _communities[idx] = branchComm.copyWith(
            isJoined: true,
            memberCount: branchComm.memberCount + 1,
          );
        }
      }
    }
    if (notify) {
      notifyListeners();
    }
  }

  List<Community> get filteredCommunities {
    Iterable<Community> base;
    switch (_activeFilter) {
      case CommunityFilter.all:
        base = _communities;
        break;
      case CommunityFilter.joined:
        base = _communities.where((c) => c.isJoined);
        break;
      case CommunityFilter.branches:
        base = _communities.where((c) => c.category == CommunityCategory.branch);
        break;
      case CommunityFilter.clubs:
        base = _communities.where((c) => c.category == CommunityCategory.club);
        break;
      case CommunityFilter.campus:
        base = _communities.where((c) => c.category == CommunityCategory.campus);
        break;
    }

    final q = _browseQuery.trim().toLowerCase();
    if (q.isEmpty) return base.toList();

    return base.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.handle.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          c.categoryLabel.toLowerCase().contains(q);
    }).toList();
  }

  void setFilter(CommunityFilter filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    notifyListeners();
  }

  void setBrowseQuery(String query) {
    if (_browseQuery == query) return;
    _browseQuery = query;
    notifyListeners();
  }

  Community? getById(String id) {
    for (final c in _communities) {
      if (c.id == id) return c;
    }
    return null;
  }

  void joinCommunity(String communityId) {
    final idx = _communities.indexWhere((c) => c.id == communityId);
    if (idx == -1 || _communities[idx].isJoined) return;
    final current = _communities[idx];
    _communities[idx] = current.copyWith(
      isJoined: true,
      memberCount: current.memberCount + 1,
    );
    notifyListeners();
  }

  void leaveCommunity(String communityId) {
    final idx = _communities.indexWhere((c) => c.id == communityId);
    if (idx == -1 || !_communities[idx].isJoined) return;
    final current = _communities[idx];
    _communities[idx] = current.copyWith(
      isJoined: false,
      memberCount: current.memberCount > 0 ? current.memberCount - 1 : 0,
    );
    notifyListeners();
  }

  void toggleJoin(String communityId) {
    final idx = _communities.indexWhere((c) => c.id == communityId);
    if (idx == -1) return;
    if (_communities[idx].isJoined) {
      leaveCommunity(communityId);
    } else {
      joinCommunity(communityId);
    }
  }

  List<Community> searchCommunities(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return _communities.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.handle.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          c.categoryLabel.toLowerCase().contains(q);
    }).toList();
  }

  String _normalizeBranch(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s&/]+'), '');
  }
}
