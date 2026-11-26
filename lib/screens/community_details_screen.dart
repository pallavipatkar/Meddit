import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../models/community.dart';
import '../models/post.dart';
import '../providers/community_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/post_provider.dart';
import '../providers/user_provider.dart';
import '../providers/vote_provider.dart';
import '../utils/post_actions_helper.dart';
import '../utils/time_formatter.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/post_card.dart';

class CommunityDetailsScreen extends StatefulWidget {
  final String communityId;

  const CommunityDetailsScreen({super.key, required this.communityId});

  @override
  State<CommunityDetailsScreen> createState() => _CommunityDetailsScreenState();
}

class _CommunityDetailsScreenState extends State<CommunityDetailsScreen> {
  PostTag? _selectedTag;

  void _toggleMembership(CommunityProvider provider, Community community) {
    final wasJoined = community.isJoined;
    provider.toggleJoin(community.id);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasJoined
              ? 'Left ${community.handle}'
              : 'Joined ${community.handle}',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final communityProvider = context.watch<CommunityProvider>();
    final postProvider = context.watch<PostProvider>();
    final community = communityProvider.getById(widget.communityId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (community == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Community')),
        body: const EmptyStateView(
          icon: Icons.groups_outlined,
          title: 'Community not found',
          subtitle: 'This campus community may have been moved or removed.',
        ),
      );
    }

    final isUserBranch = communityProvider.isUserBranchCommunity(community);
    final allCommunityPosts = postProvider.postsForCommunity(community.id);
    final posts = _selectedTag == null
        ? allCommunityPosts
        : allCommunityPosts.where((p) => p.tag == _selectedTag).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(community.handle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: FilledButton(
                onPressed: () =>
                    _toggleMembership(communityProvider, community),
                style: FilledButton.styleFrom(
                  backgroundColor: community.isJoined
                      ? theme.colorScheme.secondaryContainer
                      : theme.colorScheme.primary,
                  foregroundColor: community.isJoined
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onPrimary,
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  community.isJoined ? 'Leave' : 'Join',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context
              .read<NavigationProvider>()
              .openCreatePost(communityId: community.id);
          Navigator.of(context).popUntil(
            (route) =>
                route.isFirst || route.settings.name == AppRoutes.mainShell,
          );
        },
        icon: const Icon(Icons.edit_outlined),
        label: Text('Post in ${community.handle}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
        children: [
          // Community Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: community.accentColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          community.icon,
                          size: 30,
                          color: community.accentColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    community.categoryLabel,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme
                                          .colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                                if (isUserBranch)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.successGreen.withValues(
                                        alpha: isDark ? 0.22 : 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Your Branch',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.successGreen,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              community.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  community.handle,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${TimeFormatter.compactCount(community.memberCount)} members',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    community.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: community.isJoined
                        ? OutlinedButton.icon(
                            onPressed: () =>
                                _toggleMembership(communityProvider, community),
                            icon: const Icon(Icons.check_circle_outline_rounded),
                            label: const Text('Joined · Tap to Leave Community'),
                          )
                        : ElevatedButton.icon(
                            onPressed: () =>
                                _toggleMembership(communityProvider, community),
                            icon: const Icon(Icons.group_add_outlined),
                            label: const Text('Join Community'),
                          ),
                  ),
                  if (community.rules.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Divider(color: theme.colorScheme.outline),
                    const SizedBox(height: 10),
                    Text(
                      'Community Guidelines',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...community.rules.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key + 1}. ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Posts Section Header & Tag Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discussions & Doubts (${posts.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_selectedTag != null)
                TextButton(
                  onPressed: () => setState(() => _selectedTag = null),
                  child: const Text('Clear filter'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PostTag.values.map((tag) {
                final selected = _selectedTag == tag;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_tagLabel(tag)),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() {
                        _selectedTag = selected ? null : tag;
                      });
                    },
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          if (posts.isEmpty)
            EmptyStateView(
              icon: Icons.chat_bubble_outline_rounded,
              title: _selectedTag == null
                  ? 'No posts yet in ${community.handle}'
                  : 'No ${_tagLabel(_selectedTag!)} posts yet',
              subtitle:
                  'Be the first MITS student to ask a doubt or share notes here.',
              actionLabel: 'Create Post',
              onAction: () {
                context
                    .read<NavigationProvider>()
                    .openCreatePost(communityId: community.id);
                Navigator.of(context).popUntil(
                  (route) =>
                      route.isFirst ||
                      route.settings.name == AppRoutes.mainShell,
                );
              },
            )
          else
            ...posts.map((post) {
              final currentUserId =
                  context.watch<UserProvider>().currentUser.id;
              final voteProvider = context.watch<VoteProvider>();
              final isOwnPost = post.authorId == currentUserId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PostCard(
                  post: post,
                  score: voteProvider.getPostScore(post),
                  userVote: voteProvider.getPostUserVote(post.id, currentUserId),
                  isOwnPost: isOwnPost,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.postDetails,
                    arguments: post.id,
                  ),
                  onCommunityTap: () {},
                  onUpvote: () =>
                      voteProvider.togglePostUpvote(post.id, currentUserId),
                  onDownvote: () =>
                      voteProvider.togglePostDownvote(post.id, currentUserId),
                  onSave: () => postProvider.toggleSave(post.id),
                  onEdit: isOwnPost
                      ? () => PostActionsHelper.openEditPost(context, post)
                      : null,
                  onDelete: isOwnPost
                      ? () => PostActionsHelper.confirmDeletePost(context, post)
                      : null,
                  onShare: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Link copied for "${post.title}"'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  String _tagLabel(PostTag tag) {
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
