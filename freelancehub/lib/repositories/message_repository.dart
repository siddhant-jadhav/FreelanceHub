import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_exception.dart';
import '../core/firebase/firebase_config.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Repository managing real-time chat, conversations, and messaging.
class MessageRepository {
  final FirebaseFirestore? _injectedFirestore;

  MessageRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  static final MessageRepository instance = MessageRepository();

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseConfig.instance.firestore;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  CollectionReference<Map<String, dynamic>> get _messages =>
      _firestore.collection('messages');

  /// Find existing conversation between two users or create a new one
  Future<String> getOrCreateConversation({
    required String currentUserId,
    required String currentUserName,
    required String recipientUserId,
    required String recipientUserName,
    String? currentPhotoUrl,
    String? recipientPhotoUrl,
    String? projectId,
  }) async {
    try {
      // Query if conversation already exists with these two participants
      final query = await _conversations
          .where('participantIds', arrayContains: currentUserId)
          .get();

      for (final doc in query.docs) {
        final participants = List<String>.from(doc.data()['participantIds'] ?? []);
        if (participants.contains(recipientUserId)) {
          return doc.id;
        }
      }

      // Create new conversation
      final now = DateTime.now();
      final newDoc = await _conversations.add({
        'participantIds': [currentUserId, recipientUserId],
        'participantNames': {
          currentUserId: currentUserName,
          recipientUserId: recipientUserName,
        },
        'participantPhotos': {
          currentUserId: currentPhotoUrl,
          recipientUserId: recipientPhotoUrl,
        },
        'lastMessage': '',
        'lastMessageSenderId': '',
        'lastMessageTime': Timestamp.fromDate(now),
        'unreadCounts': {
          currentUserId: 0,
          recipientUserId: 0,
        },
        'projectId': projectId,
      });

      return newDoc.id;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Send message and update parent conversation snippet & unread count
  Future<void> sendMessage(MessageModel message) async {
    try {
      final batch = _firestore.batch();

      // 1. Add message document
      final msgRef = _messages.doc();
      batch.set(msgRef, message.toMap());

      // 2. Update parent conversation
      final convRef = _conversations.doc(message.conversationId);
      batch.update(convRef, {
        'lastMessage': message.message,
        'lastMessageSenderId': message.senderId,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts.${message.receiverId}': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Real-time message stream for a conversation
  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return _messages
        .where('conversationId', isEqualTo: conversationId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  /// Real-time stream of all conversations for a user
  Stream<List<ConversationModel>> streamUserConversations(String userId) {
    return _conversations
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ConversationModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return list;
    });
  }

  /// Mark conversation as read for the current user
  Future<void> markConversationAsRead(String conversationId, String userId) async {
    try {
      await _conversations.doc(conversationId).update({
        'unreadCounts.$userId': 0,
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
