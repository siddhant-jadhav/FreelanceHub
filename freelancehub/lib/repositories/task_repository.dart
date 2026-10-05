import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart' show ServerValue;
import 'package:flutter/foundation.dart';
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
      // Mirror to Realtime DB for multi-engine synchronization
      try {
        await FirebaseConfig.instance.realtimeDb.ref('tasks/${docRef.id}').set({
          ...task.toMap(),
          'id': docRef.id,
          'createdAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
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
    Query<Map<String, dynamic>> query = _tasks.where('status', isEqualTo: 'open');

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      final tasks = snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    });
  }

  /// Fetch tasks posted by a specific client
  Future<List<TaskModel>> getClientTasks(String clientId) async {
    try {
      final snapshot = await _tasks
          .where('clientId', isEqualTo: clientId)
          .get();

      final list = snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Stream tasks posted by a specific client
  Stream<List<TaskModel>> streamClientTasks(String clientId) {
    return _tasks
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
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

  /// Increment offers count on task safely without crashing on mock IDs
  Future<void> incrementOffersCount(String taskId) async {
    try {
      final doc = await _tasks.doc(taskId).get();
      if (doc.exists) {
        await _tasks.doc(taskId).update({
          'offersCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      try {
        await FirebaseConfig.instance.realtimeDb.ref('tasks/$taskId/offersCount').set(ServerValue.increment(1));
      } catch (_) {}
    } catch (e) {
      debugPrint('incrementOffersCount notice: $e');
    }
  }
}
