import 'package:cloud_firestore/cloud_firestore.dart';

/// Custom Proposal / Offer submitted by a freelancer for a Task.
class ProposalModel {
  final String id;
  final String taskId;
  final String taskTitle;
  final String freelancerId;
  final String freelancerName;
  final String? freelancerTitle;
  final double freelancerRating;
  final String clientId;
  final double proposedPrice;
  final int deliveryTimeDays;
  final String coverLetter;
  final List<Map<String, dynamic>> milestones;
  final String status; // 'pending', 'accepted', 'rejected', 'withdrawn'
  final DateTime createdAt;

  const ProposalModel({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.freelancerId,
    required this.freelancerName,
    this.freelancerTitle,
    this.freelancerRating = 5.0,
    required this.clientId,
    required this.proposedPrice,
    required this.deliveryTimeDays,
    required this.coverLetter,
    this.milestones = const [],
    this.status = 'pending',
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  factory ProposalModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawMilestones = map['milestones'] as List<dynamic>? ?? [];
    final milestoneList = rawMilestones
        .whereType<Map<String, dynamic>>()
        .toList();

    return ProposalModel(
      id: docId,
      taskId: (map['taskId'] as String?) ?? '',
      taskTitle: (map['taskTitle'] as String?) ?? '',
      freelancerId: (map['freelancerId'] as String?) ?? '',
      freelancerName: (map['freelancerName'] as String?) ?? '',
      freelancerTitle: map['freelancerTitle'] as String?,
      freelancerRating: (map['freelancerRating'] as num?)?.toDouble() ?? 5.0,
      clientId: (map['clientId'] as String?) ?? '',
      proposedPrice: (map['proposedPrice'] as num?)?.toDouble() ?? 0.0,
      deliveryTimeDays: (map['deliveryTimeDays'] as num?)?.toInt() ?? 7,
      coverLetter: (map['coverLetter'] as String?) ?? '',
      milestones: milestoneList,
      status: (map['status'] as String?) ?? 'pending',
      createdAt: parseDate(map['createdAt']),
    );
  }

  factory ProposalModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ProposalModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'taskTitle': taskTitle,
      'freelancerId': freelancerId,
      'freelancerName': freelancerName,
      'freelancerTitle': freelancerTitle,
      'freelancerRating': freelancerRating,
      'clientId': clientId,
      'proposedPrice': proposedPrice,
      'deliveryTimeDays': deliveryTimeDays,
      'coverLetter': coverLetter,
      'milestones': milestones,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ProposalModel copyWith({
    String? status,
    double? proposedPrice,
    int? deliveryTimeDays,
    String? coverLetter,
    List<Map<String, dynamic>>? milestones,
  }) {
    return ProposalModel(
      id: id,
      taskId: taskId,
      taskTitle: taskTitle,
      freelancerId: freelancerId,
      freelancerName: freelancerName,
      freelancerTitle: freelancerTitle,
      freelancerRating: freelancerRating,
      clientId: clientId,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      deliveryTimeDays: deliveryTimeDays ?? this.deliveryTimeDays,
      coverLetter: coverLetter ?? this.coverLetter,
      milestones: milestones ?? this.milestones,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
