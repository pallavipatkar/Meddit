import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meddit/main.dart';
import 'package:meddit/models/community.dart';
import 'package:meddit/models/post.dart';
import 'package:meddit/providers/community_provider.dart';
import 'package:meddit/providers/post_provider.dart';
import 'package:meddit/providers/search_provider.dart';
import 'package:meddit/providers/user_provider.dart';
import 'package:meddit/providers/vote_provider.dart';
import 'package:meddit/utils/mock_data.dart';

void main() {
  testWidgets('Meddit splash screen renders and navigates to login',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MedditApp());

    expect(find.text('Meddit'), findsOneWidget);
    expect(find.text('MITS Gwalior Campus Discussions & Doubts'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(find.text('MITS Student Email Access'), findsOneWidget);
    expect(find.text('Explore Campus Feed (UI Preview)'), findsOneWidget);
  });

  group('CommunityProvider', () {
    test('includes MITS Gwalior branch, campus, and club communities', () {
      final provider = CommunityProvider();
      final handles = provider.allCommunities.map((c) => c.handle).toSet();

      expect(
        handles,
        containsAll([
          'm/cse',
          'm/it',
          'm/aiml',
          'm/aids',
          'm/ece',
          'm/ee',
          'm/mech',
          'm/civil',
          'm/mitsgeneral',
          'm/placements',
          'm/codingclub',
          'm/robotics',
        ]),
      );

      final branches = provider.allCommunities
          .where((c) => c.category == CommunityCategory.branch);
      final clubs = provider.allCommunities
          .where((c) => c.category == CommunityCategory.club);
      final campus = provider.allCommunities
          .where((c) => c.category == CommunityCategory.campus);

      expect(branches.length, greaterThanOrEqualTo(8));
      expect(clubs.length, greaterThanOrEqualTo(3));
      expect(campus.length, greaterThanOrEqualTo(3));
    });

    test('auto-detects and joins user branch community', () {
      final provider = CommunityProvider();
      provider.syncUserBranch('ECE');

      final branchComm = provider.userBranchCommunity;
      expect(branchComm, isNotNull);
      expect(branchComm!.handle, 'm/ece');
      expect(branchComm.isJoined, isTrue);
    });

    test('join and leave update membership and member count', () {
      final provider = CommunityProvider();
      final itBefore = provider.getById('comm_it')!;
      final initialCount = itBefore.memberCount;
      expect(itBefore.isJoined, isFalse);

      provider.toggleJoin('comm_it');
      final itJoined = provider.getById('comm_it')!;
      expect(itJoined.isJoined, isTrue);
      expect(itJoined.memberCount, initialCount + 1);

      provider.toggleJoin('comm_it');
      final itLeft = provider.getById('comm_it')!;
      expect(itLeft.isJoined, isFalse);
      expect(itLeft.memberCount, initialCount);
    });
  });

  group('PostProvider', () {
    test('creates, edits, and deletes own posts', () {
      final postProvider = PostProvider();
      final community = MockData.communities.first;
      final author = MockData.sampleStudent;

      final created = postProvider.createPost(
        title: 'OS Lab Viva Questions',
        description: 'What topics are asked in 5th sem OS practical viva?',
        community: community,
        author: author,
        tag: PostTag.doubt,
      );

      expect(postProvider.getPostById(created.id), isNotNull);
      expect(
        postProvider
            .postsForCommunity(community.id)
            .any((p) => p.id == created.id),
        isTrue,
      );

      final emptyEdit = postProvider.updatePost(
        postId: created.id,
        title: '   ',
        description: 'Valid',
        community: community,
        tag: PostTag.doubt,
      );
      expect(emptyEdit, isFalse);

      final updatedOk = postProvider.updatePost(
        postId: created.id,
        title: 'OS Lab Viva Important Questions',
        description: 'Updated description for 5th sem OS practical viva.',
        community: community,
        tag: PostTag.notes,
      );
      expect(updatedOk, isTrue);
      final updated = postProvider.getPostById(created.id)!;
      expect(updated.title, 'OS Lab Viva Important Questions');
      expect(updated.tag, PostTag.notes);
      expect(updated.isEdited, isTrue);

      postProvider.deletePost(created.id);
      expect(postProvider.getPostById(created.id), isNull);
    });

    test('validates, adds, edits, and deletes own comments', () {
      final postProvider = PostProvider();
      final author = MockData.sampleStudent;
      final postId = postProvider.feedPosts.first.id;
      final initialCount = postProvider.getPostById(postId)!.commentCount;

      expect(
        postProvider.addComment(postId: postId, content: '   ', author: author),
        isNull,
      );

      final addedComment = postProvider.addComment(
        postId: postId,
        content: 'Check unit 2 solved PYQs!',
        author: author,
      );
      expect(addedComment, isNotNull);
      expect(postProvider.getPostById(postId)!.commentCount, initialCount + 1);
      expect(addedComment!.authorId, author.id);

      expect(
        postProvider.updateComment(commentId: addedComment.id, content: ''),
        isFalse,
      );

      expect(
        postProvider.updateComment(
          commentId: addedComment.id,
          content: 'Check unit 2 and unit 3 solved PYQs!',
        ),
        isTrue,
      );
      final editedComment = postProvider
          .commentsForPost(postId)
          .firstWhere((c) => c.id == addedComment.id);
      expect(editedComment.content, 'Check unit 2 and unit 3 solved PYQs!');
      expect(editedComment.isEdited, isTrue);

      postProvider.deleteComment(addedComment.id);
      expect(postProvider.getPostById(postId)!.commentCount, initialCount);
      expect(
        postProvider
            .commentsForPost(postId)
            .any((c) => c.id == addedComment.id),
        isFalse,
      );
    });
  });

  group('VoteProvider', () {
    test('supports post upvote, toggle off, downvote, and vote switching', () {
      final voteProvider = VoteProvider();
      final postProvider = PostProvider();
      final userId = MockData.sampleStudent.id;
      final post = postProvider.getPostById('post_2')!; // initially unvoted

      final baseScore = voteProvider.getPostScore(post);
      expect(voteProvider.getPostUserVote(post.id, userId), 0);

      // Upvote
      voteProvider.togglePostUpvote(post.id, userId);
      expect(voteProvider.getPostUserVote(post.id, userId), 1);
      expect(voteProvider.getPostScore(post), baseScore + 1);

      // Tap upvote again -> removes vote
      voteProvider.togglePostUpvote(post.id, userId);
      expect(voteProvider.getPostUserVote(post.id, userId), 0);
      expect(voteProvider.getPostScore(post), baseScore);

      // Downvote
      voteProvider.togglePostDownvote(post.id, userId);
      expect(voteProvider.getPostUserVote(post.id, userId), -1);
      expect(voteProvider.getPostScore(post), baseScore - 1);

      // Switch from downvote to upvote (+2 net change)
      voteProvider.togglePostUpvote(post.id, userId);
      expect(voteProvider.getPostUserVote(post.id, userId), 1);
      expect(voteProvider.getPostScore(post), baseScore + 1);

      // Switch from upvote to downvote (-2 net change)
      voteProvider.togglePostDownvote(post.id, userId);
      expect(voteProvider.getPostUserVote(post.id, userId), -1);
      expect(voteProvider.getPostScore(post), baseScore - 1);
    });

    test('supports comment voting and prevents duplicate votes per user', () {
      final voteProvider = VoteProvider();
      final postProvider = PostProvider();
      final userId = MockData.sampleStudent.id;
      final comment = postProvider
          .commentsForPost('post_1')
          .firstWhere((c) => c.id == 'c_1');

      final baseScore = voteProvider.getCommentScore(comment);
      expect(voteProvider.getCommentUserVote(comment.id, userId), 0);

      // Upvote
      voteProvider.toggleCommentUpvote(comment.id, userId);
      expect(voteProvider.getCommentUserVote(comment.id, userId), 1);
      expect(voteProvider.getCommentScore(comment), baseScore + 1);

      // Second user upvotes -> aggregates independently
      voteProvider.toggleCommentUpvote(comment.id, 'student_99');
      expect(voteProvider.getCommentScore(comment), baseScore + 2);

      // First user switches to downvote -> only 1 vote per user
      voteProvider.toggleCommentDownvote(comment.id, userId);
      expect(voteProvider.getCommentUserVote(comment.id, userId), -1);
      expect(voteProvider.getCommentScore(comment), baseScore);

      // First user taps downvote again -> removes vote
      voteProvider.toggleCommentDownvote(comment.id, userId);
      expect(voteProvider.getCommentUserVote(comment.id, userId), 0);
      expect(voteProvider.getCommentScore(comment), baseScore + 1);
    });

    testWidgets('Home Feed voting buttons update score live in UI',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MedditApp());
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Explore Campus Feed (UI Preview)'));
      await tester.pumpAndSettle();

      // Top hot post is post_2 with initial score 139 (142 - 3)
      expect(find.text('139'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_upward_rounded).first);
      await tester.pump();
      expect(find.text('140'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_downward_rounded).first);
      await tester.pump();
      expect(find.text('138'), findsOneWidget);
    });
  });

  group('SearchProvider and SearchScreen', () {
    test('searches posts and communities case-insensitively and trims spaces',
        () {
      final searchProvider = SearchProvider();
      final postProvider = PostProvider();
      final communityProvider = CommunityProvider();

      searchProvider.setQuery('   dbms   ');
      expect(searchProvider.hasQuery, isTrue);
      final posts = searchProvider.findMatchingPosts(postProvider);
      expect(posts, isNotEmpty);
      expect(
        posts.any((p) => p.title.toLowerCase().contains('dbms')),
        isTrue,
      );

      searchProvider.setQuery('  robotics  ');
      final communities =
          searchProvider.findMatchingCommunities(communityProvider);
      expect(communities, isNotEmpty);
      expect(communities.first.handle, 'm/robotics');

      // Whitespace-only query returns no results
      searchProvider.setQuery('   ');
      expect(searchProvider.hasQuery, isFalse);
      expect(searchProvider.findMatchingPosts(postProvider), isEmpty);
      expect(searchProvider.findMatchingCommunities(communityProvider), isEmpty);

      // Live update when a new post is added
      searchProvider.setQuery('QuantumLab');
      expect(searchProvider.findMatchingPosts(postProvider), isEmpty);
      postProvider.createPost(
        title: 'QuantumLab Elective Notes',
        description: 'Sharing MITS QuantumLab syllabus notes.',
        community: communityProvider.allCommunities.first,
        author: MockData.sampleStudent,
        tag: PostTag.notes,
      );
      expect(searchProvider.findMatchingPosts(postProvider).length, 1);
    });

    testWidgets(
        'SearchScreen switches Posts and Communities tabs, clears query, and shows empty state',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MedditApp());
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Explore Campus Feed (UI Preview)'));
      await tester.pumpAndSettle();

      // Navigate to Search tab in bottom navigation
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Default view shows Trending Campus Topics
      expect(find.text('Trending Campus Topics'), findsOneWidget);

      // Type query into search bar
      await tester.enterText(find.byType(TextField), '  robotics  ');
      await tester.pumpAndSettle();

      // Posts tab shows matching post
      expect(find.textContaining('STM32 vs ESP32'), findsOneWidget);

      // Switch to Communities tab
      await tester.tap(find.textContaining('Communities ('));
      await tester.pumpAndSettle();
      expect(find.text('m/robotics'), findsOneWidget);

      // Query with no results shows empty state
      await tester.enterText(find.byType(TextField), 'xyznonexistent');
      await tester.pumpAndSettle();
      expect(
        find.text('No communities found for "xyznonexistent"'),
        findsOneWidget,
      );

      // Clear button resets back to default view
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Quick Community Filters'), findsOneWidget);
    });
  });

  group('UserProvider and ProfileScreen', () {
    test('updates student name, username, branch, year, and bio with validation',
        () {
      final userProvider = UserProvider();
      expect(userProvider.currentUser.formattedUsername, '@aarav_cs23');

      final emptyUpdate = userProvider.updateProfile(
        name: '   ',
        username: 'aarav_cs23',
        branch: 'CSE',
        academicYear: '3rd Year',
        bio: 'Test',
      );
      expect(emptyUpdate, isFalse);

      final updated = userProvider.updateProfile(
        name: 'Aarav S.',
        username: '@aarav_mits',
        branch: 'AI/ML',
        academicYear: '4th Year',
        bio: 'Updated bio',
      );
      expect(updated, isTrue);
      expect(userProvider.currentUser.name, 'Aarav S.');
      expect(userProvider.currentUser.username, 'aarav_mits');
      expect(userProvider.currentUser.formattedUsername, '@aarav_mits');
      expect(userProvider.currentUser.branch, 'AI/ML');
      expect(userProvider.currentUser.academicYear, '4th Year');
      expect(userProvider.currentUser.bio, 'Updated bio');
    });

    testWidgets(
        'ProfileScreen shows dynamic stats, Posts/Comments/About tabs, and updates on edit',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MedditApp());
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Explore Campus Feed (UI Preview)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Header & student info
      expect(find.text('Aarav Sharma'), findsWidgets);
      expect(find.text('@aarav_cs23'), findsOneWidget);
      expect(find.text('0901CS231042'), findsOneWidget);
      expect(find.text('185'), findsOneWidget); // dynamic karma: 62 + 117 + 6

      // Switch to Comments tab
      await tester.tap(find.text('Comments (1)'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Thanks for sharing the exact SQL window function'),
        findsOneWidget,
      );

      // Switch to About tab
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      expect(find.text('Student Details'), findsOneWidget);
      expect(find.text('0901CS231042@mitsgwalior.in'), findsOneWidget);

      // Open Edit Profile sheet and update name & username
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'Aarav MITS',
      );
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Aarav MITS'), findsOneWidget);
    });
  });
}
