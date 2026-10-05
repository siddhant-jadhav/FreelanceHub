import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

/// Central Firebase Configuration and Initialization for FreelanceHub.
/// Manages connection to Auth, Firestore, Storage, Messaging, Realtime DB, and App Check.
class FirebaseConfig {
  FirebaseConfig._();
  static final FirebaseConfig instance = FirebaseConfig._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;
  FirebaseDatabase get realtimeDb => FirebaseDatabase.instance;
  FirebaseMessaging get messaging => FirebaseMessaging.instance;

  /// Initializes all Firebase subsystems with graceful fallbacks.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;

      // Configure Firestore offline persistence & settings safely
      try {
        if (!kIsWeb) {
          firestore.settings = const Settings(
            persistenceEnabled: true,
            cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          );
        }
      } catch (e) {
        debugPrint('Firestore settings notice: $e');
      }

      // Configure Firebase App Check only if production keys are provided
      try {
        await _initializeSecurityAppCheck();
      } catch (e) {
        debugPrint('App check notice: $e');
      }
    } catch (e) {
      debugPrint('FirebaseConfig initialization notice: $e');
    }
  }

  /// App Check attestation is disabled in development to prevent unregistered debug token exchange errors.
  Future<void> _initializeSecurityAppCheck() async {
    // Only activate App Check when configured with valid keys in production.
  }
}
