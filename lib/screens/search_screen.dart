import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_routes.dart';
import '../models/community.dart';
import '../models/post.dart';
import '../providers/community_provider.dart';
import '../providers/post_provider.dart';
import '../providers/search_provider.dart';
import '../providers/user_provider.dart';
import '../providers/vote_provider.dart';
import '../utils/post_actions_helper.dart';
import '../widgets/community_card.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/post_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  static const List<String> _trendingTopics = [
    'DBMS',
    'Placements',
    'Flutter',
    'Notes',
    'Robotics',
    'Library',
    'PyTorch',
    'CSE',
  ];

  static const List<String> _communitySuggestions = [
    'CSE',
    'IT',
    'AI/ML',
    'AI & DS',
    'ECE',
    'Clubs',
    'Placements',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyTopic(SearchProvider searchProvider, String topic) {
    _searchController.value = TextEditingValue(
      text: topic,
      selection: TextSelection.collapsed(offset: topic.length),
    );
    searchProvider.setQuery(topic);
    searchProvider.recordRecentQuery(topic);
  }

  void _clearSearch(SearchProvider searchProvider) {
    _searchController.clear();
    searchProvider.clearQuery();
  }

  void _handleToggleJoin(
    CommunityProvider communityProvider,
    Community community,
  ) {
    final wasJoined = community.isJoined;
    communityProvider.toggleJoin(community.id);
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
    final searchProvider = context.watch<SearchProvider>();
    final postProvider = context.watch<PostProvider>();
    final communityProvider = context.watch<CommunityProvider>();
    final voteProvider = context.watch<VoteProvider>();
    final currentUserId = context.watch<UserProvider>().currentUser.id;
    final theme = Theme.of(context);

    // Keep controller synced if cleared externally.
    if (_searchController.text != searchProvider.query) {
      _searchController.value = TextEditingValue(
        text: searchProvider.query,
        selection: TextSelection.collapsed(offset: searchProvider.query.length),
      );
    }

    final hasQuery = searchProvider.hasQuery;
    final trimmedQuery = searchProvider.trimmedQuery;
    final matchingPosts = searchProvider.findMatchingPosts(postProvider);
    final matchingCommunities =
        searchProvider.findMatchingCommunities(communityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          // Search Bar + Posts/Communities Filter Tabs
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outline),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: searchProvider.setQuery,
                  onSubmitted: searchProvider.recordRecentQuery,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: searchProvider.activeTab == SearchTab.posts
                        ? 'Search posts by title, topic, or branch...'
                        : 'Search communities by name, branch, or club...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: searchProvider.query.isNotEmpty
                        ? IconButton(
                            onPressed: () => _clearSearch(searchProvider),
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SearchTabButton(
                        icon: Icons.article_outlined,
                        label: hasQuery
                            ? 'Posts (${matchingPosts.length})'
                            : 'Posts',
                        selected: searchProvider.activeTab == SearchTab.posts,
                        onTap: () => searchProvider.setTab(SearchTab.posts),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SearchTabButton(
                        icon: Icons.groups_outlined,
                        label: hasQuery
                            ? 'Communities (${matchingCommunities.length})'
                            : 'Communities',
                        selected:
                            searchProvider.activeTab == SearchTab.communities,
                        onTap: () =>
                            searchProvider.setTab(SearchTab.communities),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: !hasQuery
                ? _buildDefaultView(
                    context,
                    searchProvider: searchProvider,
                    postProvider: postProvider,
                    communityProvider: communityProvider,
                    voteProvider: voteProvider,
                    currentUserId: currentUserId,
                  )
                : searchProvider.activeTab == SearchTab.posts
                    ? _buildPostsResults(
                        context,
                        query: trimmedQuery,
                        posts: matchingPosts,
                        otherTabCount: matchingCommunities.length,
                        searchProvider: searchProvider,
                        postProvider: postProvider,
                        voteProvider: voteProvider,
                        currentUserId: currentUserId,
                      )
                    : _buildCommunitiesResults(
                        context,
                        query: trimmedQuery,
                        communities: matchingCommunities,
                        otherTabCount: matchingPosts.length,
                        searchProvider: searchProvider,
                        communityProvider: communityProvider,
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultView(
    BuildContext context, {
    required SearchProvider searchProvider,
    required PostProvider postProvider,
    required CommunityProvider communityProvider,
    required VoteProvider voteProvider,
    required String currentUserId,
  }) {
    final theme = Theme.of(context);
    final isPostsTab = searchProvider.activeTab == SearchTab.posts;
    final suggestions = isPostsTab ? _trendingTopics : _communitySuggestions;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        if (searchProvider.recentQueries.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton(
                onPressed: searchProvider.clearRecentQueries,
                child: const Text('Clear all'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: searchProvider.recentQueries.map((recent) {
              return InputChip(
                avatar: const Icon(Icons.history_rounded, size: 16),
                label: Text(recent),
                onPressed: () => _applyTopic(searchProvider, recent),
                onDeleted: () => searchProvider.removeRecentQuery(recent),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        Text(
          isPostsTab ? 'Trending Campus Topics' : 'Quick Community Filters',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((topic) {
            return ActionChip(
              avatar: Icon(
                isPostsTab
                    ? Icons.trending_up_rounded
                    : Icons.school_outlined,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              label: Text(topic),
              onPressed: () => _applyTopic(searchProvider, topic),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        if (isPostsTab) ...[
          Text(
            'Top Campus Discussions',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...postProvider
              .sortedFeedPosts(voteProvider.getPostScore)
              .take(3)
              .map(
                (post) => _buildPostItem(
                  context,
                  post: post,
                  postProvider: postProvider,
                  voteProvider: voteProvider,
                  currentUserId: currentUserId,
                ),
              ),
        ] else ...[
          Text(
            'Popular MITS Communities',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...communityProvider.allCommunities.take(5).map((community) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CommunityCard(
                community: community,
                isUserBranch:
                    communityProvider.isUserBranchCommunity(community),
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.communityDetails,
                  arguments: community.id,
                ),
                onToggleJoin: () =>
                    _handleToggleJoin(communityProvider, community),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildPostsResults(
    BuildContext context, {
    required String query,
    required List<Post> posts,
    required int otherTabCount,
    required SearchProvider searchProvider,
    required PostProvider postProvider,
    required VoteProvider voteProvider,
    required String currentUserId,
  }) {
    if (posts.isEmpty) {
      return EmptyStateView(
        icon: Icons.article_outlined,
        title: 'No posts found for "$query"',
        subtitle: otherTabCount > 0
            ? 'Found $otherTabCount matching ${otherTabCount == 1 ? 'community' : 'communities'} in the Communities tab.'
            : 'Try searching by subject (DBMS, OS), branch (CSE, ECE), or keyword.',
        actionLabel:
            otherTabCount > 0 ? 'View Communities ($otherTabCount)' : 'Clear Search',
        onAction: otherTabCount > 0
            ? () => searchProvider.setTab(SearchTab.communities)
            : () => _clearSearch(searchProvider),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return _buildPostItem(
          context,
          post: posts[index],
          postProvider: postProvider,
          voteProvider: voteProvider,
          currentUserId: currentUserId,
        );
      },
    );
  }

  Widget _buildCommunitiesResults(
    BuildContext context, {
    required String query,
    required List<Community> communities,
    required int otherTabCount,
    required SearchProvider searchProvider,
    required CommunityProvider communityProvider,
  }) {
    if (communities.isEmpty) {
      return EmptyStateView(
        icon: Icons.groups_outlined,
        title: 'No communities found for "$query"',
        subtitle: otherTabCount > 0
            ? 'Found $otherTabCount matching ${otherTabCount == 1 ? 'post' : 'posts'} in the Posts tab.'
            : 'Try searching by branch name (CSE, IT, ECE), club, or campus hub.',
        actionLabel:
            otherTabCount > 0 ? 'View Posts ($otherTabCount)' : 'Clear Search',
        onAction: otherTabCount > 0
            ? () => searchProvider.setTab(SearchTab.posts)
            : () => _clearSearch(searchProvider),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: communities.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final community = communities[index];
        return CommunityCard(
          community: community,
          isUserBranch: communityProvider.isUserBranchCommunity(community),
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.communityDetails,
            arguments: community.id,
          ),
          onToggleJoin: () => _handleToggleJoin(communityProvider, community),
        );
      },
    );
  }

  Widget _buildPostItem(
    BuildContext context, {
    required Post post,
    required PostProvider postProvider,
    required VoteProvider voteProvider,
    required String currentUserId,
  }) {
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
        onCommunityTap: () => Navigator.of(context).pushNamed(
          AppRoutes.communityDetails,
          arguments: post.communityId,
        ),
        onUpvote: () => voteProvider.togglePostUpvote(post.id, currentUserId),
        onDownvote: () =>
            voteProvider.togglePostDownvote(post.id, currentUserId),
        onSave: () => postProvider.toggleSave(post.id),
        onEdit: isOwnPost
            ? () => PostActionsHelper.openEditPost(context, post)
            : null,
        onDelete: isOwnPost
            ? () => PostActionsHelper.confirmDeletePost(context, post)
            : null,
      ),
    );
  }
}

class _SearchTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SearchTabButton({
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
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
