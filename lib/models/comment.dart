class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorBranch;
  final String authorYear;
  final String content;
  final DateTime createdAt;
  final int upvotes;
  final int downvotes;
  final bool isVerifiedAnswer;
  final bool isEdited;

  const Comment({
    required this.id,
    required this.postId,
    this.authorId = '',
    required this.authorName,
    required this.authorBranch,
    required this.authorYear,
    required this.content,
    required this.createdAt,
    required this.upvotes,
    this.downvotes = 0,
    this.isVerifiedAnswer = false,
    this.isEdited = false,
  });

  int get baseScore => upvotes - downvotes;

  Comment copyWith({
    String? content,
    int? upvotes,
    int? downvotes,
    bool? isVerifiedAnswer,
    bool? isEdited,
  }) {
    return Comment(
      id: id,
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorBranch: authorBranch,
      authorYear: authorYear,
      content: content ?? this.content,
      createdAt: createdAt,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      isVerifiedAnswer: isVerifiedAnswer ?? this.isVerifiedAnswer,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}
