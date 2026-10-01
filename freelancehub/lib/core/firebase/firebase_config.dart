import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
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

      // Configure Firestore offline persistence & settings
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Configure Firebase App Check if in supported platform
      await _initializeSecurityAppCheck();

      _isInitialized = true;
    } catch (e) {
      debugPrint('FirebaseConfig initialization notice: $e');
    }
  }

  /// Configures App Check for attestation security without blocking dev environments
  Future<void> _initializeSecurityAppCheck() async {
    try {
      if (kIsWeb) {
        // Web reCAPTCHA or debug provider
        await FirebaseAppCheck.instance.activate(
          providerWeb: ReCaptchaV3Provider('recaptcha-v3-site-key'),
        );
      } else {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleDeviceCheckProvider(),
        );
      }
    } catch (e) {
      debugPrint('App Check activation skipped/unsupported: $e');
    }
  }
}
