import 'package:cloud_firestore/cloud_firestore.dart';

/// Task / Opportunity posted by clients for freelancers.
class TaskModel {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientCompany;
  final String? clientCountry;
  final String title;
  final String description;
  final String category;
  final List<String> requiredSkills;
  final double budget;
  final String budgetType; // 'fixed' or 'hourly'
  final DateTime deadline;
  final String status; // 'open', 'in_progress', 'completed', 'cancelled'
  final int offersCount;
  final List<String> attachments;
  final String experienceLevel;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TaskModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientCompany,
    this.clientCountry = 'United States',
    required this.title,
    required this.description,
    required this.category,
    this.requiredSkills = const [],
    required this.budget,
    this.budgetType = 'fixed',
    required this.deadline,
    this.status = 'open',
    this.offersCount = 0,
    this.attachments = const [],
    this.experienceLevel = 'Mid (3-5 yrs)',
    required this.createdAt,
    this.updatedAt,
  });

  bool get isOpen => status == 'open';

  factory TaskModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return TaskModel(
      id: docId,
      clientId: (map['clientId'] as String?) ?? '',
      clientName: (map['clientName'] as String?) ?? '',
      clientCompany: map['clientCompany'] as String?,
      clientCountry: (map['clientCountry'] as String?) ?? 'United States',
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'General',
      requiredSkills: List<String>.from(map['requiredSkills'] ?? []),
      budget: (map['budget'] as num?)?.toDouble() ?? 0.0,
      budgetType: (map['budgetType'] as String?) ?? 'fixed',
      deadline: parseDate(map['deadline']),
      status: (map['status'] as String?) ?? 'open',
      offersCount: (map['offersCount'] as num?)?.toInt() ?? 0,
      attachments: List<String>.from(map['attachments'] ?? []),
      experienceLevel: (map['experienceLevel'] as String?) ?? 'Mid (3-5 yrs)',
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  factory TaskModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return TaskModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientCompany': clientCompany,
      'clientCountry': clientCountry,
      'title': title,
      'description': description,
      'category': category,
      'requiredSkills': requiredSkills,
      'budget': budget,
      'budgetType': budgetType,
      'deadline': Timestamp.fromDate(deadline),
      'status': status,
      'offersCount': offersCount,
      'attachments': attachments,
      'experienceLevel': experienceLevel,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  TaskModel copyWith({
    String? title,
    String? description,
    String? category,
    List<String>? requiredSkills,
    double? budget,
    String? budgetType,
    DateTime? deadline,
    String? status,
    int? offersCount,
    List<String>? attachments,
    String? experienceLevel,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id,
      clientId: clientId,
      clientName: clientName,
      clientCompany: clientCompany,
      clientCountry: clientCountry,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      budget: budget ?? this.budget,
      budgetType: budgetType ?? this.budgetType,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      offersCount: offersCount ?? this.offersCount,
      attachments: attachments ?? this.attachments,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
