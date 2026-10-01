import 'package:cloud_firestore/cloud_firestore.dart';

/// Client / Buyer Profile model.
class ClientModel {
  final String id; // userId
  final String name;
  final String company;
  final String country;
  final String? photoUrl;
  final bool isVerified;
  final double totalSpent;
  final int activeProjectsCount;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ClientModel({
    required this.id,
    required this.name,
    this.company = '',
    this.country = 'United States',
    this.photoUrl,
    this.isVerified = true,
    this.totalSpent = 0.0,
    this.activeProjectsCount = 0,
    this.preferences = const {},
    required this.createdAt,
    this.updatedAt,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ClientModel(
      id: docId,
      name: (map['name'] as String?) ?? '',
      company: (map['company'] as String?) ?? '',
      country: (map['country'] as String?) ?? 'United States',
      photoUrl: map['photoUrl'] as String?,
      isVerified: (map['isVerified'] as bool?) ?? true,
      totalSpent: (map['totalSpent'] as num?)?.toDouble() ?? 0.0,
      activeProjectsCount: (map['activeProjectsCount'] as num?)?.toInt() ?? 0,
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  factory ClientModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ClientModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': id,
      'name': name,
      'company': company,
      'country': country,
      'photoUrl': photoUrl,
      'isVerified': isVerified,
      'totalSpent': totalSpent,
      'activeProjectsCount': activeProjectsCount,
      'preferences': preferences,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  ClientModel copyWith({
    String? name,
    String? company,
    String? country,
    String? photoUrl,
    bool? isVerified,
    double? totalSpent,
    int? activeProjectsCount,
    Map<String, dynamic>? preferences,
    DateTime? updatedAt,
  }) {
    return ClientModel(
      id: id,
      name: name ?? this.name,
      company: company ?? this.company,
      country: country ?? this.country,
      photoUrl: photoUrl ?? this.photoUrl,
      isVerified: isVerified ?? this.isVerified,
      totalSpent: totalSpent ?? this.totalSpent,
      activeProjectsCount: activeProjectsCount ?? this.activeProjectsCount,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
