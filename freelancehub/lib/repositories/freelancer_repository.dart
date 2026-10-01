import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_exception.dart';
import '../core/firebase/firebase_config.dart';
import '../models/freelancer_model.dart';

/// Repository managing freelancer collection and marketplace queries.
class FreelancerRepository {
  final FirebaseFirestore? _injectedFirestore;

  FreelancerRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  static final FreelancerRepository instance = FreelancerRepository();

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseConfig.instance.firestore;

  CollectionReference<Map<String, dynamic>> get _freelancers =>
      _firestore.collection('freelancers');

  /// Get single freelancer by UID
  Future<FreelancerModel?> getFreelancer(String uid) async {
    try {
      final doc = await _freelancers.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return FreelancerModel.fromFirestore(doc);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Real-time stream of freelancer profile
  Stream<FreelancerModel?> getFreelancerStream(String uid) {
    return _freelancers.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return FreelancerModel.fromFirestore(doc);
    });
  }

  /// Upsert full freelancer record
  Future<void> saveFreelancer(FreelancerModel freelancer) async {
    try {
      await _freelancers
          .doc(freelancer.id)
          .set(freelancer.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Update partial freelancer fields
  Future<void> updateFreelancer(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _freelancers.doc(uid).update(data);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Update freelancer profile header info
  Future<void> updateProfile(
    String uid, {
    String? title,
    String? bio,
    String? availability,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (bio != null) data['bio'] = bio;
    if (availability != null) data['availability'] = availability;
    if (data.isNotEmpty) {
      await updateFreelancer(uid, data);
    }
  }

  /// Update skills
  Future<void> updateSkills(String uid, List<String> skills) async {
    await updateFreelancer(uid, {'skills': skills});
  }

  /// Update hourly rate
  Future<void> updateRate(String uid, double rate) async {
    await updateFreelancer(uid, {'hourlyRate': rate});
  }

  /// Stream of freelancers for client explore and marketplace
  Stream<List<FreelancerModel>> streamFreelancers({
    String? category,
    int limit = 20,
  }) {
    Query<Map<String, dynamic>> query = _freelancers;

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('categories', arrayContains: category);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FreelancerModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Fetch top-rated vetted freelancers
  Future<List<FreelancerModel>> getTopRatedFreelancers({int limit = 10}) async {
    try {
      final snapshot = await _freelancers
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FreelancerModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Search and filter freelancers
  Future<List<FreelancerModel>> searchFreelancers({
    String? query,
    String? category,
    String? experienceLevel,
    double? maxHourlyRate,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> ref = _freelancers;

      if (category != null && category.isNotEmpty && category != 'All') {
        ref = ref.where('categories', arrayContains: category);
      }
      if (experienceLevel != null && experienceLevel != 'All Levels') {
        ref = ref.where('experienceLevel', isEqualTo: experienceLevel);
      }
      if (maxHourlyRate != null && maxHourlyRate > 0) {
        ref = ref.where('hourlyRate', isLessThanOrEqualTo: maxHourlyRate);
      }

      final snapshot = await ref.limit(limit).get();
      var results = snapshot.docs
          .map((doc) => FreelancerModel.fromFirestore(doc))
          .toList();

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        results = results.where((f) {
          return f.name.toLowerCase().contains(q) ||
              f.title.toLowerCase().contains(q) ||
              f.bio.toLowerCase().contains(q) ||
              f.skills.any((s) => s.toLowerCase().contains(q));
        }).toList();
      }

      return results;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Add portfolio item to freelancer profile
  Future<void> addPortfolioItem(String uid, PortfolioItem item) async {
    try {
      await _freelancers.doc(uid).update({
        'portfolio': FieldValue.arrayUnion([item.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Remove portfolio item from freelancer profile
  Future<void> removePortfolioItem(String uid, PortfolioItem item) async {
    try {
      await _freelancers.doc(uid).update({
        'portfolio': FieldValue.arrayRemove([item.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
