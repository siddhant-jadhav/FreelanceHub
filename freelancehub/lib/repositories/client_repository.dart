import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_exception.dart';
import '../core/firebase/firebase_config.dart';
import '../models/client_model.dart';

/// Repository managing client collection operations in Cloud Firestore.
class ClientRepository {
  final FirebaseFirestore? _injectedFirestore;

  ClientRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  static final ClientRepository instance = ClientRepository();

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseConfig.instance.firestore;

  CollectionReference<Map<String, dynamic>> get _clients =>
      _firestore.collection('clients');

  /// Fetch client profile by UID
  Future<ClientModel?> getClient(String uid) async {
    try {
      final doc = await _clients.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return ClientModel.fromFirestore(doc);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Real-time stream of client profile
  Stream<ClientModel?> getClientStream(String uid) {
    return _clients.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ClientModel.fromFirestore(doc);
    });
  }

  /// Upsert full client record
  Future<void> saveClient(ClientModel client) async {
    try {
      await _clients
          .doc(client.id)
          .set(client.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Update partial client attributes
  Future<void> updateClient(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _clients.doc(uid).update(data);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Increment or decrement client active projects count
  Future<void> adjustActiveProjects(String uid, int delta) async {
    try {
      await _clients.doc(uid).update({
        'activeProjectsCount': FieldValue.increment(delta),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Record escrow or milestone expenditure
  Future<void> recordSpend(String uid, double amount) async {
    try {
      await _clients.doc(uid).update({
        'totalSpent': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
