import 'package:cloud_firestore/cloud_firestore.dart';

/// Contract Project model representing active work orders between client & freelancer.
class ProjectModel {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientCompany;
  final String freelancerId;
  final String freelancerName;
  final String? taskId;
  final String title;
  final String tier; // 'Basic', 'Standard', 'Premium'
  final double budget;
  final double progress; // 0.0 to 1.0
  final int totalMilestones;
  final int completedMilestones;
  final String status; // 'in_progress', 'in_revision', 'delivered', 'completed', 'cancelled'
  final DateTime startedDate;
  final DateTime dueDate;
  final String? clientBrief;
  final String? deliveredFileName;
  final String? deliveredFileUrl;
  final String? deliveredFileSize;
  final String? deliveryNote;
  final bool hasWatermark;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProjectModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientCompany,
    required this.freelancerId,
    required this.freelancerName,
    this.taskId,
    required this.title,
    this.tier = 'Standard',
    required this.budget,
    this.progress = 0.0,
    this.totalMilestones = 1,
    this.completedMilestones = 0,
    this.status = 'in_progress',
    required this.startedDate,
    required this.dueDate,
    this.clientBrief,
    this.deliveredFileName,
    this.deliveredFileUrl,
    this.deliveredFileSize,
    this.deliveryNote,
    this.hasWatermark = true,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isInProgress => status == 'in_progress';
  bool get isInRevision => status == 'in_revision';
  bool get isDelivered => status == 'delivered';
  bool get isCompleted => status == 'completed';

  factory ProjectModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ProjectModel(
      id: docId,
      clientId: (map['clientId'] as String?) ?? '',
      clientName: (map['clientName'] as String?) ?? '',
      clientCompany: map['clientCompany'] as String?,
      freelancerId: (map['freelancerId'] as String?) ?? '',
      freelancerName: (map['freelancerName'] as String?) ?? '',
      taskId: map['taskId'] as String?,
      title: (map['title'] as String?) ?? '',
      tier: (map['tier'] as String?) ?? 'Standard',
      budget: (map['budget'] as num?)?.toDouble() ?? 0.0,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      totalMilestones: (map['totalMilestones'] as num?)?.toInt() ?? 1,
      completedMilestones: (map['completedMilestones'] as num?)?.toInt() ?? 0,
      status: (map['status'] as String?) ?? 'in_progress',
      startedDate: parseDate(map['startedDate']),
      dueDate: parseDate(map['dueDate']),
      clientBrief: map['clientBrief'] as String?,
      deliveredFileName: map['deliveredFileName'] as String?,
      deliveredFileUrl: map['deliveredFileUrl'] as String?,
      deliveredFileSize: map['deliveredFileSize'] as String?,
      deliveryNote: map['deliveryNote'] as String?,
      hasWatermark: (map['hasWatermark'] as bool?) ?? true,
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  factory ProjectModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ProjectModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientCompany': clientCompany,
      'freelancerId': freelancerId,
      'freelancerName': freelancerName,
      'taskId': taskId,
      'title': title,
      'tier': tier,
      'budget': budget,
      'progress': progress,
      'totalMilestones': totalMilestones,
      'completedMilestones': completedMilestones,
      'status': status,
      'startedDate': Timestamp.fromDate(startedDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'clientBrief': clientBrief,
      'deliveredFileName': deliveredFileName,
      'deliveredFileUrl': deliveredFileUrl,
      'deliveredFileSize': deliveredFileSize,
      'deliveryNote': deliveryNote,
      'hasWatermark': hasWatermark,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  ProjectModel copyWith({
    String? status,
    double? progress,
    int? completedMilestones,
    String? deliveredFileName,
    String? deliveredFileUrl,
    String? deliveredFileSize,
    String? deliveryNote,
    bool? hasWatermark,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id,
      clientId: clientId,
      clientName: clientName,
      clientCompany: clientCompany,
      freelancerId: freelancerId,
      freelancerName: freelancerName,
      taskId: taskId,
      title: title,
      tier: tier,
      budget: budget,
      progress: progress ?? this.progress,
      totalMilestones: totalMilestones,
      completedMilestones: completedMilestones ?? this.completedMilestones,
      status: status ?? this.status,
      startedDate: startedDate,
      dueDate: dueDate,
      clientBrief: clientBrief,
      deliveredFileName: deliveredFileName ?? this.deliveredFileName,
      deliveredFileUrl: deliveredFileUrl ?? this.deliveredFileUrl,
      deliveredFileSize: deliveredFileSize ?? this.deliveredFileSize,
      deliveryNote: deliveryNote ?? this.deliveryNote,
      hasWatermark: hasWatermark ?? this.hasWatermark,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
