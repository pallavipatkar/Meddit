import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/post.dart';
import '../utils/time_formatter.dart';
import 'vote_control.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final int score;
  final int userVote;
  final VoidCallback onTap;
  final VoidCallback onCommunityTap;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;
  final VoidCallback onSave;
  final VoidCallback? onShare;
  final bool isOwnPost;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showFullDescription;

  const PostCard({
    super.key,
    required this.post,
    required this.score,
    required this.userVote,
    required this.onTap,
    required this.onCommunityTap,
    required this.onUpvote,
    required this.onDownvote,
    required this.onSave,
    this.onShare,
    this.isOwnPost = false,
    this.onEdit,
    this.onDelete,
    this.showFullDescription = false,
  });

  Color _tagColor(PostTag tag, bool isDark) {
    switch (tag) {
      case PostTag.doubt:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFD97706);
      case PostTag.notes:
        return isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
      case PostTag.placement:
        return isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);
      case PostTag.event:
        return isDark ? const Color(0xFFF472B6) : const Color(0xFFBE185D);
      case PostTag.discussion:
        return isDark ? AppColors.darkPrimaryAccent : AppColors.primaryNavy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tagColor = _tagColor(post.tag, isDark);
    final editedSuffix = post.isEdited ? ' · edited' : '';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Community + Author + Tag + Owner Menu
              Row(
                children: [
                  GestureDetector(
                    onTap: onCommunityTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        post.communityHandle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${post.authorName} · ${post.authorBranch} · ${TimeFormatter.timeAgo(post.createdAt)}$editedSuffix',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      post.tagLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tagColor,
                      ),
                    ),
                  ),
                  if (isOwnPost && (onEdit != null || onDelete != null))
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') onEdit?.call();
                        if (value == 'delete') onDelete?.call();
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit post'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete post',
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                post.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                post.description,
                maxLines: showFullDescription ? null : 3,
                overflow: showFullDescription
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),

              // Actions Row: Votes, Comments, Save, Share
              Row(
                children: [
                  VoteControl(
                    score: score,
                    userVote: userVote,
                    onUpvote: onUpvote,
                    onDownvote: onDownvote,
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post.commentCount}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onSave,
                    tooltip: post.isSaved ? 'Remove bookmark' : 'Save post',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      post.isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 20,
                      color: post.isSaved
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (onShare != null)
                    IconButton(
                      onPressed: onShare,
                      tooltip: 'Share post',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.share_outlined,
                        size: 19,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
