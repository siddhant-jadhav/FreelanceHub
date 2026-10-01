import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification model for user push and in-app alerts.
class NotificationModel {
  final String id;
  final String userId;
  final String type; // 'new_proposal', 'proposal_accepted', 'new_message', 'milestone_submitted', etc.
  final String title;
  final String message;
  final String? referenceId; // e.g. projectId, taskId, conversationId
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.referenceId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return NotificationModel(
      id: docId,
      userId: (map['userId'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'general',
      title: (map['title'] as String?) ?? '',
      message: (map['message'] as String?) ?? '',
      referenceId: map['referenceId'] as String?,
      isRead: (map['isRead'] as bool?) ?? false,
      createdAt: parseDate(map['createdAt']),
    );
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return NotificationModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'referenceId': referenceId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
