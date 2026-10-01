import 'package:cloud_firestore/cloud_firestore.dart';

/// Single portfolio project or asset item uploaded by a freelancer.
class PortfolioItem {
  final String id;
  final String title;
  final String? description;
  final String? projectUrl;
  final String? imageUrl;
  final List<String> tags;

  const PortfolioItem({
    required this.id,
    required this.title,
    this.description,
    this.projectUrl,
    this.imageUrl,
    this.tags = const [],
  });

  factory PortfolioItem.fromMap(Map<String, dynamic> map) {
    return PortfolioItem(
      id: (map['id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      description: map['description'] as String?,
      projectUrl: map['projectUrl'] as String?,
      imageUrl: map['imageUrl'] as String?,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'projectUrl': projectUrl,
      'imageUrl': imageUrl,
      'tags': tags,
    };
  }
}

/// Comprehensive Freelancer Profile model.
class FreelancerModel {
  final String id; // userId
  final String name;
  final String title;
  final String bio;
  final String? photoUrl;
  final List<String> skills;
  final List<String> services;
  final List<String> categories;
  final String experienceLevel; // 'Entry', 'Intermediate', 'Expert'
  final List<String> languages;
  final double hourlyRate;
  final double startingPrice;
  final String currency;
  final double rating;
  final int reviewsCount;
  final int completedOrders;
  final bool isTopRated;
  final String availability; // 'available', 'busy', 'unavailable'
  final List<PortfolioItem> portfolio;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FreelancerModel({
    required this.id,
    required this.name,
    required this.title,
    required this.bio,
    this.photoUrl,
    this.skills = const [],
    this.services = const [],
    this.categories = const [],
    this.experienceLevel = 'Intermediate',
    this.languages = const ['English'],
    this.hourlyRate = 45.0,
    this.startingPrice = 100.0,
    this.currency = 'USD',
    this.rating = 5.0,
    this.reviewsCount = 0,
    this.completedOrders = 0,
    this.isTopRated = false,
    this.availability = 'available',
    this.portfolio = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory FreelancerModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawPortfolio = map['portfolio'] as List<dynamic>? ?? [];
    final portfolioList = rawPortfolio
        .whereType<Map<String, dynamic>>()
        .map((p) => PortfolioItem.fromMap(p))
        .toList();

    return FreelancerModel(
      id: docId,
      name: (map['name'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      bio: (map['bio'] as String?) ?? '',
      photoUrl: map['photoUrl'] as String?,
      skills: List<String>.from(map['skills'] ?? []),
      services: List<String>.from(map['services'] ?? []),
      categories: List<String>.from(map['categories'] ?? []),
      experienceLevel: (map['experienceLevel'] as String?) ?? 'Intermediate',
      languages: List<String>.from(map['languages'] ?? ['English']),
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 45.0,
      startingPrice: (map['startingPrice'] as num?)?.toDouble() ?? 100.0,
      currency: (map['currency'] as String?) ?? 'USD',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      reviewsCount: (map['reviewsCount'] as num?)?.toInt() ?? 0,
      completedOrders: (map['completedOrders'] as num?)?.toInt() ?? 0,
      isTopRated: (map['isTopRated'] as bool?) ?? false,
      availability: (map['availability'] as String?) ?? 'available',
      portfolio: portfolioList,
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  factory FreelancerModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return FreelancerModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': id,
      'name': name,
      'title': title,
      'bio': bio,
      'photoUrl': photoUrl,
      'skills': skills,
      'services': services,
      'categories': categories,
      'experienceLevel': experienceLevel,
      'languages': languages,
      'hourlyRate': hourlyRate,
      'startingPrice': startingPrice,
      'currency': currency,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'completedOrders': completedOrders,
      'isTopRated': isTopRated,
      'availability': availability,
      'portfolio': portfolio.map((p) => p.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  FreelancerModel copyWith({
    String? name,
    String? title,
    String? bio,
    String? photoUrl,
    List<String>? skills,
    List<String>? services,
    List<String>? categories,
    String? experienceLevel,
    List<String>? languages,
    double? hourlyRate,
    double? startingPrice,
    String? currency,
    double? rating,
    int? reviewsCount,
    int? completedOrders,
    bool? isTopRated,
    String? availability,
    List<PortfolioItem>? portfolio,
    DateTime? updatedAt,
  }) {
    return FreelancerModel(
      id: id,
      name: name ?? this.name,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      skills: skills ?? this.skills,
      services: services ?? this.services,
      categories: categories ?? this.categories,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      languages: languages ?? this.languages,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      startingPrice: startingPrice ?? this.startingPrice,
      currency: currency ?? this.currency,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      completedOrders: completedOrders ?? this.completedOrders,
      isTopRated: isTopRated ?? this.isTopRated,
      availability: availability ?? this.availability,
      portfolio: portfolio ?? this.portfolio,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
