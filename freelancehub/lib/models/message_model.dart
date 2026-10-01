import 'package:cloud_firestore/cloud_firestore.dart';

/// Single direct message between client and freelancer.
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String message;
  final String? attachmentUrl;
  final String? attachmentName;
  final bool isRead;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.attachmentUrl,
    this.attachmentName,
    this.isRead = false,
    required this.createdAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return MessageModel(
      id: docId,
      conversationId: (map['conversationId'] as String?) ?? '',
      senderId: (map['senderId'] as String?) ?? '',
      receiverId: (map['receiverId'] as String?) ?? '',
      message: (map['message'] as String?) ?? '',
      attachmentUrl: map['attachmentUrl'] as String?,
      attachmentName: map['attachmentName'] as String?,
      isRead: (map['isRead'] as bool?) ?? false,
      createdAt: parseDate(map['createdAt']),
    );
  }

  factory MessageModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return MessageModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
