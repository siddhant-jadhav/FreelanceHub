import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  String? _currentRole; // 'client' or 'freelancer'
  String? get currentRole => _currentRole;

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseDatabase get database => FirebaseDatabase.instance;

  User? get currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    try {
      return FirebaseAuth.instance.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  void setCurrentRole(String? role) {
    _currentRole = role;
  }

  /// Sign Up with Email and Password & store profile in Realtime Database.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'client' or 'freelancer'
    String? referralCode,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      _currentRole = role;
      await user.updateDisplayName(fullName.trim());

      // Save user profile to Realtime Database
      final userRef = database.ref('users/${user.uid}');
      await userRef.set({
        'uid': user.uid,
        'name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'role': role,
        'referralCode': referralCode?.trim() ?? '',
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      // Index username if applicable
      final username = email.split('@').first.toLowerCase();
      await database.ref('usernames/$username').set(user.uid);
    }

    return credential;
  }

  /// Sign In with Email or Username and Password, and cache user role.
  Future<UserCredential> signIn({
    required String identifier,
    required String password,
    String? fallbackRole,
  }) async {
    String emailToUse = identifier.trim();

    // If identifier is a username rather than an email, look up the email
    if (!emailToUse.contains('@')) {
      final usernameClean = emailToUse.replaceAll('@', '').toLowerCase();
      final snapshot = await database.ref('usernames/$usernameClean').get();
      if (snapshot.exists) {
        final uid = snapshot.value as String;
        final userSnapshot = await database.ref('users/$uid/email').get();
        if (userSnapshot.exists) {
          emailToUse = userSnapshot.value as String;
        }
      }
    }

    final credential = await auth.signInWithEmailAndPassword(
      email: emailToUse,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      final fetchedRole = await getUserRole(user.uid);
      _currentRole = fetchedRole ?? fallbackRole;
    }

    return credential;
  }

  /// Retrieve user role from Realtime Database.
  Future<String?> getUserRole([String? uid]) async {
    final targetUid = uid ?? currentUser?.uid;
    if (targetUid == null) return _currentRole;
    try {
      final snapshot = await database.ref('users/$targetUid/role').get();
      if (snapshot.exists && snapshot.value is String) {
        _currentRole = snapshot.value as String;
        return _currentRole;
      }
    } catch (_) {}
    return _currentRole;
  }

  /// Retrieve user profile from Realtime Database.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final snapshot = await database.ref('users/$uid').get();
      if (snapshot.exists && snapshot.value is Map) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (_) {}
    return null;
  }

  /// Sign Out
  Future<void> signOut() async {
    _currentRole = null;
    try {
      await auth.signOut();
    } catch (_) {}
  }
}
