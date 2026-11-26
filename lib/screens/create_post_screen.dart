import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_routes.dart';
import '../models/community.dart';
import '../models/post.dart';
import '../providers/community_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/post_provider.dart';
import '../providers/user_provider.dart';
import '../providers/vote_provider.dart';

class CreatePostScreen extends StatefulWidget {
  final Post? editingPost;

  const CreatePostScreen({super.key, this.editingPost});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCommunityId;
  PostTag _selectedTag = PostTag.doubt;

  bool get _isEditing => widget.editingPost != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editingPost;
    if (editing != null) {
      _titleController.text = editing.title;
      _descriptionController.text = editing.description;
      _selectedCommunityId = editing.communityId;
      _selectedTag = editing.tag;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _syncPreselectedCommunity(
    NavigationProvider navProvider,
    List<Community> communities,
  ) {
    if (_isEditing) return;

    final preselected = navProvider.preselectedCommunityId;
    if (preselected != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedCommunityId = preselected;
        });
        navProvider.clearPreselectedCommunity();
      });
    } else if (_selectedCommunityId == null && communities.isNotEmpty) {
      _selectedCommunityId = communities.first.id;
    }
  }

  void _openCommunityPicker(List<Community> communities) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    'Select MITS Community',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: communities.length,
                    itemBuilder: (context, index) {
                      final c = communities[index];
                      final isSelected = c.id == _selectedCommunityId;
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: c.accentColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(c.icon, color: c.accentColor, size: 22),
                        ),
                        title: Text(
                          c.handle,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          setState(() => _selectedCommunityId = c.id);
                          Navigator.of(sheetContext).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitPost(List<Community> communities) {
    if (!_formKey.currentState!.validate()) return;

    final community = communities.firstWhere(
      (c) => c.id == _selectedCommunityId,
      orElse: () => communities.first,
    );
    final postProvider = context.read<PostProvider>();

    if (_isEditing) {
      postProvider.updatePost(
        postId: widget.editingPost!.id,
        title: _titleController.text,
        description: _descriptionController.text,
        community: community,
        tag: _selectedTag,
      );
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final navProvider = context.read<NavigationProvider>();

    final newPost = postProvider.createPost(
      title: _titleController.text,
      description: _descriptionController.text,
      community: community,
      author: userProvider.currentUser,
      tag: _selectedTag,
    );
    context.read<VoteProvider>().togglePostUpvote(
          newPost.id,
          userProvider.currentUser.id,
        );
    userProvider.incrementKarma(5);

    _titleController.clear();
    _descriptionController.clear();
    FocusScope.of(context).unfocus();

    navProvider.setIndex(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Posted to ${community.handle}! (+5 karma)'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          onPressed: () => Navigator.of(context).pushNamed(
            AppRoutes.postDetails,
            arguments: newPost.id,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final communities = context.watch<CommunityProvider>().allCommunities;
    final navProvider = context.watch<NavigationProvider>();
    _syncPreselectedCommunity(navProvider, communities);

    final selectedCommunity = communities.firstWhere(
      (c) => c.id == _selectedCommunityId,
      orElse: () => communities.first,
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Post' : 'Create Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: FilledButton(
                onPressed: () => _submitPost(communities),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  _isEditing ? 'Save' : 'Post',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Community Selector
            Text(
              'Community',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _openCommunityPicker(communities),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selectedCommunity.accentColor
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        selectedCommunity.icon,
                        color: selectedCommunity.accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedCommunity.handle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            selectedCommunity.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tag Selector
            Text(
              'Category Tag',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PostTag.values.map((tag) {
                final selected = _selectedTag == tag;
                return ChoiceChip(
                  label: Text(_tagLabel(tag)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedTag = tag),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Title Input
            Text(
              'Title',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              maxLength: 140,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ask a clear question or write a descriptive title...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title cannot be empty.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description Input
            Text(
              'Details',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              minLines: 6,
              maxLines: 12,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'Add context, subject code, semester, or what you have already tried...',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Post description cannot be empty.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _submitPost(communities),
                icon: Icon(_isEditing ? Icons.save_outlined : Icons.send_rounded),
                label: Text(
                  _isEditing
                      ? 'Save Changes'
                      : 'Publish to ${selectedCommunity.handle}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _tagLabel(PostTag tag) {
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
}
