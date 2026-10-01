import 'package:cloud_firestore/cloud_firestore.dart';

/// Conversation thread grouping messages between two participants.
class ConversationModel {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotos;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts;
  final String? projectId;

  const ConversationModel({
    required this.id,
    required this.participantIds,
    this.participantNames = const {},
    this.participantPhotos = const {},
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageTime,
    this.unreadCounts = const {},
    this.projectId,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawNames = map['participantNames'] as Map<dynamic, dynamic>? ?? {};
    final names = rawNames.map((k, v) => MapEntry(k.toString(), v.toString()));

    final rawPhotos = map['participantPhotos'] as Map<dynamic, dynamic>? ?? {};
    final photos = rawPhotos.map((k, v) => MapEntry(k.toString(), v?.toString()));

    final rawUnread = map['unreadCounts'] as Map<dynamic, dynamic>? ?? {};
    final unreads = rawUnread.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));

    return ConversationModel(
      id: docId,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: names,
      participantPhotos: photos,
      lastMessage: (map['lastMessage'] as String?) ?? '',
      lastMessageSenderId: (map['lastMessageSenderId'] as String?) ?? '',
      lastMessageTime: parseDate(map['lastMessageTime']),
      unreadCounts: unreads,
      projectId: map['projectId'] as String?,
    );
  }

  factory ConversationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ConversationModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCounts': unreadCounts,
      'projectId': projectId,
    };
  }

  String getOtherParticipantName(String currentUserId) {
    for (final entry in participantNames.entries) {
      if (entry.key != currentUserId) return entry.value;
    }
    return 'Chat';
  }
}
