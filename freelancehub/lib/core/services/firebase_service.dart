import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../repositories/client_repository.dart';
import '../../repositories/freelancer_repository.dart';
import '../../repositories/message_repository.dart';
import '../../repositories/milestone_repository.dart';
import '../../repositories/notification_repository.dart';
import '../../repositories/payment_repository.dart';
import '../../repositories/project_repository.dart';
import '../../repositories/proposal_repository.dart';
import '../../repositories/review_repository.dart';
import '../../repositories/task_repository.dart';
import '../../repositories/user_repository.dart';
import '../../services/auth_service.dart';
import '../../services/client_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../firebase/firebase_config.dart';

/// Central Gateway bridging the new Firebase Service Layer with FreelanceHub app components.
/// Ensures complete backward compatibility for existing screens while providing
/// access to domain services, Cloud Firestore repositories, Storage, and Messaging.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  // Core Firebase handles
  FirebaseAuth get auth => FirebaseConfig.instance.auth;
  FirebaseFirestore get firestore => FirebaseConfig.instance.firestore;
  FirebaseStorage get storage => FirebaseConfig.instance.storage;
  FirebaseDatabase get database => FirebaseConfig.instance.realtimeDb;

  // Services
  AuthService get authService => AuthService.instance;
  ClientService get clientService => ClientService.instance;
  FirestoreService get firestoreService => FirestoreService.instance;
  StorageService get storageService => StorageService.instance;
  NotificationService get notificationService => NotificationService.instance;

  // Repositories
  UserRepository get userRepository => UserRepository.instance;
  FreelancerRepository get freelancerRepository => FreelancerRepository.instance;
  ClientRepository get clientRepository => ClientRepository.instance;
  TaskRepository get taskRepository => TaskRepository.instance;
  ProposalRepository get proposalRepository => ProposalRepository.instance;
  ProjectRepository get projectRepository => ProjectRepository.instance;
  MilestoneRepository get milestoneRepository => MilestoneRepository.instance;
  MessageRepository get messageRepository => MessageRepository.instance;
  NotificationRepository get notificationRepository => NotificationRepository.instance;
  PaymentRepository get paymentRepository => PaymentRepository.instance;
  ReviewRepository get reviewRepository => ReviewRepository.instance;

  // Role and Auth state delegation
  String? get currentRole => authService.currentRole;
  User? get currentUser => authService.currentUser;
  Stream<User?> get authStateChanges => authService.authStateChanges;

  void setCurrentRole(String? role) {
    authService.setCurrentRole(role);
  }

  /// Sign Up with Email and Password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? referralCode,
  }) {
    return authService.signUp(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      referralCode: referralCode,
    );
  }

  /// Sign In with Email or Username and Password
  Future<UserCredential> signIn({
    required String identifier,
    required String password,
    String? fallbackRole,
  }) {
    return authService.signIn(
      identifier: identifier,
      password: password,
      fallbackRole: fallbackRole,
    );
  }

  /// Retrieve user role
  Future<String?> getUserRole([String? uid]) {
    return authService.getUserRole(uid);
  }

  /// Retrieve user profile from Realtime Database or Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      // Check Firestore first
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }

      // Fallback to RTDB
      final snapshot = await database.ref('users/$uid').get();
      if (snapshot.exists && snapshot.value is Map) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (_) {}
    return null;
  }

  /// Sign Out
  Future<void> signOut() {
    return authService.signOut();
  }

  /// Provision the two application accounts
  Future<void> ensureDefaultUsersProvisioned() {
    return authService.ensureDefaultUsersProvisioned();
  }
}
