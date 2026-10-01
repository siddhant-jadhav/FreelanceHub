import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_exception.dart';
import '../core/firebase/firebase_config.dart';
import '../models/notification_model.dart';

/// Repository managing user notifications in Cloud Firestore.
class NotificationRepository {
  final FirebaseFirestore? _injectedFirestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  static final NotificationRepository instance = NotificationRepository();

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseConfig.instance.firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  /// Create and persist a new notification document
  Future<String> createNotification(NotificationModel notification) async {
    try {
      final docRef = await _notifications.add(notification.toMap());
      return docRef.id;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Real-time stream of notifications for a user
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Real-time count of unread notifications
  Stream<int> streamUnreadCount(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notifications.doc(notificationId).update({'isRead': true});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final query = await _notifications
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
