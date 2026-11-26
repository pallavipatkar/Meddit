import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';
import '../providers/vote_provider.dart';
import '../screens/create_post_screen.dart';

class PostActionsHelper {
  PostActionsHelper._();

  static void openEditPost(BuildContext context, Post post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreatePostScreen(editingPost: post),
      ),
    );
  }

  static Future<void> confirmDeletePost(
    BuildContext context,
    Post post, {
    bool popAfterDelete = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Post?'),
          content: Text(
            'Are you sure you want to delete "${post.title}"? This will also remove all comments on this post.',
          ),
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

    if (confirmed != true || !context.mounted) return;

    context.read<PostProvider>().deletePost(post.id);
    context.read<VoteProvider>().removePostVotes(post.id);
    if (popAfterDelete) {
      Navigator.of(context).pop();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
