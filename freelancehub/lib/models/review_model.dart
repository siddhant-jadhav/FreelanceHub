import 'package:cloud_firestore/cloud_firestore.dart';

/// Client review and rating left for a freelancer upon project completion.
class ReviewModel {
  final String id;
  final String projectId;
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final String freelancerId;
  final double rating; // 1.0 to 5.0
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.projectId,
    required this.clientId,
    required this.clientName,
    this.clientPhotoUrl,
    required this.freelancerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ReviewModel(
      id: docId,
      projectId: (map['projectId'] as String?) ?? '',
      clientId: (map['clientId'] as String?) ?? '',
      clientName: (map['clientName'] as String?) ?? '',
      clientPhotoUrl: map['clientPhotoUrl'] as String?,
      freelancerId: (map['freelancerId'] as String?) ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: (map['comment'] as String?) ?? '',
      createdAt: parseDate(map['createdAt']),
    );
  }

  factory ReviewModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ReviewModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'clientId': clientId,
      'clientName': clientName,
      'clientPhotoUrl': clientPhotoUrl,
      'freelancerId': freelancerId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
