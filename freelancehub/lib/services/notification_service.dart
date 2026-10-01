import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../core/firebase/firebase_config.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

/// Dedicated service managing Firebase Cloud Messaging (FCM) and application alerts.
class NotificationService {
  final FirebaseMessaging? _injectedMessaging;
  final FirebaseFirestore? _injectedFirestore;
  final NotificationRepository? _injectedNotificationRepo;

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    NotificationRepository? notificationRepo,
  })  : _injectedMessaging = messaging,
        _injectedFirestore = firestore,
        _injectedNotificationRepo = notificationRepo;

  static final NotificationService instance = NotificationService();

  FirebaseMessaging get _messaging =>
      _injectedMessaging ?? FirebaseConfig.instance.messaging;
  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseConfig.instance.firestore;
  NotificationRepository get _notificationRepo =>
      _injectedNotificationRepo ?? NotificationRepository.instance;

  /// Initialize FCM permissions and token listener
  Future<void> initialize({required String currentUserId}) async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await _messaging.getToken();
        if (token != null) {
          await saveDeviceToken(currentUserId, token);
        }

        // Listen for token refreshes
        _messaging.onTokenRefresh.listen((newToken) {
          saveDeviceToken(currentUserId, newToken);
        });

        // Foreground message handler
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint(
            'Received foreground push: ${message.notification?.title}',
          );
        });
      }
    } catch (e) {
      debugPrint('FCM initialization notice: $e');
    }
  }

  /// Persist device FCM token to user document
  Future<void> saveDeviceToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastFcmUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  // --- Domain Notification Triggers ---

  Future<void> notifyNewProposal({
    required String clientUserId,
    required String freelancerName,
    required String taskTitle,
    required String taskId,
  }) async {
    await _notificationRepo.createNotification(
      NotificationModel(
        id: '',
        userId: clientUserId,
        type: 'new_proposal',
        title: 'New Custom Offer',
        message: '$freelancerName submitted a proposal for "$taskTitle".',
        referenceId: taskId,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> notifyProposalAccepted({
    required String freelancerUserId,
    required String clientName,
    required String taskTitle,
    required String projectId,
  }) async {
    await _notificationRepo.createNotification(
      NotificationModel(
        id: '',
        userId: freelancerUserId,
        type: 'proposal_accepted',
        title: 'Proposal Accepted! 🎉',
        message: '$clientName accepted your proposal for "$taskTitle".',
        referenceId: projectId,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> notifyNewMessage({
    required String recipientUserId,
    required String senderName,
    required String messageSnippet,
    required String conversationId,
  }) async {
    await _notificationRepo.createNotification(
      NotificationModel(
        id: '',
        userId: recipientUserId,
        type: 'new_message',
        title: 'Message from $senderName',
        message: messageSnippet,
        referenceId: conversationId,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> notifyMilestoneSubmitted({
    required String clientUserId,
    required String freelancerName,
    required String milestoneTitle,
    required String projectId,
  }) async {
    await _notificationRepo.createNotification(
      NotificationModel(
        id: '',
        userId: clientUserId,
        type: 'milestone_submitted',
        title: 'Deliverable Submitted',
        message:
            '$freelancerName submitted "$milestoneTitle" for your review.',
        referenceId: projectId,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> notifyMilestoneApproved({
    required String freelancerUserId,
    required String milestoneTitle,
    required double amount,
    required String projectId,
  }) async {
    await _notificationRepo.createNotification(
      NotificationModel(
        id: '',
        userId: freelancerUserId,
        type: 'milestone_approved',
        title: 'Milestone Approved! 💰',
        message:
            '"$milestoneTitle" approved. \$${amount.toStringAsFixed(2)} released from escrow.',
        referenceId: projectId,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> notifyRevisionRequested({
    required String freelancerUserId,
    required String clientName,
    required String milestoneTitle,
    required String projectId,
  }) async {
    await _notificationRepo.createNotification(
      NotificationModel(
        id: '',
        userId: freelancerUserId,
        type: 'revision_requested',
        title: 'Revision Requested',
        message:
            '$clientName requested revisions on milestone "$milestoneTitle".',
        referenceId: projectId,
        createdAt: DateTime.now(),
      ),
    );
  }
}
