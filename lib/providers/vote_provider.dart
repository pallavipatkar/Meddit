import 'package:flutter/foundation.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../models/vote.dart';
import '../services/mock_campus_service.dart';

/// Manages post and comment votes separately from content models.
/// Stores at most one vote per (target, userId) pair so scores are always
/// computed dynamically and can later be backed by Firestore vote documents.
class VoteProvider extends ChangeNotifier {
  final MockCampusService _service;

  /// Map of `<targetType>:<targetId>` -> `{ userId: 1 | -1 }`
  final Map<String, Map<String, int>> _votesByTarget = {};

  VoteProvider({MockCampusService? service})
      : _service = service ?? MockCampusService() {
    for (final record in _service.fetchVotes()) {
      final targetMap =
          _votesByTarget.putIfAbsent(record.targetKey, () => {});
      targetMap[record.userId] = record.value;
    }
  }

  int getPostUserVote(String postId, String userId) {
    final key = VoteRecord.buildTargetKey(VoteTargetType.post, postId);
    return _votesByTarget[key]?[userId] ?? 0;
  }

  int getCommentUserVote(String commentId, String userId) {
    final key = VoteRecord.buildTargetKey(VoteTargetType.comment, commentId);
    return _votesByTarget[key]?[userId] ?? 0;
  }

  int getPostScore(Post post) {
    final key = VoteRecord.buildTargetKey(VoteTargetType.post, post.id);
    return post.baseScore + _sumVotes(key);
  }

  int getCommentScore(Comment comment) {
    final key = VoteRecord.buildTargetKey(VoteTargetType.comment, comment.id);
    return comment.baseScore + _sumVotes(key);
  }

  void togglePostUpvote(String postId, String userId) {
    final key = VoteRecord.buildTargetKey(VoteTargetType.post, postId);
    _toggleVote(key, userId, 1);
  }

  void togglePostDownvote(String postId, String userId) {
    final key = VoteRecord.buildTargetKey(VoteTargetType.post, postId);
    _toggleVote(key, userId, -1);
  }

  void toggleCommentUpvote(String commentId, String userId) {
    final key = VoteRecord.buildTargetKey(VoteTargetType.comment, commentId);
    _toggleVote(key, userId, 1);
  }

  void toggleCommentDownvote(String commentId, String userId) {
    final key = VoteRecord.buildTargetKey(VoteTargetType.comment, commentId);
    _toggleVote(key, userId, -1);
  }

  void removePostVotes(String postId) {
    final key = VoteRecord.buildTargetKey(VoteTargetType.post, postId);
    if (_votesByTarget.remove(key) != null) {
      notifyListeners();
    }
  }

  void removeCommentVotes(String commentId) {
    final key = VoteRecord.buildTargetKey(VoteTargetType.comment, commentId);
    if (_votesByTarget.remove(key) != null) {
      notifyListeners();
    }
  }

  void _toggleVote(String targetKey, String userId, int direction) {
    if (userId.isEmpty) return;
    final targetMap = _votesByTarget.putIfAbsent(targetKey, () => {});
    final current = targetMap[userId] ?? 0;

    if (current == direction) {
      // Tapping the same vote removes it.
      targetMap.remove(userId);
    } else {
      // Cast new vote or switch direction (-1 <-> 1).
      targetMap[userId] = direction;
    }
    notifyListeners();
  }

  int _sumVotes(String targetKey) {
    final targetMap = _votesByTarget[targetKey];
    if (targetMap == null || targetMap.isEmpty) return 0;
    var sum = 0;
    for (final v in targetMap.values) {
      sum += v;
    }
    return sum;
  }
}
