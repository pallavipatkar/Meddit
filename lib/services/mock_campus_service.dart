import '../models/comment.dart';
import '../models/community.dart';
import '../models/post.dart';
import '../models/student_user.dart';
import '../models/vote.dart';
import '../utils/mock_data.dart';

/// Abstraction layer over campus data.
/// Currently backed by realistic in-memory mock data; can be swapped with
/// Cloud Firestore & Firebase Auth services in the backend integration phase.
class MockCampusService {
  StudentUser getCurrentStudent() => MockData.sampleStudent;

  List<Community> fetchCommunities() => List<Community>.from(MockData.communities);

  List<Post> fetchPosts() => List<Post>.from(MockData.posts);

  List<Comment> fetchComments() => List<Comment>.from(MockData.comments);

  List<VoteRecord> fetchVotes() => List<VoteRecord>.from(MockData.initialVotes);
}
