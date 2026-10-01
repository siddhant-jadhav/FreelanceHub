import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_exception.dart';
import '../core/firebase/firebase_config.dart';

/// Low-level Cloud Firestore service providing transaction, batch,
/// collection, document, and converter helpers across FreelanceHub.
class FirestoreService {
  final FirebaseFirestore? _injectedFirestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  static final FirestoreService instance = FirestoreService();

  FirebaseFirestore get firestore =>
      _injectedFirestore ?? FirebaseConfig.instance.firestore;

  // Collection Reference Helper
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return firestore.collection(collectionPath);
  }

  // Document Reference Helper
  DocumentReference<Map<String, dynamic>> doc(String documentPath) {
    return firestore.doc(documentPath);
  }

  // Get a single document with error wrapping
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    String collectionPath,
    String documentId,
  ) async {
    try {
      return await collection(collectionPath).doc(documentId).get();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // Set document with merge support
  Future<void> setDocument(
    String collectionPath,
    String documentId,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    try {
      await collection(collectionPath)
          .doc(documentId)
          .set(data, SetOptions(merge: merge));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // Update document fields with server timestamp
  Future<void> updateDocument(
    String collectionPath,
    String documentId,
    Map<String, dynamic> data, {
    bool includeUpdatedAt = true,
  }) async {
    try {
      final payload = Map<String, dynamic>.from(data);
      if (includeUpdatedAt) {
        payload['updatedAt'] = FieldValue.serverTimestamp();
      }
      await collection(collectionPath).doc(documentId).update(payload);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // Delete document
  Future<void> deleteDocument(
    String collectionPath,
    String documentId,
  ) async {
    try {
      await collection(collectionPath).doc(documentId).delete();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // Stream document snapshots
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDocument(
    String collectionPath,
    String documentId,
  ) {
    return collection(collectionPath).doc(documentId).snapshots();
  }

  // Stream collection queries
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(
    String collectionPath, {
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)?
        queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }

  // Execute a Firestore Batch Write
  WriteBatch batch() => firestore.batch();

  Future<void> commitBatch(WriteBatch batch) async {
    try {
      await batch.commit();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // Execute a Firestore Transaction
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      return await firestore.runTransaction<T>(
        transactionHandler,
        timeout: timeout,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // FieldValue shortcuts
  FieldValue get serverTimestamp => FieldValue.serverTimestamp();
  FieldValue get deleteField => FieldValue.delete();
  FieldValue increment(num value) => FieldValue.increment(value);
  FieldValue arrayUnion(List<dynamic> elements) =>
      FieldValue.arrayUnion(elements);
  FieldValue arrayRemove(List<dynamic> elements) =>
      FieldValue.arrayRemove(elements);
}
