import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment and Escrow transaction record.
class PaymentModel {
  final String id;
  final String projectId;
  final String? milestoneId;
  final String clientId;
  final String freelancerId;
  final double amount;
  final double platformFee;
  final double netAmount;
  final String status; // 'held_in_escrow', 'released', 'refunded', 'disputed'
  final String paymentMethod; // 'card', 'paypal', 'balance'
  final DateTime createdAt;
  final DateTime? releasedAt;

  const PaymentModel({
    required this.id,
    required this.projectId,
    this.milestoneId,
    required this.clientId,
    required this.freelancerId,
    required this.amount,
    this.platformFee = 0.0,
    required this.netAmount,
    this.status = 'held_in_escrow',
    this.paymentMethod = 'card',
    required this.createdAt,
    this.releasedAt,
  });

  bool get isHeldInEscrow => status == 'held_in_escrow';
  bool get isReleased => status == 'released';

  factory PaymentModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return PaymentModel(
      id: docId,
      projectId: (map['projectId'] as String?) ?? '',
      milestoneId: map['milestoneId'] as String?,
      clientId: (map['clientId'] as String?) ?? '',
      freelancerId: (map['freelancerId'] as String?) ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      platformFee: (map['platformFee'] as num?)?.toDouble() ?? 0.0,
      netAmount: (map['netAmount'] as num?)?.toDouble() ?? 0.0,
      status: (map['status'] as String?) ?? 'held_in_escrow',
      paymentMethod: (map['paymentMethod'] as String?) ?? 'card',
      createdAt: parseDate(map['createdAt']),
      releasedAt: map['releasedAt'] != null ? parseDate(map['releasedAt']) : null,
    );
  }

  factory PaymentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return PaymentModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'milestoneId': milestoneId,
      'clientId': clientId,
      'freelancerId': freelancerId,
      'amount': amount,
      'platformFee': platformFee,
      'netAmount': netAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
      'releasedAt': releasedAt != null ? Timestamp.fromDate(releasedAt!) : null,
    };
  }
}
