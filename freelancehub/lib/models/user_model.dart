import 'package:cloud_firestore/cloud_firestore.dart';

/// User account model representing authenticated clients and freelancers.
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'client' or 'freelancer'
  final String? photoUrl;
  final String? phoneNumber;
  final String? referralCode;
  final int onboardingStep;
  final bool profileCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.photoUrl,
    this.phoneNumber,
    this.referralCode,
    this.onboardingStep = 0,
    this.profileCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isClient => role == 'client';
  bool get isFreelancer => role == 'freelancer';

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return UserModel(
      id: docId,
      email: (map['email'] as String?) ?? '',
      fullName: (map['fullName'] as String?) ?? (map['name'] as String?) ?? '',
      role: (map['role'] as String?) ?? 'client',
      photoUrl: map['photoUrl'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      referralCode: map['referralCode'] as String?,
      onboardingStep: (map['onboardingStep'] as num?)?.toInt() ?? 0,
      profileCompleted: (map['profileCompleted'] as bool?) ?? false,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'referralCode': referralCode,
      'onboardingStep': onboardingStep,
      'profileCompleted': profileCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? fullName,
    String? role,
    String? photoUrl,
    String? phoneNumber,
    String? referralCode,
    int? onboardingStep,
    bool? profileCompleted,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      referralCode: referralCode ?? this.referralCode,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
