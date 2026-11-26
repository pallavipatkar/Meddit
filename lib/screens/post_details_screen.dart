import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_routes.dart';
import '../models/comment.dart';
import '../providers/post_provider.dart';
import '../providers/user_provider.dart';
import '../providers/vote_provider.dart';
import '../utils/post_actions_helper.dart';
import '../utils/time_formatter.dart';
import '../widgets/comment_tile.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/vote_control.dart';

class PostDetailsScreen extends StatefulWidget {
  final String postId;

  const PostDetailsScreen({super.key, required this.postId});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final _commentController = TextEditingController();
  String? _commentError;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _commentError = 'Please enter a comment before posting.';
      });
      return;
    }

    final user = context.read<UserProvider>().currentUser;
    final addedComment = context.read<PostProvider>().addComment(
          postId: widget.postId,
          content: text,
          author: user,
        );
    if (addedComment == null) return;

    context
        .read<VoteProvider>()
        .toggleCommentUpvote(addedComment.id, user.id);
    context.read<UserProvider>().incrementKarma(2);
    _commentController.clear();
    setState(() {
      _commentError = null;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _showEditCommentDialog(Comment comment) async {
    final controller = TextEditingController(text: comment.content);
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Comment'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              minLines: 2,
              maxLines: 5,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Update your comment...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Comment cannot be empty.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved == true && mounted) {
      context.read<PostProvider>().updateComment(
            commentId: comment.id,
            content: controller.text,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    controller.dispose();
  }

  Future<void> _confirmDeleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Comment?'),
          content: const Text('Are you sure you want to delete your comment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    context.read<PostProvider>().deleteComment(comment.id);
    context.read<VoteProvider>().removeCommentVotes(comment.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    final voteProvider = context.watch<VoteProvider>();
    final currentUser = context.watch<UserProvider>().currentUser;
    final post = postProvider.getPostById(widget.postId);
    final theme = Theme.of(context);

    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: const EmptyStateView(
          icon: Icons.article_outlined,
          title: 'Post unavailable',
          subtitle: 'This post could not be found.',
        ),
      );
    }

    final comments = postProvider.commentsForPost(
      post.id,
      scoreOf: voteProvider.getCommentScore,
    );
    final isOwnPost = post.authorId == currentUser.id;
    final editedSuffix = post.isEdited ? ' · edited' : '';

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.communityDetails,
            arguments: post.communityId,
          ),
          child: Text(post.communityHandle),
        ),
        actions: [
          IconButton(
            onPressed: () => postProvider.toggleSave(post.id),
            tooltip: post.isSaved ? 'Remove bookmark' : 'Save post',
            icon: Icon(
              post.isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Link copied for "${post.title}"'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined),
          ),
          if (isOwnPost)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  PostActionsHelper.openEditPost(context, post);
                } else if (value == 'delete') {
                  PostActionsHelper.confirmDeletePost(
                    context,
                    post,
                    popAfterDelete: true,
                  );
                }
              },
              itemBuilder: (context) => [
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
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                // Full Post Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Text(
                                post.authorName.isNotEmpty
                                    ? post.authorName[0].toUpperCase()
                                    : 'M',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.authorName,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${post.authorBranch} · ${post.authorYear} · ${TimeFormatter.timeAgo(post.createdAt)}$editedSuffix',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                post.tagLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          post.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.28,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          post.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.55,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            VoteControl(
                              score: voteProvider.getPostScore(post),
                              userVote: voteProvider.getPostUserVote(
                                post.id,
                                currentUser.id,
                              ),
                              onUpvote: () => voteProvider.togglePostUpvote(
                                post.id,
                                currentUser.id,
                              ),
                              onDownvote: () => voteProvider.togglePostDownvote(
                                post.id,
                                currentUser.id,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${comments.length} ${comments.length == 1 ? 'comment' : 'comments'}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Comments Header
                Text(
                  'Comments & Answers (${comments.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),

                if (comments.isEmpty)
                  const EmptyStateView(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No comments yet',
                    subtitle: 'Share your insight or help clear this doubt below.',
                  )
                else
                  ...comments.map((comment) {
                    final isOwnComment = comment.authorId == currentUser.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CommentTile(
                        comment: comment,
                        score: voteProvider.getCommentScore(comment),
                        userVote: voteProvider.getCommentUserVote(
                          comment.id,
                          currentUser.id,
                        ),
                        isOwnComment: isOwnComment,
                        onUpvote: () => voteProvider.toggleCommentUpvote(
                          comment.id,
                          currentUser.id,
                        ),
                        onDownvote: () => voteProvider.toggleCommentDownvote(
                          comment.id,
                          currentUser.id,
                        ),
                        onEdit: isOwnComment
                            ? () => _showEditCommentDialog(comment)
                            : null,
                        onDelete: isOwnComment
                            ? () => _confirmDeleteComment(comment)
                            : null,
                      ),
                    );
                  }),
              ],
            ),
          ),

          // Add Comment Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outline),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      minLines: 1,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) {
                        if (_commentError != null) {
                          setState(() => _commentError = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Write a helpful answer or comment...',
                        errorText: _commentError,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submitComment,
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                      minimumSize: const Size(44, 44),
                    ),
                    child: const Icon(Icons.send_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
