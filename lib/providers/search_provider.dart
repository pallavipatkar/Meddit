import 'package:flutter/foundation.dart';
import '../models/community.dart';
import '../models/post.dart';
import 'community_provider.dart';
import 'post_provider.dart';

enum SearchTab { posts, communities }

/// Coordinates search query state, active tab, and recent search terms while
/// delegating matching to existing PostProvider and CommunityProvider data.
class SearchProvider extends ChangeNotifier {
  String _query = '';
  SearchTab _activeTab = SearchTab.posts;
  final List<String> _recentQueries = [];

  String get query => _query;
  String get trimmedQuery => _query.trim();
  bool get hasQuery => trimmedQuery.isNotEmpty;
  SearchTab get activeTab => _activeTab;
  List<String> get recentQueries => List.unmodifiable(_recentQueries);

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void clearQuery() {
    if (_query.isEmpty) return;
    _query = '';
    notifyListeners();
  }

  void setTab(SearchTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
  }

  void recordRecentQuery(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return;

    _recentQueries.removeWhere(
      (q) => q.toLowerCase() == normalized.toLowerCase(),
    );
    _recentQueries.insert(0, normalized);
    if (_recentQueries.length > 6) {
      _recentQueries.removeLast();
    }
    notifyListeners();
  }

  void removeRecentQuery(String value) {
    _recentQueries.remove(value);
    notifyListeners();
  }

  void clearRecentQueries() {
    if (_recentQueries.isEmpty) return;
    _recentQueries.clear();
    notifyListeners();
  }

  List<Post> findMatchingPosts(PostProvider postProvider) {
    if (!hasQuery) return const [];
    return postProvider.searchPosts(trimmedQuery);
  }

  List<Community> findMatchingCommunities(CommunityProvider communityProvider) {
    if (!hasQuery) return const [];
    return communityProvider.searchCommunities(trimmedQuery);
  }
}
