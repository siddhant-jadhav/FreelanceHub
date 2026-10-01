import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_exception.dart';
import '../core/firebase/firebase_config.dart';
import '../models/user_model.dart';

/// Repository managing user collection operations in Cloud Firestore.
class UserRepository {
  final FirebaseFirestore? _injectedFirestore;

  UserRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  static final UserRepository instance = UserRepository();

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseConfig.instance.firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Fetch user profile by UID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Real-time stream of user profile changes
  Stream<UserModel?> getUserStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Upsert full user model
  Future<void> saveUser(UserModel user) async {
    try {
      await _users.doc(user.id).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Update partial user attributes
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _users.doc(uid).update(data);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Mark onboarding progress & completion
  Future<void> updateOnboardingProgress(
    String uid, {
    required int step,
    bool completed = false,
  }) async {
    try {
      await _users.doc(uid).update({
        'onboardingStep': step,
        'profileCompleted': completed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Update user profile photo URL
  Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    try {
      await _users.doc(uid).update({
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
