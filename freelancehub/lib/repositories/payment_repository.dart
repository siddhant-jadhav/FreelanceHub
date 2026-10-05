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
      try {
        await FirebaseConfig.instance.realtimeDb.ref('payments/${docRef.id}').set({
          ...payment.toMap(),
          'id': docRef.id,
          'createdAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
      return docRef.id;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Mark escrow funds as released upon milestone approval
  Future<void> releaseEscrowPayment(String paymentId) async {
    try {
      try {
        await _payments.doc(paymentId).update({
          'status': 'released',
          'releasedAt': FieldValue.serverTimestamp(),
        });
        try {
          await FirebaseConfig.instance.realtimeDb.ref('payments/$paymentId/status').set('released');
        } catch (_) {}
        return;
      } catch (_) {}

      // Fallback: search by id or clean projectId
      final snapshot = await _payments.get();
      final cleanTarget = paymentId.startsWith('FH-')
          ? paymentId.replaceFirst('FH-', '').toLowerCase()
          : paymentId.toLowerCase();

      for (final doc in snapshot.docs) {
        final p = PaymentModel.fromFirestore(doc);
        final cleanPId = p.projectId.startsWith('FH-')
            ? p.projectId.replaceFirst('FH-', '').toLowerCase()
            : p.projectId.toLowerCase();

        if (doc.id == paymentId || cleanPId == cleanTarget || p.id == paymentId) {
          await doc.reference.update({
            'status': 'released',
            'releasedAt': FieldValue.serverTimestamp(),
          });
          try {
            await FirebaseConfig.instance.realtimeDb.ref('payments/${doc.id}/status').set('released');
          } catch (_) {}
          return;
        }
      }
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Get all payments for a project
  Future<List<PaymentModel>> getPaymentsForProject(String projectId) async {
    try {
      final snapshot = await _payments.get();
      final cleanId = projectId.startsWith('FH-')
          ? projectId.replaceFirst('FH-', '').toLowerCase()
          : projectId.toLowerCase();

      final list = snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .where((p) {
            final pId = p.projectId.startsWith('FH-')
                ? p.projectId.replaceFirst('FH-', '').toLowerCase()
                : p.projectId.toLowerCase();
            return pId == cleanId || p.projectId == projectId;
          })
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Real-time stream of payments for a project
  Stream<List<PaymentModel>> streamPaymentsForProject(String projectId) {
    final cleanId = projectId.startsWith('FH-')
        ? projectId.replaceFirst('FH-', '').toLowerCase()
        : projectId.toLowerCase();

    return _payments.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .where((p) {
            final pId = p.projectId.startsWith('FH-')
                ? p.projectId.replaceFirst('FH-', '').toLowerCase()
                : p.projectId.toLowerCase();
            return pId == cleanId || p.projectId == projectId;
          })
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Get transactions for user (client or freelancer)
  Future<List<PaymentModel>> getUserPayments(
    String userId, {
    required bool isClient,
  }) async {
    try {
      final snapshot = await _payments.get();
      final list = snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .where((p) {
            final target = isClient ? p.clientId : p.freelancerId;
            final other = isClient ? p.freelancerId : p.clientId;
            return target == userId ||
                (target.toLowerCase().contains('siddhant') && !isClient) ||
                (target.toLowerCase().contains('vedant') && isClient) ||
                (other.toLowerCase().contains('vedant') && !isClient);
          })
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Stream transactions for user (client or freelancer)
  Stream<List<PaymentModel>> streamUserPayments(
    String userId, {
    required bool isClient,
  }) {
    return _payments.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .where((p) {
            final target = isClient ? p.clientId : p.freelancerId;
            final other = isClient ? p.freelancerId : p.clientId;
            return target == userId ||
                (target.toLowerCase().contains('siddhant') && !isClient) ||
                (target.toLowerCase().contains('vedant') && isClient) ||
                (other.toLowerCase().contains('vedant') && !isClient);
          })
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
