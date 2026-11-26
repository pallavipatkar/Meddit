enum PostTag { doubt, discussion, notes, placement, event }

class Post {
  final String id;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final String authorBranch;
  final String authorYear;
  final String communityId;
  final String communityName;
  final String communityHandle;
  final PostTag tag;
  final int upvotes;
  final int downvotes;
  final int commentCount;
  final DateTime createdAt;
  final bool isSaved;
  final bool isEdited;

  const Post({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.authorBranch,
    required this.authorYear,
    required this.communityId,
    required this.communityName,
    required this.communityHandle,
    required this.tag,
    required this.upvotes,
    required this.downvotes,
    required this.commentCount,
    required this.createdAt,
    this.isSaved = false,
    this.isEdited = false,
  });

  int get baseScore => upvotes - downvotes;

  String get tagLabel {
    switch (tag) {
      case PostTag.doubt:
        return 'Doubt';
      case PostTag.discussion:
        return 'Discussion';
      case PostTag.notes:
        return 'Notes';
      case PostTag.placement:
        return 'Placement';
      case PostTag.event:
        return 'Event';
    }
  }

  Post copyWith({
    String? title,
    String? description,
    String? communityId,
    String? communityName,
    String? communityHandle,
    PostTag? tag,
    int? upvotes,
    int? downvotes,
    int? commentCount,
    bool? isSaved,
    bool? isEdited,
  }) {
    return Post(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      authorId: authorId,
      authorName: authorName,
      authorBranch: authorBranch,
      authorYear: authorYear,
      communityId: communityId ?? this.communityId,
      communityName: communityName ?? this.communityName,
      communityHandle: communityHandle ?? this.communityHandle,
      tag: tag ?? this.tag,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt,
      isSaved: isSaved ?? this.isSaved,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}
