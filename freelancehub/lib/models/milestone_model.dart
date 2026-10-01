import 'package:cloud_firestore/cloud_firestore.dart';

/// Milestone within a project order. Tracks escrow funding, deliverables, and release.
class MilestoneModel {
  final String id;
  final String projectId;
  final int milestoneNumber;
  final String title;
  final String description;
  final double amount;
  final DateTime dueDate;
  final String status; // 'pending', 'funded_in_escrow', 'submitted', 'approved', 'released'
  final String? deliverableNote;
  final String? deliverableFileUrl;
  final String? deliverableFileName;
  final DateTime? submittedAt;
  final DateTime? approvedAt;

  const MilestoneModel({
    required this.id,
    required this.projectId,
    required this.milestoneNumber,
    required this.title,
    this.description = '',
    required this.amount,
    required this.dueDate,
    this.status = 'pending',
    this.deliverableNote,
    this.deliverableFileUrl,
    this.deliverableFileName,
    this.submittedAt,
    this.approvedAt,
  });

  bool get isApproved => status == 'approved' || status == 'released';
  bool get isSubmitted => status == 'submitted';
  bool get isFunded => status == 'funded_in_escrow';

  factory MilestoneModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return MilestoneModel(
      id: docId,
      projectId: (map['projectId'] as String?) ?? '',
      milestoneNumber: (map['milestoneNumber'] as num?)?.toInt() ?? 1,
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: parseDate(map['dueDate']),
      status: (map['status'] as String?) ?? 'pending',
      deliverableNote: map['deliverableNote'] as String?,
      deliverableFileUrl: map['deliverableFileUrl'] as String?,
      deliverableFileName: map['deliverableFileName'] as String?,
      submittedAt: map['submittedAt'] != null ? parseDate(map['submittedAt']) : null,
      approvedAt: map['approvedAt'] != null ? parseDate(map['approvedAt']) : null,
    );
  }

  factory MilestoneModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return MilestoneModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'milestoneNumber': milestoneNumber,
      'title': title,
      'description': description,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'deliverableNote': deliverableNote,
      'deliverableFileUrl': deliverableFileUrl,
      'deliverableFileName': deliverableFileName,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    };
  }

  MilestoneModel copyWith({
    String? status,
    String? deliverableNote,
    String? deliverableFileUrl,
    String? deliverableFileName,
    DateTime? submittedAt,
    DateTime? approvedAt,
  }) {
    return MilestoneModel(
      id: id,
      projectId: projectId,
      milestoneNumber: milestoneNumber,
      title: title,
      description: description,
      amount: amount,
      dueDate: dueDate,
      status: status ?? this.status,
      deliverableNote: deliverableNote ?? this.deliverableNote,
      deliverableFileUrl: deliverableFileUrl ?? this.deliverableFileUrl,
      deliverableFileName: deliverableFileName ?? this.deliverableFileName,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }
}
