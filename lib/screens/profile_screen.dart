import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_routes.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../models/student_user.dart';
import '../providers/community_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/post_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../providers/vote_provider.dart';
import '../utils/mock_data.dart';
import '../utils/post_actions_helper.dart';
import '../utils/time_formatter.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/post_card.dart';
import '../widgets/vote_control.dart';

enum _ProfileTab { posts, comments, about }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  _ProfileTab _selectedTab = _ProfileTab.posts;

  int _calculateDynamicKarma(
    List<Post> myPosts,
    List<Comment> myComments,
    VoteProvider voteProvider,
  ) {
    var total = 0;
    for (final post in myPosts) {
      total += voteProvider.getPostScore(post);
    }
    for (final comment in myComments) {
      total += voteProvider.getCommentScore(comment);
    }
    return total;
  }

  void _openEditProfileSheet() {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.currentUser;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.name);
    final usernameController = TextEditingController(text: user.username);
    final bioController = TextEditingController(text: user.bio);
    String selectedBranch = user.branch;
    String selectedYear = user.academicYear;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Student Profile',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration:
                            const InputDecoration(labelText: 'Full Name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name cannot be empty.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixText: '@',
                        ),
                        validator: (value) {
                          final clean = (value ?? '')
                              .trim()
                              .replaceFirst(RegExp(r'^@+'), '');
                          if (clean.isEmpty) {
                            return 'Username cannot be empty.';
                          }
                          if (clean.contains(' ')) {
                            return 'Username cannot contain spaces.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedBranch,
                              decoration:
                                  const InputDecoration(labelText: 'Branch'),
                              items: MockData.branches
                                  .map(
                                    (b) => DropdownMenuItem(
                                      value: b,
                                      child: Text(b),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => selectedBranch = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedYear,
                              decoration:
                                  const InputDecoration(labelText: 'Year'),
                              items: MockData.academicYears
                                  .map(
                                    (y) => DropdownMenuItem(
                                      value: y,
                                      child: Text(y),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => selectedYear = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bioController,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(labelText: 'Bio'),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            userProvider.updateProfile(
                              name: nameController.text,
                              username: usernameController.text,
                              branch: selectedBranch,
                              academicYear: selectedYear,
                              bio: bioController.text,
                            );
                            Navigator.of(sheetContext).pop();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final postProvider = context.watch<PostProvider>();
    final voteProvider = context.watch<VoteProvider>();
    final communityProvider = context.watch<CommunityProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    final myPosts = postProvider.postsByAuthor(user.id);
    final myComments = postProvider.commentsByAuthor(user.id);
    final savedPosts = postProvider.savedPosts;
    final totalKarma = _calculateDynamicKarma(myPosts, myComments, voteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton.icon(
            onPressed: _openEditProfileSheet,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          // Student Profile Header Card
          _ProfileHeaderCard(
            user: user,
            onEditTap: _openEditProfileSheet,
          ),
          const SizedBox(height: 14),

          // Dynamic Statistics Row (Posts, Comments, Karma)
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Posts',
                  value: '${myPosts.length}',
                  icon: Icons.article_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Comments',
                  value: '${myComments.length}',
                  icon: Icons.chat_bubble_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Karma',
                  value: TimeFormatter.compactCount(totalKarma),
                  icon: Icons.bolt_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Separate Tabs: Posts, Comments, About
          Row(
            children: [
              Expanded(
                child: _ProfileSegmentButton(
                  label: 'Posts (${myPosts.length})',
                  selected: _selectedTab == _ProfileTab.posts,
                  onTap: () => setState(() => _selectedTab = _ProfileTab.posts),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProfileSegmentButton(
                  label: 'Comments (${myComments.length})',
                  selected: _selectedTab == _ProfileTab.comments,
                  onTap: () =>
                      setState(() => _selectedTab = _ProfileTab.comments),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProfileSegmentButton(
                  label: 'About',
                  selected: _selectedTab == _ProfileTab.about,
                  onTap: () => setState(() => _selectedTab = _ProfileTab.about),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_selectedTab == _ProfileTab.posts)
            ..._buildPostsTab(
              context,
              user: user,
              myPosts: myPosts,
              postProvider: postProvider,
              voteProvider: voteProvider,
            )
          else if (_selectedTab == _ProfileTab.comments)
            ..._buildCommentsTab(
              context,
              user: user,
              myComments: myComments,
              postProvider: postProvider,
              voteProvider: voteProvider,
            )
          else
            ..._buildAboutTab(
              context,
              user: user,
              savedPosts: savedPosts,
              communityProvider: communityProvider,
              postProvider: postProvider,
              voteProvider: voteProvider,
              themeProvider: themeProvider,
              theme: theme,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildPostsTab(
    BuildContext context, {
    required StudentUser user,
    required List<Post> myPosts,
    required PostProvider postProvider,
    required VoteProvider voteProvider,
  }) {
    if (myPosts.isEmpty) {
      return [
        EmptyStateView(
          icon: Icons.post_add_rounded,
          title: 'No posts created yet',
          subtitle:
              'Ask a campus doubt or share semester notes with MITS students.',
          actionLabel: 'Create Post',
          onAction: () => context.read<NavigationProvider>().openCreatePost(),
        ),
      ];
    }

    return myPosts.map((post) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PostCard(
          post: post,
          score: voteProvider.getPostScore(post),
          userVote: voteProvider.getPostUserVote(post.id, user.id),
          isOwnPost: true,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.postDetails,
            arguments: post.id,
          ),
          onCommunityTap: () => Navigator.of(context).pushNamed(
            AppRoutes.communityDetails,
            arguments: post.communityId,
          ),
          onUpvote: () => voteProvider.togglePostUpvote(post.id, user.id),
          onDownvote: () => voteProvider.togglePostDownvote(post.id, user.id),
          onSave: () => postProvider.toggleSave(post.id),
          onEdit: () => PostActionsHelper.openEditPost(context, post),
          onDelete: () => PostActionsHelper.confirmDeletePost(context, post),
        ),
      );
    }).toList();
  }

  List<Widget> _buildCommentsTab(
    BuildContext context, {
    required StudentUser user,
    required List<Comment> myComments,
    required PostProvider postProvider,
    required VoteProvider voteProvider,
  }) {
    if (myComments.isEmpty) {
      return [
        const EmptyStateView(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'No comment activity yet',
          subtitle:
              'Your answers and comments on campus discussions will appear here.',
        ),
      ];
    }

    return myComments.map((comment) {
      final parentPost = postProvider.getPostById(comment.postId);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ProfileCommentCard(
          comment: comment,
          parentPost: parentPost,
          score: voteProvider.getCommentScore(comment),
          userVote: voteProvider.getCommentUserVote(comment.id, user.id),
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.postDetails,
            arguments: comment.postId,
          ),
          onUpvote: () =>
              voteProvider.toggleCommentUpvote(comment.id, user.id),
          onDownvote: () =>
              voteProvider.toggleCommentDownvote(comment.id, user.id),
        ),
      );
    }).toList();
  }

  List<Widget> _buildAboutTab(
    BuildContext context, {
    required StudentUser user,
    required List<Post> savedPosts,
    required CommunityProvider communityProvider,
    required PostProvider postProvider,
    required VoteProvider voteProvider,
    required ThemeProvider themeProvider,
    required ThemeData theme,
  }) {
    final isDark = themeProvider.isDarkMode(context);
    final joinedCommunities = communityProvider.joinedCommunities;

    return [
      // Academic & Student Information
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Details',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.badge_outlined,
                label: 'Student ID',
                value: user.enrollmentNumber,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.alternate_email_rounded,
                label: 'Username',
                value: user.formattedUsername,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.school_outlined,
                label: 'Branch',
                value: user.branch,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Academic Year',
                value: user.academicYear,
              ),
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.mail_outline_rounded,
                label: 'MITS Email',
                value: user.email,
              ),
              if (user.bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Divider(color: theme.colorScheme.outline),
                const SizedBox(height: 10),
                Text(
                  'Bio',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.bio,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),

      // Joined Communities
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Joined Communities (${joinedCommunities.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (joinedCommunities.isEmpty)
                Text(
                  'You have not joined any communities yet.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: joinedCommunities.map((c) {
                    return ActionChip(
                      avatar: Icon(c.icon, size: 16, color: c.accentColor),
                      label: Text(c.handle),
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.communityDetails,
                        arguments: c.id,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),

      // Appearance & Session Settings
      Card(
        child: Column(
          children: [
            SwitchListTile(
              secondary: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text(
                'Dark Mode',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                isDark ? 'Dark navy theme active' : 'Light clean theme active',
                style: theme.textTheme.bodySmall,
              ),
              value: isDark,
              onChanged: (_) => themeProvider.toggleTheme(context),
            ),
            Divider(color: theme.colorScheme.outline),
            ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Back to Welcome Screen',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.error,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () =>
                  Navigator.of(context).pushReplacementNamed(AppRoutes.login),
            ),
          ],
        ),
      ),

      if (savedPosts.isNotEmpty) ...[
        const SizedBox(height: 18),
        Text(
          'Saved Posts (${savedPosts.length})',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...savedPosts.map((post) {
          final isOwnPost = post.authorId == user.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PostCard(
              post: post,
              score: voteProvider.getPostScore(post),
              userVote: voteProvider.getPostUserVote(post.id, user.id),
              isOwnPost: isOwnPost,
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.postDetails,
                arguments: post.id,
              ),
              onCommunityTap: () => Navigator.of(context).pushNamed(
                AppRoutes.communityDetails,
                arguments: post.communityId,
              ),
              onUpvote: () => voteProvider.togglePostUpvote(post.id, user.id),
              onDownvote: () =>
                  voteProvider.togglePostDownvote(post.id, user.id),
              onSave: () => postProvider.toggleSave(post.id),
              onEdit: isOwnPost
                  ? () => PostActionsHelper.openEditPost(context, post)
                  : null,
              onDelete: isOwnPost
                  ? () => PostActionsHelper.confirmDeletePost(context, post)
                  : null,
            ),
          );
        }),
      ],
    ];
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final StudentUser user;
  final VoidCallback onEditTap;

  const _ProfileHeaderCard({
    required this.user,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.formattedUsername,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _InfoPill(
                            icon: Icons.school_outlined,
                            label: user.branch,
                          ),
                          _InfoPill(
                            icon: Icons.calendar_today_outlined,
                            label: user.academicYear,
                          ),
                          _InfoPill(
                            icon: Icons.badge_outlined,
                            label: user.enrollmentNumber,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (user.bio.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                user.bio,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEditTap,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCommentCard extends StatelessWidget {
  final Comment comment;
  final Post? parentPost;
  final int score;
  final int userVote;
  final VoidCallback onTap;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;

  const _ProfileCommentCard({
    required this.comment,
    required this.parentPost,
    required this.score,
    required this.userVote,
    required this.onTap,
    required this.onUpvote,
    required this.onDownvote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editedSuffix = comment.isEdited ? ' · edited' : '';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (parentPost != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        parentPost!.communityHandle,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      parentPost?.title ?? 'Campus Discussion',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${TimeFormatter.timeAgo(comment.createdAt)}$editedSuffix',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                comment.content,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  VoteControl(
                    score: score,
                    userVote: userVote,
                    onUpvote: onUpvote,
                    onDownvote: onDownvote,
                    compact: true,
                  ),
                  const Spacer(),
                  Text(
                    'View post',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileSegmentButton({
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
