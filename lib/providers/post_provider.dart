import 'package:flutter/foundation.dart';
import '../models/comment.dart';
import '../models/community.dart';
import '../models/post.dart';
import '../models/student_user.dart';
import '../services/mock_campus_service.dart';

enum FeedSort { hot, latest }

class PostProvider extends ChangeNotifier {
  final MockCampusService _service;
  late List<Post> _posts;
  late List<Comment> _comments;

  FeedSort _sortMode = FeedSort.hot;
  PostTag? _selectedTag;

  PostProvider({MockCampusService? service})
      : _service = service ?? MockCampusService() {
    _posts = _service.fetchPosts();
    _comments = _service.fetchComments();
  }

  FeedSort get sortMode => _sortMode;
  PostTag? get selectedTag => _selectedTag;

  List<Post> get feedPosts => sortedFeedPosts((p) => p.baseScore);

  List<Post> sortedFeedPosts(int Function(Post post) scoreOf) {
    var list = List<Post>.from(_posts);
    if (_selectedTag != null) {
      list = list.where((p) => p.tag == _selectedTag).toList();
    }
    if (_sortMode == FeedSort.hot) {
      list.sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  List<Post> postsForCommunity(String communityId) {
    final list = _posts.where((p) => p.communityId == communityId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Post> postsByAuthor(String authorId) {
    final list = _posts.where((p) => p.authorId == authorId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Comment> commentsByAuthor(String authorId) {
    final list = _comments.where((c) => c.authorId == authorId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Post> get savedPosts => _posts.where((p) => p.isSaved).toList();

  Post? getPostById(String postId) {
    for (final p in _posts) {
      if (p.id == postId) return p;
    }
    return null;
  }

  List<Comment> commentsForPost(
    String postId, {
    int Function(Comment comment)? scoreOf,
  }) {
    final list = _comments.where((c) => c.postId == postId).toList();
    final resolveScore = scoreOf ?? (Comment c) => c.baseScore;
    list.sort((a, b) {
      if (a.isVerifiedAnswer != b.isVerifiedAnswer) {
        return a.isVerifiedAnswer ? -1 : 1;
      }
      return resolveScore(b).compareTo(resolveScore(a));
    });
    return list;
  }

  void setSortMode(FeedSort mode) {
    if (_sortMode == mode) return;
    _sortMode = mode;
    notifyListeners();
  }

  void setTagFilter(PostTag? tag) {
    if (_selectedTag == tag) {
      _selectedTag = null;
    } else {
      _selectedTag = tag;
    }
    notifyListeners();
  }

  void toggleSave(String postId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = _posts[idx];
    _posts[idx] = post.copyWith(isSaved: !post.isSaved);
    notifyListeners();
  }

  Post createPost({
    required String title,
    required String description,
    required Community community,
    required StudentUser author,
    required PostTag tag,
  }) {
    final newPost = Post(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      description: description.trim(),
      authorId: author.id,
      authorName: author.name,
      authorBranch: author.branch,
      authorYear: author.academicYear,
      communityId: community.id,
      communityName: community.name,
      communityHandle: community.handle,
      tag: tag,
      upvotes: 0,
      downvotes: 0,
      commentCount: 0,
      createdAt: DateTime.now(),
    );
    _posts.insert(0, newPost);
    notifyListeners();
    return newPost;
  }

  bool updatePost({
    required String postId,
    required String title,
    required String description,
    required Community community,
    required PostTag tag,
  }) {
    final trimmedTitle = title.trim();
    final trimmedDescription = description.trim();
    if (trimmedTitle.isEmpty || trimmedDescription.isEmpty) return false;

    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return false;

    _posts[idx] = _posts[idx].copyWith(
      title: trimmedTitle,
      description: trimmedDescription,
      communityId: community.id,
      communityName: community.name,
      communityHandle: community.handle,
      tag: tag,
      isEdited: true,
    );
    notifyListeners();
    return true;
  }

  void deletePost(String postId) {
    final initialLength = _posts.length;
    _posts.removeWhere((p) => p.id == postId);
    if (_posts.length == initialLength) return;

    _comments.removeWhere((c) => c.postId == postId);
    notifyListeners();
  }

  Comment? addComment({
    required String postId,
    required String content,
    required StudentUser author,
  }) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return null;

    final comment = Comment(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      authorId: author.id,
      authorName: author.name,
      authorBranch: author.branch,
      authorYear: author.academicYear,
      content: trimmed,
      createdAt: DateTime.now(),
      upvotes: 0,
    );
    _comments.insert(0, comment);

    final postIdx = _posts.indexWhere((p) => p.id == postId);
    if (postIdx != -1) {
      _posts[postIdx] = _posts[postIdx].copyWith(
        commentCount: _posts[postIdx].commentCount + 1,
      );
    }
    notifyListeners();
    return comment;
  }

  bool updateComment({
    required String commentId,
    required String content,
  }) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;

    final idx = _comments.indexWhere((c) => c.id == commentId);
    if (idx == -1) return false;

    _comments[idx] = _comments[idx].copyWith(
      content: trimmed,
      isEdited: true,
    );
    notifyListeners();
    return true;
  }

  void deleteComment(String commentId) {
    final idx = _comments.indexWhere((c) => c.id == commentId);
    if (idx == -1) return;

    final postId = _comments[idx].postId;
    _comments.removeAt(idx);

    final postIdx = _posts.indexWhere((p) => p.id == postId);
    if (postIdx != -1) {
      final currentCount = _posts[postIdx].commentCount;
      _posts[postIdx] = _posts[postIdx].copyWith(
        commentCount: currentCount > 0 ? currentCount - 1 : 0,
      );
    }
    notifyListeners();
  }

  List<Post> searchPosts(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final normalized = (q.startsWith('#') ? q.substring(1) : q).trim();
    if (normalized.isEmpty) return [];
    return _posts.where((p) {
      return p.title.toLowerCase().contains(normalized) ||
          p.description.toLowerCase().contains(normalized) ||
          p.communityName.toLowerCase().contains(normalized) ||
          p.communityHandle.toLowerCase().contains(normalized) ||
          p.tagLabel.toLowerCase().contains(normalized) ||
          p.authorBranch.toLowerCase().contains(normalized) ||
          p.authorName.toLowerCase().contains(normalized);
    }).toList();
  }

  Future<void> refreshFeed() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    notifyListeners();
  }
}
