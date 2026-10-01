import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_exception.dart';
import '../core/firebase/firebase_config.dart';
import '../models/task_model.dart';

/// Repository managing task creation, retrieval, and marketplace queries.
class TaskRepository {
  final FirebaseFirestore? _injectedFirestore;

  TaskRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  static final TaskRepository instance = TaskRepository();

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseConfig.instance.firestore;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _firestore.collection('tasks');

  /// Create and publish a new task
  Future<String> createTask(TaskModel task) async {
    try {
      final docRef = await _tasks.add(task.toMap());
      return docRef.id;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Get single task by ID
  Future<TaskModel?> getTask(String taskId) async {
    try {
      final doc = await _tasks.doc(taskId).get();
      if (!doc.exists || doc.data() == null) return null;
      return TaskModel.fromFirestore(doc);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Stream a single task in real-time
  Stream<TaskModel?> getTaskStream(String taskId) {
    return _tasks.doc(taskId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return TaskModel.fromFirestore(doc);
    });
  }

  /// Stream open tasks for Buyer Requests and live opportunities
  Stream<List<TaskModel>> streamOpenTasks({
    String? category,
    int limit = 25,
  }) {
    Query<Map<String, dynamic>> query = _tasks
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true);

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
    });
  }

  /// Fetch tasks posted by a specific client
  Future<List<TaskModel>> getClientTasks(String clientId) async {
    try {
      final snapshot = await _tasks
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Stream tasks posted by a specific client
  Stream<List<TaskModel>> streamClientTasks(String clientId) {
    return _tasks
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
    });
  }

  /// Update task status ('open', 'in_progress', 'completed', 'cancelled')
  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      await _tasks.doc(taskId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Increment offers count on task
  Future<void> incrementOffersCount(String taskId) async {
    try {
      await _tasks.doc(taskId).update({
        'offersCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
