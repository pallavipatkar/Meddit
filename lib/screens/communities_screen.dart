import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../models/community.dart';
import '../providers/community_provider.dart';
import '../providers/user_provider.dart';
import '../utils/time_formatter.dart';
import '../widgets/community_card.dart';
import '../widgets/empty_state_view.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final _browseController = TextEditingController();

  @override
  void dispose() {
    _browseController.dispose();
    super.dispose();
  }

  void _handleToggleJoin(CommunityProvider provider, Community community) {
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
    final user = context.watch<UserProvider>().currentUser;
    final theme = Theme.of(context);
    final communities = communityProvider.filteredCommunities;
    final joinedCount = communityProvider.joinedCommunities.length;
    final branchCommunity = communityProvider.communityForBranch(user.branch);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communities'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$joinedCount Joined',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Category Filter Header
          Container(
            width: double.infinity,
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
                  controller: _browseController,
                  onChanged: communityProvider.setBrowseQuery,
                  decoration: InputDecoration(
                    hintText: 'Browse branches, clubs, or campus hubs...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    suffixIcon: communityProvider.browseQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _browseController.clear();
                              communityProvider.setBrowseQuery('');
                            },
                            icon: const Icon(Icons.close_rounded, size: 19),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CategoryPill(
                        label: 'All (${communityProvider.allCommunities.length})',
                        selected: communityProvider.activeFilter ==
                            CommunityFilter.all,
                        onTap: () =>
                            communityProvider.setFilter(CommunityFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _CategoryPill(
                        label: 'Joined ($joinedCount)',
                        selected: communityProvider.activeFilter ==
                            CommunityFilter.joined,
                        onTap: () =>
                            communityProvider.setFilter(CommunityFilter.joined),
                      ),
                      const SizedBox(width: 8),
                      _CategoryPill(
                        label: 'Branches',
                        selected: communityProvider.activeFilter ==
                            CommunityFilter.branches,
                        onTap: () => communityProvider
                            .setFilter(CommunityFilter.branches),
                      ),
                      const SizedBox(width: 8),
                      _CategoryPill(
                        label: 'Clubs',
                        selected: communityProvider.activeFilter ==
                            CommunityFilter.clubs,
                        onTap: () =>
                            communityProvider.setFilter(CommunityFilter.clubs),
                      ),
                      const SizedBox(width: 8),
                      _CategoryPill(
                        label: 'Campus',
                        selected: communityProvider.activeFilter ==
                            CommunityFilter.campus,
                        onTap: () =>
                            communityProvider.setFilter(CommunityFilter.campus),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                // Auto-detected Student Branch Community Card
                if (branchCommunity != null &&
                    communityProvider.browseQuery.isEmpty &&
                    (communityProvider.activeFilter == CommunityFilter.all ||
                        communityProvider.activeFilter ==
                            CommunityFilter.branches)) ...[
                  _MyBranchHighlightCard(
                    community: branchCommunity,
                    studentBranch: user.branch,
                    studentYear: user.academicYear,
                    onOpen: () => Navigator.of(context).pushNamed(
                      AppRoutes.communityDetails,
                      arguments: branchCommunity.id,
                    ),
                    onToggleJoin: () =>
                        _handleToggleJoin(communityProvider, branchCommunity),
                  ),
                  const SizedBox(height: 18),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _sectionTitle(communityProvider.activeFilter),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${communities.length} found',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (communities.isEmpty)
                  EmptyStateView(
                    icon: Icons.groups_outlined,
                    title: 'No communities match your filter',
                    subtitle:
                        'Try switching category tabs or clearing your search query.',
                    actionLabel: 'Show All Communities',
                    onAction: () {
                      _browseController.clear();
                      communityProvider.setBrowseQuery('');
                      communityProvider.setFilter(CommunityFilter.all);
                    },
                  )
                else
                  ...communities.map((community) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
            ),
          ),
        ],
      ),
    );
  }

  String _sectionTitle(CommunityFilter filter) {
    switch (filter) {
      case CommunityFilter.all:
        return 'All MITS Gwalior Communities';
      case CommunityFilter.joined:
        return 'Your Joined Communities';
      case CommunityFilter.branches:
        return 'Branch Communities';
      case CommunityFilter.clubs:
        return 'Student Clubs';
      case CommunityFilter.campus:
        return 'General Campus Hubs';
    }
  }
}

class _MyBranchHighlightCard extends StatelessWidget {
  final Community community;
  final String studentBranch;
  final String studentYear;
  final VoidCallback onOpen;
  final VoidCallback onToggleJoin;

  const _MyBranchHighlightCard({
    required this.community,
    required this.studentBranch,
    required this.studentYear,
    required this.onOpen,
    required this.onToggleJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.primaryIndigo, AppColors.darkSurfaceVariant]
              : [AppColors.primaryNavy, AppColors.accentIndigo],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'YOUR BRANCH · $studentBranch · $studentYear',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      community.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          community.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${community.handle} · ${TimeFormatter.compactCount(community.memberCount)} members',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onOpen,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'View Posts',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onToggleJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryNavy,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        community.isJoined ? 'Joined ✓' : 'Join Branch',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
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

class _CategoryPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryPill({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
