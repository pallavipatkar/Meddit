enum VoteTargetType { post, comment }

class VoteRecord {
  final String targetId;
  final VoteTargetType targetType;
  final String userId;
  final int value; // 1 for upvote, -1 for downvote

  const VoteRecord({
    required this.targetId,
    required this.targetType,
    required this.userId,
    required this.value,
  }) : assert(value == 1 || value == -1);

  String get targetKey => buildTargetKey(targetType, targetId);

  static String buildTargetKey(VoteTargetType type, String id) =>
      '${type.name}:$id';
}
