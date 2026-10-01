import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_exception.dart';
import '../core/firebase/firebase_config.dart';
import '../models/payment_model.dart';

/// Repository managing payment escrow deposits and releases in Cloud Firestore.
class PaymentRepository {
  final FirebaseFirestore? _injectedFirestore;

  PaymentRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  static final PaymentRepository instance = PaymentRepository();

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseConfig.instance.firestore;

  CollectionReference<Map<String, dynamic>> get _payments =>
      _firestore.collection('payments');

  /// Deposit funds into escrow for a project milestone
  Future<String> createEscrowDeposit(PaymentModel payment) async {
    try {
      final docRef = await _payments.add(payment.toMap());
      return docRef.id;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Mark escrow funds as released upon milestone approval
  Future<void> releaseEscrowPayment(String paymentId) async {
    try {
      await _payments.doc(paymentId).update({
        'status': 'released',
        'releasedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Get all payments for a project
  Future<List<PaymentModel>> getPaymentsForProject(String projectId) async {
    try {
      final snapshot = await _payments
          .where('projectId', isEqualTo: projectId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Real-time stream of payments for a project
  Stream<List<PaymentModel>> streamPaymentsForProject(String projectId) {
    return _payments
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Stream transactions for user (client or freelancer)
  Stream<List<PaymentModel>> streamUserPayments(
    String userId, {
    required bool isClient,
  }) {
    final field = isClient ? 'clientId' : 'freelancerId';
    return _payments
        .where(field, isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    });
  }
}
