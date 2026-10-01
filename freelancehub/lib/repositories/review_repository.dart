import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_exception.dart';
import '../core/firebase/firebase_config.dart';
import '../models/review_model.dart';

/// Repository managing client reviews and ratings in Cloud Firestore.
class ReviewRepository {
  final FirebaseFirestore? _injectedFirestore;

  ReviewRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  static final ReviewRepository instance = ReviewRepository();

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseConfig.instance.firestore;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection('reviews');

  /// Submit a new review & update freelancer aggregated rating
  Future<String> createReview(ReviewModel review) async {
    try {
      final docRef = await _reviews.add(review.toMap());

      // Update freelancer rating in Firestore
      final freelancerRef =
          _firestore.collection('freelancers').doc(review.freelancerId);
      final freelancerDoc = await freelancerRef.get();
      if (freelancerDoc.exists && freelancerDoc.data() != null) {
        final data = freelancerDoc.data()!;
        final currentReviews = (data['reviewsCount'] as num?)?.toInt() ?? 0;
        final currentRating = (data['rating'] as num?)?.toDouble() ?? 5.0;

        final newReviews = currentReviews + 1;
        final newRating =
            ((currentRating * currentReviews) + review.rating) / newReviews;

        await freelancerRef.update({
          'reviewsCount': newReviews,
          'rating': double.parse(newRating.toStringAsFixed(2)),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return docRef.id;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Fetch all reviews for a freelancer
  Future<List<ReviewModel>> getReviewsForFreelancer(
    String freelancerId,
  ) async {
    try {
      final snapshot = await _reviews
          .where('freelancerId', isEqualTo: freelancerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Real-time stream of reviews for a freelancer
  Stream<List<ReviewModel>> streamReviewsForFreelancer(
    String freelancerId,
  ) {
    return _reviews
        .where('freelancerId', isEqualTo: freelancerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    });
  }
}
