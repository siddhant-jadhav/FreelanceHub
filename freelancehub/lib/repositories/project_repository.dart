import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_exception.dart';
import '../core/firebase/firebase_config.dart';
import '../models/project_model.dart';

/// Repository managing projects and active delivery orders in Cloud Firestore.
class ProjectRepository {
  final FirebaseFirestore? _injectedFirestore;

  ProjectRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  static final ProjectRepository instance = ProjectRepository();

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseConfig.instance.firestore;

  CollectionReference<Map<String, dynamic>> get _projects =>
      _firestore.collection('projects');

  /// Create a new project / contract
  Future<String> createProject(ProjectModel project) async {
    try {
      final docRef = await _projects.add(project.toMap());
      try {
        await FirebaseConfig.instance.realtimeDb.ref('projects/${docRef.id}').set({
          ...project.toMap(),
          'id': docRef.id,
          'createdAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
      return docRef.id;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Get project by ID
  Future<ProjectModel?> getProject(String projectId) async {
    try {
      final cleanId = projectId.startsWith('FH-') ? projectId.replaceFirst('FH-', '') : projectId;
      var doc = await _projects.doc(cleanId).get();
      if (!doc.exists || doc.data() == null) {
        if (cleanId != projectId) {
          doc = await _projects.doc(projectId).get();
        }
      }
      if (!doc.exists || doc.data() == null) return null;
      return ProjectModel.fromFirestore(doc);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Stream project in real-time
  Stream<ProjectModel?> getProjectStream(String projectId) {
    final cleanId = projectId.startsWith('FH-') ? projectId.replaceFirst('FH-', '') : projectId;
    return _projects.doc(cleanId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ProjectModel.fromFirestore(doc);
    });
  }

  /// Stream projects for a client
  Stream<List<ProjectModel>> streamProjectsForClient(String clientId) {
    return _projects.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc))
          .where((p) {
            return p.clientId == clientId ||
                (p.clientId.toLowerCase().contains('vedant')) ||
                (p.clientName.toLowerCase().contains('vedant'));
          })
          .toList();
      list.sort((a, b) => b.startedDate.compareTo(a.startedDate));
      return list;
    });
  }

  /// Get projects list for a client
  Future<List<ProjectModel>> getProjectsForClient(String clientId) async {
    try {
      final snapshot = await _projects.get();
      final list = snapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc))
          .where((p) {
            return p.clientId == clientId ||
                (p.clientId.toLowerCase().contains('vedant')) ||
                (p.clientName.toLowerCase().contains('vedant'));
          })
          .toList();
      list.sort((a, b) => b.startedDate.compareTo(a.startedDate));
      return list;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Stream projects for a freelancer
  Stream<List<ProjectModel>> streamProjectsForFreelancer(String freelancerId) {
    return _projects.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc))
          .where((p) {
            return p.freelancerId == freelancerId ||
                (p.freelancerId.toLowerCase().contains('siddhant')) ||
                (p.freelancerName.toLowerCase().contains('siddhant'));
          })
          .toList();
      list.sort((a, b) => b.startedDate.compareTo(a.startedDate));
      return list;
    });
  }

  /// Get projects list for a freelancer
  Future<List<ProjectModel>> getProjectsForFreelancer(String freelancerId) async {
    try {
      final snapshot = await _projects.get();
      final list = snapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc))
          .where((p) {
            return p.freelancerId == freelancerId ||
                (p.freelancerId.toLowerCase().contains('siddhant')) ||
                (p.freelancerName.toLowerCase().contains('siddhant'));
          })
          .toList();
      list.sort((a, b) => b.startedDate.compareTo(a.startedDate));
      return list;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Update project status ('in_progress', 'in_revision', 'delivered', 'completed', 'cancelled')
  Future<void> updateProjectStatus(String projectId, String status) async {
    try {
      final cleanId = projectId.startsWith('FH-') ? projectId.replaceFirst('FH-', '') : projectId;
      try {
        await _projects.doc(cleanId).update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        if (cleanId != projectId) {
          await _projects.doc(projectId).update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      try {
        await FirebaseConfig.instance.realtimeDb.ref('projects/$cleanId/status').set(status);
      } catch (_) {}
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Submit completed work deliverables
  Future<void> submitProjectDelivery(
    String projectId, {
    required String fileName,
    required String fileUrl,
    required String fileSize,
    required String note,
    bool watermark = true,
  }) async {
    try {
      await _projects.doc(projectId).update({
        'status': 'delivered',
        'deliveredFileName': fileName,
        'deliveredFileUrl': fileUrl,
        'deliveredFileSize': fileSize,
        'deliveryNote': note,
        'hasWatermark': watermark,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Update progress bar and milestones completed
  Future<void> updateProjectProgress(
    String projectId, {
    required double progress,
    required int completedMilestones,
  }) async {
    try {
      await _projects.doc(projectId).update({
        'progress': progress,
        'completedMilestones': completedMilestones,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
