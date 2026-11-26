import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_routes.dart';
import '../models/post.dart';
import '../providers/navigation_provider.dart';
import '../providers/post_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../providers/vote_provider.dart';
import '../utils/post_actions_helper.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/meddit_logo.dart';
import '../widgets/post_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showCampusNotices(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MITS Campus Highlights',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const _NoticeTile(
                icon: Icons.library_books_outlined,
                title: 'Central Library Extended Hours',
                subtitle: 'Open until 10:30 PM for Mid-Sem & End-Sem prep.',
              ),
              const SizedBox(height: 10),
              const _NoticeTile(
                icon: Icons.event_available_outlined,
                title: 'GDG & Coding Club Flutter Jam',
                subtitle: 'Saturday 11:00 AM · Silver Jubilee Hall',
              ),
              const SizedBox(height: 10),
              const _NoticeTile(
                icon: Icons.work_outline_rounded,
                title: 'T&P Resume Review Thread Live',
                subtitle: 'Check m/placements for senior feedback.',
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    final voteProvider = context.watch<VoteProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final currentUserId = context.watch<UserProvider>().currentUser.id;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final posts = postProvider.sortedFeedPosts(voteProvider.getPostScore);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const MedditLogo(size: 34, showText: false),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meddit',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'MITS Gwalior Feed',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => themeProvider.toggleTheme(context),
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            onPressed: () => _showCampusNotices(context),
            tooltip: 'Campus highlights',
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Sort & Tag Filter Strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outline),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SortChip(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Hot',
                    selected: postProvider.sortMode == FeedSort.hot,
                    onTap: () => postProvider.setSortMode(FeedSort.hot),
                  ),
                  const SizedBox(width: 8),
                  _SortChip(
                    icon: Icons.schedule_rounded,
                    label: 'Latest',
                    selected: postProvider.sortMode == FeedSort.latest,
                    onTap: () => postProvider.setSortMode(FeedSort.latest),
                  ),
                  Container(
                    height: 22,
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: theme.colorScheme.outline,
                  ),
                  ...PostTag.values.map((tag) {
                    final selected = postProvider.selectedTag == tag;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_tagTitle(tag)),
                        selected: selected,
                        onSelected: (_) => postProvider.setTagFilter(tag),
                        labelStyle: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                        showCheckmark: false,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Feed List
          Expanded(
            child: posts.isEmpty
                ? EmptyStateView(
                    icon: Icons.forum_outlined,
                    title: 'No posts match this filter',
                    subtitle:
                        'Try clearing the tag filter or start a new campus discussion.',
                    actionLabel: 'Create Post',
                    onAction: () =>
                        context.read<NavigationProvider>().openCreatePost(),
                  )
                : RefreshIndicator(
                    onRefresh: postProvider.refreshFeed,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      itemCount: posts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final isOwnPost = post.authorId == currentUserId;
                        return PostCard(
                          post: post,
                          score: voteProvider.getPostScore(post),
                          userVote:
                              voteProvider.getPostUserVote(post.id, currentUserId),
                          isOwnPost: isOwnPost,
                          onTap: () => Navigator.of(context).pushNamed(
                            AppRoutes.postDetails,
                            arguments: post.id,
                          ),
                          onCommunityTap: () => Navigator.of(context).pushNamed(
                            AppRoutes.communityDetails,
                            arguments: post.communityId,
                          ),
                          onUpvote: () => voteProvider.togglePostUpvote(
                            post.id,
                            currentUserId,
                          ),
                          onDownvote: () => voteProvider.togglePostDownvote(
                            post.id,
                            currentUserId,
                          ),
                          onSave: () => postProvider.toggleSave(post.id),
                          onEdit: isOwnPost
                              ? () =>
                                  PostActionsHelper.openEditPost(context, post)
                              : null,
                          onDelete: isOwnPost
                              ? () => PostActionsHelper.confirmDeletePost(
                                  context, post)
                              : null,
                          onShare: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Link copied for "${post.title}"',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _tagTitle(PostTag tag) {
    switch (tag) {
      case PostTag.doubt:
        return 'Doubts';
      case PostTag.discussion:
        return 'Discussions';
      case PostTag.notes:
        return 'Notes';
      case PostTag.placement:
        return 'Placements';
      case PostTag.event:
        return 'Events';
    }
  }
}

class _SortChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _NoticeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
