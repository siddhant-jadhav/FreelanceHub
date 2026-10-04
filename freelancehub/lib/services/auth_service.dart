import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../core/firebase/firebase_config.dart';

/// Dedicated Authentication Service for FreelanceHub.
/// Handles user registration, login, logout, password reset,
/// authentication state changes, and role resolution.
class AuthService {
  final FirebaseAuth? _injectedAuth;
  final FirebaseFirestore? _injectedFirestore;
  final FirebaseDatabase? _injectedRealtimeDb;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseDatabase? realtimeDb,
  })  : _injectedAuth = auth,
        _injectedFirestore = firestore,
        _injectedRealtimeDb = realtimeDb;

  static final AuthService instance = AuthService();

  FirebaseAuth get _auth => _injectedAuth ?? FirebaseConfig.instance.auth;
  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseConfig.instance.firestore;
  FirebaseDatabase get _realtimeDb =>
      _injectedRealtimeDb ?? FirebaseConfig.instance.realtimeDb;

  String? _currentRole;
  String? get currentRole => _currentRole;

  void setCurrentRole(String? role) {
    _currentRole = role;
  }

  /// Current authenticated Firebase user (safe in widget tests)
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Current user ID
  String? get currentUid => currentUser?.uid;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (e) {
      debugPrint('authStateChanges stream notice: $e');
      return const Stream.empty();
    }
  }

  /// Sign Up with Email & Password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'client' or 'freelancer'
    String? referralCode,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        _currentRole = role;
        await user.updateDisplayName(fullName.trim());

        final now = DateTime.now();

        // 1. Write to Cloud Firestore (Primary application database)
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': fullName.trim(),
          'email': email.trim().toLowerCase(),
          'role': role,
          'referralCode': referralCode?.trim() ?? '',
          'profileCompleted': false,
          'onboardingStep': 0,
          'photoUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Also create role-specific initial document in Firestore
        if (role == 'freelancer') {
          await _firestore.collection('freelancers').doc(user.uid).set({
            'userId': user.uid,
            'name': fullName.trim(),
            'title': '',
            'bio': '',
            'skills': <String>[],
            'services': <String>[],
            'hourlyRate': 0.0,
            'rating': 5.0,
            'reviewsCount': 0,
            'completedOrders': 0,
            'isTopRated': false,
            'availability': 'available',
            'portfolio': <Map<String, dynamic>>[],
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          await _firestore.collection('clients').doc(user.uid).set({
            'userId': user.uid,
            'name': fullName.trim(),
            'company': '',
            'country': 'United States',
            'isVerified': true,
            'totalSpent': 0.0,
            'activeProjectsCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // 2. Write to Realtime Database (mirror for backward compatibility)
        try {
          final userRef = _realtimeDb.ref('users/${user.uid}');
          await userRef.set({
            'uid': user.uid,
            'name': fullName.trim(),
            'email': email.trim().toLowerCase(),
            'role': role,
            'referralCode': referralCode?.trim() ?? '',
            'createdAt': now.millisecondsSinceEpoch,
            'updatedAt': now.millisecondsSinceEpoch,
          });

          final username = email.split('@').first.toLowerCase();
          await _realtimeDb.ref('usernames/$username').set(user.uid);
        } catch (e) {
          debugPrint('RTDB mirror notice: $e');
        }
      }

      return credential;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Sign In with Email or Username and Password
  Future<UserCredential> signIn({
    required String identifier,
    required String password,
    String? fallbackRole,
  }) async {
    try {
      String emailToUse = identifier.trim();

      // If identifier is username, look up matching email
      if (!emailToUse.contains('@')) {
        final usernameClean = emailToUse.replaceAll('@', '').toLowerCase();
        try {
          final snapshot = await _realtimeDb.ref('usernames/$usernameClean').get();
          if (snapshot.exists) {
            final uid = snapshot.value as String;
            final userSnapshot = await _realtimeDb.ref('users/$uid/email').get();
            if (userSnapshot.exists) {
              emailToUse = userSnapshot.value as String;
            }
          }
        } catch (_) {}
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final fetchedRole = await getUserRole(user.uid);
        _currentRole = fetchedRole ?? fallbackRole;
      }

      return credential;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Resolve User Role (checks Firestore first, falls back to RTDB)
  Future<String?> getUserRole([String? uid]) async {
    final targetUid = uid ?? currentUser?.uid;
    if (targetUid == null) return _currentRole;

    try {
      // 1. Try Firestore
      final doc = await _firestore.collection('users').doc(targetUid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['role'] != null) {
          _currentRole = data['role'] as String;
          return _currentRole;
        }
      }

      // 2. Fallback to Realtime Database
      final snapshot = await _realtimeDb.ref('users/$targetUid/role').get();
      if (snapshot.exists && snapshot.value is String) {
        _currentRole = snapshot.value as String;
        return _currentRole;
      }
    } catch (e) {
      debugPrint('getUserRole notice: $e');
    }

    return _currentRole;
  }

  /// Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    _currentRole = null;
    try {
      await _auth.signOut();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Automatically provisions the only two application accounts in Firebase Auth & Firestore
  /// Client: vedant@gmail.com
  /// Freelancer: siddhant@gmail.com
  Future<void> ensureDefaultUsersProvisioned() async {
    final originalUser = currentUser;
    try {
      // 1. Provision Vedant (Client)
      String? vedantUid;
      try {
        final clientCred = await _auth.createUserWithEmailAndPassword(
          email: 'vedant@gmail.com',
          password: 'password123',
        );
        vedantUid = clientCred.user?.uid;
        await clientCred.user?.updateDisplayName('Vedant');
      } catch (e) {
        try {
          final loginCred = await _auth.signInWithEmailAndPassword(
            email: 'vedant@gmail.com',
            password: 'password123',
          );
          vedantUid = loginCred.user?.uid;
        } catch (_) {}
      }

      if (vedantUid != null) {
        await _firestore.collection('users').doc(vedantUid).set({
          'uid': vedantUid,
          'fullName': 'Vedant',
          'email': 'vedant@gmail.com',
          'role': 'client',
          'profileCompleted': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await _firestore.collection('clients').doc(vedantUid).set({
          'userId': vedantUid,
          'name': 'Vedant',
          'company': 'Tech Ventures',
          'country': 'India',
          'isVerified': true,
          'totalSpent': 0.0,
          'activeProjectsCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 2. Provision Siddhant (Freelancer)
      String? siddhantUid;
      try {
        final freelancerCred = await _auth.createUserWithEmailAndPassword(
          email: 'siddhant@gmail.com',
          password: 'password123',
        );
        siddhantUid = freelancerCred.user?.uid;
        await freelancerCred.user?.updateDisplayName('Siddhant');
      } catch (e) {
        try {
          final loginCred = await _auth.signInWithEmailAndPassword(
            email: 'siddhant@gmail.com',
            password: 'password123',
          );
          siddhantUid = loginCred.user?.uid;
        } catch (_) {}
      }

      if (siddhantUid != null) {
        await _firestore.collection('users').doc(siddhantUid).set({
          'uid': siddhantUid,
          'fullName': 'Siddhant',
          'email': 'siddhant@gmail.com',
          'role': 'freelancer',
          'profileCompleted': true,
          'onboardingCompleted': true,
          'onboardingStep': 2,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await _firestore.collection('freelancers').doc(siddhantUid).set({
          'userId': siddhantUid,
          'name': 'Siddhant',
          'title': 'Senior Flutter & Full-Stack Developer',
          'bio': 'Specializing in cross-platform Flutter applications, clean architecture, and real-time Firebase backends.',
          'skills': ['Flutter', 'Dart', 'Firebase', 'State Management', 'REST API'],
          'services': ['Mobile App Engineering', 'Full Stack Integration'],
          'hourlyRate': 50.0,
          'rating': 5.0,
          'reviewsCount': 0,
          'completedOrders': 0,
          'isTopRated': true,
          'availability': 'available',
          'portfolio': [],
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Restore session if user was previously signed in, or sign out if no user was signed in
      if (originalUser != null && originalUser.email != null) {
        // Leave as is or re-authenticate if needed
      } else {
        await _auth.signOut();
        _currentRole = null;
      }
    } catch (e) {
      debugPrint('ensureDefaultUsersProvisioned error: $e');
    }
  }
}
